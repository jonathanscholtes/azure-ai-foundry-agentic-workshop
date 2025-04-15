from data.storageaccount import energy_usage
from model.records_model import DataCenterEnergyRecord


def get_all_data_center_energy()-> list[DataCenterEnergyRecord]:
    return energy_usage.get_all_data_center_energy()