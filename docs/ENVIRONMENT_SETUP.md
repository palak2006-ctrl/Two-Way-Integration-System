# 🔧 Environment Setup Guide for Zenskar Integration

This guide provides detailed instructions for setting up the development environment for the Zenskar Two-Way Integration System.

## 📋 Prerequisites Overview

Before starting, ensure you have the following accounts and tools:

### **Required Accounts**
- **GitHub Account** (for repository access)
- **Neon Postgres Account** (free at https://neon.tech)
- **Stripe Test Account** (free at https://stripe.com)
- **ngrok Account** (free at https://ngrok.com)

### **Required Tools**
- **Python 3.8+**
- **Docker & Docker Compose**
- **Git**
- **ngrok CLI**

## 🐍 Python Environment Setup

### **Python Installation**

#### **Windows**
```cmd
# Download from https://python.org/downloads/
# Make sure to check "Add Python to PATH" during installation

# Verify installation
python --version
pip --version
```

#### **macOS**
```bash
# Using Homebrew (recommended)
brew install python@3.9

# Or download from https://python.org/downloads/
python3 --version
pip3 --version
```

#### **Linux (Ubuntu/Debian)**
```bash
# Update package list
sudo apt update

# Install Python 3.9
sudo apt install python3.9 python3.9-pip python3.9-venv

# Verify installation
python3.9 --version
pip3 --version
```

### **Virtual Environment Setup**
```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Verify activation
which python  # Should show venv path
```

## 🐳 Docker Setup

### **Docker Installation**

#### **Windows**
```cmd
# Download Docker Desktop from https://www.docker.com/products/docker-desktop/
# Install Docker Desktop for Windows
# Enable WSL 2 integration (recommended)

# Verify installation
docker --version
docker-compose --version
```

#### **macOS**
```bash
# Download Docker Desktop from https://www.docker.com/products/docker-desktop/
# Install Docker Desktop for Mac

# Verify installation
docker --version
docker-compose --version
```

#### **Linux (Ubuntu/Debian)**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

### **Docker Configuration**
```bash
# Test Docker installation
docker run hello-world

# Start Docker service (if needed)
# Windows/macOS: Docker Desktop should start automatically
# Linux:
sudo systemctl start docker
sudo systemctl enable docker
```

## 🗄️ Database Setup (Neon Postgres)

### **1. Create Neon Account**
1. Go to https://neon.tech
2. Sign up with GitHub/Google
3. Create a new project
4. Choose a region close to you

### **2. Get Database Connection String**
1. In Neon dashboard, go to your project
2. Click on "Connection Details"
3. Copy the connection string
4. It should look like: `postgresql://username:password@hostname/database`

### **3. Configure Environment Variables**
```bash
# Create .env file
cp env.example .env

# Edit .env file with your database URL
DATABASE_URL=postgresql://username:password@hostname/database
```

## 💳 Stripe Setup

### **1. Create Stripe Account**
1. Go to https://stripe.com
2. Sign up for a free account
3. Complete account verification

### **2. Get API Keys**
1. Go to Stripe Dashboard → Developers → API Keys
2. Copy your **Publishable Key** (starts with `pk_test_`)
3. Copy your **Secret Key** (starts with `sk_test_`)

### **3. Configure Environment Variables**
```bash
# Add to .env file
STRIPE_API_KEY=sk_test_your_secret_key_here
STRIPE_PUBLISHABLE_KEY=pk_test_your_publishable_key_here
```

### **4. Webhook Setup (After ngrok)**
1. Set up ngrok first (see ngrok section)
2. Get your webhook URL from ngrok output
3. Go to Stripe Dashboard → Developers → Webhooks
4. Add endpoint: `https://your-url.ngrok-free.dev/webhooks/stripe`
5. Select events: `customer.created`, `customer.updated`, `customer.deleted`
6. Copy webhook secret (starts with `whsec_`)

## 🌐 ngrok Setup

### **1. Create ngrok Account**
1. Go to https://ngrok.com
2. Sign up for a free account
3. Get your authtoken from the dashboard

### **2. Install ngrok**

#### **Windows**
```cmd
# Download from https://ngrok.com/download
# Extract and add to PATH
# Or use Chocolatey
choco install ngrok
```

#### **macOS**
```bash
# Using Homebrew
brew install ngrok/ngrok/ngrok

# Or download from https://ngrok.com/download
```

#### **Linux**
```bash
# Download and install
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar xvzf ngrok-v3-stable-linux-amd64.tgz
sudo mv ngrok /usr/local/bin
```

### **3. Configure ngrok**
```bash
# Add authtoken
ngrok config add-authtoken YOUR_AUTHTOKEN_HERE

# Test ngrok
ngrok http 8000
```

## 🔧 Environment Variables Configuration

### **Complete .env File**
```bash
# Database Configuration
DATABASE_URL=postgresql://username:password@hostname/database

# Stripe Configuration
STRIPE_API_KEY=sk_test_your_secret_key_here
STRIPE_PUBLISHABLE_KEY=pk_test_your_publishable_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here

# Kafka Configuration
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
KAFKA_TOPIC=customer-events

# Application Configuration
APP_ENV=development
LOG_LEVEL=INFO
API_HOST=0.0.0.0
API_PORT=8000

# ngrok Configuration (optional - for webhook testing)
NGROK_AUTHTOKEN=your_ngrok_authtoken_here
```

### **Environment-Specific Configurations**

#### **Development**
```bash
APP_ENV=development
LOG_LEVEL=DEBUG
DATABASE_URL=postgresql://dev_user:dev_pass@localhost/dev_db
```

#### **Production**
```bash
APP_ENV=production
LOG_LEVEL=WARNING
DATABASE_URL=postgresql://prod_user:prod_pass@prod-host/prod_db
STRIPE_API_KEY=sk_live_your_live_key_here
```

## 🚀 Project Setup

### **1. Clone Repository**
```bash
# Clone the repository
git clone <repository-url>
cd "Zenskar Assignment"

# Verify you're in the correct directory
pwd  # Should show project path
```

### **2. Install Dependencies**
```bash
# Activate virtual environment
source venv/bin/activate  # macOS/Linux
# or
venv\Scripts\activate     # Windows

# Install dependencies
pip install -r requirements.txt
```

### **3. Database Migration**
```bash
# Run database migrations
alembic upgrade head

# Verify tables created
python -c "from app.database import engine; print('Database connected!')"
```

### **4. Start Kafka**
```bash
# Start Kafka with Docker
docker-compose up -d

# Verify Kafka is running
docker ps
```

### **5. Test Setup**
```bash
# Run setup verification
python test_setup.py

# Should show all green checkmarks
```

## 🧪 Environment Verification

### **1. Python Environment**
```bash
# Check Python version
python --version  # Should be 3.8+

# Check virtual environment
which python  # Should show venv path

# Check installed packages
pip list
```

### **2. Docker Environment**
```bash
# Check Docker
docker --version
docker-compose --version

# Check Docker containers
docker ps
```

### **3. Database Connection**
```bash
# Test database connection
python -c "from app.database import engine; print('Database connected!')"
```

### **4. Stripe Connection**
```bash
# Test Stripe API
python -c "import stripe; stripe.api_key='your_key'; print('Stripe connected!')"
```

### **5. Kafka Connection**
```bash
# Check Kafka topics
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092
```

## 🔧 Troubleshooting Environment Issues

### **Common Python Issues**

#### **Python Not Found**
```bash
# Add Python to PATH
export PATH="/usr/local/bin/python3:$PATH"  # macOS/Linux
setx PATH "%PATH%;C:\Python39"            # Windows
```

#### **Virtual Environment Issues**
```bash
# Recreate virtual environment
rm -rf venv
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### **Common Docker Issues**

#### **Docker Not Running**
```bash
# Start Docker service
sudo systemctl start docker  # Linux
# Windows/macOS: Start Docker Desktop
```

#### **Permission Denied**
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Log out and log back in
```

### **Common Database Issues**

#### **Connection Failed**
```bash
# Check DATABASE_URL in .env
cat .env | grep DATABASE_URL

# Test connection manually
psql $DATABASE_URL
```

#### **Migration Issues**
```bash
# Reset migrations
alembic downgrade base
alembic upgrade head
```

### **Common Stripe Issues**

#### **API Key Invalid**
```bash
# Check API key format
echo $STRIPE_API_KEY  # Should start with sk_test_

# Test with curl
curl -u $STRIPE_API_KEY: https://api.stripe.com/v1/customers
```

### **Common ngrok Issues**

#### **Authtoken Invalid**
```bash
# Reconfigure authtoken
ngrok config add-authtoken YOUR_AUTHTOKEN_HERE
```

#### **Port Already in Use**
```bash
# Kill existing ngrok processes
pkill ngrok
# or
taskkill /F /IM ngrok.exe  # Windows
```

## 📊 Environment Health Check

### **Complete System Test**
```bash
# Run comprehensive test
python test_setup.py

# Expected output:
# ✅ Python 3.8+ detected
# ✅ Virtual environment active
# ✅ Dependencies installed
# ✅ Database connected
# ✅ Kafka running
# ✅ Stripe API accessible
# ✅ ngrok configured
```

### **Service Status Check**
```bash
# Check all services
./manage.sh status  # macOS/Linux
manage_windows.bat status  # Windows

# Expected output:
# ✅ API Server: Running
# ✅ Sync Worker: Running
# ✅ ngrok: Running
# ✅ Kafka: Running
```

## 🎯 Next Steps

After completing environment setup:

1. **Start the application**: `./setup_complete.sh` (macOS/Linux) or `setup_complete_windows.bat` (Windows)
2. **Test the API**: Visit http://localhost:8000/docs
3. **Set up webhooks**: Follow the webhook setup guide
4. **Test integration**: Create a customer and verify sync

## 💡 Pro Tips

- **Keep .env file secure** - never commit it to version control
- **Use different environments** for development and production
- **Monitor logs** for debugging issues
- **Test connections** before starting the application
- **Keep dependencies updated** for security

---

**🎉 Environment setup complete!** You're now ready to run the Zenskar Integration System!
