#!/bin/bash

# Zenskar Integration Sync Worker Startup Script
# Fault-tolerant Kafka consumer worker startup

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Kafka is running
kafka_running() {
    docker ps | grep -q kafka
}

# Function to wait for Kafka to be ready
wait_for_kafka() {
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for Kafka to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if nc -z localhost 9092 2>/dev/null; then
            print_success "Kafka is ready!"
            return 0
        fi
        print_status "Attempt $attempt/$max_attempts - waiting for Kafka..."
        sleep 2
        ((attempt++))
    done
    
    print_error "Kafka failed to start after $max_attempts attempts"
    return 1
}

echo "🔄 Starting Zenskar Sync Worker..."

# Check if we're in the right directory
if [ ! -f "app/workers/sync_worker.py" ]; then
    print_error "app/workers/sync_worker.py not found. Please run this script from the project root directory."
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    print_warning "Virtual environment not found. Creating it..."
    python3 -m venv venv
    print_success "Virtual environment created"
fi

# Activate virtual environment
print_status "Activating virtual environment..."
source venv/bin/activate

# Check if dependencies are installed
if ! python -c "import kafka, stripe" 2>/dev/null; then
    print_warning "Dependencies not found. Installing..."
    pip install -r requirements.txt
    print_success "Dependencies installed"
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_error ".env file not found. Please run ./start.sh first to set up the environment."
    exit 1
fi

# Check if Kafka is running
print_status "Checking if Kafka is running..."
if ! kafka_running; then
    print_warning "Kafka is not running. Starting Kafka..."
    docker-compose up -d
    
    if ! wait_for_kafka; then
        print_error "Failed to start Kafka. Please check Docker and try again."
        print_status "Try: docker-compose logs kafka"
        exit 1
    fi
fi

print_success "Kafka is running"

# Test database connection
print_status "Testing database connection..."
python -c "
from app.database import engine
from sqlalchemy import text
try:
    with engine.connect() as conn:
        conn.execute(text('SELECT 1'))
    print('✅ Database connection successful')
except Exception as e:
    print(f'❌ Database connection failed: {e}')
    exit(1)
"

if [ $? -ne 0 ]; then
    print_error "Database connection failed. Please check your DATABASE_URL in .env file."
    exit 1
fi

# Test Kafka connection
print_status "Testing Kafka connection..."
python -c "
from kafka import KafkaProducer
from app.config import get_settings
import json

settings = get_settings()
try:
    producer = KafkaProducer(
        bootstrap_servers=settings.kafka_bootstrap_servers,
        value_serializer=lambda v: json.dumps(v).encode('utf-8')
    )
    producer.close()
    print('✅ Kafka connection successful')
except Exception as e:
    print(f'❌ Kafka connection failed: {e}')
    exit(1)
"

if [ $? -ne 0 ]; then
    print_error "Kafka connection failed. Please check your Kafka configuration."
    exit 1
fi

# Test Stripe connection
print_status "Testing Stripe connection..."
python -c "
import stripe
from app.config import get_settings

settings = get_settings()
stripe.api_key = settings.stripe_api_key
try:
    stripe.Customer.list(limit=1)
    print('✅ Stripe connection successful')
except Exception as e:
    print(f'❌ Stripe connection failed: {e}')
    exit(1)
"

if [ $? -ne 0 ]; then
    print_error "Stripe connection failed. Please check your STRIPE_API_KEY in .env file."
    exit 1
fi

# Start the sync worker
print_success "All connections verified. Starting sync worker..."
print_status "Worker will process customer events from Kafka"
print_status "Press Ctrl+C to stop the worker"
echo ""

# Start the worker with error handling
python -m app.workers.sync_worker