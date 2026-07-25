@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
REM ============================================================
REM  Dingzhou No.8 Middle School - Dependency installer
REM  Supports two backends (auto install pywechat127 by default):
REM    1. pywechat127 (recommended) - WeChat 4.1.6+ incl. 4.1.9+
REM    2. wxauto4 (fallback) - WeChat 4.1.0 - 4.1.8.107 only
REM ============================================================

echo.
echo  ============================================================
echo   Dingzhou No.8 MS - Environment diagnostics starting
echo  ============================================================
echo.

REM --- 1. Check default python exists ---
python --version >nul 2>&1
if errorlevel 1 (
    echo  [ERROR] python command not found.
    echo  Please install official Python 3.11 first (see setup_python.md).
    pause
    exit /b 1
)

REM --- 2. Read python path and version ---
for /f "delims=" %%P in ('where python') do (
    set PYTHON_FIRST=%%P
    goto :found_python
)
:found_python
echo  [INFO] python command path: !PYTHON_FIRST!

for /f "tokens=*" %%V in ('python -c "import sys;print(sys.version)"') do (
    set PYTHON_VERSION=%%V
)
echo  [INFO] Python version: !PYTHON_VERSION!

REM --- 3. Detect Microsoft Store edition ---
python -c "import sys;print('STORE' if 'WindowsApps' in sys.executable else 'OFFICIAL')" >"%TEMP%\py_kind.txt" 2>nul
set /p PY_KIND=<%TEMP%\py_kind.txt
del "%TEMP%\py_kind.txt" 2>nul

if "!PY_KIND!"=="STORE" (
    echo  [WARN] Detected Microsoft Store Python. Use py -3.11 instead.
    echo  See setup_python.md for details.
    echo.
    pause
    exit /b 1
)

REM --- 3.1 Check if default python is too new (3.13+) ---
python -c "import sys;print('TOO_NEW' if sys.version_info[:2] >= (3,13) else 'OK')" >"%TEMP%\py_ver.txt" 2>nul
set /p PY_VER_CHECK=<%TEMP%\py_ver.txt
del "%TEMP%\py_ver.txt" 2>nul

if "!PY_VER_CHECK!"=="TOO_NEW" (
    echo  [INFO] Default Python is 3.13+. Both backends require 3.9-3.12.
    echo  Use py -3.11 to install and run:
    echo      py -3.11 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple pywechat127
    echo.
    echo  Edit run_daily.bat top: set "PYTHON_EXE=py -3.11"
    echo.
    choice /C YN /M "Continue with current python anyway (Y=continue / N=exit)"
    if errorlevel 2 (
        pause
        exit /b 1
    )
)

REM --- 4. Version check (both backends require 3.9-3.12) ---
python -c "import sys;ver=sys.version_info[:2];exit(0 if (3,9)<=ver<=(3,12) else 1)"
if errorlevel 1 (
    echo  [ERROR] Both backends require Python 3.9-3.12.
    echo  Use py -3.11 to install and run.
    pause
    exit /b 1
)
echo  [INFO] Python version meets requirement (3.9-3.12).

REM --- 5. Install backend (pywechat127 recommended) ---
echo.
echo  ============================================================
echo   Installing backend: pywechat127 (recommended)
echo   - Supports WeChat 4.1.6+ including latest 4.1.9+
echo   - Pure UI automation (pywinauto), low ban risk
echo  ============================================================
echo.

pip install --upgrade pywechat127
if errorlevel 1 (
    echo  [WARN] Default PyPI failed, switching to Tsinghua mirror ...
    pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --upgrade pywechat127
)
if errorlevel 1 (
    echo  [ERROR] pywechat127 install failed. Run manually:
    echo      py -3.11 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple pywechat127
    echo.
    echo  Or try the alternative backend wxauto4 (only for WeChat 4.1.0-4.1.8.107):
    echo      py -3.11 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple wxauto4
    pause
    exit /b 1
)

echo.
echo  ============================================================
echo   pywechat127 installed successfully!
echo  ============================================================
echo.
echo  Next steps:
echo    1. Make sure WeChat 4.1.6+ is running and logged in.
echo    2. Edit group names in send_safety_reminder.py top config.
echo    3. Keep TEST_MODE = True, double-click run_daily.bat to test.
echo    4. The script auto-detects installed backend (pywechat127 by default).
echo.
pause
endlocal
