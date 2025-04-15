from model.records_model import DataCenterEnergyRecord
from graphql_api.types import DataCenterEnergyRecordType, Zone, BatteryBackupStatus, GridEnergySource, AlarmStatus

def to_graphql(record: DataCenterEnergyRecord) -> DataCenterEnergyRecordType:
    return DataCenterEnergyRecordType(
        timestamp=record.timestamp,
        data_center_id=record.data_center_id,
        zone=Zone(record.zone),
        power_draw_kw=record.power_draw_kw,
        it_load_kw=record.it_load_kw,
        cooling_load_kw=record.cooling_load_kw,
        pue=record.pue,
        temperature_c=record.temperature_c,
        humidity_percent=record.humidity_percent,
        ups_load_percent=record.ups_load_percent,
        battery_backup_status=BatteryBackupStatus(record.battery_backup_status),
        grid_energy_source=GridEnergySource(record.grid_energy_source),
        co2_emissions_kg=record.co2_emissions_kg,
        alarm_status=AlarmStatus(record.alarm_status),
        operator_notes=record.operator_notes,
    )
