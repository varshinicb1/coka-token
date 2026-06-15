@echo off
title COKA Billing - Auto Setup
cd /d "%~dp0"

echo ============================================
echo    COKA Billing - Auto Setup Launcher
echo ============================================
echo.

REM Check if we're in the build directory or source directory
if exist "coka_billing.exe" goto :LAUNCH
if exist "build\windows\x64\runner\Release\coka_billing.exe" goto :IN_BUILD

echo [INFO] This script should be placed alongside coka_billing.exe
echo       or in the project root with build\windows\x64\runner\Release\
echo.
echo [ACTION] Please copy setup_and_run.bat to the folder with coka_billing.exe
pause
exit /b 1

:IN_BUILD
cd build\windows\x64\runner\Release

:LAUNCH
echo [1/3] Checking Bluetooth status...
powershell -NoProfile -Command ^
"try { $bt = Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'OK' -and $_.FriendlyName -match 'Veer|Seznik|Seiznik' } | Select-Object -First 1; if ($bt) { exit 0 } else { exit 1 } } catch { exit 2 }" 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Seiznik Veer printer detected!
    goto :START_APP
)

echo [!] Seiznik Veer printer not found. Let's set it up.
echo.
echo [2/3] Opening Bluetooth settings...
echo [ACTION] Please:
echo   1. Put your Seiznik Veer printer in PAIRING MODE
echo      (press the button with Bluetooth icon on the printer)
echo   2. In the Bluetooth settings window that opens, click "Add device"
echo   3. Select "Bluetooth" and choose "Seznik_Veer_03B4"
echo   4. Wait for pairing to complete
echo.
echo    After pairing, close Bluetooth settings and press any key here...
pause >nul

echo [3/3] Verifying printer pairing...
powershell -NoProfile -Command ^
"$bt = Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'OK' -and $_.FriendlyName -match 'Veer|Seznik|Seiznik' } | Select-Object -First 1; if ($bt) { Write-Output 'OK - Printer paired successfully!'; exit 0 } else { Write-Output 'Printer not found. Try pairing again.'; exit 1 }"

if %ERRORLEVEL% NEQ 0 (
    echo [!] Printer not detected yet.
    echo     You can manually pair later via Windows Settings ^> Bluetooth ^& devices
    echo     Then restart this script.
    echo.
    pause
    exit /b 1
)

:START_APP
echo.
echo [LAUNCH] Starting COKA Billing...
start "" "coka_billing.exe"
echo [DONE] App launched! Auto-connecting to printer...
echo.
echo NOTE: If printer does not print, check:
echo   - Printer is turned ON
echo   - Bluetooth is enabled on this laptop
echo   - Run this script again
echo.
timeout /t 3 /nobreak >nul
