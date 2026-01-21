import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'adb_commander.dart';

/// Manages UI Automator watcher for native dialog handling
class DialogWatcher {
  final AdbCommander _adb;
  final String watcherApkPath;
  final String watcherPackageName;
  final String watcherClassName;

  DialogWatcher(
    this._adb, {
    String? watcherApkPath,
    this.watcherPackageName = 'com.testpilot.watcher.test',
    this.watcherClassName = 'com.testpilot.watcher.NativeWatcher',
  }) : watcherApkPath = watcherApkPath ?? _findWatcherApkPath();

  /// Find the watcher APK path (works from both root and example dirs)
  static String _findWatcherApkPath() {
    final currentDir = Directory.current.path;

    // Try 1: From example directory - go up to root
    var tryPath = path.join(
      currentDir,
      '..',
      'native_assets',
      'android',
      'build',
      'libs',
      'native_watcher.apk',
    );
    if (File(tryPath).existsSync()) {
      return path.normalize(tryPath);
    }

    // Try 2: From root directory
    tryPath = path.join(
      currentDir,
      'native_assets',
      'android',
      'build',
      'libs',
      'native_watcher.apk',
    );
    if (File(tryPath).existsSync()) {
      return path.normalize(tryPath);
    }

    // Default: assume running from root
    return path.join(
      currentDir,
      'native_assets',
      'android',
      'build',
      'libs',
      'native_watcher.apk',
    );
  }

  /// Start the native dialog watcher on device
  Future<Process> start(String deviceId) async {
    print('🤖 Starting native dialog watcher...');

    // Step 1: Ensure APK is built
    await _ensureWatcherBuilt();

    // Step 2: Install instrumentation APK
    print('  📤 Installing watcher APK...');
    await _adb.run(['install', '-r', '-t', watcherApkPath], deviceId: deviceId);
    print('  ✅ Watcher APK installed');

    // Step 3: Start instrumentation test
    print('  🚀 Starting watcher process...');
    final process = await Process.start(_adb.adbExecutable, [
      '-s',
      deviceId,
      'shell',
      'am',
      'instrument',
      '-w',
      '-e',
      'class',
      '$watcherClassName#testWatchForDialogs',
      '$watcherPackageName/androidx.test.runner.AndroidJUnitRunner',
    ]);

    // Step 4: Stream logs with prefix
    process.stdout.transform(utf8.decoder).listen((line) {
      if (line.trim().isNotEmpty) {
        print('  [Watcher] $line');
      }
    });

    process.stderr.transform(utf8.decoder).listen((line) {
      if (line.trim().isNotEmpty) {
        print('  [Watcher Error] $line');
      }
    });

    // Wait a bit for watcher to initialize
    await Future.delayed(const Duration(milliseconds: 500));

    print('  ✅ Watcher started (PID: ${process.pid})');
    return process;
  }

  /// Stop the watcher process
  Future<void> stop(Process watcherProcess) async {
    print('🛑 Stopping native watcher...');
    watcherProcess.kill();

    // Wait for process to exit
    await watcherProcess.exitCode.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        watcherProcess.kill(ProcessSignal.sigkill);
        return -1;
      },
    );

    print('  ✅ Watcher stopped');
  }

  /// Ensure the watcher APK is built
  Future<void> _ensureWatcherBuilt() async {
    final apkFile = File(watcherApkPath);

    if (await apkFile.exists()) {
      print('  ✅ Watcher APK found: ${apkFile.path}');
      return;
    }

    print('  ⚠️  Watcher APK not found, building...');
    await _buildWatcher();
  }

  /// Build the watcher APK using Gradle
  Future<void> _buildWatcher() async {
    // Find the native_assets/android directory
    final currentDir = Directory.current.path;

    String? androidDir;

    // Try from example directory
    var tryDir = path.join(currentDir, '..', 'native_assets', 'android');
    if (Directory(tryDir).existsSync()) {
      androidDir = path.normalize(tryDir);
    } else {
      // Try from root directory
      tryDir = path.join(currentDir, 'native_assets', 'android');
      if (Directory(tryDir).existsSync()) {
        androidDir = tryDir;
      }
    }

    if (androidDir == null) {
      throw WatcherException(
        'Could not find native_assets/android directory.\n'
        'Searched:\n'
        '  - $currentDir/../native_assets/android\n'
        '  - $currentDir/native_assets/android\n',
      );
    }

    final gradleWrapper = Platform.isWindows ? 'gradlew.bat' : './gradlew';
    final gradleFile = File(path.join(androidDir, gradleWrapper));

    if (!await gradleFile.exists()) {
      throw WatcherException(
        'Gradle wrapper not found at: ${gradleFile.path}\n'
        'Please run: cd $androidDir && chmod +x gradlew',
      );
    }

    print('  🔨 Building watcher APK from: $androidDir');

    // Use buildWatcherApk task which builds AND copies to build/libs/
    final process = await Process.start(gradleWrapper, [
      'buildWatcherApk',
    ], workingDirectory: androidDir);

    // Stream build output
    process.stdout.transform(utf8.decoder).listen((line) {
      print('    [Gradle] $line');
    });

    process.stderr.transform(utf8.decoder).listen((line) {
      print('    [Gradle Error] $line');
    });

    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      throw WatcherException(
        'Failed to build watcher APK (exit code: $exitCode)',
      );
    }

    final apkFile = File(watcherApkPath);
    if (!await apkFile.exists()) {
      throw WatcherException(
        'Build succeeded but APK not found at: $watcherApkPath',
      );
    }

    print('  ✅ Watcher APK built successfully');
  }

  /// Check if watcher is supported on device
  static Future<bool> isSupported(AdbCommander adb, String deviceId) async {
    try {
      final result = await adb.run(
        ['shell', 'which', 'uiautomator'],
        deviceId: deviceId,
        throwOnError: false,
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Get watcher statistics from device logs
  Future<WatcherStats> getStats(String deviceId) async {
    try {
      final result = await _adb.run(
        ['logcat', '-d', '-s', 'TestPilotWatcher'],
        deviceId: deviceId,
        throwOnError: false,
      );

      final output = result.stdout as String;
      return _parseStats(output);
    } catch (e) {
      return WatcherStats.empty();
    }
  }

  WatcherStats _parseStats(String logOutput) {
    int dialogsDetected = 0;
    int dialogsDismissed = 0;
    final events = <String>[];

    final lines = logOutput.split('\n');
    for (final line in lines) {
      if (line.contains('Detected:')) {
        dialogsDetected++;
        events.add(line);
      }
      if (line.contains('Dismissed') || line.contains('Granted')) {
        dialogsDismissed++;
      }
    }

    return WatcherStats(
      dialogsDetected: dialogsDetected,
      dialogsDismissed: dialogsDismissed,
      events: events,
    );
  }

  /// Clear device logs before starting watcher
  Future<void> clearLogs(String deviceId) async {
    await _adb.run(['logcat', '-c'], deviceId: deviceId, throwOnError: false);
  }
}

/// Watcher statistics
class WatcherStats {
  final int dialogsDetected;
  final int dialogsDismissed;
  final List<String> events;

  WatcherStats({
    required this.dialogsDetected,
    required this.dialogsDismissed,
    required this.events,
  });

  factory WatcherStats.empty() {
    return WatcherStats(dialogsDetected: 0, dialogsDismissed: 0, events: []);
  }

  @override
  String toString() {
    return 'WatcherStats(detected: $dialogsDetected, dismissed: $dialogsDismissed)';
  }
}

/// Custom exception for watcher-related errors
class WatcherException implements Exception {
  final String message;

  WatcherException(this.message);

  @override
  String toString() => 'WatcherException: $message';
}
