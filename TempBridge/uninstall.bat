@echo off
echo ========================================
echo TempBridge - Desinstalador
echo ========================================
echo.

:: Verifica Permissoes de Admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERRO] Este script precisa ser executado como Administrador!
    pause
    exit /b 1
)

set "TASK_NAME=TempBridgeMonitoring"

echo Parando processo TempBridge...
taskkill /F /IM TempBridge.exe >nul 2>&1

echo.
echo Removendo tarefa agendada...
schtasks /Delete /TN "%TASK_NAME%" /F

:: Limpeza de legado (versoes anteriores)
set "OLD_SHORTCUT=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\TempBridge.lnk"
set "SCRIPT_DIR=%~dp0"
set "OLD_VBS=%SCRIPT_DIR%TempBridge_Hidden.vbs"

if exist "%OLD_SHORTCUT%" (
    echo [INFO] Removendo atalho antigo do Startup...
    del "%OLD_SHORTCUT%"
)
if exist "%OLD_VBS%" (
    echo [INFO] Removendo script VBS antigo...
    del "%OLD_VBS%"
)

if %errorLevel% equ 0 (
    echo [OK] TempBridge removido da inicializacao.
) else (
    echo [AVISO] Tarefa nao encontrada ou erro ao remover.
)

echo.
echo ========================================
echo Desinstalacao concluida!
echo ========================================
echo.
echo TempBridge nao iniciara mais automaticamente.
echo Voce pode executar manualmente se precisar.
echo.
pause
