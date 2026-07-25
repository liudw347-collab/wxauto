@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
REM ============================================================
REM  定州市第八中学 - 安全提醒脚本依赖安装与 Python 环境诊断
REM  双击运行即可
REM ============================================================

echo.
echo  ============================================================
echo   定州市第八中学 - 环境诊断开始
echo  ============================================================
echo.

REM --- 1. 检测 Python 是否存在 ---
python --version >nul 2>&1
if errorlevel 1 (
    echo  [错误] 未检测到 python 命令。
    echo.
    echo  请先按 setup_python.md 安装官方版 Python 3.11。
    echo  下载地址：https://www.python.org/downloads/release/python-3119/
    echo  安装时务必勾选 "Add Python to PATH"
    echo.
    pause
    exit /b 1
)

REM --- 2. 读取 Python 路径与版本 ---
for /f "delims=" %%P in ('where python') do (
    set PYTHON_FIRST=%%P
    goto :found_python
)
:found_python
echo  [信息] python 命令路径：!PYTHON_FIRST!

for /f "tokens=*" %%V in ('python -c "import sys;print(sys.version)"') do (
    set PYTHON_VERSION=%%V
)
echo  [信息] Python 版本：!PYTHON_VERSION!

REM --- 3. 检测是否微软商店版（路径含 WindowsApps） ---
set IS_STORE=0
echo !PYTHON_FIRST! | findstr /I "WindowsApps" >nul && set IS_STORE=1
python -c "import sys;print('STORE' if 'WindowsApps' in sys.executable else 'OFFICIAL')" >"%TEMP%\py_kind.txt" 2>nul
set /p PY_KIND=<%TEMP%\py_kind.txt
del "%TEMP%\py_kind.txt" 2>nul

if "!PY_KIND!"=="STORE" (
    echo.
    echo  [警告] ^|^|^| 检测到当前 python 是【微软商店版】 ^|^|^|
    echo  ----------------------------------------------------------
    echo  商店版 Python 有以下已知问题，会导致 wxauto 无法正常工作：
    echo    1. 路径重定向：pip 安装的包被装到沙箱目录，其他程序读不到
    echo    2. COM 权限受限：wxauto 依赖的 pywin32 经常初始化失败
    echo    3. 任务计划程序调用商店版 python 会因沙箱机制失败
    echo  ----------------------------------------------------------
    echo.
    echo  推荐方案：保留商店版不动，另外安装官方版 Python 3.11。
    echo  详见仓库内 setup_python.md 文档。
    echo.
    echo  安装完官方版后，请用以下命令验证（注意是 py launcher，不是 python）：
    echo      py -3.11 --version
    echo.
    echo  然后编辑 run_daily.bat 顶部的 PYTHON_EXE 配置，指向官方版，
    echo  例如：set PYTHON_EXE=py -3.11
    echo       或：set PYTHON_EXE=C:\Python311\python.exe
    echo.
    pause
    exit /b 1
)

if !IS_STORE!==1 (
    echo  [警告] 路径含 WindowsApps，疑似商店版，已在上文处理。
)

REM --- 3.1 检查当前默认 Python 版本是否为 3.14（太新，wxauto 兼容性差）---
python -c "import sys;print('TOO_NEW' if sys.version_info[:2] >= (3,14) else 'OK')" >"%TEMP%\py_ver.txt" 2>nul
set /p PY_VER_CHECK=<%TEMP%\py_ver.txt
del "%TEMP%\py_ver.txt" 2>nul

if "!PY_VER_CHECK!"=="TOO_NEW" (
    echo.
    echo  [提示] 当前默认 Python 是 3.14+，wxauto 与 pywin32 对 3.14 的适配尚不稳定。
    echo  建议改用 Python 3.11 安装依赖与运行脚本。
    echo.
    echo  如果您已经安装了官方版 3.11，请用以下命令安装依赖：
    echo      py -3.11 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple wxauto pywin32
    echo.
    echo  并编辑 run_daily.bat 顶部：set "PYTHON_EXE=py -3.11"
    echo.
    choice /C YN /M "是否继续用当前 Python 安装依赖（Y=继续 / N=退出）"
    if errorlevel 2 (
        pause
        exit /b 1
    )
    echo  [信息] 已选择继续，使用当前默认 Python 安装依赖。
)

REM --- 4. 版本号检查（3.8 ~ 3.13 允许；3.12+ 给提示但不阻塞） ---
python -c "import sys;exit(0 if sys.version_info[:2] >= (3,8) else 1)"
if errorlevel 1 (
    echo  [错误] Python 版本过低，请升级到 3.8 以上。
    pause
    exit /b 1
)

echo  [信息] Python 版本符合要求。

REM --- 5. 安装依赖 ---
echo.
echo  正在安装 / 升级 wxauto ...
echo.
pip install --upgrade wxauto
if errorlevel 1 (
    echo  [警告] 默认 PyPI 源安装失败，正在切换到清华镜像源 ...
    pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --upgrade wxauto
)
if errorlevel 1 (
    echo  [错误] wxauto 安装失败，请手动执行：
    echo      py -3.11 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple wxauto
    pause
    exit /b 1
)

echo.
echo  正在安装 / 升级 pywin32（wxauto 依赖）...
echo.
pip install --upgrade pywin32
if errorlevel 1 (
    echo  [警告] 默认 PyPI 源安装失败，正在切换到清华镜像源 ...
    pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --upgrade pywin32
)
if errorlevel 1 (
    echo  [警告] pywin32 安装失败，但部分 wxauto 版本可以不依赖它继续运行。
    echo  建议先尝试运行 run_daily.bat；如果报错再回来处理。
) else (
    REM 运行 pywin32 post-install
    python -c "import pywin32_postinstall;pywin32_postinstall.install()" 2>nul
)

echo.
echo  ============================================================
echo   ✓ 依赖安装完成！
echo  ============================================================
echo.
echo  下一步：
echo    1. 编辑 send_safety_reminder.py 顶部的群名配置
echo    2. 保持 TEST_MODE = True，双击 run_daily.bat 测试一次
echo.
pause
endlocal
