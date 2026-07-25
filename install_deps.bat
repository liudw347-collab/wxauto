@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
REM ============================================================
REM  Dingzhou No.8 Middle School - Dependency installer + Python env diagnostics
REM  Double-click to run.
REM ============================================================

echo.
echo  ============================================================
echo   Dingzhou No.8 MS - Environment diagnostics starting
echo  ============================================================
echo.

REM --- 1. Check if python exists ---
python --version >nul 2>&1
if errorlevel 1 (
    echo  [ERROR] python command not found.
    echo.
    echo  Please install official Python 3.11 first (see setup_python.md).
    echo  Download: https://www.python.org/downloads/release/python-3119/
    echo  Remember to check "Add Python to PATH" during installation.
    echo.
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

REM --- 3. Detect Microsoft Store edition (path contains WindowsApps) ---
set IS_STORE=0
echo !PYTHON_FIRST! | findstr /I "WindowsApps" >nul && set IS_STORE=1
python -c "import sys;print('STORE' if 'WindowsApps' in sys.executable else 'OFFICIAL')" >"%TEMP%\py_kind.txt" 2>nul
set /p PY_KIND=<%TEMP%\py_kind.txt
del "%TEMP%\py_kind.txt" 2>nul

if "!PY_KIND!"=="STORE" (
    echo.
    echo  [WARN] ^|^|^| Detected Microsoft Store Python ^|^|^|
    echo  ----------------------------------------------------------
    echo  Store Python has known issues that break wxauto4:
    echo    1. Path redirection: pip-installed packages go to sandbox dir
    echo    2. COM permission restricted: pywin32 init fails
    echo    3. Task Scheduler cannot call Store python reliably
    echo  ----------------------------------------------------------
    echo.
    echo  Solution: keep Store python, install official Python 3.11 alongside.
    echo  See setup_python.md for details.
    echo.
    echo  After installing official 3.11, verify:
    echo      py -3.11 --version
    echo.
    echo  Then edit run_daily.bat top config:
    echo      set "PYTHON_EXE=py -3.11"
    echo      or: set "PYTHON_EXE=C:\Python311\python.exe"
    echo.
    pause
    exit /b 1
)

if !IS_STORE!==1 (
    echo  [WARN] Path contains WindowsApps, treated as Store edition above.
)

REM --- 3.1 Check if default python is too new (3.13+) ---
python -c "import sys;print('TOO_NEW' if sys.version_info[:2] >= (3,13) else 'OK')" >"%TEMP%\py_ver.txt" 2>nul
set /p PY_VER_CHECK=<%TEMP%\py_ver.txt
del "%TEMP%\py_ver.txt" 2>nul

if "!PY_VER_CHECK!"=="TOO_NEW" (
    echo.
    echo  [INFO] Current default Python is 3.13+.
    echo  wxauto4 free version requires Python 3.9-3.12 only.
    echo  Use py -3.11 to install and run:
    echo      py -3.11 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple wxauto4
    echo.
    echo  Edit run_daily.bat top: set "PYTHON_EXE=py -3.11"
    echo.
    choice /C YN /M "Continue with current python anyway (Y=continue / N=exit)"
    if errorlevel 2 (
        pause
        exit /b 1
    )
    echo  [INFO] Continuing with current default python.
)

REM --- 4. Version check (wxauto4 requires 3.9-3.12) ---
python -c "import sys;ver=sys.version_info[:2];exit(0 if (3,9)<=ver<=(3,12) else 1)"
if errorlevel 1 (
    echo  [ERROR] wxauto4 requires Python 3.9-3.12. Current default python does not match.
    echo  Use py -3.11 to install and run:
    echo      py -3.11 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple wxauto4
    echo  Edit run_daily.bat top: set "PYTHON_EXE=py -3.11"
    pause
    exit /b 1
)

echo  [INFO] Python version meets wxauto4 requirement (3.9-3.12).

REM --- 5. Install dependencies (package name is wxauto4, NOT wxauto) ---
REM     wxauto4 auto-installs pywin32, pillow, psutil, tenacity, etc.
echo.
echo  Installing / upgrading wxauto4 ...
echo.
pip install --upgrade wxauto4
if errorlevel 1 (
    echo  [WARN] Default PyPI failed, switching to Tsinghua mirror ...
    pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --upgrade wxauto4
)
if errorlevel 1 (
    echo  [ERROR] wxauto4 install failed. Run manually:
    echo      py -3.11 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple wxauto4
    echo  NOTE: package name is wxauto4 (with 4), not wxauto!
    pause
    exit /b 1
)

echo.
echo  ============================================================
echo   wxauto4 dependencies installed successfully!
echo  ============================================================
echo.
echo  Next steps:
echo    1. Edit group names in send_safety_reminder.py top config
echo    2. Keep TEST_MODE = True, double-click run_daily.bat to test
echo.
pause
endlocal
