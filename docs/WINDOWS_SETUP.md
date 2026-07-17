# 🪟 Windows Setup Guide for Zenskar Integration

This guide provides step-by-step instructions for setting up the Zenskar Two-Way Integration System on Windows.

## 📋 Prerequisites

### 1. **Python 3.8+ Installation**
```cmd
# Download from https://python.org/downloads/
# Make sure to check "Add Python to PATH" during installation

# Verify installation
python --version
pip --version
```

### 2. **Git Installation**
```cmd
# Download from https://git-scm.com/download/win
# Use default settings during installation

# Verify installation
git --version
```

### 3. **Docker Desktop Installation**
```cmd
# Download from https://www.docker.com/products/docker-desktop/
# Install Docker Desktop for Windows
# Enable WSL 2 integration (recommended)

# Verify installation
docker --version
docker-compose --version
```

### 4. **WSL 2 Setup (Recommended)**
```powershell
# Run PowerShell as Administrator
wsl --install
# Restart computer after installation
wsl --set-default-version 2
```

## 🚀 Quick Start (Windows)

### **One-Command Setup**
```cmd
# Navigate to project directory
cd "C:\path\to\Zenskar Assignment"

# Run complete setup
setup_complete_windows.bat
```

This will:
- ✅ Set up the entire environment
- ✅ Configure ngrok with your authtoken
- ✅ Start all services (API, Worker, ngrok)
- ✅ Provide webhook URL for Stripe setup

### **Manual Setup (Step by Step)**

#### **Step 1: Clone and Navigate**
```cmd
# Clone the repository
git clone <repository-url>
cd "Zenskar Assignment"

# Verify you're in the correct directory
dir
```

#### **Step 2: Environment Setup**
```cmd
# Run complete setup
setup_windows.bat
```

This script will:
- ✅ Check Python version and dependencies
- ✅ Install ngrok and configure with authtoken
- ✅ Create virtual environment
- ✅ Install all dependencies
- ✅ Set up database and run migrations
- ✅ Start Kafka with Docker
- ✅ Verify all connections

#### **Step 3: Start Services**

**Option A: One-Command Setup**
```cmd
# Start all services at once
setup_complete_windows.bat
```

**Option B: Manual Service Startup**

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

## 🔧 Service Management (Windows)

### **Check Status**
```cmd
# Check all services status
manage_windows.bat status
```

### **Test System**
```cmd
# Test the system
manage_windows.bat test
```

### **Stop All Services**
```cmd
# Stop all services
manage_windows.bat stop
```

### **Start All Services**
```cmd
# Start all services
manage_windows.bat start
```

### **Restart All Services**
```cmd
# Restart all services
manage_windows.bat restart
```

### **View Service Logs**
```cmd
# View service logs
manage_windows.bat logs
```

## 🧪 Testing the System

### **Test 1: API Health Check**
```cmd
curl http://localhost:8000/health
# Expected: {"status":"healthy"}
```

### **Test 2: Create Customer**
```cmd
curl -X POST http://localhost:8000/customers/ ^
  -H "Content-Type: application/json" ^
  -d "{\"name\":\"John Doe\",\"email\":\"john@example.com\"}"
```

### **Test 3: List Customers**
```cmd
curl http://localhost:8000/customers/
```

### **Test 4: System Test**
```cmd
manage_windows.bat test
```

## 🌐 ngrok Integration (Windows)

### **Automatic Configuration**
The system automatically:
- ✅ Installs ngrok if not present
- ✅ Configures with your authtoken: `33e3RRIq4OsphucDl71VQml9q2p_5p2J3wnFJL6AUv6jmmCDE`
- ✅ Creates HTTPS tunnel to localhost:8000
- ✅ Displays webhook URL for Stripe setup

### **Webhook URL**
After running `run_ngrok_windows.bat` or `setup_complete_windows.bat`, you'll see:
```
🌐 Public URL: https://your-url.ngrok-free.dev
🔗 Webhook URL: https://your-url.ngrok-free.dev/webhooks/stripe
```

### **Stripe Webhook Setup**
1. **Copy the webhook URL** from the output
2. **Go to Stripe Dashboard**: https://dashboard.stripe.com/test/webhooks
3. **Add endpoint** with the webhook URL
4. **Select events**: customer.created, customer.updated, customer.deleted
5. **Copy webhook secret** and update `.env` file
6. **Restart services**: `manage_windows.bat restart`

## 🔧 Windows-Specific Troubleshooting

### **Common Issues**

#### **1. Python Not Found**
```cmd
# Add Python to PATH
setx PATH "%PATH%;C:\Python39;C:\Python39\Scripts"
# Restart Command Prompt
```

#### **2. Docker Not Running**
```cmd
# Start Docker Desktop
# Wait for Docker to be ready
docker run hello-world
```

#### **3. Port 8000 Already in Use**
```cmd
# Stop conflicting processes
manage_windows.bat stop

# Or kill specific processes
netstat -ano | findstr :8000
taskkill /PID <PID> /F
```

#### **4. WSL 2 Issues**
```powershell
# Update WSL
wsl --update
wsl --set-default-version 2
```

#### **5. ngrok Issues**
```cmd
# Check ngrok status
curl http://localhost:4040/api/tunnels

# Restart ngrok
run_ngrok_windows.bat
```

### **Debug Commands**

```cmd
# Check all running processes
tasklist | findstr /i "python uvicorn ngrok"

# Check Docker containers
docker ps

# Check port usage
netstat -ano | findstr :8000

# Test API endpoints
curl http://localhost:8000/health
```

## 📊 Service URLs (Windows)

- **Local API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health
- **ngrok Dashboard**: http://localhost:4040
- **Public URL**: (Shown when ngrok starts)

## 🚀 Windows Scripts Reference

### **Setup Scripts**

| Script | Purpose | Usage |
|--------|---------|-------|
| `setup_windows.bat` | Complete environment setup | `setup_windows.bat` |
| `setup_complete_windows.bat` | One-command setup and start | `setup_complete_windows.bat` |
| `test_setup.py` | Verify environment | `python test_setup.py` |

### **Service Scripts**

| Script | Purpose | Usage |
|--------|---------|-------|
| `run_api_windows.bat` | Start FastAPI server | `run_api_windows.bat` |
| `run_worker_windows.bat` | Start sync worker | `run_worker_windows.bat` |
| `run_ngrok_windows.bat` | Start ngrok tunnel | `run_ngrok_windows.bat` |

### **Management Scripts**

| Script | Purpose | Usage |
|--------|---------|-------|
| `manage_windows.bat` | Service management | `manage_windows.bat [command]` |
| `manage_windows.bat status` | Check service status | `manage_windows.bat status` |
| `manage_windows.bat start` | Start all services | `manage_windows.bat start` |
| `manage_windows.bat stop` | Stop all services | `manage_windows.bat stop` |
| `manage_windows.bat restart` | Restart all services | `manage_windows.bat restart` |
| `manage_windows.bat test` | Test the system | `manage_windows.bat test` |
| `manage_windows.bat logs` | View service logs | `manage_windows.bat logs` |

## 🔧 Fault-Tolerant Features (Windows)

### **Automatic Error Handling**
- ✅ **Port conflict detection** and resolution
- ✅ **Service dependency checking** before startup
- ✅ **Connection testing** for database, Kafka, and Stripe
- ✅ **Graceful error messages** with solutions
- ✅ **Automatic retry mechanisms**

### **Service Management**
- ✅ **Background process management**
- ✅ **Health checks and monitoring**
- ✅ **Easy restart and recovery**
- ✅ **Status monitoring** for all services

### **Smart Startup**
- ✅ **Dependency verification** before starting services
- ✅ **Service orchestration** with proper startup order
- ✅ **Connection testing** for all external services
- ✅ **Error recovery** with helpful messages

## 💡 Windows Pro Tips

- **Use Command Prompt as Administrator** for Docker operations
- **Enable WSL 2** for better Docker performance
- **Keep Docker Desktop running** in the background
- **Use Windows Terminal** for better command line experience
- **Check Windows Defender** if services fail to start

## 🎯 Next Steps After Setup

1. **Copy the webhook URL** from ngrok output
2. **Go to Stripe Dashboard**: https://dashboard.stripe.com/test/webhooks
3. **Add endpoint** with the webhook URL
4. **Select events**: customer.created, customer.updated, customer.deleted
5. **Copy webhook secret** and update `.env` file
6. **Restart services**: `manage_windows.bat restart`

---

**🎉 Ready to go!** Run `setup_complete_windows.bat` to get started with your two-way integration system on Windows!
