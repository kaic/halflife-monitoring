@echo off
setlocal

echo ========================================
echo TempBridge - Background Installer (Service)
echo ========================================
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
set "TARGET_DIR=%ProgramData%\TempBridge"
set "STARTER_PS=%TARGET_DIR%\start_tempbridge.ps1"
set "LOG_FILE=%TARGET_DIR%\install.log"
set "SERVICE_NAME=TempBridgeSvc"

if not exist "%EXE_SOURCE%" (
    echo [ERROR] Could not find TempBridge.exe at:
    echo   %EXE_SOURCE%
    echo Publish the executable (dotnet publish) before running the installer.
    pause
    exit /b 1
)

echo Cleaning previous installs...
schtasks /Delete /TN TempBridgeMonitoring /F >nul 2>&1
sc stop "%SERVICE_NAME%" >nul 2>&1
sc delete "%SERVICE_NAME%" >nul 2>&1
if exist "%TARGET_DIR%" rd /S /Q "%TARGET_DIR%" >nul 2>&1
mkdir "%TARGET_DIR%"

copy /Y "%EXE_SOURCE%" "%TARGET_DIR%\TempBridge.exe" >nul
if %errorLevel% neq 0 (
    echo [ERROR] Failed to copy TempBridge to %TARGET_DIR%.
    pause
    exit /b 1
)

set "RUNNER_LOG=%TARGET_DIR%\service.log"

"%POWERSHELL_PATH%" -NoProfile -ExecutionPolicy Bypass -Command "try { Unblock-File -LiteralPath '%EXE_SOURCE%' -ErrorAction Stop } catch { }"
"%POWERSHELL_PATH%" -NoProfile -ExecutionPolicy Bypass -Command "try { Unblock-File -LiteralPath '%TARGET_DIR%\TempBridge.exe' -ErrorAction Stop } catch { }"

echo [INFO] Writing starter script to:
set "_tmp=%STARTER_PS%"
echo   %_tmp%
(
    echo $ErrorActionPreference = 'Stop'
    echo $docs = [Environment]::GetFolderPath('MyDocuments')
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

echo Registering Windows service (LocalSystem)...
sc create "%SERVICE_NAME%" binPath= "\"%POWERSHELL_PATH%\" -NoProfile -ExecutionPolicy Bypass -File \"%STARTER_PS%\"" start= auto obj= LocalSystem DisplayName= "TempBridge Background" > "%LOG_FILE%" 2>&1
if %errorLevel% neq 0 (
    type "%LOG_FILE%"
    echo [ERROR] Service creation failed.
    pause
    exit /b 1
)

echo Starting service to validate launch...
sc start "%SERVICE_NAME%" >> "%LOG_FILE%" 2>&1
if %errorLevel% neq 0 (
    type "%LOG_FILE%"
    echo [WARN] Service failed to start. Check the log above.
) else (
    echo [OK] TempBridge is now running as a hidden service.
)

echo.
echo ========================================
echo Installation completed!
echo ========================================
echo.
echo Service log:
if exist "%RUNNER_LOG%" type "%RUNNER_LOG%"
echo.
pause
