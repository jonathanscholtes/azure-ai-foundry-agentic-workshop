import strawberry
from typing import List
from graphql_api.types import DataCenterEnergyRecordType
from graphql_api.converters import to_graphql
from service.energy_usage import get_all_data_center_energy

@strawberry.type
class Query:
    @strawberry.field
    def energy_usage(self) -> List[DataCenterEnergyRecordType]:
        records = get_all_data_center_energy()  # returns List[DataCenterEnergyRecord]
        return [to_graphql(record) for record in records]

schema = strawberry.Schema(query=Query)
