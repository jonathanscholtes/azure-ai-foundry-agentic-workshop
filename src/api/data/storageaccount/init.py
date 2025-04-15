from os import environ
from dotenv import load_dotenv
from azure.identity import DefaultAzureCredential
from adlfs import AzureBlobFileSystem

load_dotenv(override=True)

abfs :AzureBlobFileSystem | None = None
storage_account_container:str |None=None

def storage_init():

    credential = DefaultAzureCredential()

    AZURE_STORAGE_URL = environ.get("AZURE_STORAGE_URL")
    AZURE_STORAGE_CONTAINER = environ.get("AZURE_STORAGE_CONTAINER")
    global abfs
    global storage_account_container


    storage_account_container = AZURE_STORAGE_CONTAINER
    abfs  =  AzureBlobFileSystem(AZURE_STORAGE_URL, credential=credential)


storage_init()