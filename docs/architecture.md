# 🏗️ System Architecture

## Implementation Flow Diagram

```mermaid
graph TB
    subgraph "Client Layer"
        API[REST API Client]
        STRIPE_DASH[Stripe Dashboard]
    end
    
    subgraph "API Layer"
        FASTAPI[FastAPI Application]
        CUSTOMERS_API[Customer API Endpoints]
        WEBHOOKS_API[Webhook Endpoints]
    end
    
    subgraph "Service Layer"
        CUSTOMER_SERVICE[Customer Service]
        INTEGRATION_SERVICE[Integration Service]
    end
    
    subgraph "Data Layer"
        POSTGRES[(PostgreSQL Database)]
        KAFKA[(Kafka Message Queue)]
    end
    
    subgraph "Integration Layer"
        STRIPE_API[Stripe API]
        SYNC_WORKER[Sync Worker]
    end
    
    subgraph "External Systems"
        STRIPE[Stripe Platform]
    end
    
    %% API Flow
    API --> FASTAPI
    FASTAPI --> CUSTOMERS_API
    FASTAPI --> WEBHOOKS_API
    
    %% Service Flow
    CUSTOMERS_API --> CUSTOMER_SERVICE
    WEBHOOKS_API --> INTEGRATION_SERVICE
    
    %% Data Flow
    CUSTOMER_SERVICE --> POSTGRES
    CUSTOMER_SERVICE --> KAFKA
    INTEGRATION_SERVICE --> POSTGRES
    
    %% Event Processing
    KAFKA --> SYNC_WORKER
    SYNC_WORKER --> STRIPE_API
    STRIPE_API --> STRIPE
    
    %% Webhook Flow
    STRIPE_DASH --> STRIPE
    STRIPE --> WEBHOOKS_API
    
    %% Styling
    classDef apiLayer fill:#e1f5fe
    classDef serviceLayer fill:#f3e5f5
    classDef dataLayer fill:#e8f5e8
    classDef integrationLayer fill:#fff3e0
    classDef externalLayer fill:#ffebee
    
    class FASTAPI,CUSTOMERS_API,WEBHOOKS_API apiLayer
    class CUSTOMER_SERVICE,INTEGRATION_SERVICE serviceLayer
    class POSTGRES,KAFKA dataLayer
    class STRIPE_API,SYNC_WORKER integrationLayer
    class STRIPE,STRIPE_DASH externalLayer
```

## Data Flow Explanation

### 1. **Customer Creation Flow**
1. Client sends POST request to `/customers/`
2. FastAPI validates request using Pydantic schemas
3. Customer Service creates customer in PostgreSQL
4. Event published to Kafka topic
5. Sync Worker processes event
6. Customer created in Stripe via API
7. Mapping stored between internal and Stripe IDs

### 2. **Stripe Webhook Flow**
1. Customer updated in Stripe Dashboard
2. Stripe sends webhook to `/webhooks/stripe`
3. Webhook handler validates signature
4. Integration Service processes webhook
5. Customer updated in PostgreSQL
6. Event published to Kafka for other integrations

### 3. **Event-Driven Architecture**
- **Kafka Producer**: Publishes events when data changes
- **Kafka Consumer**: Processes events for external sync
- **Idempotency**: Prevents duplicate processing
- **Error Handling**: Retry mechanisms for failed operations

## Key Components

### **API Layer**
- **FastAPI**: Modern, fast web framework
- **Pydantic**: Data validation and serialization
- **RESTful Endpoints**: Standard HTTP methods
- **Error Handling**: Proper HTTP status codes

### **Service Layer**
- **Customer Service**: Business logic for customer operations
- **Integration Service**: Handles external system mappings
- **Event Publishing**: Kafka event generation

### **Data Layer**
- **PostgreSQL**: Primary database (Neon)
- **Kafka**: Message queue for event processing
- **Database Migrations**: Alembic for schema management

### **Integration Layer**
- **Stripe Integration**: External API communication
- **Sync Worker**: Background event processing
- **Webhook Handler**: Real-time external updates

## Scalability Features

- **Horizontal Scaling**: Multiple worker instances
- **Event Processing**: Asynchronous message handling
- **Database Optimization**: Connection pooling
- **Monitoring**: Health checks and logging
