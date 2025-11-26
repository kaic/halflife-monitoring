@echo off
setlocal

echo ========================================
echo TempBridge - Scheduler Installer
========================================
echo.

:: Require elevation
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This script must run as Administrator.
    echo Right-click and choose "Run as administrator".
    pause
    exit /b 1
)

set "SCRIPT_DIR=%~dp0"
set "EXE_SOURCE=%SCRIPT_DIR%TempBridge.exe"
set "POWERSHELL_PATH=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "DOCS_PATH=%USERPROFILE%\Documents"
set "TARGET_DIR=%ProgramData%\TempBridge"
set "STARTER_PS=%TARGET_DIR%\start_tempbridge.ps1"
set "LOG_FILE=%TARGET_DIR%\install.log"
set "TASK_NAME=TempBridgeMonitoring"

if not exist "%EXE_SOURCE%" (
    echo [ERROR] Could not find TempBridge.exe at:
    echo   %EXE_SOURCE%
    echo Publish the executable (dotnet publish) before running the installer.
    pause
    exit /b 1
)

echo Cleaning previous installs...
schtasks /Delete /TN "%TASK_NAME%" /F >nul 2>&1
sc stop TempBridgeSvc >nul 2>&1
sc delete TempBridgeSvc >nul 2>&1
if exist "%TARGET_DIR%" rd /S /Q "%TARGET_DIR%" >nul 2>&1
mkdir "%TARGET_DIR%"

copy /Y "%EXE_SOURCE%" "%TARGET_DIR%\TempBridge.exe" >nul
if %errorLevel% neq 0 (
    echo [ERROR] Failed to copy TempBridge to %TARGET_DIR%.
    pause
    exit /b 1
)

set "RUNNER_LOG=%TARGET_DIR%\launcher.log"

"%POWERSHELL_PATH%" -NoProfile -ExecutionPolicy Bypass -Command "try { Unblock-File -LiteralPath '%EXE_SOURCE%' -ErrorAction Stop } catch { }"
"%POWERSHELL_PATH%" -NoProfile -ExecutionPolicy Bypass -Command "try { Unblock-File -LiteralPath '%TARGET_DIR%\TempBridge.exe' -ErrorAction Stop } catch { exit 2 }"
if %errorLevel% neq 0 (
    echo [WARN] Could not clear the Alternate Data Stream. SmartScreen might prompt on the first launch.
) else (
    echo [OK] Alternate Data Stream cleared successfully.
)

echo [INFO] Writing starter script to:
set "_tmp=%STARTER_PS%"
echo   %_tmp%
(
    echo $ErrorActionPreference = 'Stop'
    echo $docs = '%DOCS_PATH%'
    echo $exe = '%TARGET_DIR%\TempBridge.exe'
    echo $log = '%RUNNER_LOG%'
    echo $wd = '%TARGET_DIR%'
    echo function Log { param([string]$m^) $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; Add-Content -LiteralPath $log -Value "[$ts] $m" }
    echo try {
    echo ^   if (-not (Test-Path -LiteralPath $exe^)) { Log "ERROR missing exe $exe"; exit 1 }
    echo ^   Log "Start user=$env:USERNAME docs=$docs exe=$exe"
    echo ^   $psi = New-Object System.Diagnostics.ProcessStartInfo
    echo ^   $psi.FileName = $exe
    echo ^   $psi.WorkingDirectory = $wd
    echo ^   $psi.UseShellExecute = $false
    echo ^   $psi.CreateNoWindow = $true
    echo ^   $psi.WindowStyle = 'Hidden'
    echo ^   $psi.Environment['TEMPBRIDGE_DOCUMENTS'] = $docs
    echo ^   $p = [System.Diagnostics.Process]::Start($psi)
    echo ^   if (-not $p^) { Log "ERROR failed to start process"; exit 1 }
    echo ^   Log "Started TempBridge pid=$($p.Id)"
    echo ^   exit 0
    echo } catch {
    echo ^   Log ("ERROR " + $_.Exception.Message)
    echo ^   exit 1
    echo }
) > "%STARTER_PS%"

if %errorLevel% neq 0 (
    echo [ERROR] Failed to write the starter PowerShell script.
    pause
    exit /b 1
)

echo Registering scheduled task (SYSTEM, boot start)...
schtasks /Create /TN "%TASK_NAME%" /TR "\"%POWERSHELL_PATH%\" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%STARTER_PS%\"" /SC ONSTART /RU SYSTEM /RL HIGHEST /F > "%LOG_FILE%" 2>&1
if %errorLevel% neq 0 (
    type "%LOG_FILE%"
    echo [ERROR] Failed to create scheduled task. See log above.
    pause
    exit /b 1
)

echo Triggering the task now to validate launch...
schtasks /Run /TN "%TASK_NAME%" >> "%LOG_FILE%" 2>&1
if %errorLevel% neq 0 (
    type "%LOG_FILE%"
    echo [WARN] Scheduled task did not start. Check the log above.
) else (
    echo [OK] TempBridge started in the background via Task Scheduler.
)

echo.
echo ========================================
echo Installation completed!
echo ========================================
echo.
echo Launcher log:
if exist "%RUNNER_LOG%" type "%RUNNER_LOG%"
echo.
pause
