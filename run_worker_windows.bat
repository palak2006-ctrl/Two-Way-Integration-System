@echo off
REM Zenskar Integration - Start Sync Worker (Windows)
REM This script starts the sync worker with fault tolerance

setlocal enabledelayedexpansion

echo [INFO] Starting Sync Worker...
echo =============================

REM Check if virtual environment exists
if not exist "venv" (
    echo [ERROR] Virtual environment not found. Please run setup_windows.bat first
    pause
    exit /b 1
)

REM Activate virtual environment
echo [INFO] Activating virtual environment...
call venv\Scripts\activate.bat

REM Check if .env file exists
if not exist ".env" (
    echo [ERROR] .env file not found. Please run setup_windows.bat first
    pause
    exit /b 1
)

REM Check if Kafka is running
echo [INFO] Checking Kafka status...
docker ps | findstr kafka >nul
if %errorlevel% neq 0 (
    echo [WARNING] Kafka is not running. Starting Kafka...
    docker-compose up -d
    timeout /t 5 >nul
)

REM Test database connection
echo [INFO] Testing database connection...
python -c "from app.database import engine; print('Database connected!')" 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Database connection failed. Please check your DATABASE_URL in .env file
    pause
    exit /b 1
)

echo [SUCCESS] Database connection successful

REM Start sync worker
echo [INFO] Starting sync worker...
echo [INFO] Press Ctrl+C to stop the worker
echo.

python -m app.workers.sync_worker

echo.
echo [INFO] Sync worker stopped
pause
