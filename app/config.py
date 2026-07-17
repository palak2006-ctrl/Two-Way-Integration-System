from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # Database
    database_url: str
    
    # Stripe
    stripe_api_key: str
    stripe_webhook_secret: str
    
    # Kafka
    kafka_bootstrap_servers: str = "localhost:9092"
    kafka_customer_topic: str = "customer-events"
    kafka_consumer_group: str = "customer-sync-workers"
    
    # Application
    app_env: str = "development"
    log_level: str = "INFO"
    
    class Config:
        env_file = ".env"


@lru_cache()
def get_settings() -> Settings:
    return Settings()
