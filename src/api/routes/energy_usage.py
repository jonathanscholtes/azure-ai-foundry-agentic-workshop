import logging
from fastapi import APIRouter, Response
from service import energy_usage
from model.records_model import DataCenterEnergyRecord
from fastapi.logger import logger
from typing import List

gunicorn_logger = logging.getLogger("gunicorn.error")
logger.handlers = gunicorn_logger.handlers
logger.setLevel(gunicorn_logger.level)

# Initialize Router with "/content" prefix
router = APIRouter(prefix="/usage")

@router.get("/energy-usage", response_model=List[DataCenterEnergyRecord])
def get_energy_usage():
    return energy_usage.get_all_data_center_energy()