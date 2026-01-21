#!/usr/bin/env dart

/// 🚀 FLUTTER TEST PILOT - COMPREHENSIVE REAL-WORLD TEST RUNNER
///
/// This script demonstrates how to actually use all Phase 2 & 3 features:
/// - Native handling (permissions, dialog watcher, animations)
/// - Retry logic for flaky tests
/// - Parallel execution across devices
/// - Test discovery
/// - Screenshots on failure
/// - Complete integration workflow
///
/// Run this script to see everything in action:
/// dart run test/run_real_world_test.dart

import 'dart:io';
import 'package:flutter_test_pilot/src/native/adb_commander.dart';
import 'package:flutter_test_pilot/src/native/permission_granter.dart';
import 'package:flutter_test_pilot/src/native/dialog_watcher.dart';
import 'package:flutter_test_pilot/src/native/native_handler.dart';
import 'package:flutter_test_pilot/src/executor/retry_handler.dart';
import 'package:flutter_test_pilot/src/executor/parallel_executor.dart';
import 'package:flutter_test_pilot/src/discovery/test_finder.dart';
import 'package:flutter_test_pilot/src/reporting/screenshot_capturer.dart';
import 'package:flutter_test_pilot/src/core/models/test_result.dart';
import 'package:flutter_test_pilot/src/core/cache/cache_manager.dart';

void main() async {
  print('╔═══════════════════════════════════════════════════════════════╗');
  print('║  🚀 FLUTTER TEST PILOT - REAL WORLD TEST DEMONSTRATION       ║');
  print('╚═══════════════════════════════════════════════════════════════╝\n');

  final testRunner = RealWorldTestRunner();
  await testRunner.runFullDemonstration();
}

class RealWorldTestRunner {
  final adb = AdbCommander();
  late final screenshotCapturer = ScreenshotCapturer(adb);
  late final retryHandler = RetryHandler(
    maxRetries: 2,
    initialDelay: Duration(seconds: 3),
  );
  late final testFinder = TestFinder();

  Future<void> runFullDemonstration() async {
    print('📋 DEMONSTRATION PLAN:\n');
    print('   1. Check ADB and device availability');
    print('   2. Discover test files in the example project');
    print('   3. Show native handler capabilities');
    print('   4. Run a test with retry logic');
    print('   5. Demonstrate parallel execution (if multiple devices)');
    print('   6. Show screenshot capture');
    print('   7. Display cache statistics\n');

    print('═' * 70);
    print('PHASE 1: ENVIRONMENT CHECK');
    print('═' * 70 + '\n');

    await _checkEnvironment();

    print('\n' + '═' * 70);
    print('PHASE 2: TEST DISCOVERY');
    print('═' * 70 + '\n');

    await _discoverTests();

    print('\n' + '═' * 70);
    print('PHASE 3: NATIVE HANDLER DEMONSTRATION');
    print('═' * 70 + '\n');

    await _demonstrateNativeHandler();

    print('\n' + '═' * 70);
    print('PHASE 4: RETRY HANDLER DEMONSTRATION');
    print('═' * 70 + '\n');

    await _demonstrateRetryHandler();

    print('\n' + '═' * 70);
    print('PHASE 5: PARALLEL EXECUTION DEMONSTRATION');
    print('═' * 70 + '\n');

    await _demonstrateParallelExecution();

    print('\n' + '═' * 70);
    print('PHASE 6: SCREENSHOT & REPORTING');
    print('═' * 70 + '\n');

    await _demonstrateScreenshots();

    print('\n' + '═' * 70);
    print('PHASE 7: CACHE MANAGEMENT');
    print('═' * 70 + '\n');

    await _demonstrateCaching();

    print(
      '\n' +
          '╔═══════════════════════════════════════════════════════════════╗',
    );
    print('║                    ✅ DEMONSTRATION COMPLETE!                  ║');
    print(
      '╚═══════════════════════════════════════════════════════════════╝\n',
    );

    print('🎯 WHAT YOU LEARNED:\n');
    print('   ✅ How to check ADB and device availability');
    print('   ✅ How to discover tests automatically');
    print('   ✅ How to use native handling (permissions, watcher, animations)');
    print('   ✅ How to implement retry logic for flaky tests');
    print('   ✅ How to run tests in parallel across devices');
    print('   ✅ How to capture screenshots on failure');
    print('   ✅ How to use intelligent caching\n');

    print('🚀 NEXT STEPS:\n');
    print('   1. Connect an Android device: adb devices');
    print('   2. Run actual integration test:');
    print('      flutter test integration_test/plugin_integration_test.dart');
    print('   3. Run with native features:');
    print('      dart run test/run_with_native_support.dart');
    print('   4. Try parallel execution with multiple devices\n');
  }

  Future<void> _checkEnvironment() async {
    print('🔍 Checking ADB availability...');
    final adbAvailable = await AdbCommander.isAvailable();

    if (adbAvailable) {
      print('   ✅ ADB is available\n');

      print('📱 Scanning for connected devices...');
      final devices = await adb.getDevices();

      if (devices.isEmpty) {
        print('   ⚠️  No devices connected');
        print('   💡 Connect a device or start an emulator:\n');
        print('      adb devices');
        print('      emulator -avd <device_name>\n');
      } else {
        print('   ✅ Found ${devices.length} device(s):\n');

        for (final deviceId in devices) {
          print('   📱 Device: $deviceId');

          try {
            final model = await adb.getDeviceModel(deviceId);
            final androidVersion = await adb.getAndroidVersion(deviceId);
            final apiLevel = await adb.getApiLevel(deviceId);

            print('      • Model: $model');
            print('      • Android: $androidVersion (API $apiLevel)');

            // Check native capabilities
            final handler = NativeHandler();
            final capabilities = await handler.checkCapabilities(deviceId);
            print(
              '      • Watcher support: ${capabilities.watcherSupported ? "✅" : "❌"}',
            );
            print(
              '      • Permission grant: ${capabilities.permissionGrantingSupported ? "✅" : "❌"}',
            );
          } catch (e) {
            print('      ⚠️  Could not get device details: $e');
          }
          print('');
        }
      }
    } else {
      print('   ❌ ADB not available');
      print('   💡 Install Android SDK or add ADB to PATH:\n');
      print('      export ANDROID_HOME=~/Library/Android/sdk');
      print('      export PATH=\$PATH:\$ANDROID_HOME/platform-tools\n');
    }
  }

  Future<void> _discoverTests() async {
    print('🔍 Discovering test files in example project...\n');

    try {
      // Find all test files
      final allTests = await testFinder.findTests();

      print('📊 Test Discovery Results:\n');
      print('   • Total test files found: ${allTests.length}');

      if (allTests.isEmpty) {
        print('   ℹ️  No test files found in integration_test/ or test/\n');
        print('   💡 Run this from flutter_test_pilot directory:\n');
        print('      cd iltc-services/flutter_test_pilot');
        print('      dart run test/run_real_world_test.dart\n');
        return;
      }

      print('\n   📄 Test Files:\n');
      for (final testFile in allTests.take(10)) {
        print('      • $testFile');

        // Try to get metadata
        try {
          final metadata = await testFinder.getTestMetadata(testFile);
          print(
            '        ↳ ${metadata.testCount} test case(s), ${(metadata.size / 1024).toStringAsFixed(1)} KB',
          );
        } catch (e) {
          // Skip if can't read metadata
        }
      }

      if (allTests.length > 10) {
        print('      ... and ${allTests.length - 10} more');
      }

      print('\n   📁 Grouped by directory:');
      final grouped = testFinder.groupByDirectory(allTests);
      for (final entry in grouped.entries) {
        print('      • ${entry.key}/: ${entry.value.length} file(s)');
      }
    } catch (e) {
      print('   ⚠️  Error discovering tests: $e');
    }
  }

  Future<void> _demonstrateNativeHandler() async {
    print('🤖 Native Handler Features:\n');

    final devices = await adb.getDevices();

    if (devices.isEmpty) {
      print('   ⚠️  Skipped - no devices connected\n');
      print('   💡 This would show:');
      print('      • Pre-granting permissions');
      print('      • Starting dialog watcher');
      print('      • Disabling animations');
      print('      • Running tests with native support\n');
      return;
    }

    final deviceId = devices.first;
    final handler = NativeHandler();

    print('   📱 Using device: $deviceId\n');

    // 1. Show permission granting
    print('   1️⃣ PERMISSION GRANTING:');
    final granter = PermissionGranter(adb);
    print(
      '      • Available modes: ${PermissionMode.values.map((m) => m.name).join(", ")}',
    );
    print(
      '      • Common permissions: ${PermissionGranter.commonPermissions.length}',
    );
    print('      • Sample permissions:');
    for (final perm in PermissionGranter.commonPermissions.take(5)) {
      print('        - $perm');
    }
    print('');

    // 2. Show dialog watcher
    print('   2️⃣ DIALOG WATCHER:');
    final watcher = DialogWatcher(adb);
    final watcherApkExists = await File(watcher.watcherApkPath).exists();

    print('      • APK path: ${watcher.watcherApkPath}');
    print('      • APK exists: ${watcherApkExists ? "✅" : "❌"}');

    if (!watcherApkExists) {
      print(
        '      • Build APK: cd native_assets/android && ./gradlew buildWatcherApk',
      );
    }

    final watcherSupported = await DialogWatcher.isSupported(adb, deviceId);
    print('      • UI Automator support: ${watcherSupported ? "✅" : "❌"}');
    print('      • Handles 6 types of native dialogs automatically');
    print('');

    // 3. Show native options
    print('   3️⃣ NATIVE OPTIONS EXAMPLE:');
    print('      ```dart');
    print('      final options = NativeOptions(');
    print('        packageName: "com.example.myapp",');
    print('        permissionMode: PermissionMode.all,');
    print('        enableWatcher: true,');
    print('        disableAnimations: true,');
    print('        clearAppData: false,');
    print('      );');
    print('      ```');
    print('');

    // 4. Show complete workflow
    print('   4️⃣ COMPLETE WORKFLOW:');
    print('      1. Device setup (disable animations)');
    print('      2. Pre-grant permissions');
    print('      3. Start dialog watcher in background');
    print('      4. Run your test');
    print('      5. Collect watcher statistics');
    print('      6. Stop watcher');
    print('      7. Cleanup (re-enable animations)');
    print('');
  }

  Future<void> _demonstrateRetryHandler() async {
    print('🔄 Retry Handler with Exponential Backoff:\n');

    print('   📊 Configuration:');
    print('      • Max retries: ${retryHandler.maxRetries}');
    print('      • Initial delay: ${retryHandler.initialDelay.inSeconds}s');
    print('      • Backoff multiplier: ${retryHandler.backoffMultiplier}x');
    print('      • Max delay: ${retryHandler.maxDelay.inSeconds}s\n');

    print('   🧪 Simulating flaky test...\n');

    var attemptCount = 0;
    final startTime = DateTime.now();

    final result = await retryHandler.runWithRetry(
      testPath: 'example/integration_test/demo_test.dart',
      deviceId: 'demo-device',
      testRunner: () async {
        attemptCount++;
        final attemptDuration = DateTime.now().difference(startTime);

        print('      Attempt $attemptCount at ${attemptDuration.inSeconds}s');

        // Simulate failure on first attempt, success on second
        if (attemptCount < 2) {
          print('      ❌ Failed with network timeout (simulated)\n');
          return TestResult(
            testPath: 'example/integration_test/demo_test.dart',
            testHash: 'abc123',
            passed: false,
            duration: Duration(milliseconds: 500),
            timestamp: DateTime.now(),
            deviceId: 'demo-device',
            errorMessage: 'Network timeout - connection unavailable',
          );
        }

        print('      ✅ Passed!\n');
        return TestResult(
          testPath: 'example/integration_test/demo_test.dart',
          testHash: 'abc123',
          passed: true,
          duration: Duration(milliseconds: 500),
          timestamp: DateTime.now(),
          deviceId: 'demo-device',
        );
      },
      onRetry: (attempt, max, delay) {
        print(
          '      ⏳ Waiting ${delay.inSeconds}s before retry $attempt/$max...\n',
        );
      },
    );

    print('   📊 Results:');
    print('      • Total attempts: $attemptCount');
    print('      • Final status: ${result.passed ? "✅ PASSED" : "❌ FAILED"}');
    print(
      '      • Total time: ${DateTime.now().difference(startTime).inSeconds}s',
    );
    print(
      '      • Retriable errors detected: ${RetryHandler.isRetriableError(result.errorMessage)}',
    );
    print('');
  }

  Future<void> _demonstrateParallelExecution() async {
    print('⚡ Parallel Test Execution:\n');

    final devices = await adb.getDevices();

    if (devices.length < 2) {
      print('   ⚠️  Skipped - need 2+ devices for parallel demo');
      print('   ℹ️  Current devices: ${devices.length}\n');
      print('   💡 Start multiple emulators to see parallel execution:\n');
      print('      emulator -avd Pixel_4_API_30 &');
      print('      emulator -avd Pixel_5_API_31 &\n');
      print('   📊 With 2 devices, you get ~2x speedup');
      print('   📊 With 3 devices, you get ~3x speedup\n');
      return;
    }

    print('   📱 Available devices: ${devices.length}');
    for (final device in devices) {
      print('      • $device');
    }
    print('');

    final executor = ParallelExecutor(maxConcurrency: devices.length);

    // Simulate running multiple tests
    final testFiles = [
      'integration_test/forms_test.dart',
      'integration_test/gestures_test.dart',
      'integration_test/api_test.dart',
      'integration_test/ui_test.dart',
      'integration_test/complex_test.dart',
      'integration_test/claims_test.dart',
    ];

    print('   🧪 Running ${testFiles.length} tests in parallel...\n');

    final startTime = DateTime.now();

    final results = await executor.runParallel(
      testFiles: testFiles,
      deviceIds: devices,
      testRunner: (testFile, deviceId) async {
        // Simulate test execution with varying duration
        final duration = 2 + (testFile.hashCode % 3);
        await Future.delayed(Duration(seconds: duration));

        return TestResult(
          testPath: testFile,
          testHash: 'hash_${testFile.hashCode}',
          passed: true,
          duration: Duration(seconds: duration),
          timestamp: DateTime.now(),
          deviceId: deviceId,
        );
      },
    );

    final totalTime = DateTime.now().difference(startTime).inSeconds;
    final sequentialTime = results.fold<int>(
      0,
      (sum, r) => sum + r.duration.inSeconds,
    );
    final speedup = sequentialTime / totalTime;

    print('\n   📊 Parallel Execution Results:');
    print('      • Tests completed: ${results.length}');
    print('      • Passed: ${results.where((r) => r.passed).length}');
    print('      • Sequential time: ${sequentialTime}s');
    print('      • Parallel time: ${totalTime}s');
    print('      • Speedup: ${speedup.toStringAsFixed(1)}x faster! 🚀');
    print('');
  }

  Future<void> _demonstrateScreenshots() async {
    print('📸 Screenshot & Video Capture:\n');

    final devices = await adb.getDevices();

    if (devices.isEmpty) {
      print('   ⚠️  Skipped - no devices connected\n');
      print('   💡 With a connected device, this would:');
      print('      1. Capture screenshot on test failure');
      print('      2. Save to: test_reports/screenshots/');
      print('      3. Record video of entire test run');
      print('      4. Create GIF from screenshot sequence');
      print('      5. Clean up old screenshots (7+ days)\n');
      return;
    }

    print('   📁 Output directory: ${screenshotCapturer.outputDirectory}');
    print('   📱 Target device: ${devices.first}\n');

    print('   🎯 Available Capture Methods:\n');
    print('      1. captureScreenshot() - Single screenshot');
    print('      2. captureOnFailure() - Auto-capture when test fails');
    print('      3. startRecording() / stopRecording() - Video recording');
    print('      4. captureSequence() - Multiple screenshots at intervals');
    print('      5. createGif() - Convert screenshots to GIF\n');

    print('   📝 Example Usage:');
    print('      ```dart');
    print('      final capturer = ScreenshotCapturer(adb);');
    print('      ');
    print('      // Capture on failure');
    print('      if (!testPassed) {');
    print('        await capturer.captureOnFailure(');
    print('          deviceId,');
    print('          "login_test",');
    print('          errorMessage,');
    print('        );');
    print('      }');
    print('      ```\n');

    print('   🎬 Video Recording Example:');
    print('      ```dart');
    print('      // Start recording');
    print('      final process = await capturer.startRecording(');
    print('        deviceId,');
    print('        "complete_flow_test",');
    print('      );');
    print('      ');
    print('      // Run your test...');
    print('      await runTest();');
    print('      ');
    print('      // Stop and download');
    print('      final videoPath = await capturer.stopRecording(');
    print('        deviceId,');
    print('        process,');
    print('        "complete_flow_test",');
    print('      );');
    print('      ```\n');
  }

  Future<void> _demonstrateCaching() async {
    print('💾 Intelligent Test Caching:\n');

    try {
      final cacheManager = CacheManager.instance;
      await cacheManager.initialize();

      final stats = cacheManager.getStats();

      print('   📊 Cache Statistics:');
      print('      • Cached results: ${stats['total_cached_results']}');
      print('      • Passed: ${stats['passed']}');
      print('      • Failed: ${stats['failed']}');
      print('      • Cache size: ${stats['cache_size_mb']} MB');
      print('      • Hit rate: ${stats['cache_hit_rate'] ?? "N/A"}');
      print('');

      print('   💡 How Caching Works:');
      print('      1. Calculates hash of test file content');
      print('      2. If file unchanged, returns cached result instantly');
      print('      3. Saves ~95% of test execution time for unchanged tests');
      print('      4. Automatically invalidates cache when file changes');
      print('');

      print('   📝 Example: Test result cached');
      final testEntry = CacheEntry(
        key: 'example/integration_test/login_test.dart',
        hash: 'abc123def456',
        timestamp: DateTime.now(),
        payload: {
          'passed': true,
          'duration': 12.5,
          'deviceId': 'emulator-5554',
        },
        namespace: 'test_results',
      );

      await cacheManager.saveEntry(testEntry);

      final retrieved = cacheManager.getEntry(
        key: 'example/integration_test/login_test.dart',
        hash: 'abc123def456',
        namespace: 'test_results',
      );

      print('      ✅ Entry saved and retrieved: ${retrieved != null}');
      print('      ⚡ Cache hit = ~0.3s vs ~12.5s (40x faster!)');
      print('');
    } catch (e) {
      print('   ⚠️  Error accessing cache: $e\n');
    }
  }
}
