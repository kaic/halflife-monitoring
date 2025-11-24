@echo off
echo ========================================
echo TempBridge - Instalador de Startup (Admin)
echo ========================================
echo.

:: Verifica Permissoes de Admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERRO] Este script precisa ser executado como Administrador!
    echo Clique com o botao direito e selecione "Executar como Administrador".
    pause
    exit /b 1
)

set "SCRIPT_DIR=%~dp0"
set "EXE_PATH=%SCRIPT_DIR%TempBridge.exe"
set "TASK_NAME=TempBridgeMonitoring"

echo Configurando tarefa agendada para iniciar com Windows (Admin)...
echo.

:: Remove tarefa anterior se existir
schtasks /Delete /TN "%TASK_NAME%" /F >nul 2>&1

:: Cria nova tarefa:
:: /SC ONLOGON - Inicia ao logar
:: /RL HIGHEST - Executa com privilegios maximos (Admin)
:: /TR ... - Caminho do executavel
schtasks /Create /TN "%TASK_NAME%" /TR "'%EXE_PATH%'" /SC ONLOGON /RL HIGHEST /F

if %errorLevel% equ 0 (
    echo [OK] Tarefa agendada criada com sucesso!
    echo Nome: %TASK_NAME%
    echo.
    echo TempBridge iniciara automaticamente com privilegios de Admin no proximo login.
    echo.
    echo Deseja iniciar agora? (S/N^)
    choice /C SN /M "Iniciar TempBridge"
    
    if errorlevel 2 goto :end
    if errorlevel 1 goto :start
) else (
    echo [ERRO] Falha ao criar tarefa agendada.
    pause
    exit /b 1
)

:start
echo.
echo Iniciando TempBridge...
schtasks /Run /TN "%TASK_NAME%"
timeout /t 2 >nul
echo.
echo TempBridge iniciado via Agendador de Tarefas.
goto :end

:end
echo.
echo ========================================
echo Instalacao concluida!
echo ========================================
echo.
echo IMPORTANTE:
echo - TempBridge roda em background com permissoes de Admin
echo - Para parar: Task Manager ^> TempBridge.exe ^> End Task
echo.
pause
