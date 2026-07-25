@echo off
chcp 65001 >nul
REM ============================================================
REM  WeChat version & window detection script
REM  Run this to diagnose "WeChat not found" errors
REM ============================================================

echo.
echo  ============================================================
echo   WeChat environment diagnostics
echo  ============================================================
echo.

REM --- 1. Check WeChat process ---
echo  [Step 1] Checking WeChat process ...
tasklist /FI "IMAGENAME eq WeChat.exe" 2>nul | findstr /I "WeChat.exe" >nul
if errorlevel 1 (
    echo  [ERROR] WeChat.exe is NOT running.
    echo  Please start WeChat PC, scan to login, then run this script again.
    pause
    exit /b 1
)
echo  [OK] WeChat.exe is running.
echo.

REM --- 2. Check WeChat main window via PowerShell ---
echo  [Step 2] Finding WeChat main window (class name WeChatMainWndForPC) ...
powershell -NoProfile -Command "Add-Type -AssemblyName UIAutomationClient; $root = [System.Windows.Automation.AutomationElement]::RootElement; $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ClassNameProperty, 'WeChatMainWndForPC'); $wnd = $root.FindFirst([System.Windows.TreeScope]::Children, $cond); if ($wnd) { Write-Host '[OK] Found WeChat main window (WeChatMainWndForPC).' ; Write-Host ('Name: ' + $wnd.Current.Name) } else { Write-Host '[WARN] WeChatMainWndForPC window NOT found.'; Write-Host 'Your WeChat is likely 3.x or 4.1.9+ (not 4.1.0-4.1.8.107).' }" 2>nul

echo.

REM --- 3. Check WeChat install path & version ---
echo  [Step 3] Locating WeChat install directory ...
for /f "tokens=2*" %%A in ('reg query "HKCU\Software\Tencent\WeChat" /v InstallPath 2^>nul ^| findstr InstallPath') do set "WC_INSTALL=%%B"
if not defined WC_INSTALL (
    for /f "tokens=2*" %%A in ('reg query "HKLM\Software\Tencent\WeChat" /v InstallPath 2^>nul ^| findstr InstallPath') do set "WC_INSTALL=%%B"
)
if defined WC_INSTALL (
    echo  [INFO] WeChat install path: !WC_INSTALL!
    if exist "!WC_INSTALL!\WeChat.exe" (
        for %%F in ("!WC_INSTALL!\WeChat.exe") do echo  [INFO] WeChat.exe file version: %%~nxF
        powershell -NoProfile -Command "(Get-Item '!WC_INSTALL!\WeChat.exe').VersionInfo | Select-Object FileVersion, ProductVersion | Format-List" 2>nul
    ) else (
        echo  [WARN] WeChat.exe not found in install path.
    )
) else (
    echo  [WARN] WeChat install path not found in registry.
)
echo.

REM --- 4. Version compatibility verdict ---
echo  ============================================================
echo   Compatibility verdict
echo  ============================================================
echo.
echo  wxauto4 free version requires:
echo    - WeChat PC 4.1.0 ~ 4.1.8.107
echo    - Python 3.9 ~ 3.12
echo.
echo  If your WeChat version is:
echo    - 3.x.x       -> UNSUPPORTED. Must install 4.1.8.107.
echo    - 4.1.0~4.1.8 -> OK, wxauto4 free version works.
echo    - 4.1.9+      -> Need wxautox4 (Plus, paid, with license).
echo.
echo  Download WeChat 4.1.8.107 (replace current install):
echo  https://github.com/SiverKing/wechat4.0-windows-versions/releases/tag/v4.1.8.107
echo.
echo  Steps to install:
echo    1. Exit WeChat completely (right-click tray icon -> Quit).
echo    2. Control Panel -> Uninstall current WeChat.
echo    3. Run WeChatSetup_4.1.8.107.exe to install.
echo    4. After install, DISABLE auto-update:
echo       Settings -> General -> uncheck "Auto-update WeChat"
echo    5. Login, then run this script again to verify.
echo.
pause
