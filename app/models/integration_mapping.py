from sqlalchemy import Column, Integer, String, DateTime, func, UniqueConstraint
from app.database import Base


class IntegrationMapping(Base):
    """Maps internal customer IDs to external system IDs"""
    __tablename__ = "integration_mappings"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    internal_id = Column(Integer, nullable=False, index=True)
    external_id = Column(String(255), nullable=False, index=True)
    integration_name = Column(String(50), nullable=False, index=True)  # 'stripe', 'salesforce', etc.
    entity_type = Column(String(50), nullable=False)  # 'customer', 'invoice', etc.
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), server_default=func.now())
    
    __table_args__ = (
        UniqueConstraint('internal_id', 'integration_name', 'entity_type', name='uix_internal_integration_entity'),
        UniqueConstraint('external_id', 'integration_name', 'entity_type', name='uix_external_integration_entity'),
    )
