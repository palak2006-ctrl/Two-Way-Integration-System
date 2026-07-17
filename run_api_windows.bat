@echo off
REM Zenskar Integration - Start FastAPI Server (Windows)
REM This script starts the FastAPI server with fault tolerance

setlocal enabledelayedexpansion

echo [INFO] Starting FastAPI Server...
echo ================================

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

REM Check if Kafka is running
echo [INFO] Checking Kafka status...
docker ps | findstr kafka >nul
if %errorlevel% neq 0 (
    echo [WARNING] Kafka is not running. Starting Kafka...
    docker-compose up -d
    timeout /t 5 >nul
)

REM Start FastAPI server
echo [INFO] Starting FastAPI server on http://localhost:8000...
echo [INFO] Press Ctrl+C to stop the server
echo.

uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

echo.
echo [INFO] FastAPI server stopped
pause
