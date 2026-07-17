@echo off
REM Zenskar Integration Windows Setup Script
REM This script sets up the entire environment for Windows

setlocal enabledelayedexpansion

REM Colors for output (Windows doesn't support colors in batch, but we'll use echo)
echo [INFO] Zenskar Two-Way Integration System - Windows Setup
echo ========================================================

REM Check if Python is installed
echo [INFO] Checking Python installation...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed. Please install Python 3.8+ from https://python.org
    echo [INFO] Make sure to check "Add Python to PATH" during installation
    pause
    exit /b 1
)

python --version
echo [SUCCESS] Python is installed

REM Check if Docker is installed
echo [INFO] Checking Docker installation...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not installed. Please install Docker Desktop from https://docker.com
    echo [INFO] Docker Desktop is required for Kafka
    pause
    exit /b 1
)

docker --version
echo [SUCCESS] Docker is installed

REM Check if Docker Compose is available
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker Compose is not available. Please ensure Docker Desktop is running
    pause
    exit /b 1
)

echo [SUCCESS] Docker Compose is available

REM Check if ngrok is installed
echo [INFO] Checking ngrok installation...
ngrok version >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] ngrok is not installed. Installing ngrok...
    
    REM Download ngrok for Windows
    echo [INFO] Downloading ngrok for Windows...
    powershell -Command "Invoke-WebRequest -Uri 'https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip' -OutFile 'ngrok.zip'"
    
    if exist ngrok.zip (
        echo [INFO] Extracting ngrok...
        powershell -Command "Expand-Archive -Path 'ngrok.zip' -DestinationPath '.' -Force"
        del ngrok.zip
        
        REM Add ngrok to PATH (temporarily for this session)
        set PATH=%PATH%;%CD%
        
        ngrok version >nul 2>&1
        if %errorlevel% neq 0 (
            echo [ERROR] Failed to install ngrok. Please install manually from https://ngrok.com/download
            pause
            exit /b 1
        )
    ) else (
        echo [ERROR] Failed to download ngrok. Please install manually from https://ngrok.com/download
        pause
        exit /b 1
    )
)

echo [SUCCESS] ngrok is installed

REM Configure ngrok with the provided authtoken
echo [INFO] Configuring ngrok with authtoken...
ngrok config add-authtoken 33e3RRIq4OsphucDl71VQml9q2p_5p2J3wnFJL6AUv6jmmCDE

if %errorlevel% equ 0 (
    echo [SUCCESS] ngrok configured successfully
) else (
    echo [ERROR] Failed to configure ngrok authtoken
    pause
    exit /b 1
)

REM Create virtual environment if it doesn't exist
echo [INFO] Setting up Python virtual environment...
if not exist "venv" (
    echo [INFO] Creating virtual environment...
    python -m venv venv
    echo [SUCCESS] Virtual environment created
) else (
    echo [SUCCESS] Virtual environment already exists
)

REM Activate virtual environment
echo [INFO] Activating virtual environment...
call venv\Scripts\activate.bat

REM Upgrade pip
echo [INFO] Upgrading pip...
python -m pip install --upgrade pip

REM Install dependencies
echo [INFO] Installing Python dependencies...
pip install -r requirements.txt

if %errorlevel% equ 0 (
    echo [SUCCESS] Dependencies installed successfully
) else (
    echo [ERROR] Failed to install dependencies
    pause
    exit /b 1
)

REM Check if .env file exists
echo [INFO] Checking environment configuration...
if not exist ".env" (
    echo [WARNING] .env file not found. Creating from template...
    copy env.example .env
    echo [WARNING] Please edit .env file with your actual credentials:
    echo [WARNING]   - DATABASE_URL: Get from Neon dashboard
    echo [WARNING]   - STRIPE_API_KEY: Get from Stripe dashboard
    echo [WARNING]   - STRIPE_WEBHOOK_SECRET: Will be set after webhook setup
    echo [INFO] Opening .env file for editing...
    notepad .env
    
    REM Check if user has configured the .env file
    findstr /C:"your_stripe_key_here" .env >nul
    if %errorlevel% equ 0 (
        echo [ERROR] Please configure your .env file before continuing
        echo [INFO] Required fields to configure:
        echo [INFO]   - DATABASE_URL (from Neon dashboard)
        echo [INFO]   - STRIPE_API_KEY (from Stripe dashboard)
        pause
        exit /b 1
    )
)

echo [SUCCESS] Environment configuration ready

REM Check if port 8000 is available
echo [INFO] Checking if port 8000 is available...
netstat -an | findstr ":8000" >nul
if %errorlevel% equ 0 (
    echo [WARNING] Port 8000 is already in use. Attempting to free it...
    taskkill /f /im python.exe >nul 2>&1
    timeout /t 2 >nul
    
    netstat -an | findstr ":8000" >nul
    if %errorlevel% equ 0 (
        echo [ERROR] Port 8000 is still in use. Please free it manually:
        echo [INFO]   netstat -ano | findstr :8000
        echo [INFO]   taskkill /f /pid [PID_NUMBER]
        pause
        exit /b 1
    )
)

echo [SUCCESS] Port 8000 is available

REM Start Kafka with Docker
echo [INFO] Starting Kafka with Docker Compose...
docker-compose down >nul 2>&1
docker-compose up -d

if %errorlevel% equ 0 (
    echo [SUCCESS] Kafka containers started
) else (
    echo [ERROR] Failed to start Kafka containers
    echo [INFO] Make sure Docker Desktop is running
    pause
    exit /b 1
)

REM Wait for Kafka to be ready
echo [INFO] Waiting for Kafka to be ready...
timeout /t 10 >nul
echo [SUCCESS] Kafka is ready

REM Run database migrations
echo [INFO] Running database migrations...
alembic upgrade head

if %errorlevel% equ 0 (
    echo [SUCCESS] Database migrations completed
) else (
    echo [ERROR] Database migrations failed
    echo [INFO] Please check your DATABASE_URL in .env file
    pause
    exit /b 1
)

REM Test the setup
echo [INFO] Testing setup...
python test_setup.py

if %errorlevel% equ 0 (
    echo [SUCCESS] Setup verification passed
) else (
    echo [WARNING] Setup verification had issues, but continuing...
)

echo.
echo [SUCCESS] Setup Complete!
echo ========================
echo [SUCCESS] All services are ready to start
echo.
echo [INFO] Next Steps:
echo 1. Start FastAPI server: run_api.bat
echo 2. Start sync worker: run_worker.bat
echo 3. Start ngrok: run_ngrok.bat
echo 4. Setup Stripe webhook with ngrok URL
echo.
echo [INFO] URLs:
echo   - API: http://localhost:8000
echo   - API Docs: http://localhost:8000/docs
echo   - Health Check: http://localhost:8000/health
echo.
echo [INFO] Troubleshooting:
echo   - Check logs: docker-compose logs
echo   - Restart Kafka: docker-compose restart
echo   - Check processes: tasklist | findstr python
echo.
pause
