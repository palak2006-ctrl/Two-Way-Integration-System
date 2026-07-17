from typing import Optional
from app.integrations.base import BaseIntegration
from app.integrations.stripe_integration import StripeIntegration


class IntegrationFactory:
    """Factory to create integration instances"""
    
    _integrations = {
        "stripe": StripeIntegration
    }
    
    @classmethod
    def get_integration(cls, integration_name: str) -> Optional[BaseIntegration]:
        """Get integration instance by name"""
        integration_class = cls._integrations.get(integration_name.lower())
        if integration_class:
            return integration_class()
        return None
    
    @classmethod
    def register_integration(cls, name: str, integration_class: type):
        """Register new integration dynamically"""
        cls._integrations[name.lower()] = integration_class
