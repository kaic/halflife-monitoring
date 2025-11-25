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
set "LOG_FILE=%SCRIPT_DIR%install.log"
set "RUNNER_PS=%SCRIPT_DIR%run_tempbridge.ps1"
set "REGISTER_PS=%SCRIPT_DIR%register_tempbridge_task.ps1"

if not exist "%EXE_PATH%" (
    echo [ERROR] Could not find the executable at "%EXE_PATH%".
    echo Build TempBridge first, then rerun this installer.
    pause
    exit /b 1
)

echo Cleaning old installs...
if exist "%OLD_SHORTCUT%" del "%OLD_SHORTCUT%"
if exist "%OLD_VBS%" del "%OLD_VBS%"
if exist "%REGISTER_PS%" del "%REGISTER_PS%"
if exist "%SCRIPT_DIR%run_tempbridge.log" del "%SCRIPT_DIR%run_tempbridge.log"

if not exist "%RUNNER_PS%" (
    echo [ERROR] Missing helper: %RUNNER_PS%
    echo Make sure run_tempbridge.ps1 is present.
    pause
    exit /b 1
)

echo [INFO] Creating PowerShell task registration script...
(
    echo $ErrorActionPreference = 'Stop'
    echo $taskName = '%TASK_NAME%'
    echo $runner = '%RUNNER_PS%'
    echo if (-not (Test-Path -LiteralPath $runner)) { throw "Runner not found: $runner" }
    echo $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$runner`""
    echo $trigger = New-ScheduledTaskTrigger -AtLogOn
    echo Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest -User $env:USERNAME -Force ^| Out-Null
    echo Start-ScheduledTask -TaskName $taskName ^| Out-Null
    echo 'TASK_OK'
) > "%REGISTER_PS%"

echo Setting scheduled task to start with Windows (Admin)...
echo.

:: Remove previous task if it exists
schtasks /Delete /TN "%TASK_NAME%" /F >nul 2>&1

:: Register task via PowerShell to avoid cmd quoting issues
"%POWERSHELL_PATH%" -NoProfile -ExecutionPolicy Bypass -File "%REGISTER_PS%" > "%LOG_FILE%" 2>&1
if %errorLevel% neq 0 (
    type "%LOG_FILE%"
    echo [ERROR] Failed to create scheduled task. If prompted for a password, provide your Windows password.
    pause
    exit /b 1
)

echo [OK] Scheduled task created to start with Windows.
echo [INFO] Task details written to: %LOG_FILE%
echo Waiting a few seconds for the task to run and create run_tempbridge.log (if any)...
timeout /t 5 >nul

if exist "%SCRIPT_DIR%run_tempbridge.log" (
    echo [INFO] Found run log: %SCRIPT_DIR%run_tempbridge.log
    echo Showing last lines:
    "%POWERSHELL_PATH%" -NoProfile -Command "Get-Content -Path '%SCRIPT_DIR%run_tempbridge.log' -Tail 10"
) else (
    echo [WARN] run_tempbridge.log not found yet. It will be created when the task actually runs.
)

echo.
echo ========================================
echo Installation completed!
echo ========================================
echo.
pause
