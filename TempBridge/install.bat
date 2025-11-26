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
set "TARGET_DIR=%LocalAppData%\TempBridge"
set "RUNNER_PS=%TARGET_DIR%\start_tempbridge.ps1"
set "POWERSHELL_PATH=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "TASK_NAME=TempBridgeMonitoring"
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

echo [INFO] Adding TempBridge exclusions to all detected antivirus products...
echo.

:: Call PowerShell script to handle all antivirus exclusions (optimized for speed)
"%POWERSHELL_PATH%" -NoProfile -ExecutionPolicy Bypass -Command ^
  "$targetExe = '%TARGET_DIR%\\TempBridge.exe'; $targetDir = '%TARGET_DIR%'; " ^
  "$avFound = 0; " ^
  "Write-Host ''; " ^
  "Write-Host '=== Scanning for Antivirus Products ==='; " ^
  "Write-Host ''; " ^
  "$procs = @{}; Get-Process | ForEach-Object { $procs[$_.ProcessName.ToLower()] = $true }; " ^
  "if (Get-Command Add-MpPreference -ErrorAction SilentlyContinue) { " ^
  "  Write-Host '[1/11] Windows Defender:' -NoNewline; " ^
  "  try { Add-MpPreference -ExclusionPath $targetDir -ErrorAction Stop; Write-Host ' ADDED' -ForegroundColor Green; $avFound++ } " ^
  "  catch { Write-Host ' FAILED (may need manual configuration)' -ForegroundColor Yellow } " ^
  "} else { Write-Host '[1/11] Windows Defender: NOT DETECTED' } " ^
  "Write-Host '[2/11] Bitdefender:' -NoNewline; " ^
  "if ($procs['bdagent'] -or $procs['bdservicehost']) { " ^
  "  Write-Host ' DETECTED (add manually via GUI)' -ForegroundColor Yellow; $avFound++ " ^
  "} else { Write-Host ' NOT DETECTED' } " ^
  "Write-Host '[3/11] Avast:' -NoNewline; " ^
  "if ($procs['avastsvc'] -or $procs['avastui']) { " ^
  "  Write-Host ' DETECTED (add manually: Settings > General > Exclusions)' -ForegroundColor Yellow; $avFound++ " ^
  "} else { Write-Host ' NOT DETECTED' } " ^
  "Write-Host '[4/11] AVG:' -NoNewline; " ^
  "if ($procs['avgsvc'] -or $procs['avgui']) { " ^
  "  Write-Host ' DETECTED (add manually: Settings > General > Exclusions)' -ForegroundColor Yellow; $avFound++ " ^
  "} else { Write-Host ' NOT DETECTED' } " ^
  "Write-Host '[5/11] Norton/Symantec:' -NoNewline; " ^
  "if ($procs['nortonsecurity'] -or $procs['ccsvchst']) { " ^
  "  Write-Host ' DETECTED (add manually: Settings > Antivirus > Scans and Risks > Exclusions)' -ForegroundColor Yellow; $avFound++ " ^
  "} else { Write-Host ' NOT DETECTED' } " ^
  "Write-Host '[6/11] McAfee:' -NoNewline; " ^
  "if ($procs['mcshield'] -or $procs['mcapexe']) { " ^
  "  Write-Host ' DETECTED (add manually: Virus and Spyware Protection > Excluded Files)' -ForegroundColor Yellow; $avFound++ " ^
  "} else { Write-Host ' NOT DETECTED' } " ^
  "Write-Host '[7/11] Kaspersky:' -NoNewline; " ^
  "$kaspFound = $false; $procs.Keys | Where-Object { $_ -like 'avp*' -or $_ -like 'kavfs*' } | ForEach-Object { $kaspFound = $true }; " ^
  "if ($kaspFound) { " ^
  "  Write-Host ' DETECTED (add manually: Settings > Additional > Threats and Exclusions)' -ForegroundColor Yellow; $avFound++ " ^
  "} else { Write-Host ' NOT DETECTED' } " ^
  "Write-Host '[8/11] ESET:' -NoNewline; " ^
  "if ($procs['ekrn'] -or $procs['egui']) { " ^
  "  Write-Host ' DETECTED (add manually: Setup > Computer > Exclusions)' -ForegroundColor Yellow; $avFound++ " ^
  "} else { Write-Host ' NOT DETECTED' } " ^
  "Write-Host '[9/11] Avira:' -NoNewline; " ^
  "$aviraFound = $false; $procs.Keys | Where-Object { $_ -like 'avira*' } | ForEach-Object { $aviraFound = $true }; " ^
  "if ($aviraFound) { " ^
  "  Write-Host ' DETECTED (add manually: System Scanner > Exceptions)' -ForegroundColor Yellow; $avFound++ " ^
  "} else { Write-Host ' NOT DETECTED' } " ^
  "Write-Host '[10/11] Trend Micro:' -NoNewline; " ^
  "if ($procs['tmlisten'] -or $procs['pccntmon']) { " ^
  "  Write-Host ' DETECTED (add manually: Settings > Exception List)' -ForegroundColor Yellow; $avFound++ " ^
  "} else { Write-Host ' NOT DETECTED' } " ^
  "Write-Host '[11/11] Malwarebytes:' -NoNewline; " ^
  "if ($procs['mbam'] -or $procs['mbamservice']) { " ^
  "  Write-Host ' DETECTED (add manually: Settings > Exclusions)' -ForegroundColor Yellow; $avFound++ " ^
  "} else { Write-Host ' NOT DETECTED' } " ^
  "Write-Host ''; " ^
  "Write-Host \"Found $avFound antivirus product(s) on this system.\"; " ^
  "Write-Host ''; " ^
  "if ($avFound -gt 0) { " ^
  "  Write-Host 'IMPORTANT: If you see DETECTED or FAILED above, please add manually:' -ForegroundColor Cyan; " ^
  "  Write-Host \"  Exclusion path: $targetExe\" -ForegroundColor White; " ^
  "  Write-Host \"  Or directory: $targetDir\" -ForegroundColor White; " ^
  "  Write-Host '  See docs\\ANTIVIRUS_FIX.md for detailed instructions.' -ForegroundColor White; " ^
  "  Write-Host ''; " ^
  "}"

echo.

set "DOCS_PATH=%USERPROFILE%\Documents"

echo Writing launcher script to %RUNNER_PS% ...
(
echo $ErrorActionPreference = 'Stop'
echo $docs = '%DOCS_PATH%'
echo $exe = '%TARGET_DIR%\TempBridge.exe'
echo $log = '%LOG_FILE%'
echo $wd = '%TARGET_DIR%'
echo.
echo function Log { param^([string]$m^) $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; Add-Content -LiteralPath $log -Value "[$ts] $m" }
echo.
echo try {
echo     if ^(-not ^(Test-Path -LiteralPath $exe^)^) { Log "ERROR missing exe $exe"; exit 1 }
echo     Log "Start user=$env:USERNAME docs=$docs exe=$exe"
echo     $psi = New-Object System.Diagnostics.ProcessStartInfo
echo     $psi.FileName = $exe
echo     $psi.WorkingDirectory = $wd
echo     $psi.UseShellExecute = $false
echo     $psi.CreateNoWindow = $true
echo     $psi.WindowStyle = 'Hidden'
echo     $psi.Environment['TEMPBRIDGE_DOCUMENTS'] = $docs
echo     $p = [System.Diagnostics.Process]::Start^($psi^)
echo     if ^(-not $p^) { Log "ERROR failed to start process"; exit 1 }
echo     Log "Started TempBridge pid=$^($p.Id^)"
echo     exit 0
echo } catch {
echo     Log ^("ERROR " + $_.Exception.Message^)
echo     exit 1
echo }
) > "%RUNNER_PS%"

if %errorLevel% neq 0 (
    echo [ERROR] Failed to write the launcher script.
    pause
    exit /b 1
)

echo Registering scheduled task (current user, highest privileges)...
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
if exist "%TASK_LOG%" type "%TASK_LOG%"
echo.
pause
