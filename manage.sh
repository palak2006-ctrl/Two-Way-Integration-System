#!/bin/bash

# Zenskar Integration Management Script
# Easy management of all services

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

# Function to show status
show_status() {
    echo "🔍 Zenskar Integration System Status"
    echo "===================================="
    
    # Check API server
    if port_in_use 8000; then
        print_success "✅ FastAPI Server (Port 8000)"
    else
        print_warning "❌ FastAPI Server (Port 8000) - Not running"
    fi
    
    # Check sync worker
    if pgrep -f "sync_worker" >/dev/null; then
        print_success "✅ Sync Worker"
    else
        print_warning "❌ Sync Worker - Not running"
    fi
    
    # Check ngrok
    if curl -s http://localhost:4040/api/tunnels >/dev/null 2>&1; then
        ngrok_url=$(get_ngrok_url)
        if [ ! -z "$ngrok_url" ]; then
            print_success "✅ ngrok Tunnel: $ngrok_url"
        else
            print_warning "❌ ngrok Tunnel - Running but no URL"
        fi
    else
        print_warning "❌ ngrok Tunnel - Not running"
    fi
    
    # Check Kafka
    if docker ps | grep -q kafka; then
        print_success "✅ Kafka (Docker)"
    else
        print_warning "❌ Kafka (Docker) - Not running"
    fi
    
    echo ""
}

# Function to start all services
start_all() {
    print_status "Starting all services..."
    
    # Start Kafka if not running
    if ! docker ps | grep -q kafka; then
        print_status "Starting Kafka..."
        docker-compose up -d
        sleep 10
    fi
    
    # Start API server if not running
    if ! port_in_use 8000; then
        print_status "Starting FastAPI server..."
        ./run_api.sh &
        sleep 5
    fi
    
    # Start sync worker if not running
    if ! pgrep -f "sync_worker" >/dev/null; then
        print_status "Starting sync worker..."
        ./run_worker.sh &
        sleep 5
    fi
    
    # Start ngrok if not running
    if ! curl -s http://localhost:4040/api/tunnels >/dev/null 2>&1; then
        print_status "Starting ngrok..."
        ./run_ngrok.sh &
        sleep 10
    fi
    
    print_success "All services started!"
    show_status
}

# Function to stop all services
stop_all() {
    print_status "Stopping all services..."
    
    # Stop ngrok
    pkill -f ngrok 2>/dev/null || true
    print_status "Stopped ngrok"
    
    # Stop sync worker
    pkill -f "sync_worker" 2>/dev/null || true
    print_status "Stopped sync worker"
    
    # Stop API server
    pkill -f "uvicorn.*8000" 2>/dev/null || true
    print_status "Stopped FastAPI server"
    
    # Stop Kafka
    docker-compose down 2>/dev/null || true
    print_status "Stopped Kafka"
    
    print_success "All services stopped!"
}

# Function to restart all services
restart_all() {
    print_status "Restarting all services..."
    stop_all
    sleep 3
    start_all
}

# Function to show logs
show_logs() {
    echo "📋 Service Logs"
    echo "==============="
    
    if docker ps | grep -q kafka; then
        echo "🐳 Kafka Logs:"
        docker-compose logs --tail=20 kafka
        echo ""
    fi
    
    if port_in_use 8000; then
        echo "🚀 FastAPI Logs (check terminal where API is running)"
    fi
    
    if pgrep -f "sync_worker" >/dev/null; then
        echo "🔄 Sync Worker Logs (check terminal where worker is running)"
    fi
    
    if curl -s http://localhost:4040/api/tunnels >/dev/null 2>&1; then
        echo "🌐 ngrok Logs:"
        curl -s http://localhost:4040/api/tunnels | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for tunnel in data['tunnels']:
        print(f'  - {tunnel[\"name\"]}: {tunnel[\"public_url\"]} -> {tunnel[\"config\"][\"addr\"]}')
except:
    pass
"
    fi
}

# Function to test the system
test_system() {
    echo "🧪 Testing Zenskar Integration System"
    echo "===================================="
    
    # Test API health
    print_status "Testing API health..."
    if curl -s http://localhost:8000/health >/dev/null; then
        print_success "✅ API Health Check - OK"
    else
        print_error "❌ API Health Check - Failed"
        return 1
    fi
    
    # Test customer creation
    print_status "Testing customer creation..."
    timestamp=$(date +%s)
    response=$(curl -s -X POST http://localhost:8000/customers/ \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"Test User $timestamp\",\"email\":\"test$timestamp@example.com\"}" 2>/dev/null)
    
    if echo "$response" | grep -q "id"; then
        print_success "✅ Customer Creation - OK"
    else
        print_error "❌ Customer Creation - Failed"
        print_status "Response: $response"
        return 1
    fi
    
    # Test customer listing
    print_status "Testing customer listing..."
    if curl -s http://localhost:8000/customers >/dev/null; then
        print_success "✅ Customer Listing - OK"
    else
        print_error "❌ Customer Listing - Failed"
        return 1
    fi
    
    print_success "All tests passed! System is working correctly."
}

# Function to show help
show_help() {
    echo "🔧 Zenskar Integration Management Script"
    echo "======================================="
    echo ""
    echo "Usage: ./manage.sh [command]"
    echo ""
    echo "Commands:"
    echo "  status     - Show status of all services"
    echo "  start      - Start all services"
    echo "  stop       - Stop all services"
    echo "  restart    - Restart all services"
    echo "  logs       - Show service logs"
    echo "  test       - Test the system"
    echo "  help       - Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./manage.sh status"
    echo "  ./manage.sh start"
    echo "  ./manage.sh test"
}

# Main script logic
case "${1:-help}" in
    "status")
        show_status
        ;;
    "start")
        start_all
        ;;
    "stop")
        stop_all
        ;;
    "restart")
        restart_all
        ;;
    "logs")
        show_logs
        ;;
    "test")
        test_system
        ;;
    "help"|*)
        show_help
        ;;
esac
