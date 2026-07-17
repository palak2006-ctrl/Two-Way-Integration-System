from kafka import KafkaConsumer
from kafka.errors import KafkaError
import json
import logging
from typing import Callable
from app.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


class EventConsumer:
    def __init__(self, handler: Callable):
        self.consumer = KafkaConsumer(
            settings.kafka_customer_topic,
            bootstrap_servers=settings.kafka_bootstrap_servers,
            group_id=settings.kafka_consumer_group,
            value_deserializer=lambda m: json.loads(m.decode('utf-8')),
            auto_offset_reset='earliest',
            enable_auto_commit=False,
            max_poll_records=10
        )
        self.handler = handler
    
    def start_consuming(self):
        """Start consuming messages from Kafka"""
        logger.info(f"Starting consumer for topic: {settings.kafka_customer_topic}")
        
        try:
            for message in self.consumer:
                try:
                    event_data = message.value
                    logger.info(f"Received event: {event_data.get('event_type')}")
                    
                    # Process the event
                    self.handler(event_data)
                    
                    # Commit offset after successful processing
                    self.consumer.commit()
                    
                except Exception as e:
                    logger.error(f"Error processing message: {e}")
                    # Implement dead letter queue logic here if needed
                    
        except KeyboardInterrupt:
            logger.info("Consumer interrupted by user")
        finally:
            self.consumer.close()
