@echo off
REM Build Native Watcher APK for Windows
REM Output: build\libs\native_watcher.apk

setlocal enabledelayedexpansion

echo.
echo 🔨 Building Native Watcher APK...
echo.

REM Change to script directory
cd /d "%~dp0"

REM Check if gradlew.bat exists
if not exist "gradlew.bat" (
    echo ❌ Error: gradlew.bat not found!
    echo Run: gradle wrapper --gradle-version 8.5
    exit /b 1
)

REM Clean previous build (optional)
echo 🧹 Cleaning previous build...
call gradlew.bat clean
if errorlevel 1 (
    echo ❌ Clean failed
    exit /b 1
)

REM Build the APK
echo.
echo 🔨 Building APK with test-driven configuration support...
call gradlew.bat buildWatcherApk
if errorlevel 1 (
    echo ❌ Build failed
    exit /b 1
)

REM Check if APK was created
if exist "build\libs\native_watcher.apk" (
    echo.
    echo ✅ SUCCESS! Native Watcher APK built successfully!
    echo.
    echo 📦 Location: build\libs\native_watcher.apk
    
    REM Get file size
    for %%A in ("build\libs\native_watcher.apk") do (
        set size=%%~zA
        set /a sizeMB=!size! / 1024 / 1024
        set /a sizeKB=!size! / 1024
        if !sizeMB! GTR 0 (
            echo 📊 Size: !sizeMB!MB
        ) else (
            echo 📊 Size: !sizeKB!KB
        )
    )
    
    echo.
    echo 🎯 Features included:
    echo    ✅ Test-driven configuration (allow/deny/ignore)
    echo    ✅ Permission handling
    echo    ✅ Location precision selection
    echo    ✅ Google Sign-In picker dismissal
    echo    ✅ ANR dialog handling
    echo.
    echo 🚀 Ready to use in your tests!
    echo.
) else (
    echo.
    echo ❌ Error: APK not found at build\libs\native_watcher.apk
    exit /b 1
)

endlocal
