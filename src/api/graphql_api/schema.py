import strawberry
from typing import List
from graphql_api.types import DataCenterEnergyRecordType
from graphql_api.converters import to_graphql
from service.energy_usage import get_all_data_center_energy

import logging

logger = logging.getLogger(__name__)

@strawberry.type
class Query:
    @strawberry.field
    def energy_usage(self) -> List[DataCenterEnergyRecordType]:
        records = get_all_data_center_energy()
        logger.info(f"Fetched records sample: {records[:1]}")
        return [to_graphql(record) for record in records]

schema = strawberry.Schema(query=Query)
