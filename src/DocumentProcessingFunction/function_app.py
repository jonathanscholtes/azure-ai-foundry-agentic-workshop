import azure.functions as func
import azure.durable_functions as df
from azure.identity import DefaultAzureCredential
from azure.core.credentials import AzureKeyCredential
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
    SemanticSearch,
    AzureOpenAIVectorizer,
    AzureOpenAIVectorizerParameters,
    SearchIndexerDataUserAssignedIdentity 
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

   
    
    file_name = myblob.name.split('/')[-1] 

    # Start the Durable Functions orchestration
    instance_id = await client.start_new("document_orchestrator", None, {"filename": file_name,"data": base64_bytes.decode('ascii')})
    logging.info(f"Started orchestration with ID = '{instance_id}'.")


# Orchestrator Function
@myApp.orchestration_trigger(context_name="context")
def document_orchestrator(context):
    """
    Orchestrates multiple activities based on the input from the Blob trigger.
    """
    data_base64 = context.get_input()["data"]
    filename = context.get_input()["filename"]

    logging.info(f"File Name: {filename} ")
    logging.info(f"Data: {data_base64} ")
    
    # Chunk the document
    chunks = yield context.call_activity('chunk_pdf', {"filename": filename,"data": data_base64})

    # Generate embeddings
    embeddings = yield context.call_activity('generate_embeddings', chunks)

    # Update search index
    yield context.call_activity('update_search_index', embeddings)

    # Move the blob to a "completed" container
    yield context.call_activity('move_blob', {"filename": filename,"data": data_base64})
    
    return "Orchestration Completed"


### Activity Functions ##

# Chunking the PDF
@myApp.activity_trigger(input_name="input")
def chunk_pdf(input: dict):
    try:

        data_base64 = input.get("data")
        filename = input.get("filename")

        logging.info(f"Reading and chunking PDF: {len(data_base64)} bytes")


        base64_bytes = data_base64.encode('ascii')
        pdf_data = base64.b64decode(base64_bytes)
        pdf_file = io.BytesIO(pdf_data)
        doc = fitz.open(stream=pdf_file, filetype="pdf")

        documents = []
        for index, page in enumerate(doc):
            documents.append({
                "page_content": page.get_text(),
                "metadata": {"title": filename, "page_number": index + 1}
            })

        # Chunking
        splitter = RecursiveCharacterTextSplitter(
            chunk_size=int(environ.get("DOCUMENT_CHUNK_SIZE")),
            chunk_overlap=int(environ.get("DOCUMENT_CHUNK_OVERLAP"))
        )
        chunks = splitter.split_documents([Document(**doc) for doc in documents])

        for chunk in chunks:
            chunk.metadata["chunk_id"] = str(uuid.uuid4())

        # Return as list of plain dicts (JSON-serializable)
        return [{"content": c.page_content, "metadata": c.metadata} for c in chunks]

    except Exception as ex:
        logging.error(f"Error chunking PDF: {ex}")
        logging.error(traceback.format_exc())
        raise ex


# Generate embeddings for the chunks
@myApp.activity_trigger(input_name="chunks")
def generate_embeddings(chunks: List[dict]):
    try:
        logging.info(f"Generating embeddings for {len(chunks)} chunks")

        credential = DefaultAzureCredential()

        # Set the API type to `azure_ad`
        environ["OPENAI_API_TYPE"] = "azure_ad"
        # Set the API_KEY to the token from the Azure credential
        token = credential.get_token("https://cognitiveservices.azure.com/.default").token
        environ["OPENAI_API_KEY"] = token

        environ["AZURE_OPENAI_AD_TOKEN"] = environ["OPENAI_API_KEY"]

        embeddings = AzureOpenAIEmbeddings(
            azure_deployment=environ.get("AZURE_OPENAI_EMBEDDING"),
            openai_api_version=environ.get("AZURE_OPENAI_API_VERSION"),
            azure_endpoint=environ.get("AZURE_OPENAI_ENDPOINT"),
            api_key=environ.get("OPENAI_API_KEY")
        )
        
        embeddings_list = []
        for chunk in chunks:
            content = chunk["content"]
            metadata = chunk.get("metadata", {})
            embedding = embeddings.embed_query(content)

            chunk_id = str(metadata.get("chunk_id"))
            title = str(metadata.get("title"))
            page_number = str(metadata.get("page_number")) 
            
            embeddings_list.append({           
                "chunk_id": chunk_id,
                "content": content,
                "title": title,
                "pageNumber": page_number,
                "content_vector": embedding
            })
        
        return embeddings_list

    except Exception as ex:
        logging.error(f"Error generating embeddings: {ex}")
        logging.error(traceback.format_exc())
        raise ex




# Update search index with the embeddings
@myApp.activity_trigger(input_name="embeddings")
def update_search_index(embeddings):
    try:
        logging.info(f"Updating search index with {len(embeddings)} embeddings")

    
        # Configuration for Azure Cognitive Search
        search_endpoint = environ["AZURE_AI_SEARCH_ENDPOINT"]
        index_name = environ["AZURE_AI_SEARCH_INDEX"]
        search_api_key = environ["AZURE_AI_SEARCH_API_KEY"]

        ### Switched to Key to resolve ###
        ### - occasional random failures:Failed to get Azure RBAC authorization decision ###

        # Initialize the Azure credentials
        credential = AzureKeyCredential(search_api_key)

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
                    profiles=[VectorSearchProfile(name="my-vector-config", algorithm_configuration_name="my-algorithms-config",vectorizer_name="my-vectorizer")],
                    algorithms=[HnswAlgorithmConfiguration(name="my-algorithms-config", kind="hnsw")],
                    vectorizers=[
                    AzureOpenAIVectorizer(
                        vectorizer_name="my-vectorizer",
                        kind= "azureOpenAI",
                         parameters=AzureOpenAIVectorizerParameters(
                                resource_url=environ["AZURE_OPENAI_ENDPOINT"],   
                                deployment_name=environ["AZURE_OPENAI_EMBEDDING"],
                                model_name="text-embedding-ada-002",
                                auth_identity= SearchIndexerDataUserAssignedIdentity(odata_type="#Microsoft.Azure.Search.DataUserAssignedIdentity",
                                 resource_id=str(environ["AZURE_CLIENT_RESOURCE_ID"]))
                                )
                        )
                ]
                )
                
            )

            try:
                search_index_client.create_index(index)
            except Exception as ex:
                logging.error(f"Error creating search index: {ex}")
                logging.error(traceback.format_exc())

        # Now process the embeddings and upload them in batches
        documents = []
        batch_size = int(environ.get("AZURE_AI_SEARCH_BATCH_SIZE"))
        total_batches = (len(embeddings) + batch_size - 1) // batch_size
        batches_processed = 0

        for index, embedding in enumerate(embeddings):
            try:
                # Prepare the metadata and content for the index
                chunk_id = str(embedding["chunk_id"])
                content = str(embedding["content"])
                title = str(embedding["title"])
                page_number = str(embedding["pageNumber"])
                content_vector = embedding["content_vector"]

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
                logging.info((embedding))
                raise ex

    except Exception as ex:
        logging.error(f"Error updating search index: {ex}")
        logging.error(traceback.format_exc())
        raise ex



# Move the processed blob to the "completed" container
@myApp.activity_trigger(input_name="input")
def move_blob(input: dict):
    try:

        data_base64 = input.get("data")
        filename = input.get("filename")

        logging.info(f"Moving blob {filename} to the completed container")

        base64_bytes = data_base64.encode('ascii')
        pdf_data = base64.b64decode(base64_bytes)

        container_name = "load"
        completed_container = "completed"

        # Blob storage logic to move the file
        credential = DefaultAzureCredential()
        AZURE_STORAGE_URL = environ.get("AZURE_STORAGE_URL")

        # Create the BlobServiceClient object    
        blob_service_client =  BlobServiceClient(AZURE_STORAGE_URL, credential=credential)    
        blob_client = blob_service_client.get_blob_client(container=container_name, blob=filename)
        
        # Upload to completed container
        completed_blob_client = blob_service_client.get_blob_client(container=completed_container, blob=filename)
        completed_blob_client.upload_blob(pdf_data, overwrite=True)
        
        logging.info(f"Deleted blob: {filename}")
        blob_client.delete_blob()

    except Exception as ex:
        logging.error(f"Error moving blob: {ex}")
        logging.error(traceback.format_exc())
        raise ex
