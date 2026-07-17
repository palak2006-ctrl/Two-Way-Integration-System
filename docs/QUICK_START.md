# 🚀 Zenskar Integration - Quick Start Guide

## **One-Command Setup (Recommended)**

```bash
# Make scripts executable
chmod +x *.sh

# Run complete setup and start all services
./setup_complete.sh
```

This will:
- ✅ Set up the entire environment
- ✅ Configure ngrok with your authtoken
- ✅ Start all services (API, Worker, ngrok)
- ✅ Provide webhook URL for Stripe setup

## **Manual Setup (Step by Step)**

### **1. Initial Setup**
```bash
chmod +x *.sh
./start.sh
```

### **2. Start Services**
```bash
# Terminal 1: Start API
./run_api.sh

# Terminal 2: Start Worker  
./run_worker.sh

# Terminal 3: Start ngrok
./run_ngrok.sh
```

### **3. Management**
```bash
# Check status
./manage.sh status

# Test system
./manage.sh test

# Stop all services
./manage.sh stop

# Restart all services
./manage.sh restart
```

## **🔧 Fault-Tolerant Features**

### **Automatic Error Handling:**
- ✅ Port conflict detection and resolution
- ✅ Service dependency checking
- ✅ Connection testing before startup
- ✅ Graceful error messages with solutions

### **Smart Service Management:**
- ✅ Automatic service discovery
- ✅ Background process management
- ✅ Health checks and monitoring
- ✅ Easy restart and recovery

### **ngrok Integration:**
- ✅ Automatic ngrok installation
- ✅ Pre-configured authtoken: `33e3RRIq4OsphucDl71VQml9q2p_5p2J3wnFJL6AUv6jmmCDE`
- ✅ URL detection and display
- ✅ Webhook URL generation

## **📋 What Each Script Does**

| Script | Purpose | Fault Tolerance |
|--------|---------|----------------|
| `start.sh` | Complete environment setup | ✅ Checks all dependencies |
| `run_api.sh` | Start FastAPI server | ✅ Port conflict resolution |
| `run_worker.sh` | Start sync worker | ✅ Connection testing |
| `run_ngrok.sh` | Start ngrok tunnel | ✅ URL detection |
| `setup_complete.sh` | Start all services | ✅ Full orchestration |
| `manage.sh` | Service management | ✅ Status monitoring |

## **🧪 Testing Commands**

```bash
# Test API health
curl http://localhost:8000/health

# Create a customer
curl -X POST http://localhost:8000/customers \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com"}'

# List customers
curl http://localhost:8000/customers

# Test system
./manage.sh test
```

## **🔧 Troubleshooting**

### **Common Issues:**
```bash
# Port 8000 in use
./manage.sh stop
./manage.sh start

# Services not starting
./manage.sh status
./manage.sh logs

# ngrok not working
./run_ngrok.sh
```

### **Reset Everything:**
```bash
# Stop all services
./manage.sh stop

# Clean up
docker-compose down
pkill -f "uvicorn|sync_worker|ngrok"

# Start fresh
./setup_complete.sh
```

## **📊 Service URLs**

- **Local API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health
- **ngrok Dashboard**: http://localhost:4040
- **Public URL**: (Shown when ngrok starts)

## **🎯 Next Steps After Setup**

1. **Copy the webhook URL** from ngrok output
2. **Go to Stripe Dashboard**: https://dashboard.stripe.com/test/webhooks
3. **Add endpoint** with the webhook URL
4. **Select events**: customer.created, customer.updated, customer.deleted
5. **Copy webhook secret** and update `.env` file
6. **Restart services**: `./manage.sh restart`

## **💡 Pro Tips**

- Use `./manage.sh status` to check all services
- Use `./manage.sh test` to verify everything works
- Use `./manage.sh logs` to debug issues
- All scripts are fault-tolerant and will guide you through any issues
