from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.queue.consumer import EventConsumer
from app.queue.events import EventType
from app.integrations.factory import IntegrationFactory
from app.services.integration_service import IntegrationService
from app.services.customer_service import CustomerService
from app.schemas.customer import CustomerCreate, CustomerUpdate
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class SyncWorker:
    """Worker to process customer events and sync with external systems"""
    
    def __init__(self):
        self.integration = IntegrationFactory.get_integration("stripe")
    
    def process_event(self, event_data: dict):
        """Process customer event from Kafka"""
        db = SessionLocal()
        try:
            event_type = event_data.get("event_type")
            customer_id = event_data.get("customer_id")
            customer_data = event_data.get("customer_data")
            source = event_data.get("source", "internal")
            
            # Skip events from external sources to avoid infinite loops
            if source != "internal":
                logger.info(f"Skipping event from external source: {source}")
                return
            
            integration_service = IntegrationService(db)
            
            if event_type == EventType.CUSTOMER_CREATED:
                self._handle_create(customer_id, customer_data, integration_service)
            elif event_type == EventType.CUSTOMER_UPDATED:
                self._handle_update(customer_id, customer_data, integration_service)
            elif event_type == EventType.CUSTOMER_DELETED:
                self._handle_delete(customer_id, integration_service)
            
        except Exception as e:
            logger.error(f"Error processing event: {e}", exc_info=True)
        finally:
            db.close()
    
    def _handle_create(self, customer_id: int, customer_data: dict, integration_service: IntegrationService):
        """Handle customer creation"""
        external_id = self.integration.create_customer(customer_data)
        if external_id:
            integration_service.create_mapping(
                internal_id=customer_id,
                external_id=external_id,
                integration_name=self.integration.integration_name
            )
            logger.info(f"Synced customer {customer_id} to Stripe: {external_id}")
    
    def _handle_update(self, customer_id: int, customer_data: dict, integration_service: IntegrationService):
        """Handle customer update"""
        external_id = integration_service.get_external_id(
            internal_id=customer_id,
            integration_name=self.integration.integration_name
        )
        
        if external_id:
            success = self.integration.update_customer(external_id, customer_data)
            if success:
                logger.info(f"Updated Stripe customer {external_id}")
        else:
            logger.warning(f"No Stripe mapping found for customer {customer_id}")
    
    def _handle_delete(self, customer_id: int, integration_service: IntegrationService):
        """Handle customer deletion"""
        external_id = integration_service.get_external_id(
            internal_id=customer_id,
            integration_name=self.integration.integration_name
        )
        
        if external_id:
            success = self.integration.delete_customer(external_id)
            if success:
                integration_service.delete_mapping(
                    internal_id=customer_id,
                    integration_name=self.integration.integration_name
                )
                logger.info(f"Deleted Stripe customer {external_id}")
    
    def start(self):
        """Start the worker"""
        logger.info("Starting sync worker...")
        consumer = EventConsumer(handler=self.process_event)
        consumer.start_consuming()


if __name__ == "__main__":
    worker = SyncWorker()
    worker.start()
