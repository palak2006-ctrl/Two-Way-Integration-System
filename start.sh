#!/bin/bash

# Zenskar Integration Complete Setup Script
# This script sets up the entire environment with fault tolerance

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if port is in use
port_in_use() {
    lsof -ti:$1 >/dev/null 2>&1
}

# Function to wait for service to be ready
wait_for_service() {
    local host=$1
    local port=$2
    local service_name=$3
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for $service_name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if nc -z $host $port 2>/dev/null; then
            print_success "$service_name is ready!"
            return 0
        fi
        print_status "Attempt $attempt/$max_attempts - waiting for $service_name..."
        sleep 2
        ((attempt++))
    done
    
    print_error "$service_name failed to start after $max_attempts attempts"
    return 1
}

echo "🚀 Zenskar Two-Way Integration System Setup"
echo "=========================================="

# Check Python version
print_status "Checking Python version..."
python_version=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
required_version="3.8"

if [ "$(printf '%s\n' "$required_version" "$python_version" | sort -V | head -n1)" = "$required_version" ]; then
    print_success "Python $python_version is compatible"
else
    print_error "Python $python_version is not compatible. Requires Python 3.8+"
    exit 1
fi

# Check if Docker is installed
print_status "Checking Docker installation..."
if ! command_exists docker; then
    print_error "Docker is not installed. Please install Docker first."
    print_status "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! command_exists docker-compose; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    print_status "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

print_success "Docker and Docker Compose are installed"

# Check if ngrok is installed
print_status "Checking ngrok installation..."
if ! command_exists ngrok; then
    print_warning "ngrok is not installed. Installing ngrok..."
    
    # Try to install ngrok using different methods
    if command_exists brew; then
        print_status "Installing ngrok via Homebrew..."
        brew install ngrok
    else
        print_status "Installing ngrok manually..."
        # Download ngrok for macOS
        curl -O https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-amd64.zip
        unzip ngrok-v3-stable-darwin-amd64.zip
        sudo mv ngrok /usr/local/bin/
        rm ngrok-v3-stable-darwin-amd64.zip
    fi
    
    if ! command_exists ngrok; then
        print_error "Failed to install ngrok. Please install manually from https://ngrok.com/download"
        exit 1
    fi
fi

print_success "ngrok is installed"

# Configure ngrok with the provided authtoken
print_status "Configuring ngrok with authtoken..."
ngrok config add-authtoken 33e3RRIq4OsphucDl71VQml9q2p_5p2J3wnFJL6AUv6jmmCDE

if [ $? -eq 0 ]; then
    print_success "ngrok configured successfully"
else
    print_error "Failed to configure ngrok authtoken"
    exit 1
fi

# Create virtual environment if it doesn't exist
print_status "Setting up Python virtual environment..."
if [ ! -d "venv" ]; then
    print_status "Creating virtual environment..."
    python3 -m venv venv
    print_success "Virtual environment created"
else
    print_success "Virtual environment already exists"
fi

# Activate virtual environment
print_status "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
print_status "Upgrading pip..."
pip install --upgrade pip

# Install dependencies
print_status "Installing Python dependencies..."
pip install -r requirements.txt

if [ $? -eq 0 ]; then
    print_success "Dependencies installed successfully"
else
    print_error "Failed to install dependencies"
    exit 1
fi

# Check if .env file exists
print_status "Checking environment configuration..."
if [ ! -f ".env" ]; then
    print_warning ".env file not found. Creating from template..."
    cp env.example .env
    print_warning "Please edit .env file with your actual credentials:"
    print_warning "  - DATABASE_URL: Get from Neon dashboard"
    print_warning "  - STRIPE_API_KEY: Get from Stripe dashboard"
    print_warning "  - STRIPE_WEBHOOK_SECRET: Will be set after webhook setup"
    print_status "Opening .env file for editing..."
    
    # Try to open with different editors
    if command_exists nano; then
        nano .env
    elif command_exists vim; then
        vim .env
    else
        print_status "Please edit .env file manually with your favorite editor"
    fi
    
    # Check if user has configured the .env file
    if grep -q "your_stripe_key_here" .env; then
        print_error "Please configure your .env file before continuing"
        print_status "Required fields to configure:"
        print_status "  - DATABASE_URL (from Neon dashboard)"
        print_status "  - STRIPE_API_KEY (from Stripe dashboard)"
        exit 1
    fi
fi

print_success "Environment configuration ready"

# Check if port 8000 is available
print_status "Checking if port 8000 is available..."
if port_in_use 8000; then
    print_warning "Port 8000 is already in use. Attempting to free it..."
    pkill -f "uvicorn.*8000" || true
    sleep 2
    
    if port_in_use 8000; then
        print_error "Port 8000 is still in use. Please free it manually:"
        print_status "  lsof -ti:8000 | xargs kill -9"
        exit 1
    fi
fi

print_success "Port 8000 is available"

# Start Kafka with Docker
print_status "Starting Kafka with Docker Compose..."
docker-compose down >/dev/null 2>&1 || true  # Clean up any existing containers
docker-compose up -d

if [ $? -eq 0 ]; then
    print_success "Kafka containers started"
else
    print_error "Failed to start Kafka containers"
    exit 1
fi

# Wait for Kafka to be ready
print_status "Waiting for Kafka to be ready..."
if wait_for_service localhost 9092 "Kafka"; then
    print_success "Kafka is ready"
else
    print_error "Kafka failed to start properly"
    docker-compose logs kafka
    exit 1
fi

# Run database migrations
print_status "Running database migrations..."
alembic upgrade head

if [ $? -eq 0 ]; then
    print_success "Database migrations completed"
else
    print_error "Database migrations failed"
    print_status "Please check your DATABASE_URL in .env file"
    exit 1
fi

# Test the setup
print_status "Testing setup..."
python test_setup.py

if [ $? -eq 0 ]; then
    print_success "Setup verification passed"
else
    print_warning "Setup verification had issues, but continuing..."
fi

echo ""
echo "🎉 Setup Complete!"
echo "=================="
print_success "All services are ready to start"
echo ""
echo "📋 Next Steps:"
echo "1. Start FastAPI server: ./run_api.sh"
echo "2. Start sync worker: ./run_worker.sh"
echo "3. Start ngrok: ./run_ngrok.sh"
echo "4. Setup Stripe webhook with ngrok URL"
echo ""
echo "🌐 URLs:"
echo "  - API: http://localhost:8000"
echo "  - API Docs: http://localhost:8000/docs"
echo "  - Health Check: http://localhost:8000/health"
echo ""
echo "🔧 Troubleshooting:"
echo "  - Check logs: docker-compose logs"
echo "  - Restart Kafka: docker-compose restart"
echo "  - Check processes: ps aux | grep python"