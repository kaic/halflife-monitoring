@echo off
setlocal

echo ========================================
echo TempBridge - Desinstalador
echo ========================================
echo.

:: Verifica permissoes
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERRO] Execute este script como Administrador.
    pause
    exit /b 1
)

set "RUN_KEY=TempBridge"
set "TARGET_DIR=%ProgramData%\TempBridge"
set "SERVICE_NAME=TempBridgeSvc"
set "TASK_NAME=TempBridgeMonitoring"

set "POWERSHELL_PATH=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "RUNNER_PS=%TARGET_DIR%\run_tempbridge.ps1"

echo Finalizando processos ativos...
taskkill /F /IM TempBridge.exe >nul 2>&1

if exist "%RUNNER_PS%" (
    "%POWERSHELL_PATH%" -Command "Get-Process TempBridge -ErrorAction SilentlyContinue | Stop-Process -Force" >nul 2>&1
)

echo Removendo inicializacao automatica...
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "%RUN_KEY%" /f >nul 2>&1
schtasks /Delete /TN "%TASK_NAME%" /F >nul 2>&1
sc stop "%SERVICE_NAME%" >nul 2>&1
sc delete "%SERVICE_NAME%" >nul 2>&1

if exist "%TARGET_DIR%" (
    echo Limpando arquivos em %TARGET_DIR% ...
    rd /S /Q "%TARGET_DIR%"
)

echo.
echo ========================================
echo TempBridge removido do startup.
echo ========================================
echo.
echo Rode install.bat (Admin) se quiser habilitar novamente.
echo.
pause
