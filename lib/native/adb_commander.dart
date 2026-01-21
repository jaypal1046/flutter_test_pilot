import 'dart:io';
import 'dart:convert';

/// Wrapper for Android Debug Bridge (ADB) commands
/// Provides a unified interface for all device interactions
class AdbCommander {
  final String adbExecutable;
  final Duration defaultTimeout;

  AdbCommander({
    String? adbPath,
    this.defaultTimeout = const Duration(seconds: 30),
  }) : adbExecutable = adbPath ?? _findAdbExecutable();

  /// Find ADB executable in common locations
  static String _findAdbExecutable() {
    // Platform-specific common paths
    final List<String> commonPaths;
    
    if (Platform.isMacOS) {
      commonPaths = [
        // Standard Android SDK location (macOS)
        '${Platform.environment['HOME']}/Library/Android/sdk/platform-tools/adb',
        '${Platform.environment['ANDROID_HOME']}/platform-tools/adb',
        '${Platform.environment['ANDROID_SDK_ROOT']}/platform-tools/adb',
        // Homebrew installation (Intel Mac)
        '/usr/local/bin/adb',
        // Homebrew installation (Apple Silicon)
        '/opt/homebrew/bin/adb',
        // Just 'adb' if it's in PATH
        'adb',
      ];
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Default';
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '$userProfile\\AppData\\Local';
      
      commonPaths = [
        // Standard Android SDK location (Windows)
        '$localAppData\\Android\\Sdk\\platform-tools\\adb.exe',
        '${Platform.environment['ANDROID_HOME']}\\platform-tools\\adb.exe',
        '${Platform.environment['ANDROID_SDK_ROOT']}\\platform-tools\\adb.exe',
        // Chocolatey installation
        'C:\\ProgramData\\chocolatey\\bin\\adb.exe',
        // Program Files
        'C:\\Program Files (x86)\\Android\\android-sdk\\platform-tools\\adb.exe',
        // Just 'adb' if it's in PATH
        'adb.exe',
      ];
    } else if (Platform.isLinux) {
      commonPaths = [
        // Standard Android SDK location (Linux)
        '${Platform.environment['HOME']}/Android/Sdk/platform-tools/adb',
        '${Platform.environment['ANDROID_HOME']}/platform-tools/adb',
        '${Platform.environment['ANDROID_SDK_ROOT']}/platform-tools/adb',
        // System-wide installation
        '/usr/bin/adb',
        '/usr/local/bin/adb',
        // Snap installation
        '/snap/bin/adb',
        // Just 'adb' if it's in PATH
        'adb',
      ];
    } else {
      // Fallback for other platforms
      commonPaths = ['adb'];
    }

    // Try each path
    for (final path in commonPaths) {
      final isPathCommand = path.endsWith('adb') || path.endsWith('adb.exe');
      
      if (isPathCommand && !path.contains('/') && !path.contains('\\')) {
        // This is just 'adb' or 'adb.exe' - check if it's in PATH
        try {
          if (Platform.isWindows) {
            final result = Process.runSync('where', [path]);
            if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
              return path;
            }
          } else {
            final result = Process.runSync('which', [path]);
            if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
              return path;
            }
          }
        } catch (e) {
          continue;
        }
      } else {
        // This is a full path - check if file exists
        final file = File(path);
        if (file.existsSync()) {
          return path;
        }
      }
    }

    // If not found, throw helpful error with platform-specific instructions
    final platformInstructions = _getPlatformSpecificInstructions();
    
    throw AdbNotFoundException(
      'ADB not found! Please install Android SDK or set ANDROID_HOME.\n'
      '\n'
      '$platformInstructions'
      '\n'
      '📍 Searched locations:\n${commonPaths.map((p) => "  • $p").join("\n")}',
    );
  }

  /// Get platform-specific installation instructions
  static String _getPlatformSpecificInstructions() {
    if (Platform.isMacOS) {
      return '🔧 macOS Quick Fix Options:\n'
          '\n'
          '1️⃣ Install via Homebrew:\n'
          '   brew install --cask android-platform-tools\n'
          '\n'
          '2️⃣ Or install Android Studio:\n'
          '   brew install --cask android-studio\n'
          '\n'
          '3️⃣ Or set ANDROID_HOME:\n'
          '   export ANDROID_HOME=\$HOME/Library/Android/sdk\n'
          '   export PATH=\$PATH:\$ANDROID_HOME/platform-tools\n'
          '\n'
          '4️⃣ Verify installation:\n'
          '   adb version\n';
    } else if (Platform.isWindows) {
      return '🔧 Windows Quick Fix Options:\n'
          '\n'
          '1️⃣ Install via Chocolatey:\n'
          '   choco install adb -y\n'
          '\n'
          '2️⃣ Or install Android Studio:\n'
          '   - Download from: https://developer.android.com/studio\n'
          '   - Install and run initial setup\n'
          '\n'
          '3️⃣ Or set ANDROID_HOME:\n'
          '   - Open System Properties → Environment Variables\n'
          '   - Add System Variable:\n'
          '     Name: ANDROID_HOME\n'
          '     Value: C:\\Users\\YourName\\AppData\\Local\\Android\\Sdk\n'
          '   - Add to PATH:\n'
          '     %ANDROID_HOME%\\platform-tools\n'
          '\n'
          '4️⃣ Verify installation (restart terminal):\n'
          '   adb version\n';
    } else if (Platform.isLinux) {
      return '🔧 Linux Quick Fix Options:\n'
          '\n'
          '1️⃣ Install via apt (Ubuntu/Debian):\n'
          '   sudo apt update\n'
          '   sudo apt install android-tools-adb\n'
          '\n'
          '2️⃣ Or install via snap:\n'
          '   sudo snap install adb\n'
          '\n'
          '3️⃣ Or install Android Studio:\n'
          '   - Download from: https://developer.android.com/studio\n'
          '\n'
          '4️⃣ Or set ANDROID_HOME:\n'
          '   export ANDROID_HOME=\$HOME/Android/Sdk\n'
          '   export PATH=\$PATH:\$ANDROID_HOME/platform-tools\n'
          '   # Add to ~/.bashrc or ~/.zshrc to persist\n'
          '\n'
          '5️⃣ Verify installation:\n'
          '   adb version\n';
    } else {
      return '🔧 Installation Required:\n'
          '\n'
          'Please install Android SDK or ADB tools for your platform.\n'
          'Visit: https://developer.android.com/studio/releases/platform-tools\n';
    }
  }

  /// Execute an ADB command with optional device targeting
  Future<ProcessResult> run(
    List<String> args, {
    String? deviceId,
    Duration? timeout,
    bool throwOnError = true,
  }) async {
    final fullArgs = <String>[
      if (deviceId != null) ...['-s', deviceId],
      ...args,
    ];

    final effectiveTimeout = timeout ?? defaultTimeout;

    try {
      final process = await Process.start(adbExecutable, fullArgs);

      // Collect stdout/stderr
      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();

      // Wait for process with timeout
      final exitCodeFuture = process.exitCode;
      final timedExitCode = await exitCodeFuture.timeout(
        effectiveTimeout,
        onTimeout: () {
          process.kill();
          return -1;
        },
      );

      final stdoutStr = await stdoutFuture;
      final stderrStr = await stderrFuture;

      if (timedExitCode == -1) {
        throw AdbException(
          'Command timed out after $effectiveTimeout',
          command: fullArgs.join(' '),
        );
      }

      if (throwOnError && timedExitCode != 0) {
        throw AdbException(
          'Command failed with exit code $timedExitCode',
          command: fullArgs.join(' '),
          exitCode: timedExitCode,
          stderr: stderrStr,
        );
      }

      return ProcessResult(0, timedExitCode, stdoutStr, stderrStr);
    } catch (e) {
      if (e is AdbException) rethrow;
      throw AdbException(
        'Failed to execute ADB command: $e',
        command: fullArgs.join(' '),
      );
    }
  }

  /// Grant a specific permission to an app
  Future<void> grantPermission(
    String deviceId,
    String packageName,
    String permission,
  ) async {
    print('  📋 Granting permission: $permission');
    await run([
      'shell',
      'pm',
      'grant',
      packageName,
      permission.startsWith('android.permission.')
          ? permission
          : 'android.permission.$permission',
    ], deviceId: deviceId);
  }

  /// Clear app data and cache
  Future<void> clearAppData(String deviceId, String packageName) async {
    print('  🧹 Clearing app data for: $packageName');
    await run(['shell', 'pm', 'clear', packageName], deviceId: deviceId);
  }

  /// Press the back button
  Future<void> pressBack(String deviceId) async {
    await run(['shell', 'input', 'keyevent', '4'], deviceId: deviceId);
  }

  /// Press the home button
  Future<void> pressHome(String deviceId) async {
    await run(['shell', 'input', 'keyevent', '3'], deviceId: deviceId);
  }

  /// Disable all animations (recommended for testing)
  Future<void> disableAnimations(String deviceId) async {
    print('  ⚙️  Disabling animations...');
    const settings = [
      'window_animation_scale',
      'transition_animation_scale',
      'animator_duration_scale',
    ];

    for (final setting in settings) {
      await run([
        'shell',
        'settings',
        'put',
        'global',
        setting,
        '0',
      ], deviceId: deviceId);
    }
  }

  /// Enable animations
  Future<void> enableAnimations(String deviceId) async {
    print('  ⚙️  Enabling animations...');
    const settings = [
      'window_animation_scale',
      'transition_animation_scale',
      'animator_duration_scale',
    ];

    for (final setting in settings) {
      await run([
        'shell',
        'settings',
        'put',
        'global',
        setting,
        '1',
      ], deviceId: deviceId);
    }
  }

  /// Take a screenshot and save to device
  Future<String> takeScreenshot(String deviceId, String remotePath) async {
    await run(['shell', 'screencap', '-p', remotePath], deviceId: deviceId);
    return remotePath;
  }

  /// Pull a file from device to local machine
  Future<void> pullFile(
    String deviceId,
    String remotePath,
    String localPath,
  ) async {
    await run(['pull', remotePath, localPath], deviceId: deviceId);
  }

  /// Push a file from local machine to device
  Future<void> pushFile(
    String deviceId,
    String localPath,
    String remotePath,
  ) async {
    await run(['push', localPath, remotePath], deviceId: deviceId);
  }

  /// Start screen recording
  Future<Process> startScreenRecord(String deviceId, String remotePath) async {
    final process = await Process.start(adbExecutable, [
      '-s',
      deviceId,
      'shell',
      'screenrecord',
      remotePath,
    ]);
    return process;
  }

  /// Install an APK
  Future<void> installApk(String deviceId, String apkPath) async {
    print('  📦 Installing APK: $apkPath');
    await run(
      ['install', '-r', apkPath],
      deviceId: deviceId,
      timeout: const Duration(minutes: 5),
    );
  }

  /// Uninstall an app
  Future<void> uninstallApp(String deviceId, String packageName) async {
    print('  🗑️  Uninstalling: $packageName');
    await run(['uninstall', packageName], deviceId: deviceId);
  }

  /// Get device property
  Future<String> getProperty(String deviceId, String property) async {
    final result = await run([
      'shell',
      'getprop',
      property,
    ], deviceId: deviceId);
    return (result.stdout as String).trim();
  }

  /// Check if ADB is available
  static Future<bool> isAvailable() async {
    try {
      final result = await Process.run('adb', ['version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Get list of connected devices
  Future<List<String>> getDevices() async {
    final result = await run(['devices', '-l'], throwOnError: false);
    final output = result.stdout as String;
    final lines = output.split('\n').skip(1); // Skip header

    final devices = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || !trimmed.contains('\t')) continue;

      final parts = trimmed.split('\t');
      if (parts.length >= 2 && parts[1].contains('device')) {
        devices.add(parts[0]);
      }
    }

    return devices;
  }

  /// Get device model
  Future<String> getDeviceModel(String deviceId) async {
    return await getProperty(deviceId, 'ro.product.model');
  }

  /// Get Android version
  Future<String> getAndroidVersion(String deviceId) async {
    return await getProperty(deviceId, 'ro.build.version.release');
  }

  /// Get device API level
  Future<int> getApiLevel(String deviceId) async {
    final level = await getProperty(deviceId, 'ro.build.version.sdk');
    return int.parse(level);
  }
}

/// Custom exception for ADB command failures
class AdbException implements Exception {
  final String message;
  final String? command;
  final int? exitCode;
  final String? stderr;

  AdbException(this.message, {this.command, this.exitCode, this.stderr});

  @override
  String toString() {
    final buffer = StringBuffer('AdbException: $message');
    if (command != null) buffer.write('\nCommand: adb $command');
    if (exitCode != null) buffer.write('\nExit code: $exitCode');
    if (stderr != null && stderr!.isNotEmpty) {
      buffer.write('\nStderr: $stderr');
    }
    return buffer.toString();
  }
}

/// Custom exception for when ADB is not found
class AdbNotFoundException implements Exception {
  final String message;

  AdbNotFoundException(this.message);

  @override
  String toString() => 'AdbNotFoundException: $message';
}
