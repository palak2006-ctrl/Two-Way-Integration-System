import stripe
import logging
from typing import Dict, Any, Optional
from app.integrations.base import BaseIntegration
from app.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

stripe.api_key = settings.stripe_api_key


class StripeIntegration(BaseIntegration):
    """Stripe customer integration implementation"""
    
    @property
    def integration_name(self) -> str:
        return "stripe"
    
    def create_customer(self, customer_data: Dict[str, Any]) -> Optional[str]:
        """Create customer in Stripe"""
        try:
            customer = stripe.Customer.create(
                name=customer_data.get("name"),
                email=customer_data.get("email"),
                metadata={
                    "internal_id": str(customer_data.get("id"))
                }
            )
            logger.info(f"Created Stripe customer: {customer.id}")
            return customer.id
        except stripe.error.StripeError as e:
            logger.error(f"Stripe API error: {e}")
            return None
    
    def update_customer(self, external_id: str, customer_data: Dict[str, Any]) -> bool:
        """Update customer in Stripe"""
        try:
            update_data = {}
            if "name" in customer_data:
                update_data["name"] = customer_data["name"]
            if "email" in customer_data:
                update_data["email"] = customer_data["email"]
            
            stripe.Customer.modify(external_id, **update_data)
            logger.info(f"Updated Stripe customer: {external_id}")
            return True
        except stripe.error.StripeError as e:
            logger.error(f"Stripe API error: {e}")
            return False
    
    def delete_customer(self, external_id: str) -> bool:
        """Delete customer in Stripe"""
        try:
            stripe.Customer.delete(external_id)
            logger.info(f"Deleted Stripe customer: {external_id}")
            return True
        except stripe.error.StripeError as e:
            logger.error(f"Stripe API error: {e}")
            return False
    
    def get_customer(self, external_id: str) -> Optional[Dict[str, Any]]:
        """Fetch customer from Stripe"""
        try:
            customer = stripe.Customer.retrieve(external_id)
            return {
                "name": customer.name,
                "email": customer.email,
                "external_id": customer.id
            }
        except stripe.error.StripeError as e:
            logger.error(f"Stripe API error: {e}")
            return None
