@echo off
chcp 65001 >nul
REM ============================================================
REM  定州市第八中学 - 安全提醒脚本依赖安装
REM  双击运行即可
REM ============================================================
echo.
echo  正在检查 Python 环境 ...
echo.
python --version 2>nul
if errorlevel 1 (
    echo  [错误] 未检测到 Python，请先安装 Python 3.8+：
    echo         https://www.python.org/downloads/
    echo  安装时请勾选 "Add Python to PATH"
    pause
    exit /b 1
)

echo.
echo  正在安装 / 升级 wxauto ...
echo.
pip install --upgrade wxauto

echo.
echo  正在安装 / 升级 pywin32 （wxauto 依赖）...
echo.
pip install --upgrade pywin32

echo.
echo  ✓ 依赖安装完成！
echo  下一步：编辑 send_safety_reminder.py 顶部的群名配置，
echo  然后双击 run_daily.bat 进行一次手动测试。
echo.
pause
