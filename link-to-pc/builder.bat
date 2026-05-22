@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo       LinkScanPC Executable Builder       
echo ==========================================
echo.

:: Check for Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed or not in PATH.
    echo Please install Python and try again.
    pause
    exit /b 1
)

:: Check if PyInstaller is installed
echo Checking for PyInstaller...
python -c "import PyInstaller" >nul 2>&1
if %errorlevel% neq 0 (
    echo PyInstaller not found. Installing via pip...
    pip install pyinstaller
    if !errorlevel! neq 0 (
        echo [ERROR] Failed to install PyInstaller.
        pause
        exit /b 1
    )
) else (
    echo PyInstaller is already installed.
)

:: Check and install requirements
echo Checking requirements...
if exist requirements.txt (
    pip install -r requirements.txt
)

:: Build the executable
echo Building LinkScanPC...
set BUILD_CMD=pyinstaller --noconfirm --onefile --noconsole --name "LinkScanPC" --clean

if exist app_icon.ico (
    set BUILD_CMD=!BUILD_CMD! --icon="app_icon.ico"
    echo Using icon: app_icon.ico
) else (
    echo No icon found (app_icon.ico). Building without icon.
)

set BUILD_CMD=!BUILD_CMD! link_scan_pc.py

echo Running: !BUILD_CMD!
!BUILD_CMD!

if %errorlevel% equ 0 (
    echo.
    echo ==========================================
    echo [SUCCESS] LinkScanPC built successfully!
    echo The executable is located in: dist/LinkScanPC.exe
    echo ==========================================
) else (
    echo.
    echo [ERROR] Build failed. Please check the logs above.
)

pause
