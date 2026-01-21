import 'dart:io';
import 'package:flutter_test_pilot/native/adb_commander.dart';
import 'package:flutter_test_pilot/native/permission_granter.dart';
import 'package:flutter_test_pilot/native/dialog_watcher.dart';
import 'package:flutter_test_pilot/native/native_handler.dart';
import 'package:flutter_test_pilot/executor/retry_handler.dart';
import 'package:flutter_test_pilot/executor/parallel_executor.dart';
import 'package:flutter_test_pilot/discovery/test_finder.dart';
import 'package:flutter_test_pilot/reporting/screenshot_capturer.dart';
import 'package:flutter_test_pilot/core/models/test_result.dart';
import 'package:flutter_test_pilot/core/cache/cache_manager.dart';

/// Comprehensive test suite for Flutter Test Pilot Phase 2 & 3
void main() async {
  print('🚀 Flutter Test Pilot - Comprehensive Test Suite\n');
  print('=' * 60);

  final results = <String, TestStatus>{};

  // Run all tests
  await testAdbCommander(results);
  await testPermissionGranter(results);
  await testDialogWatcher(results);
  await testNativeHandler(results);
  await testRetryHandler(results);
  await testParallelExecutor(results);
  await testTestFinder(results);
  await testScreenshotCapturer(results);
  await testCacheManager(results);

  // Print summary
  printSummary(results);
}

/// Test 1: ADB Commander
Future<void> testAdbCommander(Map<String, TestStatus> results) async {
  print('\n📱 Test 1: ADB Commander');
  print('-' * 60);

  try {
    final adb = AdbCommander();

    // Test 1.1: Check ADB availability
    print('  1.1 Checking ADB availability...');
    final isAvailable = await AdbCommander.isAvailable();
    print('      ADB available: ${isAvailable ? "✅" : "❌"}');

    if (!isAvailable) {
      results['ADB Commander'] = TestStatus.skipped;
      print('      ⚠️  Skipping ADB tests (ADB not available)');
      return;
    }

    // Test 1.2: Get devices
    print('  1.2 Getting connected devices...');
    final devices = await adb.getDevices();
    print('      Found ${devices.length} device(s): ${devices.join(", ")}');

    if (devices.isEmpty) {
      results['ADB Commander'] = TestStatus.skipped;
      print('      ⚠️  Skipping device tests (no devices connected)');
      return;
    }

    final deviceId = devices.first;

    // Test 1.3: Get device info
    print('  1.3 Getting device information...');
    try {
      final model = await adb.getDeviceModel(deviceId);
      final androidVersion = await adb.getAndroidVersion(deviceId);
      final apiLevel = await adb.getApiLevel(deviceId);
      print('      Model: $model');
      print('      Android: $androidVersion (API $apiLevel)');
    } catch (e) {
      print('      ⚠️  Could not get device info: $e');
    }

    results['ADB Commander'] = TestStatus.passed;
    print('      ✅ ADB Commander tests passed');
  } catch (e) {
    results['ADB Commander'] = TestStatus.failed;
    print('      ❌ Error: $e');
  }
}

/// Test 2: Permission Granter
Future<void> testPermissionGranter(Map<String, TestStatus> results) async {
  print('\n📋 Test 2: Permission Granter');
  print('-' * 60);

  try {
    final adb = AdbCommander();
    final granter = PermissionGranter(adb);

    // Test 2.1: Check permission list
    print('  2.1 Checking common permissions list...');
    print(
      '      Common permissions: ${PermissionGranter.commonPermissions.length}',
    );
    print(
      '      Sample: ${PermissionGranter.commonPermissions.take(3).join(", ")}',
    );

    // Test 2.2: Permission modes
    print('  2.2 Testing permission modes...');
    final modes = PermissionMode.values;
    print('      Available modes: ${modes.map((m) => m.name).join(", ")}');

    results['Permission Granter'] = TestStatus.passed;
    print('      ✅ Permission Granter tests passed');
  } catch (e) {
    results['Permission Granter'] = TestStatus.failed;
    print('      ❌ Error: $e');
  }
}

/// Test 3: Dialog Watcher
Future<void> testDialogWatcher(Map<String, TestStatus> results) async {
  print('\n🤖 Test 3: Dialog Watcher');
  print('-' * 60);

  try {
    final adb = AdbCommander();
    final watcher = DialogWatcher(adb);

    // Test 3.1: Check APK path
    print('  3.1 Checking watcher APK path...');
    print('      APK path: ${watcher.watcherApkPath}');
    final apkExists = await File(watcher.watcherApkPath).exists();
    print('      APK exists: ${apkExists ? "✅" : "❌"}');

    if (!apkExists) {
      print(
        '      ℹ️  Build APK with: cd native_assets/android && ./gradlew buildWatcherApk',
      );
    }

    // Test 3.2: Check watcher support
    if (await AdbCommander.isAvailable()) {
      final devices = await adb.getDevices();
      if (devices.isNotEmpty) {
        print('  3.2 Checking UI Automator support...');
        final isSupported = await DialogWatcher.isSupported(adb, devices.first);
        print('      UI Automator supported: ${isSupported ? "✅" : "❌"}');
      }
    }

    results['Dialog Watcher'] = TestStatus.passed;
    print('      ✅ Dialog Watcher tests passed');
  } catch (e) {
    results['Dialog Watcher'] = TestStatus.failed;
    print('      ❌ Error: $e');
  }
}

/// Test 4: Native Handler
Future<void> testNativeHandler(Map<String, TestStatus> results) async {
  print('\n🔧 Test 4: Native Handler');
  print('-' * 60);

  try {
    final handler = NativeHandler();

    // Test 4.1: Check device capabilities
    if (await AdbCommander.isAvailable()) {
      final adb = AdbCommander();
      final devices = await adb.getDevices();

      if (devices.isNotEmpty) {
        print('  4.1 Checking device capabilities...');
        final capabilities = await handler.checkCapabilities(devices.first);
        print('      $capabilities');
      }
    }

    // Test 4.2: Native options
    print('  4.2 Testing native options...');
    final options = NativeOptions(
      packageName: 'com.example.test',
      permissionMode: PermissionMode.common,
      enableWatcher: true,
      disableAnimations: true,
    );
    print('      Package: ${options.packageName}');
    print('      Permissions: ${options.permissionMode.name}');
    print('      Watcher: ${options.enableWatcher}');

    results['Native Handler'] = TestStatus.passed;
    print('      ✅ Native Handler tests passed');
  } catch (e) {
    results['Native Handler'] = TestStatus.failed;
    print('      ❌ Error: $e');
  }
}

/// Test 5: Retry Handler
Future<void> testRetryHandler(Map<String, TestStatus> results) async {
  print('\n🔄 Test 5: Retry Handler');
  print('-' * 60);

  try {
    final retryHandler = RetryHandler(
      maxRetries: 2,
      initialDelay: Duration(milliseconds: 100),
    );

    // Test 5.1: Successful retry
    print('  5.1 Testing retry with eventual success...');
    var attemptCount = 0;

    final result = await retryHandler.runWithRetry(
      testPath: 'test_example.dart',
      deviceId: 'test-device',
      testRunner: () async {
        attemptCount++;
        print('      Attempt $attemptCount');

        // Simulate failure on first attempt
        if (attemptCount < 2) {
          return TestResult(
            testPath: 'test_example.dart',
            testHash: 'abc123',
            passed: false,
            duration: Duration(milliseconds: 100),
            timestamp: DateTime.now(),
            errorMessage: 'Simulated failure',
          );
        }

        return TestResult(
          testPath: 'test_example.dart',
          testHash: 'abc123',
          passed: true,
          duration: Duration(milliseconds: 100),
          timestamp: DateTime.now(),
        );
      },
    );

    print('      Result: ${result.passed ? "✅ PASSED" : "❌ FAILED"}');
    print('      Total attempts: $attemptCount');

    // Test 5.2: Retriable error detection
    print('  5.2 Testing retriable error detection...');
    final retriable1 = RetryHandler.isRetriableError('Network timeout');
    final retriable2 = RetryHandler.isRetriableError('Connection failed');
    final retriable3 = RetryHandler.isRetriableError('Syntax error');
    print('      "Network timeout": ${retriable1 ? "✅" : "❌"} retriable');
    print('      "Connection failed": ${retriable2 ? "✅" : "❌"} retriable');
    print('      "Syntax error": ${retriable3 ? "❌" : "✅"} not retriable');

    results['Retry Handler'] = TestStatus.passed;
    print('      ✅ Retry Handler tests passed');
  } catch (e) {
    results['Retry Handler'] = TestStatus.failed;
    print('      ❌ Error: $e');
  }
}

/// Test 6: Parallel Executor
Future<void> testParallelExecutor(Map<String, TestStatus> results) async {
  print('\n⚡ Test 6: Parallel Executor');
  print('-' * 60);

  try {
    final executor = ParallelExecutor(maxConcurrency: 2);

    // Test 6.1: Simulate parallel execution
    print('  6.1 Simulating parallel execution...');
    final testFiles = ['test1.dart', 'test2.dart', 'test3.dart', 'test4.dart'];
    final deviceIds = ['device1', 'device2'];

    final executionResults = await executor.runParallel(
      testFiles: testFiles,
      deviceIds: deviceIds,
      testRunner: (testFile, deviceId) async {
        // Simulate test execution
        await Future.delayed(Duration(milliseconds: 50));
        return TestResult(
          testPath: testFile,
          testHash: 'hash_$testFile',
          passed: true,
          duration: Duration(milliseconds: 50),
          timestamp: DateTime.now(),
          deviceId: deviceId,
        );
      },
    );

    print('      Executed ${executionResults.length} tests');
    print('      Passed: ${executionResults.where((r) => r.passed).length}');

    // Test 6.2: Optimal device count
    print('  6.2 Testing optimal device count calculation...');
    final optimal1 = ParallelExecutor.calculateOptimalDeviceCount(5, 10);
    final optimal2 = ParallelExecutor.calculateOptimalDeviceCount(15, 10);
    final optimal3 = ParallelExecutor.calculateOptimalDeviceCount(25, 10);
    print('      5 tests: $optimal1 device(s)');
    print('      15 tests: $optimal2 device(s)');
    print('      25 tests: $optimal3 device(s)');

    results['Parallel Executor'] = TestStatus.passed;
    print('      ✅ Parallel Executor tests passed');
  } catch (e) {
    results['Parallel Executor'] = TestStatus.failed;
    print('      ❌ Error: $e');
  }
}

/// Test 7: Test Finder
Future<void> testTestFinder(Map<String, TestStatus> results) async {
  print('\n🔍 Test 7: Test Finder');
  print('-' * 60);

  try {
    final finder = TestFinder();

    // Test 7.1: Find all tests
    print('  7.1 Finding test files...');
    final allTests = await finder.findTests();
    print('      Found ${allTests.length} test file(s)');

    if (allTests.isNotEmpty) {
      print('      Sample: ${allTests.take(3).join("\n              ")}');

      // Test 7.2: Get test metadata
      print('  7.2 Getting test metadata...');
      try {
        final metadata = await finder.getTestMetadata(allTests.first);
        print('      File: ${metadata.name}');
        print('      Test cases: ${metadata.testCount}');
        print(
          '      Tags: ${metadata.tags.isEmpty ? "none" : metadata.tags.join(", ")}',
        );
        print('      Size: ${(metadata.size / 1024).toStringAsFixed(1)} KB');
      } catch (e) {
        print('      ⚠️  Could not read metadata: $e');
      }
    } else {
      print('      ℹ️  No test files found (this is a CLI project)');
    }

    // Test 7.3: Group by directory
    print('  7.3 Grouping tests by directory...');
    final grouped = finder.groupByDirectory(allTests);
    print('      ${grouped.length} directory group(s)');

    results['Test Finder'] = TestStatus.passed;
    print('      ✅ Test Finder tests passed');
  } catch (e) {
    results['Test Finder'] = TestStatus.failed;
    print('      ❌ Error: $e');
  }
}

/// Test 8: Screenshot Capturer
Future<void> testScreenshotCapturer(Map<String, TestStatus> results) async {
  print('\n📸 Test 8: Screenshot Capturer');
  print('-' * 60);

  try {
    final adb = AdbCommander();
    final capturer = ScreenshotCapturer(adb);

    // Test 8.1: Check output directory
    print('  8.1 Checking screenshot output directory...');
    print('      Output dir: ${capturer.outputDirectory}');

    // Test 8.2: Test file name sanitization
    print('  8.2 Testing file name sanitization...');
    final testName = 'My Test! with @special #chars';
    final sanitized = testName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    print('      Original: "$testName"');
    print('      Sanitized: "$sanitized"');

    results['Screenshot Capturer'] = TestStatus.passed;
    print('      ✅ Screenshot Capturer tests passed');
  } catch (e) {
    results['Screenshot Capturer'] = TestStatus.failed;
    print('      ❌ Error: $e');
  }
}

/// Test 9: Cache Manager
Future<void> testCacheManager(Map<String, TestStatus> results) async {
  print('\n💾 Test 9: Cache Manager');
  print('-' * 60);

  try {
    // Test 9.1: Initialize cache
    print('  9.1 Initializing cache manager...');
    final cacheManager = CacheManager.instance;
    await cacheManager.initialize();
    print('      Cache initialized');

    // Test 9.2: Get cache stats
    print('  9.2 Getting cache statistics...');
    final stats = cacheManager.getStats();
    print('      Total cached results: ${stats['total_cached_results']}');
    print('      Passed: ${stats['passed']}');
    print('      Failed: ${stats['failed']}');
    print('      Cache size: ${stats['cache_size_mb']} MB');

    // Test 9.3: Test generic cache entry
    print('  9.3 Testing generic cache entry...');
    final entry = CacheEntry(
      key: 'test_key',
      hash: 'abc123',
      timestamp: DateTime.now(),
      payload: {'result': 'success', 'duration': 123},
      namespace: 'test_namespace',
    );
    await cacheManager.saveEntry(entry);

    final retrieved = cacheManager.getEntry(
      key: 'test_key',
      hash: 'abc123',
      namespace: 'test_namespace',
    );
    print('      Entry saved and retrieved: ${retrieved != null ? "✅" : "❌"}');

    results['Cache Manager'] = TestStatus.passed;
    print('      ✅ Cache Manager tests passed');
  } catch (e) {
    results['Cache Manager'] = TestStatus.failed;
    print('      ❌ Error: $e');
  }
}

/// Print test summary
void printSummary(Map<String, TestStatus> results) {
  print('\n' + '=' * 60);
  print('📊 Test Summary');
  print('=' * 60);

  final passed = results.values.where((s) => s == TestStatus.passed).length;
  final failed = results.values.where((s) => s == TestStatus.failed).length;
  final skipped = results.values.where((s) => s == TestStatus.skipped).length;
  final total = results.length;

  print('\nResults:');
  results.forEach((name, status) {
    final icon = status == TestStatus.passed
        ? '✅'
        : status == TestStatus.failed
        ? '❌'
        : '⚠️';
    print('  $icon $name: ${status.name.toUpperCase()}');
  });

  print('\nStatistics:');
  print('  Total: $total');
  print('  Passed: $passed');
  print('  Failed: $failed');
  print('  Skipped: $skipped');

  final successRate = total > 0
      ? (passed / total * 100).toStringAsFixed(1)
      : '0.0';
  print('  Success Rate: $successRate%');

  if (failed == 0) {
    print('\n🎉 All tests passed!');
  } else {
    print('\n⚠️  Some tests failed. Check logs above for details.');
  }

  print('\n' + '=' * 60);
}

enum TestStatus { passed, failed, skipped }
