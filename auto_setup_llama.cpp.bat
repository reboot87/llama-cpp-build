@echo off
REM 一键自动化（BAT 封装）：调用 PowerShell 脚本
cd /d %~dp0
echo [INFO] 启动自动化脚本...
powershell -ExecutionPolicy Bypass -File "%~dp0auto_setup_llama.cpp.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] 自动化流程失败，查看 auto_setup_debug.log
    pause
    exit /b 1
)
echo [OK] 自动化流程完成
pause
endlocal
