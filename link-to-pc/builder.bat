@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo       LinkScanPC Executable Builder
echo ==========================================
echo.

:: Main Python file
set SCRIPT_NAME=link_scan_pc.py
set EXE_NAME=LinkScanPC

:: Check if source file exists
if not exist "%SCRIPT_NAME%" (
    echo [ERROR] %SCRIPT_NAME% not found.
    pause
    exit /b 1
)

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

:: Install requirements if available
echo Checking requirements...
if exist requirements.txt (
    echo Installing requirements...
    pip install -r requirements.txt
)

:: Delete old build files/folders
echo.
echo Cleaning old build files...

if exist build (
    rmdir /s /q build
)

if exist dist (
    rmdir /s /q dist
)

if exist "%EXE_NAME%.spec" (
    del /f /q "%EXE_NAME%.spec"
)

:: Build command
echo.
echo Building executable...

set BUILD_CMD=pyinstaller --noconfirm --onefile --windowed --clean --name "%EXE_NAME%"

:: Optional icon
if exist app_icon.ico (
    set BUILD_CMD=!BUILD_CMD! --icon=app_icon.ico
    echo Using icon: app_icon.ico
) else (
    echo No app_icon.ico found. Building without icon.
)

:: Add source file
set BUILD_CMD=!BUILD_CMD! "%SCRIPT_NAME%"

echo.
echo Running:
echo !BUILD_CMD!
echo.

!BUILD_CMD!

:: Build result
if %errorlevel% equ 0 (
    echo.
    echo ==========================================
    echo [SUCCESS] Build completed successfully!
    echo Executable:
    echo dist\%EXE_NAME%.exe
    echo ==========================================
) else (
    echo.
    echo ==========================================
    echo [ERROR] Build failed.
    echo Check the output above for details.
    echo ==========================================
)

pause