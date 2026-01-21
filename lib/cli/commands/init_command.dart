import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

/// Init command - initializes a new test project
class InitCommand extends Command<int> {
  InitCommand() {
    argParser.addOption(
      'path',
      abbr: 'p',
      help: 'Path to initialize the project (default: current directory)',
    );
  }

  @override
  String get description => 'Initialize Flutter Test Pilot in your project';

  @override
  String get name => 'init';

  @override
  Future<int> run() async {
    final logger = Logger();
    final targetPath = argResults?['path'] as String? ?? Directory.current.path;

    logger.info('🎉 Initializing Flutter Test Pilot...\n');

    final progress = logger.progress('Creating project structure');

    try {
      // Create directories
      await _createDirectories(targetPath);

      // Create config file
      await _createConfigFile(targetPath);

      // Create test_driver
      await _createTestDriver(targetPath);

      // Create example test
      await _createExampleTest(targetPath);

      progress.complete('✅ Project structure created');

      logger.info('');
      logger.success('✅ Flutter Test Pilot initialized successfully!');
      logger.info('');
      logger.info('📝 Next steps:');
      logger.info('  1. Edit .testpilot.yaml to configure settings');
      logger.info('  2. Run: flutter_test_pilot doctor');
      logger.info(
        '  3. Run: flutter_test_pilot run integration_test/example_test.dart',
      );
      logger.info('');

      return 0;
    } catch (e) {
      progress.fail('Failed to initialize');
      logger.err('Error: $e');
      return 1;
    }
  }

  Future<void> _createDirectories(String basePath) async {
    final dirs = [
      path.join(basePath, 'integration_test'),
      path.join(basePath, 'test_driver'),
      path.join(basePath, 'test_reports'),
    ];

    for (final dir in dirs) {
      await Directory(dir).create(recursive: true);
    }
  }

  Future<void> _createConfigFile(String basePath) async {
    final configPath = path.join(basePath, '.testpilot.yaml');

    if (File(configPath).existsSync()) {
      return; // Don't overwrite existing config
    }

    final config = '''
# Flutter Test Pilot Configuration
version: 2.0

# Device configuration
device:
  auto_select: true
  platform: android
  # Specify device ID (optional)
  # device_id: emulator-5554

# Test configuration
test:
  timeout: 5m
  retry_failures: 2
  retry_delay: 5s
  
# Native handling
native:
  pre_grant_permissions: true
  watcher_enabled: true
  permissions:
    - ACCESS_FINE_LOCATION
    - CAMERA
    - READ_EXTERNAL_STORAGE
    - WRITE_EXTERNAL_STORAGE

# Reporting
reporting:
  formats: [html, json, junit]
  output_dir: ./test_reports
  screenshot_on_failure: true
  video_recording: false

# Caching
caching:
  enabled: true
  invalidate_on_change: true
''';

    await File(configPath).writeAsString(config);
  }

  Future<void> _createTestDriver(String basePath) async {
    final driverPath = path.join(
      basePath,
      'test_driver',
      'integration_test.dart',
    );

    if (File(driverPath).existsSync()) {
      return;
    }

    final driver = '''
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
''';

    await File(driverPath).writeAsString(driver);
  }

  Future<void> _createExampleTest(String basePath) async {
    final testPath = path.join(
      basePath,
      'integration_test',
      'example_test.dart',
    );

    if (File(testPath).existsSync()) {
      return;
    }

    final test = '''
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Example Integration Test', () {
    testWidgets('Counter increments', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const MyApp());

      // Verify the counter starts at 0
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsNothing);

      // Tap the '+' icon and trigger a frame
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      // Verify the counter has incremented
      expect(find.text('0'), findsNothing);
      expect(find.text('1'), findsOneWidget);
    });
  });
}

// Example app
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Pilot Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '\$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
''';

    await File(testPath).writeAsString(test);
  }
}
