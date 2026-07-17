from fastapi import APIRouter, Request, HTTPException, Depends, Header
from sqlalchemy.orm import Session
import stripe
import logging
from app.database import get_db
from app.config import get_settings
from app.services.customer_service import CustomerService
from app.services.integration_service import IntegrationService
from app.schemas.customer import CustomerCreate, CustomerUpdate
from app.queue.producer import EventProducer
from app.queue.events import CustomerEvent, EventType

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/webhooks", tags=["webhooks"])
settings = get_settings()


@router.post("/stripe")
async def stripe_webhook(
    request: Request,
    stripe_signature: str = Header(None, alias="Stripe-Signature"),
    db: Session = Depends(get_db)
):
    """Handle Stripe webhook events"""
    payload = await request.body()
    
    try:
        # Verify webhook signature
        event = stripe.Webhook.construct_event(
            payload, stripe_signature, settings.stripe_webhook_secret
        )
    except ValueError as e:
        logger.error(f"Invalid payload: {e}")
        raise HTTPException(status_code=400, detail="Invalid payload")
    except stripe.error.SignatureVerificationError as e:
        logger.error(f"Invalid signature: {e}")
        raise HTTPException(status_code=400, detail="Invalid signature")
    
    # Handle the event
    event_type = event['type']
    data = event['data']['object']
    
    customer_service = CustomerService(db)
    integration_service = IntegrationService(db)
    event_producer = EventProducer()
    
    try:
        if event_type == 'customer.created':
            _handle_stripe_customer_created(data, customer_service, integration_service, event_producer)
        elif event_type == 'customer.updated':
            _handle_stripe_customer_updated(data, customer_service, integration_service, event_producer)
        elif event_type == 'customer.deleted':
            _handle_stripe_customer_deleted(data, customer_service, integration_service, event_producer)
        else:
            logger.info(f"Unhandled event type: {event_type}")
    
    except Exception as e:
        logger.error(f"Error handling webhook: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Error processing webhook")
    
    return {"status": "success"}


def _handle_stripe_customer_created(
    stripe_customer: dict,
    customer_service: CustomerService,
    integration_service: IntegrationService,
    event_producer: EventProducer
):
    """Handle customer.created event from Stripe"""
    stripe_id = stripe_customer['id']
    
    # Check if we already have this mapping (avoid duplicates)
    internal_id = integration_service.get_internal_id(
        external_id=stripe_id,
        integration_name="stripe"
    )
    
    if internal_id:
        logger.info(f"Customer already exists: {internal_id}")
        return
    
    # Check if customer created from our system (has metadata)
    metadata = stripe_customer.get('metadata', {})
    if metadata.get('internal_id'):
        logger.info("Customer created from internal system, skipping")
        return
    
    # Create customer in our system
    customer_data = CustomerCreate(
        name=stripe_customer.get('name', ''),
        email=stripe_customer['email']
    )
    
    # Create without publishing event to avoid loop
    customer = customer_service.create_customer(customer_data, publish_event=False)
    
    # Create mapping
    integration_service.create_mapping(
        internal_id=customer.id,
        external_id=stripe_id,
        integration_name="stripe"
    )
    
    logger.info(f"Created customer {customer.id} from Stripe {stripe_id}")


def _handle_stripe_customer_updated(
    stripe_customer: dict,
    customer_service: CustomerService,
    integration_service: IntegrationService,
    event_producer: EventProducer
):
    """Handle customer.updated event from Stripe"""
    stripe_id = stripe_customer['id']
    
    # Find internal customer
    internal_id = integration_service.get_internal_id(
        external_id=stripe_id,
        integration_name="stripe"
    )
    
    if not internal_id:
        logger.warning(f"No mapping found for Stripe customer {stripe_id}")
        return
    
    # Update customer without publishing event
    customer_data = CustomerUpdate(
        name=stripe_customer.get('name'),
        email=stripe_customer.get('email')
    )
    
    customer_service.update_customer(internal_id, customer_data, publish_event=False)
    logger.info(f"Updated customer {internal_id} from Stripe {stripe_id}")


def _handle_stripe_customer_deleted(
    stripe_customer: dict,
    customer_service: CustomerService,
    integration_service: IntegrationService,
    event_producer: EventProducer
):
    """Handle customer.deleted event from Stripe"""
    stripe_id = stripe_customer['id']
    
    # Find internal customer
    internal_id = integration_service.get_internal_id(
        external_id=stripe_id,
        integration_name="stripe"
    )
    
    if not internal_id:
        logger.warning(f"No mapping found for Stripe customer {stripe_id}")
        return
    
    # Delete customer without publishing event
    customer_service.delete_customer(internal_id, publish_event=False)
    
    # Delete mapping
    integration_service.delete_mapping(
        internal_id=internal_id,
        integration_name="stripe"
    )
    
    logger.info(f"Deleted customer {internal_id} from Stripe {stripe_id}")
