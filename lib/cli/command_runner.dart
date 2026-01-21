import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'commands/run_command.dart';
import 'commands/doctor_command.dart';
import 'commands/devices_command.dart';
import 'commands/init_command.dart';
import 'commands/config_command.dart';
import 'commands/cache_command.dart';

/// Main command runner for Flutter Test Pilot CLI
class TestPilotCommandRunner extends CommandRunner<int> {
  TestPilotCommandRunner()
    : super(
        'flutter_test_pilot',
        '🚀 Advanced Flutter integration testing CLI with native action handling',
      ) {
    argParser
      ..addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: 'Print the current version.',
      )
      ..addFlag('verbose', negatable: false, help: 'Enable verbose logging.');

    addCommand(RunCommand());
    addCommand(DoctorCommand());
    addCommand(DevicesCommand());
    addCommand(InitCommand());
    addCommand(ConfigCommand());
    addCommand(CacheCommand());
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final argResults = parse(args);

      if (argResults['version'] as bool) {
        _printVersion();
        return 0;
      }

      return await runCommand(argResults) ?? 0;
    } on UsageException catch (e) {
      Logger().err(e.message);
      Logger().info(e.usage);
      return 1;
    } catch (e) {
      Logger().err('Unexpected error: $e');
      return 1;
    }
  }

  void _printVersion() {
    final logger = Logger();
    logger.info('🚀 Flutter Test Pilot CLI v2.0.0');
    logger.info('Enterprise-grade Flutter testing automation');
  }
}
