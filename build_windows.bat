@echo off
echo Building Flutter Windows App...
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Flutter not found! Please install Flutter first.
    echo Visit: https://flutter.dev/docs/get-started/install/windows
    pause
    exit /b 1
)

REM Enable Windows desktop support
echo Enabling Windows desktop support...
flutter config --enable-windows-desktop

REM Get dependencies
echo Getting dependencies...
flutter pub get

REM Build release version
echo Building Windows release...
flutter build windows --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Build successful!
    echo Executable location: build\windows\runner\Release\
    echo.
    echo To create portable package:
    echo   1. Copy all files from build\windows\runner\Release\
    echo   2. Include required DLL files
    echo   3. Test on clean Windows system
    echo.
    pause
) else (
    echo Build failed!
    pause
    exit /b 1
)
