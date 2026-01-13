import 'dart:io';
import 'package:flutter/material.dart';
import 'test_generator.dart';
import 'code_analyzer.dart';

/// Test generation strategies
enum TestGenerationStrategy { minimal, balanced, comprehensive, exhaustive }

/// Automated Test Generation CLI
/// Scans your lib directory and generates comprehensive tests automatically
class AutoTestCLI {
  final String projectPath;
  final AutoTestConfig config;

  AutoTestCLI({
    required this.projectPath,
    this.config = const AutoTestConfig(),
  });

  /// Main entry point - Generate all tests automatically
  Future<AutoTestReport> generateAllTests() async {
    print('🚀 Flutter Test Pilot - Automated Test Generation');
    print('=' * 70);
    print('📁 Project: $projectPath');
    print('📊 Strategy: ${config.strategy}');
    print('=' * 70);
    print('');

    final startTime = DateTime.now();
    final report = AutoTestReport();

    try {
      // Step 1: Discover all testable files
      print('🔍 Step 1: Discovering testable files...');
      final files = await _discoverTestableFiles();
      print('   ✅ Found ${files.length} testable files');
      report.filesDiscovered = files.length;

      // Step 2: Analyze code structure
      print('🔬 Step 2: Analyzing code structure...');
      final analyzed = await _analyzeCodeStructure(files);
      print('   ✅ Analyzed ${analyzed.length} components');
      report.componentsAnalyzed = analyzed.length;

      // Step 3: Generate widget tests
      print('🧪 Step 3: Generating widget tests...');
      final widgetResults = await _generateWidgetTests(analyzed);
      report.widgetTestsGenerated = widgetResults.totalTests;
      report.widgetTestFiles = widgetResults.files;

      // Step 4: Generate integration tests
      print('🔗 Step 4: Generating integration tests...');
      final integrationResults = await _generateIntegrationTests(analyzed);
      report.integrationTestsGenerated = integrationResults.totalTests;
      report.integrationTestFiles = integrationResults.files;

      // Step 5: Generate workflow tests
      print('🔄 Step 5: Generating workflow tests...');
      final workflowResults = await _generateWorkflowTests(analyzed);
      report.workflowTestsGenerated = workflowResults.totalTests;
      report.workflowTestFiles = workflowResults.files;

      // Step 6: Generate test suite documentation
      print('📚 Step 6: Generating test documentation...');
      await _generateTestDocumentation(report);

      report.generationTime = DateTime.now().difference(startTime);
      report.success = true;
    } catch (e, stackTrace) {
      print('❌ Error during test generation: $e');
      print('Stack trace: $stackTrace');
      report.success = false;
      report.errors.add(e.toString());
    }

    // Print summary
    _printSummary(report);

    return report;
  }

  /// Discover all testable files in lib directory
  Future<List<FileInfo>> _discoverTestableFiles() async {
    final files = <FileInfo>[];
    final libDir = Directory('$projectPath/lib');

    if (!await libDir.exists()) {
      throw Exception('lib directory not found at: $projectPath/lib');
    }

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final content = await entity.readAsString();
        final info = _analyzeFile(entity, content);

        if (info.isTestable) {
          files.add(info);
          print(
            '   📄 ${info.relativePath}: ${info.widgets.length} widgets, ${info.classes.length} classes',
          );
        }
      }
    }

    return files;
  }

  /// Analyze a single file
  FileInfo _analyzeFile(File file, String content) {
    final info = FileInfo(
      path: file.path,
      relativePath: file.path.replaceFirst('$projectPath/', ''),
    );

    // Detect widgets
    final widgetRegex = RegExp(
      r'class\s+(\w+)\s+extends\s+(StatelessWidget|StatefulWidget|Widget)',
      multiLine: true,
    );

    for (final match in widgetRegex.allMatches(content)) {
      info.widgets.add(match.group(1)!);
    }

    // Detect regular classes
    final classRegex = RegExp(
      r'class\s+(\w+)(?:\s+extends\s+\w+)?(?:\s+implements\s+[\w,\s]+)?(?:\s+with\s+[\w,\s]+)?\s*\{',
      multiLine: true,
    );

    for (final match in classRegex.allMatches(content)) {
      final className = match.group(1)!;
      if (!info.widgets.contains(className) &&
          !className.startsWith('_') &&
          !_isSystemClass(className)) {
        info.classes.add(className);
      }
    }

    // Detect routes - Fixed regex pattern
    final routeRegex = RegExp(r'''['"]/([\\w/_-]+)['"]''', multiLine: true);
    for (final match in routeRegex.allMatches(content)) {
      info.routes.add(match.group(1)!);
    }

    // Detect API endpoints - Fixed regex pattern
    final apiRegex = RegExp(
      r'''(get|post|put|delete|patch)\s*\(['"]([\\w/:_-]+)['"]\)''',
      multiLine: true,
    );
    for (final match in apiRegex.allMatches(content)) {
      info.apiEndpoints.add(
        '${match.group(1)!.toUpperCase()} ${match.group(2)}',
      );
    }

    return info;
  }

  /// Check if class is a system/framework class
  bool _isSystemClass(String className) {
    final systemClasses = [
      'State',
      'Widget',
      'BuildContext',
      'Key',
      'Color',
      'Size',
      'Offset',
      'Rect',
      'EdgeInsets',
      'TextStyle',
      'BoxDecoration',
    ];
    return systemClasses.contains(className);
  }

  /// Analyze code structure
  Future<List<AnalyzedComponent>> _analyzeCodeStructure(
    List<FileInfo> files,
  ) async {
    final components = <AnalyzedComponent>[];

    for (final file in files) {
      // Analyze widgets
      for (final widget in file.widgets) {
        components.add(
          AnalyzedComponent(
            name: widget,
            type: ComponentType.widget,
            file: file,
          ),
        );
      }

      // Analyze classes
      for (final className in file.classes) {
        components.add(
          AnalyzedComponent(
            name: className,
            type: ComponentType.businessLogic,
            file: file,
          ),
        );
      }

      // Analyze routes
      for (final route in file.routes) {
        components.add(
          AnalyzedComponent(name: route, type: ComponentType.route, file: file),
        );
      }
    }

    return components;
  }

  /// Generate widget tests
  Future<TestGenerationResults> _generateWidgetTests(
    List<AnalyzedComponent> components,
  ) async {
    final results = TestGenerationResults();
    final widgetComponents = components
        .where((c) => c.type == ComponentType.widget)
        .toList();

    for (final component in widgetComponents) {
      try {
        final testContent = _generateWidgetTestContent(component);
        final fileName = '${_toSnakeCase(component.name)}_widget_test.dart';
        final filePath = '$projectPath/test/generated/$fileName';

        await _saveTestFile(filePath, testContent);

        results.files.add(filePath);
        results.totalTests++;
        print('   ✅ Generated: $fileName');
      } catch (e) {
        print('   ⚠️  Skipped ${component.name}: $e');
        results.skipped.add(component.name);
      }
    }

    return results;
  }

  /// Generate integration tests
  Future<TestGenerationResults> _generateIntegrationTests(
    List<AnalyzedComponent> components,
  ) async {
    final results = TestGenerationResults();
    final widgetComponents = components
        .where((c) => c.type == ComponentType.widget)
        .toList();

    for (final component in widgetComponents) {
      try {
        final testContent = _generateIntegrationTestContent(component);
        final fileName =
            '${_toSnakeCase(component.name)}_integration_test.dart';
        final filePath = '$projectPath/integration_test/generated/$fileName';

        await _saveTestFile(filePath, testContent);

        results.files.add(filePath);
        results.totalTests++;
        print('   ✅ Generated: $fileName');
      } catch (e) {
        print('   ⚠️  Skipped ${component.name}: $e');
        results.skipped.add(component.name);
      }
    }

    return results;
  }

  /// Generate workflow tests (multi-page flows)
  Future<TestGenerationResults> _generateWorkflowTests(
    List<AnalyzedComponent> components,
  ) async {
    final results = TestGenerationResults();
    final routes = components
        .where((c) => c.type == ComponentType.route)
        .toList();

    if (routes.length < 2) {
      print('   ℹ️  Not enough routes for workflow tests (need at least 2)');
      return results;
    }

    // Generate user journey tests
    final testContent = _generateUserJourneyTest(routes);
    final filePath =
        '$projectPath/integration_test/generated/user_journey_test.dart';

    await _saveTestFile(filePath, testContent);

    results.files.add(filePath);
    results.totalTests++;
    print('   ✅ Generated: user_journey_test.dart');

    return results;
  }

  /// Generate widget test content
  String _generateWidgetTestContent(AnalyzedComponent component) {
    return '''
// AUTO-GENERATED WIDGET TEST
// Generated by flutter_test_pilot on ${DateTime.now()}
// Component: ${component.name}
// File: ${component.file.relativePath}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

// TODO: Import your widget
// import 'package:your_app/${component.file.relativePath}';

void main() {
  group('${component.name} Widget Tests', () {
    testWidgets('should render ${component.name}', (WidgetTester tester) async {
      // TODO: Replace with actual widget initialization
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(), // TODO: Replace with ${component.name}()
          ),
        ),
      );

      // TODO: Add assertions
      // Example: expect(find.byType(${component.name}), findsOneWidget);
    });

    testWidgets('should handle user interactions', (WidgetTester tester) async {
      // TODO: Add interaction tests
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(), // TODO: Replace with ${component.name}()
          ),
        ),
      );

      // TODO: Test button taps, text input, etc.
    });

    testWidgets('should display correct content', (WidgetTester tester) async {
      // TODO: Test content rendering
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(), // TODO: Replace with ${component.name}()
          ),
        ),
      );

      // TODO: Verify text, images, icons
    });
  });
}
''';
  }

  /// Generate integration test content
  String _generateIntegrationTestContent(AnalyzedComponent component) {
    return '''
// AUTO-GENERATED INTEGRATION TEST
// Generated by flutter_test_pilot on ${DateTime.now()}
// Component: ${component.name}
// File: ${component.file.relativePath}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

// TODO: Import your app
// import 'package:your_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('${component.name} Integration Tests (E2E)', () {
    testWidgets('should navigate to ${component.name}', (WidgetTester tester) async {
      // TODO: Initialize your app
      // app.main();
      // await tester.pumpAndSettle();
      // FlutterTestPilot.initialize(tester);

      // TODO: Navigate to ${component.name}
      // await tester.tap(find.text('Navigate to ${component.name}'));
      // await tester.pumpAndSettle();

      // Verify page loaded
      // expect(find.byType(${component.name}), findsOneWidget);
    });

    testWidgets('should complete full user flow on ${component.name}', (WidgetTester tester) async {
      // TODO: Test complete user workflow
      // 1. Initialize app
      // 2. Navigate to page
      // 3. Perform actions
      // 4. Verify results
    });

    testWidgets('should handle edge cases', (WidgetTester tester) async {
      // TODO: Test edge cases
      // - Empty state
      // - Loading state
      // - Error state
      // - Offline mode
    });
  });
}
''';
  }

  /// Generate user journey test
  String _generateUserJourneyTest(List<AnalyzedComponent> routes) {
    final routeNames = routes.map((r) => r.name).take(5).join(' -> ');

    return '''
// AUTO-GENERATED USER JOURNEY TEST
// Generated by flutter_test_pilot on ${DateTime.now()}
// Flow: $routeNames

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

// TODO: Import your app
// import 'package:your_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Complete User Journey Tests', () {
    testWidgets('should complete full app workflow', (WidgetTester tester) async {
      // TODO: Initialize app
      // app.main();
      // await tester.pumpAndSettle();
      // FlutterTestPilot.initialize(tester);

      // User Journey: ${routes.map((r) => r.name).join(' -> ')}
      
${routes.take(5).map((route) => '''
      // Step: Navigate to /${route.name}
      // TODO: Add navigation and verification
      // await tester.tap(find.text('Go to ${route.name}'));
      // await tester.pumpAndSettle();
      // expect(find.text('${route.name}'), findsOneWidget);
''').join('\n')}

      // TODO: Complete the flow and add assertions
    });

    testWidgets('should handle errors gracefully in user journey', (WidgetTester tester) async {
      // TODO: Test error scenarios in the flow
    });
  });
}
''';
  }

  /// Save test file
  Future<void> _saveTestFile(String filePath, String content) async {
    final file = File(filePath);
    final dir = file.parent;

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    await file.writeAsString(content);
  }

  /// Generate test documentation
  Future<void> _generateTestDocumentation(AutoTestReport report) async {
    final docContent =
        '''
# Automated Test Generation Report

**Generated:** ${DateTime.now()}
**Project:** $projectPath

## Summary

- 📁 Files Discovered: ${report.filesDiscovered}
- 🔬 Components Analyzed: ${report.componentsAnalyzed}
- 🧪 Widget Tests Generated: ${report.widgetTestsGenerated}
- 🔗 Integration Tests Generated: ${report.integrationTestsGenerated}
- 🔄 Workflow Tests Generated: ${report.workflowTestsGenerated}
- ⏱️ Generation Time: ${report.generationTime.inSeconds}s

## Generated Files

### Widget Tests
${report.widgetTestFiles.map((f) => '- $f').join('\n')}

### Integration Tests
${report.integrationTestFiles.map((f) => '- $f').join('\n')}

### Workflow Tests
${report.workflowTestFiles.map((f) => '- $f').join('\n')}

## Next Steps

1. **Review Generated Tests**: Check each test file and customize as needed
2. **Add Business Logic**: Implement actual assertions based on requirements
3. **Configure Test Data**: Set up mock data or test fixtures
4. **Run Tests**: Execute with `flutter test` or `flutter test integration_test`
5. **CI/CD Integration**: Add to your pipeline

## Notes

⚠️ These are scaffolded tests that need customization:
- Add proper widget imports
- Implement actual test logic
- Add assertions based on requirements
- Configure API mocking if needed
- Set up test data and fixtures
''';

    final docPath = '$projectPath/test/generated/TEST_GENERATION_REPORT.md';
    await _saveTestFile(docPath, docContent);
    print('   ✅ Documentation: TEST_GENERATION_REPORT.md');
  }

  /// Print summary
  void _printSummary(AutoTestReport report) {
    print('');
    print('=' * 70);
    print('📊 TEST GENERATION SUMMARY');
    print('=' * 70);
    print('✅ Success: ${report.success}');
    print('📁 Files Discovered: ${report.filesDiscovered}');
    print('🔬 Components Analyzed: ${report.componentsAnalyzed}');
    print('🧪 Widget Tests: ${report.widgetTestsGenerated}');
    print('🔗 Integration Tests: ${report.integrationTestsGenerated}');
    print('🔄 Workflow Tests: ${report.workflowTestsGenerated}');
    print('📊 Total Tests: ${report.totalTests}');
    print('⏱️ Time: ${report.generationTime.inSeconds}s');

    if (report.errors.isNotEmpty) {
      print('');
      print('❌ Errors:');
      for (final error in report.errors) {
        print('   - $error');
      }
    }

    print('');
    print('📚 Next Steps:');
    print('   1. Review generated tests in test/generated/');
    print('   2. Review integration tests in integration_test/generated/');
    print('   3. Customize tests with actual business logic');
    print('   4. Run: flutter test');
    print('   5. Run: flutter test integration_test/');
    print('=' * 70);
  }

  /// Convert to snake_case
  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceAll(RegExp(r'^_'), '')
        .toLowerCase();
  }
}

/// Configuration for automated test generation
class AutoTestConfig {
  final TestGenerationStrategy strategy;
  final bool generateWidgetTests;
  final bool generateIntegrationTests;
  final bool generateWorkflowTests;
  final bool verbose;

  const AutoTestConfig({
    this.strategy = TestGenerationStrategy.comprehensive,
    this.generateWidgetTests = true,
    this.generateIntegrationTests = true,
    this.generateWorkflowTests = true,
    this.verbose = true,
  });
}

/// File information
class FileInfo {
  final String path;
  final String relativePath;
  final List<String> widgets = [];
  final List<String> classes = [];
  final List<String> routes = [];
  final List<String> apiEndpoints = [];

  FileInfo({required this.path, required this.relativePath});

  bool get isTestable =>
      widgets.isNotEmpty || classes.isNotEmpty || routes.isNotEmpty;
}

/// Analyzed component
class AnalyzedComponent {
  final String name;
  final ComponentType type;
  final FileInfo file;

  AnalyzedComponent({
    required this.name,
    required this.type,
    required this.file,
  });
}

/// Component type
enum ComponentType { widget, businessLogic, route, api }

/// Test generation results
class TestGenerationResults {
  final List<String> files = [];
  final List<String> skipped = [];
  int totalTests = 0;
}

/// Auto test report
class AutoTestReport {
  int filesDiscovered = 0;
  int componentsAnalyzed = 0;
  int widgetTestsGenerated = 0;
  int integrationTestsGenerated = 0;
  int workflowTestsGenerated = 0;
  List<String> widgetTestFiles = [];
  List<String> integrationTestFiles = [];
  List<String> workflowTestFiles = [];
  Duration generationTime = Duration.zero;
  bool success = false;
  List<String> errors = [];

  int get totalTests =>
      widgetTestsGenerated + integrationTestsGenerated + workflowTestsGenerated;
}
