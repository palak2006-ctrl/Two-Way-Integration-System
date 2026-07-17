#!/bin/bash

# Zenskar Integration ngrok Startup Script
# Fault-tolerant ngrok tunnel setup for webhook testing

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

# Function to get ngrok URL
get_ngrok_url() {
    curl -s http://localhost:4040/api/tunnels | python3 -c "
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

echo "🌐 Starting ngrok for Zenskar Integration..."

# Check if ngrok is installed
print_status "Checking ngrok installation..."
if ! command_exists ngrok; then
    print_error "ngrok is not installed. Please install ngrok first:"
    print_status "  brew install ngrok"
    print_status "  or visit: https://ngrok.com/download"
    exit 1
fi

print_success "ngrok is installed"

# Check if ngrok is configured
print_status "Checking ngrok configuration..."
if ! ngrok config check >/dev/null 2>&1; then
    print_warning "ngrok is not configured. Configuring with authtoken..."
    ngrok config add-authtoken 33e3RRIq4OsphucDl71VQml9q2p_5p2J3wnFJL6AUv6jmmCDE
    
    if [ $? -eq 0 ]; then
        print_success "ngrok configured successfully"
    else
        print_error "Failed to configure ngrok. Please check your authtoken."
        exit 1
    fi
else
    print_success "ngrok is already configured"
fi

# Check if port 8000 is available
print_status "Checking if port 8000 is available..."
if ! port_in_use 8000; then
    print_warning "Port 8000 is not in use. Please start the API server first:"
    print_status "  ./run_api.sh"
    print_status "  or: uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"
    exit 1
fi

print_success "Port 8000 is in use (API server is running)"

# Check if ngrok is already running
print_status "Checking if ngrok is already running..."
if curl -s http://localhost:4040/api/tunnels >/dev/null 2>&1; then
    print_warning "ngrok is already running. Getting current URL..."
    current_url=$(get_ngrok_url)
    if [ ! -z "$current_url" ]; then
        print_success "ngrok is already running with URL: $current_url"
        print_status "You can use this URL for your Stripe webhook: $current_url/webhooks/stripe"
        print_status "Press Ctrl+C to stop ngrok and restart with new URL"
        echo ""
        print_status "Waiting for ngrok to stop..."
        pkill -f ngrok || true
        sleep 3
    fi
fi

# Start ngrok
print_success "Starting ngrok tunnel..."
print_status "Creating HTTPS tunnel to localhost:8000"
print_status "ngrok dashboard will be available at: http://localhost:4040"
print_status "Press Ctrl+C to stop ngrok"
echo ""

# Start ngrok in the background and capture the URL
ngrok http 8000 --log=stdout &
ngrok_pid=$!

# Wait for ngrok to start
sleep 5

# Get the ngrok URL
print_status "Getting ngrok public URL..."
max_attempts=10
attempt=1

while [ $attempt -le $max_attempts ]; do
    ngrok_url=$(get_ngrok_url)
    if [ ! -z "$ngrok_url" ]; then
        print_success "ngrok tunnel created successfully!"
        echo ""
        echo "🌐 Public URL: $ngrok_url"
        echo "🔗 Webhook URL: $ngrok_url/webhooks/stripe"
        echo ""
        print_status "Next steps:"
        print_status "1. Copy the webhook URL: $ngrok_url/webhooks/stripe"
        print_status "2. Go to Stripe Dashboard: https://dashboard.stripe.com/test/webhooks"
        print_status "3. Add endpoint with the webhook URL"
        print_status "4. Select events: customer.created, customer.updated, customer.deleted"
        print_status "5. Copy the webhook secret and update your .env file"
        echo ""
        print_status "ngrok is running in the background (PID: $ngrok_pid)"
        print_status "Press Ctrl+C to stop ngrok"
        
        # Keep the script running and show ngrok logs
        wait $ngrok_pid
        break
    fi
    
    print_status "Attempt $attempt/$max_attempts - waiting for ngrok URL..."
    sleep 2
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    print_error "Failed to get ngrok URL after $max_attempts attempts"
    kill $ngrok_pid 2>/dev/null || true
    exit 1
fi
