#!/bin/bash

# Zenskar Integration API Startup Script
# Fault-tolerant FastAPI server startup

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

# Function to check if port is in use
port_in_use() {
    lsof -ti:$1 >/dev/null 2>&1
}

# Function to kill processes on a port
kill_port() {
    local port=$1
    local pids=$(lsof -ti:$port 2>/dev/null || true)
    if [ ! -z "$pids" ]; then
        print_warning "Killing processes on port $port: $pids"
        echo $pids | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
}

echo "🚀 Starting Zenskar Integration API..."

# Check if we're in the right directory
if [ ! -f "app/main.py" ]; then
    print_error "app/main.py not found. Please run this script from the project root directory."
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
if ! python -c "import fastapi, uvicorn" 2>/dev/null; then
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
if ! docker ps | grep -q kafka; then
    print_warning "Kafka is not running. Starting Kafka..."
    docker-compose up -d
    sleep 10
    print_success "Kafka started"
fi

# Check if port 8000 is available
print_status "Checking port 8000 availability..."
if port_in_use 8000; then
    print_warning "Port 8000 is in use. Attempting to free it..."
    kill_port 8000
    
    if port_in_use 8000; then
        print_error "Port 8000 is still in use. Please free it manually:"
        print_status "  lsof -ti:8000 | xargs kill -9"
        exit 1
    fi
fi

print_success "Port 8000 is available"

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

# Start FastAPI server
print_success "Starting FastAPI server..."
print_status "API will be available at: http://localhost:8000"
print_status "API documentation at: http://localhost:8000/docs"
print_status "Health check at: http://localhost:8000/health"
print_status "Press Ctrl+C to stop the server"
echo ""

# Start the server with error handling
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 --log-level info