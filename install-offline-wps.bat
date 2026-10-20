@echo off
REM =====================================================================
REM install-offline-wps.bat - WPS Office 离线纯净版一键安装
REM 用法: 将此文件和 WPS_Setup_x64_*.exe 放在同一目录, 右键管理员运行
REM 结果: 安装 WPS → 自动精简 → 离线可用(无云服务/广告/AI/稻壳/会员)
REM =====================================================================
setlocal EnableDelayedExpansion

echo.
echo ============================================
echo   WPS Office 离线纯净版 一键安装
echo ============================================
echo.

REM ---- 检查管理员权限 ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 请右键此文件, 选择"以管理员身份运行"
    pause
    exit /b 1
)

REM ---- 查找安装包 ----
set INSTALLER=
for %%f in (WPS_Setup_x64_*.exe) do set INSTALLER=%%f
if "%INSTALLER%"=="" (
    echo [错误] 未找到 WPS_Setup_x64_*.exe 安装包
    echo        请将安装包放在本脚本同目录下
    pause
    exit /b 1
)
echo [1/4] 找到安装包: %INSTALLER%

REM ---- 检查精简脚本 ----
set SCRIPT_DIR=%~dp0
if not exist "%SCRIPT_DIR%make-wps-offline.ps1" (
    echo [错误] 未找到 make-wps-offline.ps1
    echo        请确保完整项目目录在一起
    pause
    exit /b 1
)

REM ---- 第1步: 静默安装 WPS ----
echo.
echo [2/4] 静默安装 WPS Office (可能需要几分钟)...
"%INSTALLER%" /S /NCRC
if %errorlevel% neq 0 (
    echo [警告] 安装程序返回码 %errorlevel%, 继续尝试精简...
)

REM 等待安装完成(检查 wps.exe 是否存在)
set WPS_DIR=
for /d %%d in ("%LOCALAPPDATA%\Kingsoft\WPS Office\*") do set WPS_DIR=%%d
if "%WPS_DIR%"=="" (
    echo [错误] 安装失败, 未找到 WPS 安装目录
    pause
    exit /b 1
)
echo        安装目录: %WPS_DIR%

REM 等待文件释放
timeout /t 5 /nobreak >nul

REM ---- 第2步: 运行精简脚本 ----
echo.
echo [3/4] 执行离线精简 (服务/组件/防火墙/界面纯净)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%make-wps-offline.ps1"
if %errorlevel% neq 0 (
    echo [警告] 精简脚本返回码 %errorlevel%
)

REM ---- 第3步: 验证 ----
echo.
echo [4/4] 验证安装...
if exist "%WPS_DIR%\office6\wps.exe" (
    echo   [OK] wps.exe 存在
) else (
    echo   [警告] wps.exe 不存在
)

reg query "HKCU\Software\Kingsoft\Office\6.0\Common" /v compatible_type 2>nul | find "0x1" >nul
if %errorlevel%==0 (
    echo   [OK] 离线兼容模式已启用
) else (
    echo   [警告] compatible_type 未设置
)

sc query wpscloudsvr 2>nul | find "RUNNING" >nul
if %errorlevel%==0 (
    echo   [警告] wpscloudsvr 服务仍在运行
) else (
    echo   [OK] 云服务已移除
)

echo.
echo ============================================
echo   安装完成!
echo   首次启动 WPS 即为离线纯净版
echo   如需还原: restore-wps.ps1
echo ============================================
pause
