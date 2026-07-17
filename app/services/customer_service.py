from sqlalchemy.orm import Session
from typing import List, Optional
from app.models.customer import Customer
from app.schemas.customer import CustomerCreate, CustomerUpdate
from app.queue.producer import EventProducer
from app.queue.events import CustomerEvent, EventType
import logging

logger = logging.getLogger(__name__)


class CustomerService:
    def __init__(self, db: Session):
        self.db = db
        self.event_producer = EventProducer()
    
    def create_customer(self, customer_data: CustomerCreate, publish_event: bool = True) -> Customer:
        """Create new customer"""
        customer = Customer(
            name=customer_data.name,
            email=customer_data.email
        )
        self.db.add(customer)
        self.db.commit()
        self.db.refresh(customer)
        
        # Publish event to Kafka
        if publish_event:
            event = CustomerEvent(
                event_type=EventType.CUSTOMER_CREATED,
                customer_id=customer.id,
                customer_data=customer.to_dict(),
                source="internal"
            )
            self.event_producer.publish_customer_event(event)
        
        logger.info(f"Created customer: {customer.id}")
        return customer
    
    def get_customer(self, customer_id: int) -> Optional[Customer]:
        """Get customer by ID"""
        return self.db.query(Customer).filter(Customer.id == customer_id).first()
    
    def get_customer_by_email(self, email: str) -> Optional[Customer]:
        """Get customer by email"""
        return self.db.query(Customer).filter(Customer.email == email).first()
    
    def list_customers(self, skip: int = 0, limit: int = 100) -> List[Customer]:
        """List all customers with pagination"""
        return self.db.query(Customer).offset(skip).limit(limit).all()
    
    def update_customer(self, customer_id: int, customer_data: CustomerUpdate, publish_event: bool = True) -> Optional[Customer]:
        """Update customer"""
        customer = self.get_customer(customer_id)
        if not customer:
            return None
        
        if customer_data.name is not None:
            customer.name = customer_data.name
        if customer_data.email is not None:
            customer.email = customer_data.email
        
        self.db.commit()
        self.db.refresh(customer)
        
        # Publish event to Kafka
        if publish_event:
            event = CustomerEvent(
                event_type=EventType.CUSTOMER_UPDATED,
                customer_id=customer.id,
                customer_data=customer.to_dict(),
                source="internal"
            )
            self.event_producer.publish_customer_event(event)
        
        logger.info(f"Updated customer: {customer.id}")
        return customer
    
    def delete_customer(self, customer_id: int, publish_event: bool = True) -> bool:
        """Delete customer"""
        customer = self.get_customer(customer_id)
        if not customer:
            return False
        
        customer_dict = customer.to_dict()
        self.db.delete(customer)
        self.db.commit()
        
        # Publish event to Kafka
        if publish_event:
            event = CustomerEvent(
                event_type=EventType.CUSTOMER_DELETED,
                customer_id=customer_id,
                customer_data=customer_dict,
                source="internal"
            )
            self.event_producer.publish_customer_event(event)
        
        logger.info(f"Deleted customer: {customer_id}")
        return True
