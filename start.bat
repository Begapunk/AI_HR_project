@echo off
chcp 65001 >nul
title Offer-Catcher 启动器

echo ================================================
echo   Offer-Catcher 本地启动
echo ================================================
echo.

set ROOT=%~dp0
set BACKEND_DIR=%ROOT%backend
set FRONTEND_DIR=%ROOT%frontend

:: ── 查找 Node.js ────────────────────────────────
set NODE_DIR=
set NPM_CMD=

where node >nul 2>&1
if %ERRORLEVEL% == 0 (
    for /f "delims=" %%i in ('where node') do (
        set NODE_EXE=%%i
        for %%p in ("%%~dpi.") do set NODE_DIR=%%~fp
    )
    set NPM_CMD=npm
    goto :node_found
)

:: JetBrains / PyCharm 内置 Node
for /d %%d in ("%APPDATA%\JetBrains\PyCharm*") do (
    for /d %%v in ("%%d\node\versions\*") do (
        if exist "%%v\node.exe" (
            set NODE_DIR=%%v
            set NPM_CMD=%%v\npm.cmd
            set PATH=%%v;%PATH%
            goto :node_found
        )
    )
)

if exist "C:\Program Files\nodejs\node.exe" (
    set NODE_DIR=C:\Program Files\nodejs
    set NPM_CMD=C:\Program Files\nodejs\npm.cmd
    set PATH=C:\Program Files\nodejs;%PATH%
    goto :node_found
)

echo [错误] 未找到 Node.js，请先安装：https://nodejs.org
echo        或在命令行运行：winget install OpenJS.NodeJS.LTS
pause
exit /b 1

:node_found
echo [OK] Node.js 已找到: %NODE_DIR%

:: ── 检查 Python ──────────────────────────────────
where python >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 未找到 Python，请先安装 Python 3.10+
    pause
    exit /b 1
)
echo [OK] Python 已找到

:: ── 启动后端 ─────────────────────────────────────
echo.
echo [1/2] 启动后端 (http://localhost:8000)...
start "Offer-Catcher [后端]" cmd /k "cd /d "%BACKEND_DIR%" && python -m uvicorn main:app --reload --port 8000"

echo      等待后端启动...
:wait_backend
timeout /t 2 /nobreak >nul
curl -s http://localhost:8000/health >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :wait_backend
echo [OK] 后端已就绪

:: ── 启动前端 ─────────────────────────────────────
echo.
echo [2/2] 启动前端 (http://localhost:5173)...
start "Offer-Catcher [前端]" cmd /k "set PATH=%NODE_DIR%;%PATH% && cd /d "%FRONTEND_DIR%" && "%NPM_CMD%" run dev"

echo      等待前端启动...
:wait_frontend
timeout /t 2 /nobreak >nul
curl -s -o nul http://localhost:5173/ >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :wait_frontend
echo [OK] 前端已就绪

:: ── 完成 ─────────────────────────────────────────
echo.
echo ================================================
echo   启动成功！正在打开浏览器...
echo   前端: http://localhost:5173
echo   后端: http://localhost:8000
echo   关闭两个黑色命令行窗口即可停止服务
echo ================================================
echo.
start "" http://localhost:5173
