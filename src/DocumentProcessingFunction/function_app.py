import azure.functions as func
import azure.durable_functions as df
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
from azure.search.documents import SearchClient
from azure.search.documents.indexes import SearchIndexClient
from azure.search.documents.indexes.models import (
    SearchIndex,
    SimpleField,
    SearchableField,
    SearchField,
    SemanticConfiguration,
    SemanticField,
    VectorSearch,
    VectorSearchProfile,
    SemanticPrioritizedFields,
    HnswAlgorithmConfiguration,
    SemanticSearch
)
from azure.core.exceptions import ResourceNotFoundError
from langchain_openai import AzureOpenAIEmbeddings
from langchain_core.documents import Document
from langchain.text_splitter import RecursiveCharacterTextSplitter
import logging
import traceback
from os import environ
import base64
import io
import fitz
import uuid
from typing import List


myApp = df.DFApp(http_auth_level=func.AuthLevel.ANONYMOUS)

# Blob Trigger Function to start the Durable Function orchestration
@myApp.blob_trigger(arg_name="myblob", path="load", connection="BlobTriggerConnection")
@myApp.durable_client_input(client_name="client")
async def blob_trigger_start(myblob: func.InputStream, client):
    logging.info(f"Python blob trigger function processed blob\n"
                 f"Name: {myblob.name}\n"
                 f"Blob Size: {myblob.length} bytes")
    
    if not myblob.name.lower().endswith('.pdf'):
        logging.info(f"Skipping processing: {myblob.name} is not a .pdf file.")
        return f"Skipping processing: {myblob.name} is not a .pdf file."
    
    # Read the blob content and encode it to base64
    base64_bytes = base64.b64encode(myblob.read())

    credential = DefaultAzureCredential()

    # Set the API type to `azure_ad`
    environ["OPENAI_API_TYPE"] = "azure_ad"
    # Set the API_KEY to the token from the Azure credential
    token = credential.get_token("https://cognitiveservices.azure.com/.default").token
    environ["OPENAI_API_KEY"] = token

    environ["AZURE_OPENAI_AD_TOKEN"] = environ["OPENAI_API_KEY"]
    
    # Start the Durable Functions orchestration
    instance_id = await client.start_new("document_orchestrator", None, {"filename": myblob.name, "data": base64_bytes.decode('ascii')})
    logging.info(f"Started orchestration with ID = '{instance_id}'.")


# Orchestrator Function
@myApp.orchestration_trigger(context_name="context")
def document_orchestrator(context):
    """
    Orchestrates multiple activities based on the input from the Blob trigger.
    """
    data_base64 = context.get_input()["data"]
    filename = context.get_input()["filename"]

    logging.info(f"File Name: {filename}")
    
    # Convert the base64 data back to the original binary PDF
    pdf_content = base64.b64decode(data_base64)
    
    # Chunk the document
    chunks = yield context.call_activity('chunk_pdf', pdf_content, filename)

    # Generate embeddings
    embeddings = yield context.call_activity('generate_embeddings', chunks)

    # Update search index
    yield context.call_activity('update_search_index', embeddings)

    # Move the blob to a "completed" container
    yield context.call_activity('move_blob', filename, pdf_content)
    
    return "Orchestration Completed"


### Activity Functions ###

# Chunking the PDF
@myApp.activity_trigger
def chunk_pdf(pdf_content: bytes, filename: str):
    try:
        logging.info(f"Processing PDF: {filename}")
        pdf_file = io.BytesIO(pdf_content)
        doc = fitz.open(stream=pdf_file)
        
        documents: List[Document] = []
        for index, page in enumerate(doc):
            document = Document(page_content=page.get_text(), metadata={"title": filename, "page_number": index + 1})
            documents.append(document)

        # Split the document into chunks
        text_splitter = RecursiveCharacterTextSplitter(chunk_size=int(environ.get("DOCUMENT_CHUNK_SIZE")), chunk_overlap=int(environ.get("DOCUMENT_CHUNK_OVERLAP")))
        chunks = text_splitter.split_documents(documents)

        for chunk in chunks:
            chunk.metadata["chunk_id"] = str(uuid.uuid4())
        
        return chunks
    
    except Exception as ex:
        logging.error(f"Error chunking PDF: {ex}")
        raise ex


# Generate embeddings for the chunks
@myApp.activity_trigger
def generate_embeddings(chunks: List[Document]):
    try:
        logging.info(f"Generating embeddings for {len(chunks)} chunks")

        # Initialize Azure OpenAI Embeddings
        embeddings = AzureOpenAIEmbeddings(
            azure_deployment=environ.get("AZURE_OPENAI_EMBEDDING"),
            openai_api_version=environ.get("AZURE_OPENAI_API_VERSION"),
            azure_endpoint=environ.get("AZURE_OPENAI_ENDPOINT"),
            api_key=environ.get("AZURE_OPENAI_API_KEY")
        )
        
        embeddings_list = []
        for chunk in chunks:
            embedding = embeddings.embed_query(chunk.page_content)
            embeddings_list.append({
                "chunk_id": chunk.metadata["chunk_id"],
                "content": chunk.page_content,
                "embedding": embedding
            })
        
        return embeddings_list
    
    except Exception as ex:
        logging.error(f"Error generating embeddings: {ex}")
        raise ex


# Update search index with the embeddings
@myApp.activity_trigger
@myApp.activity_trigger
def update_search_index(embeddings):
    try:
        logging.info(f"Updating search index with {len(embeddings)} embeddings")

        # Initialize the Azure credentials
        credential = DefaultAzureCredential()

        # Configuration for Azure Cognitive Search
        search_endpoint = environ["AZURE_AI_SEARCH_ENDPOINT"]
        index_name = environ["AZURE_AI_SEARCH_INDEX"]

        # Create SearchClient
        search_client = SearchClient(endpoint=search_endpoint, index_name=index_name, credential=credential)

        # Create SearchIndexClient
        search_index_client = SearchIndexClient(endpoint=search_endpoint, credential=credential)

        # Check if the index exists and contains documents
        index_exists = False
        try:
            logging.info("Verifying if AI Search index exists...")
            search_index_client.get_index(index_name)
            index_exists = True
        except ResourceNotFoundError:
            logging.info("AI Search index not found, creating index...")

        # Create the index if it doesn't exist
        if not index_exists:
            semantic_config = SemanticConfiguration(
                name="default",
                prioritized_fields=SemanticPrioritizedFields(
                    title_field=SemanticField(field_name="title"),
                    content_fields=[SemanticField(field_name="content")]
                )
            )

            index = SearchIndex(
                name=index_name,
                fields=[
                    SimpleField(name="chunk_id", type="Edm.String", key=True, filterable=True, sortable=True),
                    SearchableField(name="content", type="Edm.String", filterable=True, sortable=True),
                    SearchableField(name="title", type="Edm.String", filterable=True, sortable=True),
                    SearchableField(name="pageNumber", type="Edm.Int", filterable=True, sortable=True),
                    SearchField(name="content_vector", type="Collection(Edm.Single)", vector_search_dimensions=1536, vector_search_profile_name="my-vector-config")
                ],
                semantic_search=SemanticSearch(configurations=[semantic_config]),
                vector_search=VectorSearch(
                    profiles=[VectorSearchProfile(name="my-vector-config", algorithm_configuration_name="my-algorithms-config")],
                    algorithms=[HnswAlgorithmConfiguration(name="my-algorithms-config", kind="hnsw")]
                )
            )

            try:
                search_index_client.create_index(index)
            except Exception as ex:
                logging.info("Index was created on different thread")

        # Now process the embeddings and upload them in batches
        documents = []
        batch_size = environ.get("AZURE_AI_SEARCH_BATCH_SIZE") 
        total_batches = (len(embeddings) + batch_size - 1) // batch_size
        batches_processed = 0

        for index, embedding in enumerate(embeddings):
            try:
                # Prepare the metadata and content for the index
                chunk_id = str(embedding["chunk_id"])
                content = str(embedding["content"])
                title = str(embedding["title"])
                page_number = str(embedding["pageNumber"])

                # Generate the embedding for the content
                # Assuming AzureOpenAIEmbeddings is used to generate embeddings for the content
                embedding_instance = AzureOpenAIEmbeddings(
                    azure_deployment=environ.get("AZURE_OPENAI_EMBEDDING"),
                    openai_api_version=environ.get("AZURE_OPENAI_API_VERSION"),
                    azure_endpoint=environ.get("AZURE_OPENAI_ENDPOINT"),
                    api_key=environ.get("AZURE_OPENAI_API_KEY")
                )
                content_vector = embedding_instance.embed_query(content)

                # Add the document to the batch
                documents.append({
                    "chunk_id": chunk_id,
                    "content": content,
                    "title": title,
                    "pageNumber": page_number,
                    "content_vector": content_vector
                })

                # Upload the batch if the batch size is reached or this is the last document
                if (index + 1) % batch_size == 0 or (index + 1) == len(embeddings):
                    result = search_client.upload_documents(documents=documents)

                    batches_processed += 1
                    batches_remaining = total_batches - batches_processed
                    logging.info(f"Batch {batches_processed}/{total_batches} uploaded. Remaining: {batches_remaining}")

                    # Clear the documents list for the next batch
                    documents = []
            except Exception as ex:
                logging.error(f"Error processing embedding: {ex}")
                raise ex

    except Exception as ex:
        logging.error(f"Error updating search index: {ex}")
        raise ex



# Move the processed blob to the "completed" container
@myApp.activity_trigger
def move_blob(filename: str, pdf_content: bytes):
    try:
        logging.info(f"Moving blob {filename} to the completed container")
        container_name = "load"
        blob_name = filename
        completed_container = "completed"

        # Blob storage logic to move the file
        credential = DefaultAzureCredential()
        blob_service_client = BlobServiceClient.from_connection_string(environ["BlobTriggerConnection"])
        blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)
        
        # Upload to completed container
        completed_blob_client = blob_service_client.get_blob_client(container=completed_container, blob=blob_name)
        completed_blob_client.upload_blob(pdf_content, overwrite=True)

        # Optionally delete the original blob
        blob_client.delete_blob()

    except Exception as ex:
        logging.error(f"Error moving blob: {ex}")
        raise ex
