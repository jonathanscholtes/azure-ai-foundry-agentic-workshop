from pydantic import BaseModel
from typing import Optional, Literal
from datetime import datetime

class DataCenterEnergyRecord(BaseModel):
    timestamp: datetime
    data_center_id: str
    zone: Literal['A1', 'B2', 'C3']
    power_draw_kw: float
    it_load_kw: float
    cooling_load_kw: float
    pue: float
    temperature_c: float
    humidity_percent: float
    ups_load_percent: float
    battery_backup_status: Literal['online', 'charging', 'discharging', 'offline']
    grid_energy_source: Literal['grid', 'solar', 'diesel', 'battery']
    co2_emissions_kg: float
    alarm_status: Literal['normal', 'warning', 'critical']
    operator_notes: Optional[str]