@echo off
REM Zenskar Integration - Start ngrok Tunnel (Windows)
REM This script starts ngrok tunnel with fault tolerance

setlocal enabledelayedexpansion

echo [INFO] Starting ngrok Tunnel...
echo ==============================

REM Check if ngrok is installed
ngrok version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] ngrok is not installed. Please run setup_windows.bat first
    pause
    exit /b 1
)

REM Check if port 8000 is running
echo [INFO] Checking if API server is running on port 8000...
netstat -an | findstr ":8000" >nul
if %errorlevel% neq 0 (
    echo [WARNING] API server is not running on port 8000
    echo [INFO] Please start the API server first: run_api_windows.bat
    echo [INFO] Or start all services: setup_complete_windows.bat
    pause
    exit /b 1
)

echo [SUCCESS] API server is running on port 8000

REM Start ngrok tunnel
echo [INFO] Starting ngrok tunnel to localhost:8000...
echo [INFO] This will create a public URL for webhook testing
echo [INFO] Press Ctrl+C to stop ngrok
echo.

ngrok http 8000

echo.
echo [INFO] ngrok tunnel stopped
pause
