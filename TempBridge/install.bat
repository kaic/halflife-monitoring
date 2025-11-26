@echo off
setlocal

echo ========================================
echo TempBridge - Instalador em Segundo Plano
echo ========================================
echo.

:: Verifica permissao de administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERRO] Este script precisa ser executado como Administrador.
    echo Clique com o botao direito e escolha "Executar como administrador".
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
    echo [ERRO] Nao encontrei o TempBridge compilado em:
    echo   %EXE_SOURCE%
    echo Gere o executavel com "dotnet publish" antes de rodar o instalador.
    pause
    exit /b 1
)

echo Limpando instalacoes antigas...
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
    echo [ERRO] Falha ao copiar o TempBridge para %EXE_TARGET%.
    pause
    exit /b 1
)

echo Removendo marca de arquivo baixado (SmartScreen)...
"%POWERSHELL_PATH%" -NoProfile -ExecutionPolicy Bypass -Command "try { Unblock-File -LiteralPath '%EXE_TARGET%' -ErrorAction Stop } catch { exit 1 }"
if %errorLevel% neq 0 (
    echo [AVISO] Nao foi possivel remover a marcacao. Windows SmartScreen pode pedir confirmacao no primeiro start.
) else (
    echo [OK] Marca de seguranca removida com sucesso.
)

set "RUNNER_LOG=%TARGET_DIR%\launcher.log"

echo [INFO] Criando script de inicializacao oculta em:
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
    echo [ERRO] Falha ao criar o script auxiliar.
    pause
    exit /b 1
)

echo Registrando execucao automatica no logon...
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "%RUN_KEY%" /t REG_SZ /d "\"%POWERSHELL_PATH%\" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%RUNNER_PS%\"" /f >nul
if %errorLevel% neq 0 (
    echo [ERRO] Nao foi possivel gravar a chave de inicializacao.
    pause
    exit /b 1
)

echo Disparando o TempBridge agora para validar...
"%POWERSHELL_PATH%" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%RUNNER_PS%" >nul 2>&1

if %errorLevel% neq 0 (
    echo [AVISO] TempBridge nao iniciou automaticamente. Verifique o arquivo de log:
    echo   %RUNNER_LOG%
) else (
    echo [OK] TempBridge iniciado em segundo plano. Arquivo de log:
    echo   %RUNNER_LOG%
)

echo.
echo ========================================
echo Instalacao concluida!
echo ========================================
echo.
echo O TempBridge sera carregado oculto sempre que qualquer usuario fizer logon.
echo Execute "uninstall.bat" (Admin) para remover.
echo.
pause
