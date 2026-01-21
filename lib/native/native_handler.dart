import 'dart:io';
import 'adb_commander.dart';
import 'permission_granter.dart';
import 'dialog_watcher.dart';
import 'watcher_config.dart'; // NEW: Import watcher config
import '../core/models/test_result.dart';

/// Orchestrates native actions during test execution
/// Combines permission granting, dialog watching, and test execution
class NativeHandler {
  final AdbCommander _adb;
  final PermissionGranter _permissionGranter;
  final DialogWatcher _dialogWatcher;
  final WatcherConfig _watcherConfig; // NEW: Config manager

  NativeHandler({
    AdbCommander? adb,
    PermissionGranter? permissionGranter,
    DialogWatcher? dialogWatcher,
    WatcherConfig? watcherConfig, // NEW: Optional config
  })  : _adb = adb ?? AdbCommander(),
        _permissionGranter = permissionGranter ?? PermissionGranter(adb ?? AdbCommander()),
        _dialogWatcher = dialogWatcher ?? DialogWatcher(adb ?? AdbCommander()),
        _watcherConfig = watcherConfig ?? WatcherConfig(adb ?? AdbCommander()); // NEW: Initialize config

  /// Run test with full native support
  Future<TestResult> runWithNativeSupport({
    required String deviceId,
    required String testFile,
    required String packageName,
    required NativeOptions options,
    required Future<TestResult> Function() testRunner,
  }) async {
    Process? watcherProcess;
    final startTime = DateTime.now();

    try {
      print('\n🚀 Native Handler Starting...');
      print('  Device: $deviceId');
      print('  Test: $testFile');
      print('  Package: $packageName');

      // Step 1: Device setup
      await _setupDevice(deviceId, options);

      // Step 2: Grant permissions
      if (options.permissionMode != PermissionMode.none) {
        await _permissionGranter.grantByMode(
          deviceId,
          packageName,
          options.permissionMode,
          customPermissions: options.customPermissions,
        );
      }

      // Step 3: Start native watcher
      if (options.enableWatcher) {
        await _dialogWatcher.clearLogs(deviceId);
        watcherProcess = await _dialogWatcher.start(deviceId);
        
        // Wait for watcher to initialize
        await Future.delayed(options.watcherStartupDelay);
      }

      // Step 4: Run the actual test
      print('\n🧪 Running test...\n');
      final result = await testRunner();

      // Step 5: Collect native statistics
      if (options.enableWatcher && watcherProcess != null) {
        final stats = await _dialogWatcher.getStats(deviceId);
        print('\n📊 Native Dialog Statistics:');
        print('  Dialogs detected: ${stats.dialogsDetected}');
        print('  Dialogs dismissed: ${stats.dialogsDismissed}');
        
        if (stats.events.isNotEmpty && options.verbose) {
          print('\n  Events:');
          for (final event in stats.events.take(10)) {
            print('    • $event');
          }
        }
      }

      return result;
    } catch (e, stackTrace) {
      print('\n❌ Native handler error: $e');
      if (options.verbose) {
        print('Stack trace: $stackTrace');
      }

      // Return failure result
      return TestResult(
        testPath: testFile,
        testHash: '',
        passed: false,
        duration: DateTime.now().difference(startTime),
        timestamp: DateTime.now(),
        deviceId: deviceId,
        errorMessage: 'Native handler error: $e',
      );
    } finally {
      // Step 6: Cleanup
      if (watcherProcess != null) {
        await _dialogWatcher.stop(watcherProcess);
      }

      if (options.cleanupAfterTest) {
        await _cleanupDevice(deviceId, packageName, options);
      }

      print('\n✅ Native handler complete');
    }
  }

  /// Setup device before test
  Future<void> _setupDevice(String deviceId, NativeOptions options) async {
    print('\n⚙️  Device Setup:');

    if (options.disableAnimations) {
      await _adb.disableAnimations(deviceId);
    }

    if (options.clearAppData) {
      await _adb.clearAppData(deviceId, options.packageName);
    }

    print('  ✅ Device ready');
  }

  /// Cleanup device after test
  Future<void> _cleanupDevice(
    String deviceId,
    String packageName,
    NativeOptions options,
  ) async {
    print('\n🧹 Cleanup:');

    if (options.enableAnimations) {
      await _adb.enableAnimations(deviceId);
    }

    if (options.clearAppDataAfterTest) {
      await _adb.clearAppData(deviceId, packageName);
    }

    print('  ✅ Cleanup complete');
  }

  /// Run test without native support (basic mode)
  Future<TestResult> runBasic({
    required String deviceId,
    required String testFile,
    required Future<TestResult> Function() testRunner,
  }) async {
    print('\n🚀 Running in basic mode (no native support)');
    print('  Device: $deviceId');
    print('  Test: $testFile\n');

    try {
      return await testRunner();
    } catch (e) {
      print('❌ Test execution error: $e');
      return TestResult(
        testPath: testFile,
        testHash: '',
        passed: false,
        duration: Duration.zero,
        timestamp: DateTime.now(),
        deviceId: deviceId,
        errorMessage: e.toString(),
      );
    }
  }

  /// Check if device supports native features
  Future<NativeCapabilities> checkCapabilities(String deviceId) async {
    print('🔍 Checking native capabilities...');

    final watcherSupported = await DialogWatcher.isSupported(_adb, deviceId);
    final apiLevel = await _adb.getApiLevel(deviceId);
    final androidVersion = await _adb.getAndroidVersion(deviceId);

    final capabilities = NativeCapabilities(
      watcherSupported: watcherSupported,
      apiLevel: apiLevel,
      androidVersion: androidVersion,
      permissionGrantingSupported: apiLevel >= 23, // Android 6.0+
      screenRecordingSupported: apiLevel >= 19, // Android 4.4+
    );

    print('  UI Automator: ${capabilities.watcherSupported ? "✅" : "❌"}');
    print('  Permission Granting: ${capabilities.permissionGrantingSupported ? "✅" : "❌"}');
    print('  API Level: ${capabilities.apiLevel}');
    print('  Android Version: ${capabilities.androidVersion}');

    return capabilities;
  }

  /// Get device info
  Future<DeviceInfo> getDeviceInfo(String deviceId) async {
    final model = await _adb.getDeviceModel(deviceId);
    final androidVersion = await _adb.getAndroidVersion(deviceId);

    return DeviceInfo(
      id: deviceId,
      name: model,
      platform: 'Android',
      model: model,
      osVersion: androidVersion,
      isAvailable: true,
    );
  }

  /// Configure watcher behavior before starting test
  Future<void> configureWatcher({
    required String deviceId,
    DialogAction permissionAction = DialogAction.allow,
    LocationPrecision locationPrecision = LocationPrecision.precise,
    DialogAction notificationAction = DialogAction.allow,
    DialogAction systemDialogAction = DialogAction.dismiss,
    bool dismissGooglePicker = true,
  }) async {
    await _watcherConfig.configure(
      deviceId: deviceId,
      permissionAction: permissionAction,
      locationPrecision: locationPrecision,
      notificationAction: notificationAction,
      systemDialogAction: systemDialogAction,
      dismissGooglePicker: dismissGooglePicker,
    );
  }

  /// Clear watcher configuration
  Future<void> clearWatcherConfig(String deviceId) async {
    await _watcherConfig.clear(deviceId);
  }
}

/// Native execution options
class NativeOptions {
  final String packageName;
  final PermissionMode permissionMode;
  final List<String>? customPermissions;
  final bool enableWatcher;
  final bool disableAnimations;
  final bool enableAnimations;
  final bool clearAppData;
  final bool clearAppDataAfterTest;
  final bool cleanupAfterTest;
  final bool verbose;
  final Duration watcherStartupDelay;

  const NativeOptions({
    required this.packageName,
    this.permissionMode = PermissionMode.common,
    this.customPermissions,
    this.enableWatcher = true,
    this.disableAnimations = true,
    this.enableAnimations = true,
    this.clearAppData = false,
    this.clearAppDataAfterTest = false,
    this.cleanupAfterTest = true,
    this.verbose = false,
    this.watcherStartupDelay = const Duration(seconds: 2),
  });

  NativeOptions copyWith({
    String? packageName,
    PermissionMode? permissionMode,
    List<String>? customPermissions,
    bool? enableWatcher,
    bool? disableAnimations,
    bool? enableAnimations,
    bool? clearAppData,
    bool? clearAppDataAfterTest,
    bool? cleanupAfterTest,
    bool? verbose,
    Duration? watcherStartupDelay,
  }) {
    return NativeOptions(
      packageName: packageName ?? this.packageName,
      permissionMode: permissionMode ?? this.permissionMode,
      customPermissions: customPermissions ?? this.customPermissions,
      enableWatcher: enableWatcher ?? this.enableWatcher,
      disableAnimations: disableAnimations ?? this.disableAnimations,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      clearAppData: clearAppData ?? this.clearAppData,
      clearAppDataAfterTest: clearAppDataAfterTest ?? this.clearAppDataAfterTest,
      cleanupAfterTest: cleanupAfterTest ?? this.cleanupAfterTest,
      verbose: verbose ?? this.verbose,
      watcherStartupDelay: watcherStartupDelay ?? this.watcherStartupDelay,
    );
  }
}

/// Native capabilities of a device
class NativeCapabilities {
  final bool watcherSupported;
  final int apiLevel;
  final String androidVersion;
  final bool permissionGrantingSupported;
  final bool screenRecordingSupported;

  const NativeCapabilities({
    required this.watcherSupported,
    required this.apiLevel,
    required this.androidVersion,
    required this.permissionGrantingSupported,
    required this.screenRecordingSupported,
  });

  bool get isFullySupported =>
      watcherSupported && permissionGrantingSupported;

  @override
  String toString() {
    return 'NativeCapabilities(watcher: $watcherSupported, '
        'permissions: $permissionGrantingSupported, '
        'API: $apiLevel)';
  }
}
