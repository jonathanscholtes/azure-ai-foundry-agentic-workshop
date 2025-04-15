from .init import abfs, storage_account_container
from model.records_model import DataCenterEnergyRecord
import pandas as pd
import numpy as np


def get_all_data_center_energy() -> list[DataCenterEnergyRecord]:
    """Read energy usage data from Azure Blob Storage and return as list of DataCenterEnergyRecord models."""

    full_blob_path = f"{storage_account_container}/usage.parquet"

    with abfs.open(full_blob_path, 'rb') as f:
        df = pd.read_parquet(f, engine="pyarrow")

    # Convert each row to a DataCenterEnergyRecord
    records = [DataCenterEnergyRecord(**row) for row in df.to_dict(orient="records")]

    return records
  
