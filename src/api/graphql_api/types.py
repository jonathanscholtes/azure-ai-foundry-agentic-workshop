import strawberry
from typing import Optional
from datetime import datetime
from enum import Enum

@strawberry.enum
class Zone(Enum):
    A1 = "A1"
    B2 = "B2"
    C3 = "C3"

@strawberry.enum
class BatteryBackupStatus(Enum):
    ONLINE = "online"
    CHARGING = "charging"
    DISCHARGING = "discharging"
    OFFLINE = "offline"

@strawberry.enum
class GridEnergySource(Enum):
    GRID = "grid"
    SOLAR = "solar"
    DIESEL = "diesel"
    BATTERY = "battery"

@strawberry.enum
class AlarmStatus(Enum):
    NORMAL = "normal"
    WARNING = "warning"
    CRITICAL = "critical"

@strawberry.type
class DataCenterEnergyRecordType:
    timestamp: datetime
    data_center_id: str
    zone: Zone
    power_draw_kw: float
    it_load_kw: float
    cooling_load_kw: float
    pue: float
    temperature_c: float
    humidity_percent: float
    ups_load_percent: float
    battery_backup_status: BatteryBackupStatus
    grid_energy_source: GridEnergySource
    co2_emissions_kg: float
    alarm_status: AlarmStatus
    operator_notes: Optional[str]
