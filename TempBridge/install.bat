@echo off
setlocal

echo ========================================
echo TempBridge - Background Installer
echo ========================================
echo.

:: Check for elevation
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This script must run as Administrator.
    echo Right-click and choose "Run as administrator".
    pause
    exit /b 1
)

set "SCRIPT_DIR=%~dp0"
set "EXE_SOURCE=%SCRIPT_DIR%TempBridge.exe"
set "TARGET_DIR=%ProgramData%\TempBridge"
set "RUNNER_PS=%TARGET_DIR%\run_tempbridge.ps1"
set "POWERSHELL_PATH=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "RUN_KEY=TempBridge"
set "SERVICE_NAME=TempBridgeSvc"
set "TASK_NAME=TempBridgeMonitoring"
set "EXE_TARGET=%TARGET_DIR%\TempBridge.exe"

if not exist "%EXE_SOURCE%" (
    echo [ERROR] Could not find TempBridge at:
    echo   %EXE_SOURCE%
    echo Publish the executable with "dotnet publish" before running the installer.
    pause
    exit /b 1
)

echo Cleaning previous installs...
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "%RUN_KEY%" /f >nul 2>&1
schtasks /Delete /TN "%TASK_NAME%" /F >nul 2>&1
sc stop "%SERVICE_NAME%" >nul 2>&1
sc delete "%SERVICE_NAME%" >nul 2>&1

if not exist "%TARGET_DIR%" (
    mkdir "%TARGET_DIR%"
) else (
    del /Q "%TARGET_DIR%\*" >nul 2>&1
)

copy /Y "%EXE_SOURCE%" "%EXE_TARGET%" >nul
if %errorLevel% neq 0 (
    echo [ERROR] Failed to copy TempBridge to %EXE_TARGET%.
    pause
    exit /b 1
)

echo Removing downloaded-file mark (SmartScreen)...
"%POWERSHELL_PATH%" -NoProfile -ExecutionPolicy Bypass -Command "try { Unblock-File -LiteralPath '%EXE_TARGET%' -ErrorAction Stop } catch { exit 2 }"
if %errorLevel% neq 0 (
    echo [WARN] Could not clear the Alternate Data Stream. Windows SmartScreen may still prompt once.
) else (
    echo [OK] Alternate Data Stream cleared successfully.
)

set "RUNNER_LOG=%TARGET_DIR%\launcher.log"

echo [INFO] Creating hidden launcher script:
set "_tmp=%RUNNER_PS%"
echo   %_tmp%
(
    echo $ErrorActionPreference = 'Stop'
    echo $exe = '%EXE_TARGET%'
    echo $log = '%RUNNER_LOG%'
    echo function Log { param([string]$m^) $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; Add-Content -LiteralPath $log -Value "[$ts] $m" }
    echo try {
    echo ^   if (-not (Test-Path -LiteralPath $exe^)) { Log "ERROR missing exe $exe"; exit 1 }
    echo ^   $docs = [Environment]::GetFolderPath('MyDocuments')
    echo ^   $psi = New-Object System.Diagnostics.ProcessStartInfo
    echo ^   $psi.FileName = $exe
    echo ^   $psi.WorkingDirectory = Split-Path -Path $exe
    echo ^   $psi.UseShellExecute = $false
    echo ^   $psi.CreateNoWindow = $true
    echo ^   $psi.WindowStyle = 'Hidden'
    echo ^   $psi.Environment['TEMPBRIDGE_DOCUMENTS'] = $docs
    echo ^   $p = [System.Diagnostics.Process]::Start($psi)
    echo ^   if (-not $p^) { Log "ERROR failed to start process"; exit 1 }
    echo ^   Log "Started TempBridge pid=$($p.Id) user=$env:USERNAME docs=$docs"
    echo ^   exit 0
    echo } catch {
    echo ^   Log ("ERROR " + $_.Exception.Message)
    echo ^   exit 1
    echo }
) > "%RUNNER_PS%"

if %errorLevel% neq 0 (
    echo [ERROR] Could not create the helper script.
    pause
    exit /b 1
)

echo Registering autorun on logon...
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "%RUN_KEY%" /t REG_SZ /d "\"%POWERSHELL_PATH%\" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%RUNNER_PS%\"" /f >nul
if %errorLevel% neq 0 (
    echo [ERROR] Unable to write the startup registry key.
    pause
    exit /b 1
)

echo Starting TempBridge now to validate...
"%POWERSHELL_PATH%" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%RUNNER_PS%" >nul 2>&1

if %errorLevel% neq 0 (
    echo [WARN] TempBridge did not start automatically. Check the launcher log:
    echo   %RUNNER_LOG%
) else (
    echo [OK] TempBridge is running in the background. Log file:
    echo   %RUNNER_LOG%
)

echo.
echo ========================================
echo Installation completed!
echo ========================================
echo.
echo TempBridge will load hidden for every user logon.
echo Run "uninstall.bat" (Admin) to remove.
echo.
pause
