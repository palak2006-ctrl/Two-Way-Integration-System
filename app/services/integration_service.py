from sqlalchemy.orm import Session
from typing import Optional
from app.models.integration_mapping import IntegrationMapping
import logging

logger = logging.getLogger(__name__)


class IntegrationService:
    def __init__(self, db: Session):
        self.db = db
    
    def create_mapping(
        self,
        internal_id: int,
        external_id: str,
        integration_name: str,
        entity_type: str = "customer"
    ) -> IntegrationMapping:
        """Create integration mapping"""
        mapping = IntegrationMapping(
            internal_id=internal_id,
            external_id=external_id,
            integration_name=integration_name,
            entity_type=entity_type
        )
        self.db.add(mapping)
        self.db.commit()
        self.db.refresh(mapping)
        return mapping
    
    def get_external_id(
        self,
        internal_id: int,
        integration_name: str,
        entity_type: str = "customer"
    ) -> Optional[str]:
        """Get external ID from internal ID"""
        mapping = self.db.query(IntegrationMapping).filter(
            IntegrationMapping.internal_id == internal_id,
            IntegrationMapping.integration_name == integration_name,
            IntegrationMapping.entity_type == entity_type
        ).first()
        return mapping.external_id if mapping else None
    
    def get_internal_id(
        self,
        external_id: str,
        integration_name: str,
        entity_type: str = "customer"
    ) -> Optional[int]:
        """Get internal ID from external ID"""
        mapping = self.db.query(IntegrationMapping).filter(
            IntegrationMapping.external_id == external_id,
            IntegrationMapping.integration_name == integration_name,
            IntegrationMapping.entity_type == entity_type
        ).first()
        return mapping.internal_id if mapping else None
    
    def delete_mapping(
        self,
        internal_id: int,
        integration_name: str,
        entity_type: str = "customer"
    ) -> bool:
        """Delete mapping"""
        mapping = self.db.query(IntegrationMapping).filter(
            IntegrationMapping.internal_id == internal_id,
            IntegrationMapping.integration_name == integration_name,
            IntegrationMapping.entity_type == entity_type
        ).first()
        
        if mapping:
            self.db.delete(mapping)
            self.db.commit()
            return True
        return False
