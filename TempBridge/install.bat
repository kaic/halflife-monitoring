@echo off
setlocal
echo ========================================
echo TempBridge - Startup Installer (Admin)
echo ========================================
echo.

:: Check for admin permissions
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This script must be run as Administrator!
    echo Right click and select "Run as Administrator".
    pause
    exit /b 1
)

set "SCRIPT_DIR=%~dp0"
set "EXE_PATH=%SCRIPT_DIR%TempBridge.exe"
set "TASK_NAME=TempBridgeMonitoring"
set "OLD_SHORTCUT=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\TempBridge.lnk"
set "OLD_VBS=%SCRIPT_DIR%TempBridge_Hidden.vbs"
set "POWERSHELL_PATH=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "DOCS_PATH=%USERPROFILE%\Documents"
set "LOG_FILE=%SCRIPT_DIR%install.log"

set "PS_CMD=%POWERSHELL_PATH% -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command \"$env:TEMPBRIDGE_DOCUMENTS='%DOCS_PATH%'; Start-Process -FilePath '%EXE_PATH%' -WorkingDirectory '%SCRIPT_DIR%' -WindowStyle Hidden\""
set "RUN_KEY=HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
set "RUN_VALUE=TempBridgeMonitoring"

if not exist "%EXE_PATH%" (
    echo [ERROR] Could not find the executable at "%EXE_PATH%".
    echo Build TempBridge first, then rerun this installer.
    pause
    exit /b 1
)

echo Cleaning old installs...
if exist "%OLD_SHORTCUT%" del "%OLD_SHORTCUT%"
if exist "%OLD_VBS%" del "%OLD_VBS%"
if exist "%LOG_FILE%" del "%LOG_FILE%"

echo Setting scheduled task to start with Windows (Admin)...
echo.

:: Remove previous task if it exists
schtasks /Delete /TN "%TASK_NAME%" /F >nul 2>&1

echo Configuring Run key entry to start hidden at logon...
reg add "%RUN_KEY%" /v "%RUN_VALUE%" /t REG_SZ /d "%PS_CMD%" /f > "%LOG_FILE%" 2>&1
if %errorLevel% neq 0 (
    type "%LOG_FILE%"
    echo [ERROR] Failed to configure startup via registry.
    pause
    exit /b 1
)

echo [OK] Run key configured: %RUN_KEY%\%RUN_VALUE%
echo Starting TempBridge now in the background...
%PS_CMD%
if %errorLevel% equ 0 (
    echo [OK] TempBridge started (you can close this window).
) else (
    echo [WARN] Could not start TempBridge automatically. Rerun this installer as Admin and try again.
)

echo.
echo ========================================
echo Installation completed!
echo ========================================
echo.
pause
