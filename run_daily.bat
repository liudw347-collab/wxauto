@echo off
chcp 65001 >nul
REM ============================================================
REM  定州市第八中学 - 每日安全提醒启动器
REM  --------------------------------------------------------
REM  作用：
REM    - 双击可手动测试一次
REM    - Windows 任务计划程序调用本文件即可实现每日定时
REM  --------------------------------------------------------
REM  Python 路径配置：
REM    如果您的电脑装了多个 Python（例如微软商店版 + 官方版），
REM    请把 PYTHON_EXE 改成官方版 Python 的绝对路径。
REM    推荐使用 py launcher 调用指定版本：
REM      set PYTHON_EXE=py -3.11
REM    或绝对路径：
REM      set PYTHON_EXE=C:\Python311\python.exe
REM      set PYTHON_EXE=%LOCALAPPDATA%\Programs\Python\Python311\python.exe
REM ============================================================

REM === Python 解释器配置（按需修改这一行即可） ===
set "PYTHON_EXE=py -3.11"

REM === 如果上面指定的命令不存在，自动回退到 python ===
%PYTHON_EXE% --version >nul 2>&1
if errorlevel 1 (
    echo  [警告] 配置的 PYTHON_EXE 不可用，回退到 python ...
    set "PYTHON_EXE=python"
)

cd /d "%~dp0"

echo  [%date% %time%] 启动定州八中安全提醒任务 ...
echo  使用解释器：%PYTHON_EXE%
echo.

REM  使用 pythonw 无窗口运行（推荐），如需查看实时输出请改用 python
%PYTHON_EXE%w "%~dp0send_safety_reminder.py"

REM  === 兼容 py launcher 的 pythonw ===
REM  如果 PYTHON_EXE 是 "py -3.11"，上面的命令实际是 "py -3.11w"（不存在）
REM  这种情况自动改用 python（带窗口），方便查看日志
if errorlevel 1 (
    if "%PYTHON_EXE:~0,2%"=="py" (
        echo  [回退] py launcher 无 pythonw，改用 py -3.11 带窗口运行
        %PYTHON_EXE% "%~dp0send_safety_reminder.py"
    )
)

REM  如需彻底使用带控制台的 python，请把上面两段注释掉，改用：
REM  %PYTHON_EXE% "%~dp0send_safety_reminder.py"
