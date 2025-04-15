from pydantic import BaseModel
from typing import Optional

class InitRequest(BaseModel):
    rows: Optional[int] = 100
    overwrite: Optional[bool] = True

class InitResponse(BaseModel):
    message: str
    rows_written: int