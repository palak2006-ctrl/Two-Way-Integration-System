from abc import ABC, abstractmethod
from typing import Dict, Any, Optional


class BaseIntegration(ABC):
    """Base class for all external integrations"""
    
    @abstractmethod
    def create_customer(self, customer_data: Dict[str, Any]) -> Optional[str]:
        """Create customer in external system, return external ID"""
        pass
    
    @abstractmethod
    def update_customer(self, external_id: str, customer_data: Dict[str, Any]) -> bool:
        """Update customer in external system"""
        pass
    
    @abstractmethod
    def delete_customer(self, external_id: str) -> bool:
        """Delete customer in external system"""
        pass
    
    @abstractmethod
    def get_customer(self, external_id: str) -> Optional[Dict[str, Any]]:
        """Fetch customer from external system"""
        pass
    
    @property
    @abstractmethod
    def integration_name(self) -> str:
        """Return integration name"""
        pass
