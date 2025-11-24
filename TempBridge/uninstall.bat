@echo off
echo ========================================
echo TempBridge - Desinstalador
echo ========================================
echo.

set "SCRIPT_DIR=%~dp0"
set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "SHORTCUT=%STARTUP_FOLDER%\TempBridge.lnk"
set "VBS_LAUNCHER=%SCRIPT_DIR%TempBridge_Hidden.vbs"

echo Parando TempBridge...
taskkill /f /im TempBridge.exe 2>nul
if %errorlevel% == 0 (
    echo [OK] TempBridge parado
) else (
    echo [INFO] TempBridge nao estava rodando
)

echo.
echo Removendo do Startup...

if exist "%SHORTCUT%" (
    del "%SHORTCUT%"
    echo [OK] Atalho removido
) else (
    echo [INFO] Atalho nao encontrado
)

if exist "%VBS_LAUNCHER%" (
    del "%VBS_LAUNCHER%"
    echo [OK] Launcher removido
) else (
    echo [INFO] Launcher nao encontrado
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
