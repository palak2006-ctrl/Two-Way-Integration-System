@echo off
REM Zenskar Integration Complete Setup and Launch Script (Windows)
REM This script sets up everything and launches all services

setlocal enabledelayedexpansion

echo [INFO] Zenskar Two-Way Integration System - Complete Setup (Windows)
echo =====================================================================

REM Step 1: Run the main setup script
echo [INFO] Step 1: Running initial setup...
call setup_windows.bat

if %errorlevel% neq 0 (
    echo [ERROR] Initial setup failed. Please fix the issues and try again.
    pause
    exit /b 1
)

echo [SUCCESS] Initial setup completed

REM Step 2: Start the API server in background
echo [INFO] Step 2: Starting FastAPI server...
start "FastAPI Server" /min run_api_windows.bat

REM Wait for API to be ready
echo [INFO] Waiting for API server to be ready...
timeout /t 10 >nul

REM Check if API is responding
echo [INFO] Testing API health...
curl -s http://localhost:8000/health >nul 2>&1
if %errorlevel% equ 0 (
    echo [SUCCESS] FastAPI server is ready
) else (
    echo [WARNING] FastAPI server may not be ready yet, but continuing...
)

REM Step 3: Start the sync worker in background
echo [INFO] Step 3: Starting sync worker...
start "Sync Worker" /min run_worker_windows.bat

REM Give worker time to start
timeout /t 5 >nul
echo [SUCCESS] Sync worker started

REM Step 4: Start ngrok
echo [INFO] Step 4: Starting ngrok tunnel...
start "ngrok Tunnel" /min run_ngrok_windows.bat

REM Wait for ngrok to be ready
timeout /t 10 >nul

REM Try to get ngrok URL
echo [INFO] Attempting to get ngrok URL...
for /f "tokens=*" %%i in ('curl -s http://localhost:4040/api/tunnels 2^>nul ^| findstr "public_url"') do (
    echo [SUCCESS] ngrok tunnel created
    echo [INFO] Check ngrok dashboard at http://localhost:4040 for the public URL
)

echo.
echo [SUCCESS] All Services Started Successfully!
echo ============================================
echo.
echo [SUCCESS] Services are running in separate windows:
echo   - FastAPI Server
echo   - Sync Worker  
echo   - ngrok Tunnel
echo.
echo [INFO] URLs:
echo   - Local API: http://localhost:8000
echo   - API Docs: http://localhost:8000/docs
echo   - Health Check: http://localhost:8000/health
echo   - ngrok Dashboard: http://localhost:4040
echo.
echo [INFO] Next Steps:
echo 1. Test the API: curl http://localhost:8000/health
echo 2. Create a customer: curl -X POST http://localhost:8000/customers -H "Content-Type: application/json" -d "{\"name\":\"Test User\",\"email\":\"test@example.com\"}"
echo 3. Check ngrok dashboard at http://localhost:4040 for the public URL
echo 4. Setup Stripe webhook with the ngrok URL
echo.
echo [INFO] Management Commands:
echo   - Stop all services: taskkill /f /im python.exe /im ngrok.exe
echo   - Restart services: Close all windows and run this script again
echo   - Check logs: docker-compose logs
echo   - Check processes: tasklist | findstr python
echo.
echo [INFO] All services are running in separate windows.
echo [INFO] Close the individual windows to stop specific services.
echo [INFO] Use the management commands above to control the services.
echo.
pause
