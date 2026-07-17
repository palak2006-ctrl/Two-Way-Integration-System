from kafka import KafkaProducer
from kafka.errors import KafkaError
import json
import logging
from datetime import datetime
from app.config import get_settings
from app.queue.events import CustomerEvent

logger = logging.getLogger(__name__)
settings = get_settings()


class EventProducer:
    def __init__(self):
        self.producer = KafkaProducer(
            bootstrap_servers=settings.kafka_bootstrap_servers,
            value_serializer=lambda v: json.dumps(v, default=self._json_serializer).encode('utf-8'),
            acks='all',
            retries=3,
            max_in_flight_requests_per_connection=1
        )
    
    def _json_serializer(self, obj):
        """Custom JSON serializer for datetime objects"""
        if isinstance(obj, datetime):
            return obj.isoformat()
        raise TypeError(f"Object of type {type(obj)} is not JSON serializable")
    
    def publish_customer_event(self, event: CustomerEvent) -> bool:
        """Publish customer event to Kafka topic"""
        try:
            future = self.producer.send(
                settings.kafka_customer_topic,
                value=event.model_dump(),
                key=str(event.customer_id).encode('utf-8')
            )
            
            # Block for 'synchronous' sends
            record_metadata = future.get(timeout=10)
            logger.info(
                f"Event published: {event.event_type} for customer {event.customer_id} "
                f"to partition {record_metadata.partition} at offset {record_metadata.offset}"
            )
            return True
        except KafkaError as e:
            logger.error(f"Failed to publish event: {e}")
            return False
    
    def close(self):
        """Close producer connection"""
        self.producer.close()
