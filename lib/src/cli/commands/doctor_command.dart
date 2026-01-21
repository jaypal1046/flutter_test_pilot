import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import '../../core/device/device_manager.dart';

/// Doctor command - validates environment setup
class DoctorCommand extends Command<int> {
  DoctorCommand() {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show detailed information.',
    );
  }

  @override
  String get description =>
      'Check your environment setup for Flutter Test Pilot';

  @override
  String get name => 'doctor';

  @override
  Future<int> run() async {
    final logger = Logger();
    logger.info('🔍 Flutter Test Pilot Environment Check\n');

    final checks = <String, Future<bool>>{
      'Flutter SDK': _checkFlutter(),
      'Dart SDK': _checkDart(),
      'Android SDK (ADB)': DeviceManager.instance.isAdbInstalled(),
      'Xcode (iOS)': DeviceManager.instance.isXcodeInstalled(),
      'Git': _checkGit(),
    };

    var allPassed = true;

    for (final entry in checks.entries) {
      final name = entry.key;
      final checkFuture = entry.value;

      final result = await checkFuture;

      if (result) {
        logger.success('✅ $name');
      } else {
        logger.err('❌ $name');
        allPassed = false;
      }
    }

    logger.info('');

    // Check for devices
    final deviceManager = DeviceManager.instance;
    final androidDevices = await deviceManager.getAndroidDevices();
    final iosDevices = await deviceManager.getIOSDevices();
    final totalDevices = androidDevices.length + iosDevices.length;

    if (totalDevices > 0) {
      logger.success('✅ $totalDevices device(s) available');
    } else {
      logger.warn('⚠️  No devices found');
    }

    logger.info('');

    if (allPassed && totalDevices > 0) {
      logger.success('🎉 Your environment is ready for testing!');
      logger.info('');
      logger.info('Next steps:');
      logger.info(
        '  1. flutter_test_pilot init        # Initialize configuration',
      );
      logger.info(
        '  2. flutter_test_pilot devices     # List available devices',
      );
      logger.info(
        '  3. flutter_test_pilot run <test>  # Run integration tests',
      );
      return 0;
    } else {
      logger.err(
        '⚠️  Some checks failed. Please install missing dependencies.',
      );
      return 1;
    }
  }

  Future<bool> _checkFlutter() async {
    final logger = Logger();
    try {
      final result = await Process.run('flutter', ['--version']);
      if (result.exitCode == 0) {
        final version = result.stdout.toString().split('\n').first;
        logger.success('✅ Flutter SDK: $version');
        return true;
      }
    } catch (e) {
      logger.err('❌ Flutter SDK: Not found or not in PATH');
      logger.info(
        '   Install from: https://flutter.dev/docs/get-started/install',
      );
    }
    return false;
  }

  Future<bool> _checkDart() async {
    final logger = Logger();
    try {
      final result = await Process.run('dart', ['--version']);
      if (result.exitCode == 0) {
        final version = result.stdout.toString().split('\n').first;
        logger.success('✅ Dart SDK: $version');
        return true;
      }
    } catch (e) {
      logger.err('❌ Dart SDK: Not found or not in PATH');
      logger.info('   Install from: https://dart.dev/get-dart');
    }
    return false;
  }

  Future<bool> _checkGit() async {
    final logger = Logger();
    try {
      final result = await Process.run('git', ['--version']);
      if (result.exitCode == 0) {
        final version = result.stdout.toString().split('\n').first;
        logger.success('✅ Git: $version');
        return true;
      }
    } catch (e) {
      logger.err('❌ Git: Not found or not in PATH');
      logger.info('   Install from: https://git-scm.com/downloads');
    }
    return false;
  }
}
