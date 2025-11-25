@echo off
setlocal enabledelayedexpansion
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
set "LOG_FILE=%SCRIPT_DIR%install.log"
set "TARGET_DOCS=%USERPROFILE%\Documents"
set "START_CMD=%POWERSHELL_PATH% -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command \"$env:TEMPBRIDGE_DOCUMENTS='%TARGET_DOCS%'; Start-Process -FilePath '%EXE_PATH%' -WorkingDirectory '%SCRIPT_DIR%' -WindowStyle Hidden\""
set "TASK_RUNNER=%SCRIPT_DIR%run_tempbridge.cmd"

if not exist "%EXE_PATH%" (
    echo [ERROR] Could not find the executable at "%EXE_PATH%".
    echo Build TempBridge first, then rerun this installer.
    pause
    exit /b 1
)

echo Cleaning old installs...
if exist "%OLD_SHORTCUT%" (
    echo [INFO] Removing old Startup shortcut...
    del "%OLD_SHORTCUT%"
)
if exist "%OLD_VBS%" (
    echo [INFO] Removing old VBS helper...
    del "%OLD_VBS%"
)
if exist "%TASK_RUNNER%" (
    echo [INFO] Removing old helper runner...
    del "%TASK_RUNNER%"
)

echo [INFO] Creating helper runner for Task Scheduler...
(
    echo @echo off
    echo set "TEMPBRIDGE_DOCUMENTS=%TARGET_DOCS%"
    echo set "LOG_FILE=%%~dp0run_tempbridge.log"
    echo cd /d "%SCRIPT_DIR%"
    echo echo [%%date%% %%time%%] start user=%%username%% profile=%%userprofile%% ^>^> "%%LOG_FILE%%"
    echo "%EXE_PATH%" ^>^> "%%LOG_FILE%%" 2^>^&1
    echo echo [%%date%% %%time%%] exit code %%errorlevel%% ^>^> "%%LOG_FILE%%"
) > "%TASK_RUNNER%"

echo Setting scheduled task to start with Windows (Admin)...
echo.

:: Remove previous task if it exists
schtasks /Delete /TN "%TASK_NAME%" /F >nul 2>&1

:: Create new task under the logged user with highest privilege, using helper runner to avoid quote issues
:: /DELAY 0000:05 adds a small delay to avoid race with user profile initialization (format mmmm:ss)
schtasks /Create /TN "%TASK_NAME%" /TR "\"%TASK_RUNNER%\"" /SC ONLOGON /RL HIGHEST /DELAY 0000:05 /RU "%USERNAME%" /F > "%LOG_FILE%" 2>&1
if %errorLevel% neq 0 (
    type "%LOG_FILE%"
    echo [ERROR] Failed to create scheduled task. If prompted for a password, provide your Windows password.
    pause
    exit /b 1
)

echo [OK] Scheduled task created to start with Windows.
echo [INFO] Task details written to: %LOG_FILE%

echo Running scheduled task now for verification...
schtasks /Run /TN "%TASK_NAME%" >> "%LOG_FILE%" 2>&1
timeout /t 3 >nul

if exist "%TASK_RUNNER%" (
    echo [INFO] Helper exists: %TASK_RUNNER%
) else (
    echo [WARN] Helper missing: %TASK_RUNNER%
)

if exist "%SCRIPT_DIR%run_tempbridge.log" (
    echo [INFO] Found run log: %SCRIPT_DIR%run_tempbridge.log
    echo Showing last lines:
    powershell -NoProfile -Command "Get-Content -Path '%SCRIPT_DIR%run_tempbridge.log' -Tail 5"
) else (
    echo [WARN] run_tempbridge.log not found yet. It will be created when the task actually runs.
)

echo.
echo ========================================
echo Installation completed!
echo ========================================
echo.
pause
