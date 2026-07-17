from enum import Enum
from pydantic import BaseModel
from typing import Optional, Dict, Any
from datetime import datetime


class EventType(str, Enum):
    CUSTOMER_CREATED = "customer.created"
    CUSTOMER_UPDATED = "customer.updated"
    CUSTOMER_DELETED = "customer.deleted"


class CustomerEvent(BaseModel):
    event_type: EventType
    customer_id: int
    customer_data: Dict[str, Any]
    source: str = "internal"  # 'internal' or 'stripe'
    timestamp: datetime = datetime.utcnow()
    idempotency_key: Optional[str] = None
    
    class Config:
        use_enum_values = True
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
