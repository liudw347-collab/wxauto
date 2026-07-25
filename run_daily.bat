@echo off
chcp 65001 >nul
REM ============================================================
REM  Dingzhou No.8 Middle School - Daily Safety Reminder Launcher
REM  --------------------------------------------------------
REM  Usage:
REM    - Double-click to test once manually
REM    - Called by Windows Task Scheduler for daily auto-run
REM  --------------------------------------------------------
REM  Python path config:
REM    If you have multiple Python versions (e.g. Store 3.14 + Official 3.11),
REM    change PYTHON_EXE below to the official Python absolute path.
REM    Recommended: use py launcher to pick a specific version:
REM      set "PYTHON_EXE=py -3.11"
REM    Or use absolute path:
REM      set "PYTHON_EXE=C:\Python311\python.exe"
REM      set "PYTHON_EXE=%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
REM ============================================================

REM === Python interpreter config (modify this line as needed) ===
set "PYTHON_EXE=py -3.11"

REM === Verify PYTHON_EXE works; fall back to 'python' if not ===
%PYTHON_EXE% --version >nul 2>&1
if errorlevel 1 (
    echo  [WARN] Configured PYTHON_EXE is unavailable, falling back to python ...
    set "PYTHON_EXE=python"
)

cd /d "%~dp0"

echo  [%date% %time%] Launching Dingzhou No.8 MS Safety Reminder task ...
echo  Using interpreter: %PYTHON_EXE%
echo.

REM Run with console window (most reliable).
REM - For manual test: console stays open so you can see logs.
REM - For Task Scheduler: configure task to "run whether user is logged on or not"
REM   and the console window will be hidden automatically.
%PYTHON_EXE% "%~dp0send_safety_reminder.py"

REM
REM Optional: run silently (no console window).
REM Uncomment ONE of the following blocks if you want silent mode:
REM
REM --- Option A: use pythonw.exe directly (recommended for absolute path) ---
REM set "PYTHONW_EXE=C:\Python311\pythonw.exe"
REM start "" /B "%PYTHONW_EXE%" "%~dp0send_safety_reminder.py"
REM
REM --- Option B: use py launcher in silent mode (via vbs helper) ---
REM   py launcher does not support pythonw directly. Use the following
REM   vbs wrapper if you really need silent mode with py -3.11:
REM   cscript //nologo "%~dp0silent.vbs" "%~dp0run_silent.bat"
