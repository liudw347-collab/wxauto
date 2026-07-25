@echo off
chcp 65001 >nul
REM ============================================================
REM  定州市第八中学 - 每日安全提醒启动器
REM  - 双击可手动测试一次
REM  - Windows 任务计划程序调用本文件即可实现每日定时
REM ============================================================

cd /d "%~dp0"

REM  切换到无窗口模式运行 Python（避免弹窗干扰）
pythonw "%~dp0send_safety_reminder.py"

REM  如需在控制台查看实时输出，请改用：
REM  python "%~dp0send_safety_reminder.py"
