import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../../core/device/device_manager.dart';

/// Devices command - lists available testing devices
class DevicesCommand extends Command<int> {
  DevicesCommand() {
    argParser.addFlag(
      'android',
      abbr: 'a',
      negatable: false,
      help: 'Show only Android devices.',
    );
    argParser.addFlag(
      'ios',
      abbr: 'i',
      negatable: false,
      help: 'Show only iOS simulators.',
    );
  }

  @override
  String get description => 'List available devices and simulators';

  @override
  String get name => 'devices';

  @override
  Future<int> run() async {
    final logger = Logger();
    final androidOnly = argResults?['android'] as bool? ?? false;
    final iosOnly = argResults?['ios'] as bool? ?? false;

    final progress = logger.progress('Scanning for devices');
    final deviceManager = DeviceManager.instance;

    try {
      // Get devices based on filters
      List<DeviceInfo> devices;
      if (androidOnly) {
        devices = await deviceManager.getAndroidDevices();
      } else if (iosOnly) {
        devices = await deviceManager.getIOSDevices();
      } else {
        devices = await deviceManager.getAllDevices();
      }

      progress.complete('Found ${devices.length} device(s)');

      if (devices.isEmpty) {
        logger.info('\n📱 No devices found');
        logger.info('');
        logger.info('Tips:');
        logger.info('  • Connect an Android device via USB');
        logger.info('  • Start an Android emulator');
        if (Platform.isMacOS) {
          logger.info('  • Boot an iOS simulator: open -a Simulator');
        }
        return 1;
      }

      // Group by platform
      final androidDevices = devices
          .where((d) => d.platform == 'android')
          .toList();
      final iosDevices = devices.where((d) => d.platform == 'ios').toList();

      logger.info('');

      // Display Android devices
      if (androidDevices.isNotEmpty && !iosOnly) {
        logger.info('🤖 Android Devices:');
        for (final device in androidDevices) {
          final statusIcon = device.isAvailable ? '✅' : '⚠️';
          final versionInfo = device.version != null
              ? ' [Android ${device.version}]'
              : '';
          logger.info(
            '  $statusIcon ${device.id}$versionInfo - ${device.name}',
          );
        }
        logger.info('');
      }

      // Display iOS devices
      if (iosDevices.isNotEmpty && !androidOnly) {
        logger.info('🍎 iOS Simulators:');
        for (final device in iosDevices) {
          final statusIcon = device.status == 'Booted' ? '✅' : '⚪';
          logger.info('  $statusIcon ${device.id} (${device.status}) - ${device.name}');
        }
        logger.info('');
      }

      // Show usage tip
      final availableCount = devices.where((d) => d.isAvailable).length;
      if (availableCount > 0) {
        logger.success('$availableCount device(s) ready for testing');
        logger.info('');
        logger.info(
          'Run tests: flutter_test_pilot run <test_file> --device <device_id>',
        );
      } else {
        logger.warn('No devices are currently available');
        logger.info('Start an emulator/simulator first');
      }

      return 0;
    } catch (e) {
      progress.fail('Error scanning devices');
      logger.err('Error: $e');
      return 1;
    }
  }
}
