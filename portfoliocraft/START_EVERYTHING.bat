@echo off
setlocal

echo ============================================
echo   PortfolioCraft - Starting full stack
echo ============================================

echo.
echo Stopping any previous containers...
docker compose down

echo.
echo Building and starting containers (portfolio, graphite, grafana, nagios)...
docker compose up --build -d

echo.
echo Waiting 30 seconds for services to initialize...
timeout /t 30 /nobreak > NUL

echo.
echo ============================================
echo   PortfolioCraft is up. Open these URLs:
echo ============================================
echo   Website        : http://localhost:8080
echo   Health check   : http://localhost:8080/healthz
echo   Graphite UI    : http://localhost:8090
echo   Grafana        : http://localhost:3000   (admin / admin)
echo   Nagios         : http://localhost:8081   (nagiosadmin / nagios)
echo ============================================
echo.
echo Next step: run send_metrics.ps1 in a new PowerShell window
echo   powershell -ExecutionPolicy Bypass -File .\send_metrics.ps1
echo.

endlocal
