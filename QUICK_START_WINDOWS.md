# 🪟 Zenskar Integration - Windows Quick Start Guide

## **Prerequisites (Install These First!)**

### **1. Docker Desktop (Required)**
- **Download**: https://www.docker.com/products/docker-desktop/
- **Enable WSL2**: See [DOCKER_SETUP.md](DOCKER_SETUP.md) for detailed instructions
- **Verify**: Open Command Prompt and run:
  ```cmd
  docker --version
  docker run hello-world
  ```

### **2. Python 3.8+**
- **Download**: https://python.org
- **Important**: Check "Add Python to PATH" during installation
- **Verify**: Open Command Prompt and run:
  ```cmd
  python --version
  ```

### **3. Git**
- **Download**: https://git-scm.com
- **Verify**: Open Command Prompt and run:
  ```cmd
  git --version
  ```

## **🚀 One-Command Setup (Recommended)**

```cmd
# Complete setup and start all services
setup_complete_windows.bat
```

This will:
- ✅ Set up the entire environment
- ✅ Configure ngrok with your authtoken
- ✅ Start all services (API, Worker, ngrok)
- ✅ Provide webhook URL for Stripe setup

## **🔧 Manual Setup (Step by Step)**

### **Step 1: Initial Setup**
```cmd
# Run complete setup
setup_windows.bat
```

### **Step 2: Start Services**

#### **Option A: Start All Services**
```cmd
# Start all services at once
setup_complete_windows.bat
```

#### **Option B: Start Services Manually (3 Command Prompts)**

**Command Prompt 1: Start API Server**
```cmd
run_api_windows.bat
```

**Command Prompt 2: Start Sync Worker**
```cmd
run_worker_windows.bat
```

**Command Prompt 3: Start ngrok Tunnel**
```cmd
run_ngrok_windows.bat
```

### **Step 3: Management**
```cmd
# Check status
manage_windows.bat status

# Test system
manage_windows.bat test

# Stop all services
manage_windows.bat stop

# Restart all services
manage_windows.bat restart

# View service logs
manage_windows.bat logs
```

## **🧪 Testing Commands**

```cmd
# Test API health
curl http://localhost:8000/health

# Create a customer
curl -X POST http://localhost:8000/customers -H "Content-Type: application/json" -d "{\"name\":\"Test User\",\"email\":\"test@example.com\"}"

# List customers
curl http://localhost:8000/customers

# Test system
manage_windows.bat test
```

## **🔧 Windows-Specific Troubleshooting**

### **Common Issues:**

#### **1. Docker Desktop Won't Start**
- **Enable Hyper-V**: Go to Windows Features → Enable Hyper-V
- **Enable Virtual Machine Platform**: Go to Windows Features → Enable Virtual Machine Platform
- **Restart computer** after enabling features

#### **2. WSL2 Issues**
```cmd
# Update WSL2
wsl --update

# Set WSL2 as default
wsl --set-default-version 2

# Restart WSL
wsl --shutdown
```

#### **3. Port 8000 Already in Use**
```cmd
# Stop conflicting processes
manage_windows.bat stop

# Or kill specific processes
netstat -ano | findstr :8000
taskkill /f /pid [PID_NUMBER]
```

#### **4. Python Not Found**
- **Reinstall Python** and check "Add Python to PATH"
- **Or add Python manually** to PATH environment variable

#### **5. Services Not Starting**
```cmd
# Check status
manage_windows.bat status

# View logs
manage_windows.bat logs

# Restart services
manage_windows.bat restart
```

### **Reset Everything:**
```cmd
# Stop all services
manage_windows.bat stop

# Clean up
docker-compose down
taskkill /f /im python.exe /im ngrok.exe

# Start fresh
setup_complete_windows.bat
```

## **📊 Service URLs**

Once everything is running:

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
6. **Restart services**: `manage_windows.bat restart`

## **💡 Pro Tips**

- Use `manage_windows.bat status` to check all services
- Use `manage_windows.bat test` to verify everything works
- Use `manage_windows.bat logs` to debug issues
- All scripts are fault-tolerant and will guide you through any issues
- Services run in separate Command Prompt windows - close them to stop specific services

## **🔧 What Each Script Does**

| Script | Purpose | Fault Tolerance |
|--------|---------|----------------|
| `setup_windows.bat` | Complete environment setup | ✅ Checks all dependencies |
| `run_api_windows.bat` | Start FastAPI server | ✅ Port conflict resolution |
| `run_worker_windows.bat` | Start sync worker | ✅ Connection testing |
| `run_ngrok_windows.bat` | Start ngrok tunnel | ✅ URL detection |
| `setup_complete_windows.bat` | Start all services | ✅ Full orchestration |
| `manage_windows.bat` | Service management | ✅ Status monitoring |

## **🎉 You're All Set!**

The system includes:
- ✅ **Two-way customer synchronization** with Stripe
- ✅ **Near real-time event processing** using Kafka
- ✅ **Webhook support** for Stripe events
- ✅ **Extensible integration architecture**
- ✅ **Production-ready** logging and error handling
- ✅ **Fault-tolerant scripts** with automatic error handling

**Next Steps:**
1. Run `setup_complete_windows.bat` to start everything
2. Test the API endpoints
3. Set up Stripe webhooks with the ngrok URL
4. Start creating and syncing customers!
