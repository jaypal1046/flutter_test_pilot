# 🔨 Cross-Platform Build Guide for Native Watcher APK

## �� Quick Build

### 🍎 macOS / Linux

```bash
cd /path/to/flutter_test_pilot/native_assets/android

# Option 1: Use build script (easiest)
./build_watcher.sh

# Option 2: Use Gradle directly
./gradlew buildWatcherApk
```

### 🪟 Windows

```cmd
cd C:\path\to\flutter_test_pilot\native_assets\android

REM Option 1: Use build script (easiest)
build_watcher.bat

REM Option 2: Use Gradle directly
gradlew.bat buildWatcherApk
```

---

## 📦 Output Location

**All platforms:** APK will be created at:

```
build/libs/native_watcher.apk        (macOS/Linux)
build\libs\native_watcher.apk        (Windows)
```

---

## 🚀 Step-by-Step Instructions

### 🍎 For macOS/Linux Users

#### First-Time Setup

```bash
# 1. Navigate to android directory
cd /Users/JayprakashPal/Desktop/iltc-dev/iltc-flutter_new/iltc-services/flutter_test_pilot/native_assets/android

# 2. Make scripts executable
chmod +x gradlew
chmod +x build_watcher.sh

# 3. Build
./build_watcher.sh
```

#### Regular Build

```bash
# Just run the script
./build_watcher.sh
```

**Expected Output:**
```
🔨 Building Native Watcher APK...

🧹 Cleaning previous build...
BUILD SUCCESSFUL in 2s

🔨 Building APK with test-driven configuration support...
BUILD SUCCESSFUL in 15s

✅ SUCCESS! Native Watcher APK built successfully!

📦 Location: build/libs/native_watcher.apk
📊 Size: 450KB

🎯 Features included:
   ✅ Test-driven configuration (allow/deny/ignore)
   ✅ Permission handling
   ✅ Location precision selection
   ✅ Google Sign-In picker dismissal
   ✅ ANR dialog handling

🚀 Ready to use in your tests!
```

---

### 🪟 For Windows Users

#### First-Time Setup

```cmd
REM 1. Open Command Prompt or PowerShell
REM 2. Navigate to android directory
cd C:\Users\YourName\Desktop\iltc-dev\iltc-flutter_new\iltc-services\flutter_test_pilot\native_assets\android

REM 3. Build (no chmod needed on Windows)
build_watcher.bat
```

#### Regular Build

```cmd
REM Just run the batch file
build_watcher.bat
```

**Expected Output:**
```
🔨 Building Native Watcher APK...

🧹 Cleaning previous build...
BUILD SUCCESSFUL in 2s

🔨 Building APK with test-driven configuration support...
BUILD SUCCESSFUL in 15s

✅ SUCCESS! Native Watcher APK built successfully!

📦 Location: build\libs\native_watcher.apk
📊 Size: 450KB

🎯 Features included:
   ✅ Test-driven configuration (allow/deny/ignore)
   ✅ Permission handling
   ✅ Location precision selection
   ✅ Google Sign-In picker dismissal
   ✅ ANR dialog handling

🚀 Ready to use in your tests!
```

---

## 🔧 Prerequisites by Platform

### 🍎 macOS

```bash
# 1. Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install Java
brew install openjdk@11

# 3. Install Android SDK
brew install --cask android-studio
# OR
brew install --cask android-platform-tools

# 4. Set ANDROID_HOME
echo 'export ANDROID_HOME=$HOME/Library/Android/sdk' >> ~/.zshrc
echo 'export PATH=$PATH:$ANDROID_HOME/platform-tools' >> ~/.zshrc
source ~/.zshrc

# 5. Verify
java -version
echo $ANDROID_HOME
adb version
```

### 🐧 Linux

```bash
# 1. Install Java
sudo apt update
sudo apt install openjdk-11-jdk

# 2. Install Android SDK
# Download from: https://developer.android.com/studio
# Or use command line tools

# 3. Set ANDROID_HOME
echo 'export ANDROID_HOME=$HOME/Android/Sdk' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/platform-tools' >> ~/.bashrc
source ~/.bashrc

# 4. Verify
java -version
echo $ANDROID_HOME
adb version
```

### 🪟 Windows

**Option 1: Using Chocolatey (Recommended)**

```powershell
# 1. Install Chocolatey (if not installed)
# Run PowerShell as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2. Install Java
choco install openjdk11 -y

# 3. Install Android Studio (includes SDK)
choco install androidstudio -y

# 4. Set ANDROID_HOME
# Open System Properties > Environment Variables
# Add new System Variable:
#   Variable name: ANDROID_HOME
#   Variable value: C:\Users\YourName\AppData\Local\Android\Sdk

# 5. Add to PATH
# Add to System PATH:
#   %ANDROID_HOME%\platform-tools
#   %ANDROID_HOME%\tools

# 6. Verify (restart terminal)
java -version
echo %ANDROID_HOME%
adb version
```

**Option 2: Manual Installation**

1. **Download Java 11+**
   - https://adoptium.net/
   - Install and note installation path

2. **Download Android Studio**
   - https://developer.android.com/studio
   - Install and run initial setup

3. **Set Environment Variables**
   - Press `Win + X` → System → Advanced system settings
   - Environment Variables
   - Add `ANDROID_HOME`: `C:\Users\YourName\AppData\Local\Android\Sdk`
   - Add to PATH: `%ANDROID_HOME%\platform-tools`

4. **Verify**
   ```cmd
   java -version
   echo %ANDROID_HOME%
   adb version
   ```

---

## �� Platform-Specific Commands

### Navigating to Directory

| Platform | Command |
|----------|---------|
| macOS/Linux | `cd /path/to/flutter_test_pilot/native_assets/android` |
| Windows CMD | `cd C:\path\to\flutter_test_pilot\native_assets\android` |
| Windows PowerShell | `cd C:\path\to\flutter_test_pilot\native_assets\android` |

### Making Scripts Executable

| Platform | Command |
|----------|---------|
| macOS/Linux | `chmod +x build_watcher.sh gradlew` |
| Windows | Not needed (`.bat` files are executable) |

### Running Build Script

| Platform | Command |
|----------|---------|
| macOS/Linux | `./build_watcher.sh` |
| Windows CMD | `build_watcher.bat` |
| Windows PowerShell | `.\build_watcher.bat` |

### Running Gradle Directly

| Platform | Command |
|----------|---------|
| macOS/Linux | `./gradlew buildWatcherApk` |
| Windows CMD | `gradlew.bat buildWatcherApk` |
| Windows PowerShell | `.\gradlew.bat buildWatcherApk` |

---

## 📁 File Structure (All Platforms)

```
native_assets/android/
├── build_watcher.sh          # macOS/Linux build script
├── build_watcher.bat         # Windows build script
├── BUILD_GUIDE.md            # This file (cross-platform)
├── BUILD_INSTRUCTIONS.md     # Detailed instructions
├── build.gradle              # Gradle build configuration
├── gradlew                   # Gradle wrapper (Unix)
├── gradlew.bat               # Gradle wrapper (Windows)
├── settings.gradle           # Gradle settings
└── src/
    └── androidTest/java/com/testpilot/watcher/
        └── NativeWatcher.java    # Watcher implementation
```

---

## 🐛 Troubleshooting by Platform

### 🍎 macOS Common Issues

**Issue: "Permission denied: ./gradlew"**

```bash
chmod +x gradlew build_watcher.sh
```

**Issue: "ANDROID_HOME not set"**

```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
echo 'export ANDROID_HOME=$HOME/Library/Android/sdk' >> ~/.zshrc
```

**Issue: "Java version error"**

```bash
brew install openjdk@11
sudo ln -sfn $(brew --prefix)/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk
```

---

### 🐧 Linux Common Issues

**Issue: "ANDROID_HOME not set"**

```bash
export ANDROID_HOME=$HOME/Android/Sdk
echo 'export ANDROID_HOME=$HOME/Android/Sdk' >> ~/.bashrc
source ~/.bashrc
```

**Issue: "Java not found"**

```bash
sudo apt update
sudo apt install openjdk-11-jdk
java -version
```

**Issue: "Permission denied"**

```bash
chmod +x gradlew build_watcher.sh
```

---

### 🪟 Windows Common Issues

**Issue: "ANDROID_HOME is not recognized"**

Solution:
1. Open System Properties (Win + Pause/Break)
2. Advanced system settings → Environment Variables
3. System Variables → New
4. Variable name: `ANDROID_HOME`
5. Variable value: `C:\Users\YourName\AppData\Local\Android\Sdk`
6. Click OK and restart terminal

**Issue: "Java is not recognized"**

Solution:
```cmd
REM Check Java installation
where java

REM If not found, add to PATH:
REM 1. Find Java installation: C:\Program Files\Java\jdk-11
REM 2. Add to System PATH: C:\Program Files\Java\jdk-11\bin
REM 3. Restart terminal
```

**Issue: "gradlew.bat is not recognized"**

Solution:
```cmd
REM Make sure you're in the correct directory
cd C:\path\to\flutter_test_pilot\native_assets\android

REM Check if file exists
dir gradlew.bat

REM Run with explicit path
.\gradlew.bat buildWatcherApk
```

**Issue: "Build failed with SDK error"**

Solution:
```cmd
REM Create local.properties file
echo sdk.dir=C:\Users\YourName\AppData\Local\Android\Sdk > local.properties

REM Retry build
gradlew.bat buildWatcherApk
```

---

## 🔄 Build Process (All Platforms)

The build process is identical across platforms:

```
1. Clean previous build
     ↓
2. Compile Java sources (NativeWatcher.java)
     ↓
3. Build instrumentation APK
     ↓
4. Copy to build/libs/native_watcher.apk
     ↓
5. ✅ Ready to use!
```

---

## ✅ Verify Build (All Platforms)

### 🍎 macOS/Linux

```bash
# Check file exists
ls -lh build/libs/native_watcher.apk

# Check file size
du -h build/libs/native_watcher.apk

# Verify it's an APK
file build/libs/native_watcher.apk
```

### 🪟 Windows

```cmd
REM Check file exists
dir build\libs\native_watcher.apk

REM Check file size
for %A in (build\libs\native_watcher.apk) do @echo %~zA bytes
```

---

## 🎮 Using the APK in Tests (All Platforms)

The Dart code is platform-agnostic:

```dart
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

testWidgets('Test with native support', (tester) async {
  final handler = NativeHandler();
  final deviceId = 'emulator-5554';
  
  // Configure watcher
  await handler.configureWatcher(
    deviceId: deviceId,
    permissionAction: DialogAction.allow,
  );
  
  // Start watcher (APK is auto-detected)
  final watcherProcess = await DialogWatcher(AdbCommander()).start(deviceId);
  
  // Run your test
  runApp(MyApp());
  
  // Clean up
  await DialogWatcher(AdbCommander()).stop(watcherProcess);
  await handler.clearWatcherConfig(deviceId);
});
```

**Works on all platforms!** ��

---

## 📊 Platform Comparison

| Feature | macOS | Linux | Windows |
|---------|-------|-------|---------|
| Build Script | `build_watcher.sh` | `build_watcher.sh` | `build_watcher.bat` |
| Gradle Wrapper | `./gradlew` | `./gradlew` | `gradlew.bat` |
| Make Executable | `chmod +x` | `chmod +x` | Not needed |
| Path Separator | `/` | `/` | `\` |
| Output Location | `build/libs/` | `build/libs/` | `build\libs\` |
| APK Works | ✅ | ✅ | ✅ |

---

## 🚀 CI/CD Examples

### GitHub Actions (Multi-Platform)

```yaml
name: Build Native Watcher

on: [push, pull_request]

jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
    
    runs-on: ${{ matrix.os }}
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up JDK 11
        uses: actions/setup-java@v3
        with:
          java-version: '11'
          distribution: 'adopt'
      
      - name: Build (Unix)
        if: runner.os != 'Windows'
        run: |
          cd native_assets/android
          chmod +x gradlew build_watcher.sh
          ./build_watcher.sh
      
      - name: Build (Windows)
        if: runner.os == 'Windows'
        run: |
          cd native_assets/android
          .\build_watcher.bat
      
      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: native-watcher-${{ matrix.os }}
          path: native_assets/android/build/libs/native_watcher.apk
```

---

## 📝 Quick Reference

### Build Commands by Platform

```bash
# macOS/Linux
cd native_assets/android
./build_watcher.sh          # Using script
./gradlew buildWatcherApk   # Using Gradle

# Windows CMD
cd native_assets\android
build_watcher.bat           # Using script
gradlew.bat buildWatcherApk # Using Gradle

# Windows PowerShell
cd native_assets\android
.\build_watcher.bat         # Using script
.\gradlew.bat buildWatcherApk # Using Gradle
```

---

## 🎯 What's Built?

The APK includes (same on all platforms):

✅ **Test-driven configuration** - Dynamic allow/deny/ignore
✅ **Permission handlers** - Location, Camera, Storage, etc.
✅ **Location precision** - Precise/Approximate selection
✅ **Google Sign-In** - Credential picker dismissal
✅ **ANR handler** - "App not responding" dialog
✅ **System dialogs** - OK, Continue, Got it, etc.

---

## 🎉 Summary

| Platform | Script | Command | Output |
|----------|--------|---------|--------|
| 🍎 macOS | `build_watcher.sh` | `./build_watcher.sh` | `build/libs/native_watcher.apk` |
| 🐧 Linux | `build_watcher.sh` | `./build_watcher.sh` | `build/libs/native_watcher.apk` |
| 🪟 Windows | `build_watcher.bat` | `build_watcher.bat` | `build\libs\native_watcher.apk` |

**All platforms produce the same APK that works everywhere!** 🚀

---

**Happy Building on Any Platform! 🎉**
