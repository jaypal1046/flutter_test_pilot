import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

/// Config command - manages configuration
class ConfigCommand extends Command<int> {
  ConfigCommand() {
    argParser
      ..addFlag('show', negatable: false, help: 'Show current configuration.')
      ..addOption(
        'set',
        help: 'Set a configuration value (e.g., device.platform=android)',
      );
  }

  @override
  String get description => 'Manage Flutter Test Pilot configuration';

  @override
  String get name => 'config';

  @override
  Future<int> run() async {
    final logger = Logger();
    final show = argResults?['show'] as bool? ?? false;
    final setValue = argResults?['set'] as String?;

    final configPath = path.join(Directory.current.path, '.testpilot.yaml');

    if (!File(configPath).existsSync()) {
      logger.err('❌ Configuration file not found: .testpilot.yaml');
      logger.info('Run: flutter_test_pilot init');
      return 1;
    }

    if (show || (setValue == null)) {
      await _showConfig(logger, configPath);
      return 0;
    }

    if (setValue != null) {
      await _setConfig(logger, configPath, setValue);
      return 0;
    }

    return 0;
  }

  Future<void> _showConfig(Logger logger, String configPath) async {
    logger.info('⚙️  Current Configuration\n');
    final content = await File(configPath).readAsString();
    logger.info(content);
  }

  Future<void> _setConfig(
    Logger logger,
    String configPath,
    String value,
  ) async {
    final parts = value.split('=');
    if (parts.length != 2) {
      logger.err('❌ Invalid format. Use: key=value');
      return;
    }

    final key = parts[0].trim();
    final newValue = parts[1].trim();

    logger.info('Setting $key = $newValue');
    logger.warn('⚠️  Manual editing of .testpilot.yaml recommended');
  }
}
