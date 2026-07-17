@echo off
REM Zenskar Integration - Service Management (Windows)
REM This script provides service management commands

setlocal enabledelayedexpansion

if "%1"=="" (
    echo [INFO] Zenskar Integration Service Management
    echo ============================================
    echo.
    echo Usage: manage_windows.bat [command]
    echo.
    echo Commands:
    echo   status    - Check status of all services
    echo   start     - Start all services
    echo   stop      - Stop all services
    echo   restart   - Restart all services
    echo   test      - Test the system
    echo   logs      - View service logs
    echo.
    pause
    exit /b 0
)

if "%1"=="status" (
    echo [INFO] Checking service status...
    echo ================================
    echo.
    
    REM Check API server
    netstat -an | findstr ":8000" >nul
    if %errorlevel% equ 0 (
        echo [SUCCESS] FastAPI Server: Running on port 8000
    ) else (
        echo [ERROR] FastAPI Server: Not running
    )
    
    REM Check Kafka
    docker ps | findstr kafka >nul
    if %errorlevel% equ 0 (
        echo [SUCCESS] Kafka: Running
    ) else (
        echo [ERROR] Kafka: Not running
    )
    
    REM Check ngrok
    netstat -an | findstr ":4040" >nul
    if %errorlevel% equ 0 (
        echo [SUCCESS] ngrok: Running on port 4040
    ) else (
        echo [ERROR] ngrok: Not running
    )
    
    REM Check Python processes
    tasklist | findstr python.exe >nul
    if %errorlevel% equ 0 (
        echo [SUCCESS] Python processes: Running
        tasklist | findstr python.exe
    ) else (
        echo [ERROR] Python processes: Not running
    )
    
    echo.
    pause
    exit /b 0
)

if "%1"=="start" (
    echo [INFO] Starting all services...
    echo ==============================
    call setup_complete_windows.bat
    exit /b 0
)

if "%1"=="stop" (
    echo [INFO] Stopping all services...
    echo ==============================
    
    echo [INFO] Stopping Python processes...
    taskkill /f /im python.exe >nul 2>&1
    
    echo [INFO] Stopping ngrok...
    taskkill /f /im ngrok.exe >nul 2>&1
    
    echo [INFO] Stopping Docker containers...
    docker-compose down
    
    echo [SUCCESS] All services stopped
    pause
    exit /b 0
)

if "%1"=="restart" (
    echo [INFO] Restarting all services...
    echo ================================
    
    echo [INFO] Stopping services...
    taskkill /f /im python.exe >nul 2>&1
    taskkill /f /im ngrok.exe >nul 2>&1
    docker-compose down
    
    timeout /t 3 >nul
    
    echo [INFO] Starting services...
    call setup_complete_windows.bat
    exit /b 0
)

if "%1"=="test" (
    echo [INFO] Testing the system...
    echo ============================
    
    REM Test API health
    echo [INFO] Testing API health...
    curl -s http://localhost:8000/health >nul 2>&1
    if %errorlevel% equ 0 (
        echo [SUCCESS] API health check passed
    ) else (
        echo [ERROR] API health check failed
    )
    
    REM Test database connection
    echo [INFO] Testing database connection...
    call venv\Scripts\activate.bat
    python -c "from app.database import engine; print('Database connected!')" 2>nul
    if %errorlevel% equ 0 (
        echo [SUCCESS] Database connection successful
    ) else (
        echo [ERROR] Database connection failed
    )
    
    REM Test Kafka
    echo [INFO] Testing Kafka...
    docker ps | findstr kafka >nul
    if %errorlevel% equ 0 (
        echo [SUCCESS] Kafka is running
    ) else (
        echo [ERROR] Kafka is not running
    )
    
    echo.
    echo [INFO] System test completed
    pause
    exit /b 0
)

if "%1"=="logs" (
    echo [INFO] Viewing service logs...
    echo =============================
    
    echo [INFO] Docker logs:
    docker-compose logs
    
    echo.
    echo [INFO] To view real-time logs, run:
    echo   docker-compose logs -f
    echo.
    pause
    exit /b 0
)

echo [ERROR] Unknown command: %1
echo [INFO] Use 'manage_windows.bat' without arguments to see available commands
pause
exit /b 1
