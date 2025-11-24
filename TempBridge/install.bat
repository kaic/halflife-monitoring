@echo off
echo ========================================
echo TempBridge - Instalador de Startup
echo ========================================
echo.

set "SCRIPT_DIR=%~dp0"
set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "VBS_LAUNCHER=%SCRIPT_DIR%TempBridge_Hidden.vbs"
set "SHORTCUT=%STARTUP_FOLDER%\TempBridge.lnk"

echo Criando launcher oculto (sem janela de console)...
echo.

:: Cria VBScript para iniciar TempBridge sem mostrar janela
> "%VBS_LAUNCHER%" echo Set WshShell = CreateObject("WScript.Shell")
>> "%VBS_LAUNCHER%" echo WshShell.Run """%SCRIPT_DIR%TempBridge.exe""", 0, False

if exist "%VBS_LAUNCHER%" (
    echo [OK] Launcher oculto criado: TempBridge_Hidden.vbs
) else (
    echo [ERRO] Falha ao criar launcher
    pause
    exit /b 1
)

echo.
echo Criando atalho no Startup do Windows...
echo.

:: Cria o atalho usando PowerShell
powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%SHORTCUT%'); $Shortcut.TargetPath = '%VBS_LAUNCHER%'; $Shortcut.WorkingDirectory = '%SCRIPT_DIR%'; $Shortcut.Save()"

if exist "%SHORTCUT%" (
    echo [OK] Atalho criado com sucesso!
    echo Local: %SHORTCUT%
    echo.
    echo TempBridge sera iniciado automaticamente (OCULTO) no proximo boot.
    echo.
    echo Deseja iniciar agora? (S/N^)
    choice /C SN /M "Iniciar TempBridge"
    
    if errorlevel 2 goto :end
    if errorlevel 1 goto :start
) else (
    echo [ERRO] Falha ao criar atalho.
    pause
    exit /b 1
)

:start
echo.
echo Iniciando TempBridge (oculto)...
start "" "%VBS_LAUNCHER%"
timeout /t 2 >nul
echo.
echo TempBridge esta rodando em segundo plano (SEM janela visivel).
echo Para verificar, abra o Task Manager e procure por "TempBridge.exe".
goto :end

:end
echo.
echo ========================================
echo Instalacao concluida!
echo ========================================
echo.
echo IMPORTANTE:
echo - TempBridge roda OCULTO (sem janela de console)
echo - Para parar: Task Manager ^> TempBridge.exe ^> End Task
echo - Para ver logs: Execute TempBridge.exe manualmente
echo.
pause
