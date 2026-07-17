#!/bin/bash

# Zenskar Integration Complete Setup and Launch Script
# This script sets up everything and launches all services

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

# Function to get ngrok URL
get_ngrok_url() {
    curl -s http://localhost:4040/api/tunnels 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for tunnel in data['tunnels']:
        if tunnel['proto'] == 'https':
            print(tunnel['public_url'])
            break
except:
    pass
"
}

echo "🚀 Zenskar Two-Way Integration System - Complete Setup"
echo "====================================================="

# Step 1: Run the main setup script
print_status "Step 1: Running initial setup..."
./start.sh

if [ $? -ne 0 ]; then
    print_error "Initial setup failed. Please fix the issues and try again."
    exit 1
fi

print_success "Initial setup completed"

# Step 2: Start the API server in background
print_status "Step 2: Starting FastAPI server..."
./run_api.sh &
api_pid=$!

# Wait for API to be ready
if wait_for_service localhost 8000 "FastAPI"; then
    print_success "FastAPI server is ready"
else
    print_error "FastAPI server failed to start"
    kill $api_pid 2>/dev/null || true
    exit 1
fi

# Step 3: Start the sync worker in background
print_status "Step 3: Starting sync worker..."
./run_worker.sh &
worker_pid=$!

# Give worker time to start
sleep 5
print_success "Sync worker started"

# Step 4: Start ngrok
print_status "Step 4: Starting ngrok tunnel..."
./run_ngrok.sh &
ngrok_pid=$!

# Wait for ngrok to be ready
sleep 10

# Get ngrok URL
ngrok_url=$(get_ngrok_url)
if [ ! -z "$ngrok_url" ]; then
    print_success "ngrok tunnel created: $ngrok_url"
    webhook_url="$ngrok_url/webhooks/stripe"
    print_success "Webhook URL: $webhook_url"
else
    print_warning "Could not get ngrok URL. Please check ngrok status."
fi

echo ""
echo "🎉 All Services Started Successfully!"
echo "===================================="
echo ""
print_success "✅ FastAPI Server (PID: $api_pid)"
print_success "✅ Sync Worker (PID: $worker_pid)"
print_success "✅ ngrok Tunnel (PID: $ngrok_pid)"
echo ""
echo "🌐 URLs:"
echo "  - Local API: http://localhost:8000"
echo "  - API Docs: http://localhost:8000/docs"
echo "  - Health Check: http://localhost:8000/health"
if [ ! -z "$ngrok_url" ]; then
    echo "  - Public URL: $ngrok_url"
    echo "  - Webhook URL: $webhook_url"
fi
echo ""
echo "📋 Next Steps:"
echo "1. Test the API: curl http://localhost:8000/health"
echo "2. Create a customer: curl -X POST http://localhost:8000/customers -H 'Content-Type: application/json' -d '{\"name\":\"Test User\",\"email\":\"test@example.com\"}'"
if [ ! -z "$webhook_url" ]; then
    echo "3. Setup Stripe webhook:"
    echo "   - Go to: https://dashboard.stripe.com/test/webhooks"
    echo "   - Add endpoint: $webhook_url"
    echo "   - Select events: customer.created, customer.updated, customer.deleted"
    echo "   - Copy webhook secret and update .env file"
    echo "   - Restart services: pkill -f python && ./setup_complete.sh"
fi
echo ""
echo "🔧 Management Commands:"
echo "  - Stop all services: pkill -f 'uvicorn|python.*sync_worker|ngrok'"
echo "  - Restart services: ./setup_complete.sh"
echo "  - Check logs: docker-compose logs"
echo "  - Check processes: ps aux | grep -E '(uvicorn|sync_worker|ngrok)'"
echo ""
print_status "All services are running in the background."
print_status "Press Ctrl+C to stop this script (services will continue running)"
print_status "Use the management commands above to control the services."

# Keep the script running and show status
while true; do
    sleep 30
    print_status "Services are running... (Press Ctrl+C to stop this script)"
done
