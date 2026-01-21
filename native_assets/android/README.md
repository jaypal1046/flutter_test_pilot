# Flutter Test Pilot - Native Dialog Watcher

This directory contains the Android UI Automator watcher that automatically handles native dialogs during test execution.

## 📁 Structure

```
native_assets/android/
├── build.gradle                    # Gradle build configuration
├── settings.gradle                 # Gradle settings
├── gradlew                         # Gradle wrapper (Unix/Mac)
├── gradlew.bat                     # Gradle wrapper (Windows)
└── src/main/java/com/testpilot/watcher/
    └── NativeWatcher.java          # UI Automator watcher implementation
```

## 🔨 Building the Watcher

The watcher is automatically built when running tests, but you can build it manually:

### On macOS/Linux:
```bash
cd native_assets/android
./gradlew buildWatcherJar
```

### On Windows:
```bash
cd native_assets\android
gradlew.bat buildWatcherJar
```

The compiled JAR will be created at:
```
native_assets/android/build/libs/native_watcher.jar
```

## 🎯 What the Watcher Does

The native watcher runs in parallel with your Flutter tests and automatically handles:

1. **Google Credential Picker** - Dismisses via back button
2. **Permission Dialogs** - Clicks "Allow" or "While using the app"
3. **Location Permission** - Selects "Precise" location
4. **Notification Permission** - Clicks "Allow"
5. **System Alerts** - Dismisses "OK", "Continue", "Got it" buttons
6. **ANR Dialogs** - Clicks "Wait" on "App Not Responding"

## 📊 Logging

The watcher logs all events to logcat with tag `TestPilotWatcher`:

```bash
# View watcher logs
adb logcat -s TestPilotWatcher

# Example output:
# D/TestPilotWatcher: 🤖 Native watcher started
# D/TestPilotWatcher: 🚨 Detected: Google Credential Picker
# D/TestPilotWatcher: ✅ Dismissed via back button
```

## 🔧 Customization

To add custom dialog handling, edit `NativeWatcher.java` and add a new handler method:

```java
private void handleMyCustomDialog() throws InterruptedException {
    UiObject2 myButton = device.findObject(By.text("My Button"));
    
    if (myButton != null) {
        dialogsDetected++;
        Log.d(TAG, "🚨 Detected: My Custom Dialog");
        myButton.click();
        Thread.sleep(STABILIZE_DELAY_MS);
        dialogsDismissed++;
        Log.d(TAG, "✅ Handled custom dialog");
    }
}
```

Then call it in the `testWatchForDialogs()` loop:

```java
while (true) {
    // ...existing handlers...
    handleMyCustomDialog();
    
    Thread.sleep(POLL_INTERVAL_MS);
}
```

Rebuild the JAR after making changes.

## 🐛 Troubleshooting

### JAR build fails
- Ensure Java 11+ is installed: `java -version`
- Check Gradle wrapper is executable: `chmod +x gradlew`

### Watcher doesn't detect dialogs
- Check device logs: `adb logcat -s TestPilotWatcher`
- Increase `POLL_INTERVAL_MS` in `NativeWatcher.java`
- Add more specific selectors for your dialog

### Watcher stops unexpectedly
- Check device logs for exceptions
- Ensure UI Automator is available: `adb shell which uiautomator`

## 📝 Requirements

- Java 11 or higher
- Android SDK with UI Automator 2.3.0+
- Gradle 7.0+ (included via wrapper)

## 🚀 Usage from CLI

The watcher is automatically managed by the Flutter Test Pilot CLI:

```bash
flutter_test_pilot run integration_test/login_test.dart \
  --native-watcher=enabled \
  --pre-grant-permissions=all
```

The CLI will:
1. Build the JAR if needed
2. Push it to the device
3. Start the watcher process
4. Run your test
5. Stop the watcher
6. Report statistics
