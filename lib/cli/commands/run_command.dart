import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../../core/cache/cache_manager.dart';
import '../../core/models/test_result.dart';
import '../../native/native_handler.dart';
import '../../native/permission_granter.dart';

/// Run command - executes integration tests
class RunCommand extends Command<int> {
  RunCommand() {
    argParser
      ..addOption('device', abbr: 'd', help: 'Device ID to run tests on.')
      ..addOption(
        'platform',
        allowed: ['android', 'ios'],
        defaultsTo: 'android',
        help: 'Platform to run tests on.',
      )
      ..addFlag(
        'cache',
        defaultsTo: true,
        help: 'Use cached results if test unchanged.',
      )
      ..addOption(
        'retry',
        defaultsTo: '2',
        help: 'Number of times to retry failed tests.',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        negatable: false,
        help: 'Enable verbose logging.',
      )
      ..addFlag(
        'screenshot',
        defaultsTo: true,
        help: 'Take screenshots on failure.',
      )
      ..addOption(
        'report',
        allowed: ['html', 'json', 'junit', 'all'],
        defaultsTo: 'html',
        help: 'Report format.',
      )
      ..addOption(
        'concurrency',
        abbr: 'j',
        defaultsTo: '3',
        help: 'Number of tests to run in parallel.',
      )
      ..addFlag(
        'parallel',
        defaultsTo: false,
        help: 'Run multiple tests in parallel.',
      )
      // NEW: Native handling options
      ..addOption(
        'app-id',
        abbr: 'p',
        help:
            'Package name of the app under test (required for native features).',
        valueHelp: 'com.example.app',
      )
      ..addFlag(
        'native-watcher',
        help: 'Enable native dialog watcher (auto-dismiss dialogs).',
        defaultsTo: false,
      )
      ..addOption(
        'pre-grant-permissions',
        help: 'Pre-grant permissions mode.',
        allowed: ['none', 'common', 'all', 'custom'],
        defaultsTo: 'none',
      )
      ..addOption(
        'custom-permissions',
        help: 'Comma-separated list of custom permissions to grant.',
        valueHelp: 'CAMERA,LOCATION',
      )
      ..addFlag(
        'disable-animations',
        help: 'Disable device animations during test.',
        defaultsTo: true,
      )
      ..addFlag(
        'clear-app-data',
        help: 'Clear app data before running test.',
        defaultsTo: false,
      );
  }

  @override
  String get description => 'Run integration tests';

  @override
  String get name => 'run';

  @override
  Future<int> run() async {
    final logger = Logger();
    final testPath = argResults?.rest.firstOrNull;

    if (testPath == null) {
      logger.err('❌ No test file specified');
      logger.info('Usage: flutter_test_pilot run <test_file>');
      logger.info(
        'Example: flutter_test_pilot run integration_test/login_test.dart',
      );
      return 1;
    }

    final deviceId = argResults?['device'] as String?;
    final platform = argResults?['platform'] as String;
    final useCache = argResults?['cache'] as bool;
    final retry = int.parse(argResults?['retry'] as String);
    final verbose = argResults?['verbose'] as bool? ?? false;

    // NEW: Native options
    final packageName = argResults?['app-id'] as String?;
    final useNativeWatcher = argResults?['native-watcher'] as bool? ?? false;
    final permissionModeStr =
        argResults?['pre-grant-permissions'] as String? ?? 'none';
    final customPermissionsStr = argResults?['custom-permissions'] as String?;
    final disableAnimations =
        argResults?['disable-animations'] as bool? ?? true;
    final clearAppData = argResults?['clear-app-data'] as bool? ?? false;

    logger.info('🚀 Flutter Test Pilot v2.0.0\n');

    // Check if test file exists
    final testFile = File(testPath);
    if (!testFile.existsSync()) {
      logger.err('❌ Test file not found: $testPath');
      return 1;
    }

    // Validate native options
    final useNativeFeatures = useNativeWatcher || permissionModeStr != 'none';
    if (useNativeFeatures && platform == 'android' && packageName == null) {
      logger.err('❌ --app-id is required when using native features');
      logger.info('Example: --app-id=com.example.myapp');
      return 1;
    }

    // Initialize cache manager
    final cacheManager = CacheManager.instance;
    await cacheManager.initialize();

    // Check cache
    if (useCache) {
      final cachedResult = await cacheManager.getCachedResult(testFile);
      if (cachedResult != null) {
        logger.success('⚡ Using cached result (test unchanged)');
        logger.info('Last run: ${_formatTimestamp(cachedResult.timestamp)}');
        logger.info(
          'Duration: ${cachedResult.duration.inSeconds}s (cached: ~0.3s)\n',
        );

        if (cachedResult.passed) {
          logger.success('✅ Test passed (from cache)');
          logger.info('📊 Run with --no-cache to force re-run');
          return 0;
        } else {
          logger.err('❌ Test failed (from cache)');
          logger.info('Error: ${cachedResult.errorMessage ?? "Unknown error"}');
          logger.info('📊 Run with --no-cache to retry');
          return 1;
        }
      } else {
        logger.info('📝 No cached result found, running test...\n');
      }
    }

    // Select device
    final selectedDevice = await _selectDevice(logger, deviceId, platform);
    if (selectedDevice == null) {
      logger.err('❌ No suitable device found');
      logger.info('Run: flutter_test_pilot devices');
      return 1;
    }

    logger.info('📱 Device: $selectedDevice');
    logger.info('📝 Test: $testPath');

    if (useNativeFeatures) {
      logger.info('🤖 Native features: enabled');
      if (useNativeWatcher) logger.info('  • Dialog watcher: enabled');
      if (permissionModeStr != 'none')
        logger.info('  • Permissions: $permissionModeStr');
      if (disableAnimations) logger.info('  • Animations: disabled');
    }
    logger.info('');

    final startTime = DateTime.now();

    try {
      TestResult result;

      if (useNativeFeatures && platform == 'android') {
        // Run with native support
        result = await _runTestWithNativeSupport(
          logger,
          testFile,
          selectedDevice,
          packageName!,
          permissionModeStr,
          customPermissionsStr,
          useNativeWatcher,
          disableAnimations,
          clearAppData,
          verbose,
        );
      } else {
        // Run basic mode
        final progress = logger.progress('Building app and running test');
        final processResult = await _runTest(
          testPath,
          selectedDevice,
          platform,
          verbose,
        );

        final duration = DateTime.now().difference(startTime);

        if (processResult.exitCode == 0) {
          progress.complete('✅ Test passed (${duration.inSeconds}s)');
        } else {
          progress.fail('❌ Test failed (${duration.inSeconds}s)');
        }

        result = TestResult(
          testPath: testFile.path,
          testHash: cacheManager.calculateFileHash(testFile),
          passed: processResult.exitCode == 0,
          duration: duration,
          timestamp: DateTime.now(),
          deviceId: selectedDevice,
          errorMessage: processResult.exitCode != 0
              ? _truncateErrorMessage(processResult.stderr.toString(), 500)
              : null,
        );
      }

      // Cache the result
      if (useCache) {
        await cacheManager.saveResult(result);
        logger.info('💾 Result cached for future runs');
      }

      if (result.passed) {
        logger.info('');
        logger.success('🎉 All tests passed!');
        logger.info('📊 Duration: ${result.duration.inSeconds}s');
        return 0;
      } else {
        if (retry > 0) {
          logger.info('🔄 Retrying ($retry attempts remaining)...\n');
          // TODO: Implement retry logic
        }

        logger.info('');
        logger.err('❌ Tests failed');
        if (result.errorMessage != null) {
          logger.detail('Error: ${result.errorMessage}');
        }
        return 1;
      }
    } catch (e, stackTrace) {
      logger.err('❌ Error running test: $e');
      if (verbose) {
        logger.detail('Stack trace:\n$stackTrace');
      }
      return 1;
    }
  }

  Future<TestResult> _runTestWithNativeSupport(
    Logger logger,
    File testFile,
    String deviceId,
    String packageName,
    String permissionMode,
    String? customPermissionsStr,
    bool useNativeWatcher,
    bool disableAnimations,
    bool clearAppData,
    bool verbose,
  ) async {
    final handler = NativeHandler();

    // Parse custom permissions
    final customPermissions = customPermissionsStr
        ?.split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    // Parse permission mode
    final permMode = _parsePermissionMode(permissionMode);

    final options = NativeOptions(
      packageName: packageName,
      permissionMode: permMode,
      customPermissions: customPermissions,
      enableWatcher: useNativeWatcher,
      disableAnimations: disableAnimations,
      clearAppData: clearAppData,
      verbose: verbose,
    );

    return await handler.runWithNativeSupport(
      deviceId: deviceId,
      testFile: testFile.path,
      packageName: packageName,
      options: options,
      testRunner: () async {
        final startTime = DateTime.now();

        // Build and run the integration test
        // This command builds the app, installs it, and runs the test
        logger.info('🔨 Building and installing app...');

        final result = await _runIntegrationTestWithBuild(
          testFile.path,
          deviceId,
          verbose,
          logger,
        );

        return TestResult(
          testPath: testFile.path,
          testHash: CacheManager.instance.calculateFileHash(testFile),
          passed: result.exitCode == 0,
          duration: DateTime.now().difference(startTime),
          timestamp: DateTime.now(),
          deviceId: deviceId,
          errorMessage: result.exitCode != 0
              ? _truncateErrorMessage(result.stderr.toString(), 500)
              : null,
        );
      },
    );
  }

  /// Run integration test with full app build and install
  Future<ProcessResult> _runIntegrationTestWithBuild(
    String testPath,
    String deviceId,
    bool verbose,
    Logger logger,
  ) async {
    // Determine the app directory and relative test path
    // If testPath is like "example/integration_test/test.dart"
    // we need to run from "example" with "integration_test/test.dart"

    final testFile = File(testPath);

    // Find the Flutter app directory (contains pubspec.yaml)
    String? appDir;
    String? relativeTestPath;

    // Check if test path contains "example/" or similar app directory
    if (testPath.contains('example/')) {
      appDir = testPath.split('example/')[0] + 'example';
      relativeTestPath = testPath.split('example/')[1];
    } else if (testPath.contains('integration_test/')) {
      // Test is in current directory
      appDir = Directory.current.path;
      relativeTestPath = testPath;
    } else {
      // Try to find pubspec.yaml
      var dir = testFile.parent;
      while (dir.path != dir.parent.path) {
        if (File('${dir.path}/pubspec.yaml').existsSync()) {
          appDir = dir.path;
          relativeTestPath = testFile.path.replaceFirst('${dir.path}/', '');
          break;
        }
        dir = dir.parent;
      }
    }

    if (appDir == null) {
      throw Exception(
        'Could not find Flutter app directory (no pubspec.yaml found)',
      );
    }

    logger.info('📂 App directory: $appDir');
    logger.info('📝 Relative test path: $relativeTestPath');

    final args = [
      'test',
      relativeTestPath!,
      '--device-id=$deviceId',
      if (verbose) '--verbose',
    ];

    logger.info('📦 Command: cd $appDir && flutter ${args.join(' ')}');
    logger.info(
      '⏳ This may take a few moments (building + installing app)...\n',
    );

    // Run the test from the app directory
    final process = await Process.start(
      'flutter',
      args,
      workingDirectory: appDir,
      runInShell: true,
    );

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    // Stream output to console AND capture it
    process.stdout.transform(SystemEncoding().decoder).listen((data) {
      stdout.write(data);
      stdoutBuffer.write(data);
    });

    process.stderr.transform(SystemEncoding().decoder).listen((data) {
      stderr.write(data);
      stderrBuffer.write(data);
    });

    final exitCode = await process.exitCode;

    // Return a ProcessResult with captured output
    return ProcessResult(
      process.pid,
      exitCode,
      stdoutBuffer.toString(),
      stderrBuffer.toString(),
    );
  }

  PermissionMode _parsePermissionMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'common':
        return PermissionMode.common;
      case 'all':
        return PermissionMode.all;
      case 'custom':
        return PermissionMode.custom;
      default:
        return PermissionMode.none;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  Future<String?> _selectDevice(
    Logger logger,
    String? deviceId,
    String platform,
  ) async {
    if (deviceId != null) {
      return deviceId;
    }

    // Auto-select first available device
    try {
      if (platform == 'android') {
        final result = await Process.run('adb', ['devices']);
        final output = result.stdout.toString();
        final lines = output
            .split('\n')
            .skip(1)
            .where((l) => l.contains('device'))
            .toList();

        if (lines.isNotEmpty) {
          final deviceLine = lines.first.trim();
          final deviceId = deviceLine.split(RegExp(r'\s+'))[0];
          return deviceId;
        }
      } else if (platform == 'ios' && Platform.isMacOS) {
        final result = await Process.run('xcrun', [
          'simctl',
          'list',
          'devices',
          'available',
          'booted',
        ]);
        final output = result.stdout.toString();
        final lines = output
            .split('\n')
            .where((l) => l.contains('iPhone') && l.contains('Booted'))
            .toList();

        if (lines.isNotEmpty) {
          final match = RegExp(r'\(([A-F0-9-]+)\)').firstMatch(lines.first);
          if (match != null) {
            return match.group(1);
          }
        }
      }
    } catch (e) {
      logger.err('Error selecting device: $e');
    }

    return null;
  }

  Future<ProcessResult> _runTest(
    String testPath,
    String deviceId,
    String platform,
    bool verbose,
  ) async {
    // Check if this is an integration test
    final isIntegrationTest = testPath.contains('integration_test');

    List<String> args;

    if (isIntegrationTest) {
      // For integration tests, use flutter test integration_test/
      // This automatically:
      // 1. Builds the app with test instrumentation
      // 2. Installs it on the device
      // 3. Launches the app
      // 4. Runs the tests
      args = [
        'test',
        testPath,
        '--device-id=$deviceId',
        '--dart-define=INTEGRATION_TEST=true',
        if (verbose) '--verbose',
      ];

      print('\n🔧 Running integration test with app build and install...');
      print('   Command: flutter ${args.join(' ')}\n');
    } else {
      // Regular widget tests
      args = ['test', testPath, '-d', deviceId, if (verbose) '--verbose'];
      print('\n🔧 Running widget test: flutter ${args.join(' ')}\n');
    }

    // Run the test and capture output in real-time
    final process = await Process.start('flutter', args);

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    // Stream output to console AND capture it
    process.stdout.transform(SystemEncoding().decoder).listen((data) {
      stdout.write(data);
      stdoutBuffer.write(data);
    });

    process.stderr.transform(SystemEncoding().decoder).listen((data) {
      stderr.write(data);
      stderrBuffer.write(data);
    });

    final exitCode = await process.exitCode;

    // Return a ProcessResult with captured output
    return ProcessResult(
      process.pid,
      exitCode,
      stdoutBuffer.toString(),
      stderrBuffer.toString(),
    );
  }

  String _truncateErrorMessage(String errorMessage, int maxLength) {
    return errorMessage.length > maxLength
        ? errorMessage.substring(0, maxLength)
        : errorMessage;
  }
}
