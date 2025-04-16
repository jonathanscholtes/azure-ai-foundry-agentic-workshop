import logging
from fastapi import APIRouter, Response,Query
from service import energy_usage
from model.records_model import DataCenterEnergyRecord
from fastapi.logger import logger
from typing import List,Optional

gunicorn_logger = logging.getLogger("gunicorn.error")
logger.handlers = gunicorn_logger.handlers
logger.setLevel(gunicorn_logger.level)

# Initialize Router with "/content" prefix
router = APIRouter(prefix="/usage")

@router.get("/energy-usage", response_model=List[DataCenterEnergyRecord], 
    summary="Get Energy Usage",
    description="Retrieve energy usage data for data centers. You can filter by `alarm_status` (e.g., critical), `zone`, or other fields.",
)
def get_energy_usage( alarm_status: Optional[str] = Query(
        None, description="Filter by alarm status (e.g., normal, warning, critical)"
    ),
    zone: Optional[str] = Query(
        None, description="Filter by zone identifier (e.g., A1, B2, C3)"
    )):

    all_data = energy_usage.get_all_data_center_energy()


    filtered_data = [
        record for record in all_data
        if (not alarm_status or record.alarm_status == alarm_status)
        and (not zone or record.zone == zone)

    ]
    return filtered_data