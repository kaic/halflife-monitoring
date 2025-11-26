@echo off
setlocal

echo ========================================
echo TempBridge - Startup Installer (Admin)
echo ========================================
echo.

:: Require elevation
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This script must be run as Administrator.
    echo Right click and select "Run as Administrator".
    pause
    exit /b 1
)

set "SCRIPT_DIR=%~dp0"
set "EXE_SOURCE=%SCRIPT_DIR%TempBridge.exe"
set "TARGET_DIR=%ProgramData%\TempBridge"
set "RUNNER_PS=%TARGET_DIR%\start_tempbridge.ps1"
set "POWERSHELL_PATH=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "RUN_KEY=TempBridge"
set "LOG_FILE=%TARGET_DIR%\launcher.log"

if not exist "%EXE_SOURCE%" (
    echo [ERROR] Could not find the executable at "%EXE_SOURCE%".
    echo Build TempBridge first, then rerun this installer.
    pause
    exit /b 1
)

echo Cleaning old installs...
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "%RUN_KEY%" /f >nul 2>&1
schtasks /Delete /TN TempBridgeMonitoring /F >nul 2>&1
sc stop TempBridgeSvc >nul 2>&1
sc delete TempBridgeSvc >nul 2>&1
if exist "%TARGET_DIR%" (
    takeown /F "%TARGET_DIR%" /R /D Y >nul 2>&1
    icacls "%TARGET_DIR%" /grant *S-1-5-32-544:F /T >nul 2>&1
    rd /S /Q "%TARGET_DIR%" >nul 2>&1
)
mkdir "%TARGET_DIR%"

echo Copying TempBridge to %TARGET_DIR% ...
copy /Y "%EXE_SOURCE%" "%TARGET_DIR%\TempBridge.exe" >nul
if %errorLevel% neq 0 (
    echo [ERROR] Failed to copy TempBridge to %TARGET_DIR%.
    pause
    exit /b 1
)

echo Removing downloaded-file mark (SmartScreen)...
"%POWERSHELL_PATH%" -NoProfile -ExecutionPolicy Bypass -Command "try { Unblock-File -LiteralPath '%EXE_SOURCE%' -ErrorAction Stop } catch { }"
"%POWERSHELL_PATH%" -NoProfile -ExecutionPolicy Bypass -Command "try { Unblock-File -LiteralPath '%TARGET_DIR%\TempBridge.exe' -ErrorAction Stop } catch { exit 2 }"

echo [INFO] Ensuring antivirus trusts TempBridge (Microsoft Defender)...
"%POWERSHELL_PATH%" -NoProfile -ExecutionPolicy Bypass -Command ^
  "if (Get-Command Add-MpPreference -ErrorAction SilentlyContinue) { try { Add-MpPreference -ExclusionPath '%TARGET_DIR%' -ErrorAction Stop; } catch {} }"

set "DOCS_PATH=%USERPROFILE%\Documents"

if not exist "%DOCS_PATH%" (
    echo [WARN] Documents folder not found for %USERPROFILE%. Using default.
)

echo Writing launcher script to %RUNNER_PS% ...
(
    echo $ErrorActionPreference = 'Stop'
    echo $docs = '%DOCS_PATH%'
    echo $exe = '%TARGET_DIR%\TempBridge.exe'
    echo $log = '%LOG_FILE%'
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
) > "%RUNNER_PS%"

if %errorLevel% neq 0 (
    echo [ERROR] Failed to write the launcher script.
    pause
    exit /b 1
)

echo Registering Run key for auto-start...
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "%RUN_KEY%" /t REG_SZ /d "\"%POWERSHELL_PATH%\" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%RUNNER_PS%\"" /f >nul
if %errorLevel% neq 0 (
    echo [WARN] Failed to register the Run key. Falling back to scheduled task.
    goto FALLBACK_TASK
)

echo Launching TempBridge now to validate...
"%POWERSHELL_PATH%" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%RUNNER_PS%" >nul 2>&1
if %errorLevel% neq 0 (
    echo [WARN] TempBridge did not start automatically. Check the log:
    if exist "%LOG_FILE%" type "%LOG_FILE%"
) else (
    echo [OK] TempBridge started in the background. Log file:
    echo   %LOG_FILE%
)

echo.
echo ========================================
echo Installation completed!
echo ========================================
echo.
pause
goto END

:FALLBACK_TASK
echo Registering scheduled task (current user)...
set "TASK_LOG=%TARGET_DIR%\task.log"
schtasks /Create /TN "%TASK_NAME%" /TR "\"%POWERSHELL_PATH%\" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%RUNNER_PS%\"" /SC ONLOGON /RL HIGHEST /IT /F > "%TASK_LOG%" 2>&1
if %errorLevel% neq 0 (
    type "%TASK_LOG%"
    echo [ERROR] Failed to create scheduled task. See log above.
    pause
    exit /b 1
)

echo Triggering the task now to validate launch...
schtasks /Run /TN "%TASK_NAME%" >> "%TASK_LOG%" 2>&1
if %errorLevel% neq 0 (
    type "%TASK_LOG%"
    echo [WARN] Scheduled task did not start. Check the log above.
) else (
    echo [OK] TempBridge started in the background via Task Scheduler.
)

echo.
echo ========================================
echo Installation completed!
echo ========================================
echo.
pause

:END
