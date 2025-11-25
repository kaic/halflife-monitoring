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
set "SERVICE_NAME=TempBridgeSvc"
set "OLD_SHORTCUT=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\TempBridge.lnk"
set "OLD_VBS=%SCRIPT_DIR%TempBridge_Hidden.vbs"
set "POWERSHELL_PATH=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "DOCS_PATH=%USERPROFILE%\Documents"
set "LOG_FILE=%SCRIPT_DIR%install.log"
set "TARGET_DIR=%ProgramData%\TempBridge"
set "STARTER_PS=%TARGET_DIR%\start_tempbridge.ps1"
set "START_CMD=%POWERSHELL_PATH% -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%STARTER_PS%\""

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
sc stop "%SERVICE_NAME%" >nul 2>&1
sc delete "%SERVICE_NAME%" >nul 2>&1

echo Preparing service-like startup (SYSTEM, hidden)...
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"
copy /Y "%EXE_PATH%" "%TARGET_DIR%\TempBridge.exe" >nul

echo [INFO] Writing starter script to %STARTER_PS%
(
    echo param(^)
    echo $ErrorActionPreference = 'Stop'
    echo $docs = '%DOCS_PATH%'
    echo $exe = '%TARGET_DIR%\TempBridge.exe'
    echo $log = '%TARGET_DIR%\service.log'
    echo $wd = '%TARGET_DIR%'
    echo function Log { param([string]$m^) $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; Add-Content -LiteralPath $log -Value "[$ts] $m" }
    echo try {
    echo ^   if (-not (Test-Path -LiteralPath $exe^)) { Log "ERROR missing exe $exe"; exit 1 }
    echo ^   Log "Start user=$env:USERNAME docs=$docs exe=$exe"
    echo ^   $psi = New-Object System.Diagnostics.ProcessStartInfo
    echo ^   $psi.FileName = $exe
    echo ^   $psi.WorkingDirectory = $wd
    echo ^   $psi.UseShellExecute = $false
    echo ^   $psi.WindowStyle = 'Hidden'
    echo ^   $psi.CreateNoWindow = $true
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

echo Registering Windows service (LocalSystem, auto start)...
echo.
sc create "%SERVICE_NAME%" binPath= "\"%POWERSHELL_PATH%\" -NoProfile -ExecutionPolicy Bypass -File \"%STARTER_PS%\"" start= auto obj= LocalSystem DisplayName= "TempBridge Service" > "%LOG_FILE%" 2>&1
if %errorLevel% neq 0 (
    type "%LOG_FILE%"
    echo [ERROR] Failed to create service.
    pause
    exit /b 1
)

echo Starting service to verify launch...
sc start "%SERVICE_NAME%" >> "%LOG_FILE%" 2>&1
timeout /t 3 >nul

echo.
echo ========================================
echo Installation completed!
echo ========================================
echo.
pause
