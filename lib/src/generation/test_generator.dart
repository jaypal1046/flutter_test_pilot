import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_suite/test_suite.dart';
import '../test_suite/test_action.dart';
import '../test_suite/ui_interaction/tap/tap.dart';
import '../test_suite/ui_interaction/type/type.dart' as type_action;
import '../test_suite/assertion_action/assertion_action.dart';
import 'code_analyzer.dart';
import 'test_templates.dart';

/// Configuration for test generation
class TestGenerationConfig {
  final bool includeSetup;
  final bool includeCleanup;
  final bool includeAssertions;
  final bool generateEdgeCases;
  final bool generateNegativeTests;
  final TestGenerationStrategy strategy;
  final int maxStepsPerSuite;
  final TestOutputMode outputMode; // NEW: Integration vs Widget test

  const TestGenerationConfig({
    this.includeSetup = true,
    this.includeCleanup = true,
    this.includeAssertions = true,
    this.generateEdgeCases = true,
    this.generateNegativeTests = true,
    this.strategy = TestGenerationStrategy.comprehensive,
    this.maxStepsPerSuite = 20,
    this.outputMode =
        TestOutputMode.integrationTest, // DEFAULT: Integration Test
  });
}

enum TestGenerationStrategy {
  minimal, // Only basic happy path tests
  balanced, // Happy path + some edge cases
  comprehensive, // All scenarios including edge cases
  exhaustive, // Everything including stress tests
}

enum TestOutputMode {
  widgetTest, // test/ directory - fast, mocked (for unit tests)
  integrationTest, // integration_test/ directory - real device (for E2E)
}

/// Result of test generation with file output
class GenerationResult {
  final List<TestSuite> testSuites;
  final List<String> warnings;
  final List<String> suggestions;
  final Map<String, dynamic> metadata;
  final int totalTestCases;
  final Duration generationTime;
  final List<GeneratedTestFile> generatedFiles;

  GenerationResult({
    required this.testSuites,
    required this.warnings,
    required this.suggestions,
    required this.metadata,
    required this.totalTestCases,
    required this.generationTime,
    this.generatedFiles = const [],
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasSuggestions => suggestions.isNotEmpty;
  bool get hasGeneratedFiles => generatedFiles.isNotEmpty;
}

/// Information about a generated test file
class GeneratedTestFile {
  final String filePath;
  final String content;
  final int testCount;
  final String widgetName;
  final DateTime createdAt;

  GeneratedTestFile({
    required this.filePath,
    required this.content,
    required this.testCount,
    required this.widgetName,
    required this.createdAt,
  });
}

/// Main test case generator with file output
class TestGenerator {
  final TestGenerationConfig config;
  final List<String> _warnings = [];
  final List<String> _suggestions = [];
  final List<GeneratedTestFile> _generatedFiles = [];

  TestGenerator({this.config = const TestGenerationConfig()});

  /// Generate test suites from a Widget and save to file
  Future<GenerationResult> generateFromWidget(
    Widget widget, {
    String? customName,
    String? outputDirectory,
    bool saveToFile = false, // Changed default to false for tests
  }) async {
    final startTime = DateTime.now();
    final testSuites = <TestSuite>[];

    try {
      // Analyze the widget
      final elements = CodeAnalyzer.detectInteractiveElements(widget);
      final widgetType = widget.runtimeType.toString();
      final scenarios = CodeAnalyzer.suggestTestScenarios(widgetType);

      // Generate test suite for widget rendering
      testSuites.add(_generateRenderingTest(widget, customName));

      // Generate interaction tests for each interactive element
      for (final element in elements) {
        final suite = _generateInteractionTest(widget, element, customName);
        if (suite != null) testSuites.add(suite);
      }

      // Generate scenario-based tests
      if (config.strategy == TestGenerationStrategy.comprehensive ||
          config.strategy == TestGenerationStrategy.exhaustive) {
        for (final scenario in scenarios) {
          final suite = _generateScenarioTest(widget, scenario, customName);
          if (suite != null) testSuites.add(suite);
        }
      }

      // Generate edge case tests
      if (config.generateEdgeCases) {
        final edgeSuite = _generateEdgeCaseTests(widget, customName);
        if (edgeSuite != null) testSuites.add(edgeSuite);
      }

      // Generate negative tests
      if (config.generateNegativeTests) {
        final negativeSuite = _generateNegativeTests(widget, customName);
        if (negativeSuite != null) testSuites.add(negativeSuite);
      }

      _addSuggestions(widget, elements);

      // Always generate the code string
      final widgetName = customName ?? widget.runtimeType.toString();
      final directory = outputDirectory ?? 'test/generated';
      final content = _generateTestFileContent(testSuites, widgetName);
      final fileName = '${_toSnakeCase(widgetName)}_test.dart';
      final filePath = '$directory/$fileName';

      // Add to generated files list (with the content)
      _generatedFiles.add(
        GeneratedTestFile(
          filePath: filePath,
          content: content,
          testCount: testSuites.length,
          widgetName: widgetName,
          createdAt: DateTime.now(),
        ),
      );

      // Try to save to file if requested (non-blocking)
      if (saveToFile) {
        _trySaveToFile(content, filePath);
      }
    } catch (e) {
      _warnings.add('Error during generation: $e');
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    return GenerationResult(
      testSuites: testSuites,
      warnings: List.from(_warnings),
      suggestions: List.from(_suggestions),
      metadata: {
        'widget_type': widget.runtimeType.toString(),
        'generation_strategy': config.strategy.name,
        'generated_at': DateTime.now().toIso8601String(),
      },
      totalTestCases: testSuites.length,
      generationTime: duration,
      generatedFiles: List.from(_generatedFiles),
    );
  }

  /// Generate test suite from a code class
  Future<GenerationResult> generateFromClass(
    Type classType, {
    String? customName,
  }) async {
    final startTime = DateTime.now();
    final testSuites = <TestSuite>[];

    try {
      // Analyze the class
      final analyzed = CodeAnalyzer.analyzeWidget(classType);

      // Generate basic structure test
      testSuites.add(_generateClassStructureTest(analyzed, customName));

      // Generate method tests
      for (final method in analyzed.methods) {
        if (method.isPublic) {
          final suite = _generateMethodTest(analyzed, method, customName);
          if (suite != null) testSuites.add(suite);
        }
      }
    } catch (e) {
      _warnings.add('Error analyzing class: $e');
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    return GenerationResult(
      testSuites: testSuites,
      warnings: List.from(_warnings),
      suggestions: List.from(_suggestions),
      metadata: {
        'class_type': classType.toString(),
        'generation_strategy': config.strategy.name,
        'generated_at': DateTime.now().toIso8601String(),
      },
      totalTestCases: testSuites.length,
      generationTime: duration,
    );
  }

  /// Generate basic rendering test
  TestSuite _generateRenderingTest(Widget widget, String? customName) {
    final widgetName = customName ?? widget.runtimeType.toString();

    return TestSuite(
      name: 'Rendering Test: $widgetName',
      description: 'Auto-generated test to verify widget renders correctly',
      steps: [
        VerifyWidget(
          finder: find.byType(widget.runtimeType),
          customDescription: 'Verify $widgetName renders',
        ),
      ],
      metadata: {
        'auto_generated': true,
        'test_type': 'rendering',
        'widget_type': widget.runtimeType.toString(),
      },
    );
  }

  /// Generate interaction test for an interactive element
  TestSuite? _generateInteractionTest(
    Widget widget,
    InteractiveElement element,
    String? customName,
  ) {
    // widgetName used for context/logging if needed in future
    final steps = <TestAction>[];
    final assertions = <TestAction>[];

    // Add steps based on element type
    switch (element.type) {
      case 'button':
        if (element.identifier != null) {
          // Add verification that button exists
          steps.add(
            VerifyWidget(
              finder: find.text(element.identifier!),
              customDescription: 'Verify "${element.identifier}" button exists',
            ),
          );

          // Tap the button
          steps.add(Tap.text(element.identifier!));

          // Wait for action to complete
          steps.add(
            WaitAction(
              duration: const Duration(milliseconds: 500),
              customDescription: 'Wait for button action to complete',
            ),
          );

          // Verify button still exists after tap
          assertions.add(
            VerifyWidget(
              finder: find.text(element.identifier!),
              customDescription: 'Verify button still exists after tap',
            ),
          );
        }
        break;

      case 'textField':
        if (element.identifier != null) {
          // Verify text field exists
          steps.add(
            VerifyWidget(
              finder: find.byWidgetPredicate((w) {
                if (w is TextField) {
                  final decoration = w.decoration;
                  return decoration?.labelText == element.identifier ||
                      decoration?.hintText == element.identifier;
                } else if (w is TextFormField) {
                  // Access decoration through dynamic
                  try {
                    final dynamic formField = w;
                    final decoration = formField.decoration as InputDecoration?;
                    return decoration?.labelText == element.identifier ||
                        decoration?.hintText == element.identifier;
                  } catch (e) {
                    return false;
                  }
                }
                return false;
              }),
              customDescription:
                  'Verify "${element.identifier}" text field exists',
            ),
          );

          // Type test data
          steps.add(
            type_action.Type.into(element.identifier!).text('Test Input'),
          );

          // Wait for input
          steps.add(
            WaitAction(
              duration: const Duration(milliseconds: 300),
              customDescription: 'Wait after text input',
            ),
          );

          // Verify text was entered
          assertions.add(
            VerifyWidget(
              finder: find.text('Test Input'),
              customDescription: 'Verify text "Test Input" was entered',
            ),
          );
        }
        break;

      case 'appBar':
        if (element.identifier != null) {
          steps.add(
            VerifyWidget(
              finder: find.text(element.identifier!),
              customDescription: 'Verify AppBar title "${element.identifier}"',
            ),
          );
        }
        steps.add(
          VerifyWidget(
            finder: find.byType(AppBar),
            customDescription: 'Verify AppBar exists',
          ),
        );
        break;

      case 'iconButton':
        steps.add(
          VerifyWidget(
            finder: find.byType(IconButton),
            customDescription: 'Verify IconButton exists',
          ),
        );
        break;

      case 'scrollable':
        steps.add(
          VerifyWidget(
            finder: find.byType(ListView),
            customDescription: 'Verify scrollable list exists',
          ),
        );
        steps.add(
          WaitAction(
            duration: const Duration(milliseconds: 500),
            customDescription: 'Wait for scroll to complete',
          ),
        );
        break;

      case 'toggle':
        if (element.identifier != null) {
          steps.add(
            VerifyWidget(
              finder: find.byKey(Key(element.identifier!)),
              customDescription: 'Verify toggle exists',
            ),
          );
        }
        break;
    }

    if (steps.isEmpty) return null;

    return TestSuite(
      name:
          'Verify and Test: ${element.type} - "${element.identifier ?? 'unnamed'}"',
      description:
          'Auto-generated integration test for ${element.type}: ${element.expectedBehavior}',
      steps: steps,
      assertions: assertions,
      metadata: {
        'auto_generated': true,
        'test_type': 'interaction',
        'element_type': element.type,
        'element_id': element.identifier,
      },
    );
  }

  /// Generate scenario-based test
  TestSuite? _generateScenarioTest(
    Widget widget,
    String scenario,
    String? customName,
  ) {
    final widgetName = customName ?? widget.runtimeType.toString();

    // Use templates for common scenarios
    return TestTemplates.generateFromScenario(widgetName, scenario, widget);
  }

  /// Generate comprehensive page verification test
  TestSuite _generatePageVerificationTest(
    Widget widget,
    String? customName,
    List<InteractiveElement> elements,
  ) {
    final widgetName = customName ?? widget.runtimeType.toString();
    final steps = <TestAction>[];

    // Add verification for each detected element
    for (final element in elements) {
      switch (element.type) {
        case 'appBar':
          if (element.identifier != null) {
            steps.add(
              VerifyWidget(
                finder: find.text(element.identifier!),
                customDescription:
                    'Verify page has AppBar with title "${element.identifier}"',
              ),
            );
          }
          break;

        case 'button':
          if (element.identifier != null) {
            steps.add(
              VerifyWidget(
                finder: find.text(element.identifier!),
                customDescription:
                    'Verify "${element.identifier}" button is present',
              ),
            );
          }
          break;

        case 'textField':
          if (element.identifier != null) {
            steps.add(
              VerifyWidget(
                finder: find.byWidgetPredicate((w) {
                  if (w is TextField) {
                    final decoration = w.decoration;
                    return decoration?.labelText == element.identifier ||
                        decoration?.hintText == element.identifier;
                  } else if (w is TextFormField) {
                    try {
                      final dynamic formField = w;
                      final decoration =
                          formField.decoration as InputDecoration?;
                      return decoration?.labelText == element.identifier;
                    } catch (e) {
                      return false;
                    }
                  }
                  return false;
                }),
                customDescription:
                    'Verify "${element.identifier}" text field is present',
              ),
            );
          }
          break;

        case 'iconButton':
          steps.add(
            VerifyWidget(
              finder: find.byType(IconButton),
              customDescription: 'Verify IconButton is present',
            ),
          );
          break;
      }
    }

    // Add general verification
    steps.add(
      VerifyWidget(
        finder: find.byType(widget.runtimeType),
        customDescription: 'Verify $widgetName widget is fully rendered',
      ),
    );

    return TestSuite(
      name: 'Page Element Verification: $widgetName',
      description:
          'Comprehensive verification of all ${elements.length} interactive elements on the page',
      steps: steps,
      metadata: {
        'auto_generated': true,
        'test_type': 'page_verification',
        'element_count': elements.length,
        'widget_type': widget.runtimeType.toString(),
      },
    );
  }

  /// Generate edge case tests
  TestSuite? _generateEdgeCaseTests(Widget widget, String? customName) {
    final widgetName = customName ?? widget.runtimeType.toString();

    return TestSuite(
      name: 'Edge Cases: $widgetName',
      description: 'Auto-generated edge case tests',
      steps: [
        VerifyWidget(
          finder: find.byType(widget.runtimeType),
          customDescription: 'Verify widget handles edge cases',
        ),
      ],
      metadata: {'auto_generated': true, 'test_type': 'edge_cases'},
    );
  }

  /// Generate negative tests
  TestSuite? _generateNegativeTests(Widget widget, String? customName) {
    final widgetName = customName ?? widget.runtimeType.toString();

    return TestSuite(
      name: 'Negative Tests: $widgetName',
      description: 'Auto-generated negative scenario tests',
      steps: [
        VerifyWidget(
          finder: find.byType(widget.runtimeType),
          customDescription: 'Verify widget handles errors gracefully',
        ),
      ],
      metadata: {'auto_generated': true, 'test_type': 'negative'},
    );
  }

  /// Generate class structure test
  TestSuite _generateClassStructureTest(
    AnalyzedCode analyzed,
    String? customName,
  ) {
    final className = customName ?? analyzed.className;

    return TestSuite(
      name: 'Structure Test: $className',
      description: 'Auto-generated test for class structure',
      steps: [],
      metadata: {
        'auto_generated': true,
        'test_type': 'structure',
        'complexity': analyzed.complexity.level.name,
      },
    );
  }

  /// Generate method test
  TestSuite? _generateMethodTest(
    AnalyzedCode analyzed,
    AnalyzedMethod method,
    String? customName,
  ) {
    if (method.complexity == MethodComplexity.complex) {
      _suggestions.add(
        'Method ${method.name} is complex - consider manual test review',
      );
    }

    return null; // Methods need custom implementation
  }

  /// Add helpful suggestions
  void _addSuggestions(Widget widget, List<InteractiveElement> elements) {
    if (elements.isEmpty) {
      _suggestions.add(
        'No interactive elements detected. Consider adding Keys to widgets for better testing.',
      );
    }

    if (elements.length > 10) {
      _suggestions.add(
        'Many interactive elements detected (${elements.length}). Consider breaking widget into smaller components.',
      );
    }

    // Check for missing keys
    final elementsWithoutKeys = elements
        .where((e) => e.identifier == null)
        .length;
    if (elementsWithoutKeys > 0) {
      _suggestions.add(
        '$elementsWithoutKeys elements without identifiers. Add Key or Semantics labels for better test reliability.',
      );
    }
  }

  /// Save generated test suites to a Dart test file
  Future<void> _saveTestSuitesToFile(
    List<TestSuite> testSuites,
    String widgetName,
    String directory,
  ) async {
    print('🔧 Attempting to save test file...');

    try {
      // Check if we're in a test environment (dart:io may not work)
      if (kIsWeb) {
        print('⚠️  File I/O not available in web environment');
        _warnings.add('File I/O not available in web environment');
        _printGeneratedCodeToConsole(testSuites, widgetName, directory);
        return;
      }

      print('📁 Creating directory: $directory');

      // Create directory if it doesn't exist
      final dir = Directory(directory);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        print('✅ Directory created');
      } else {
        print('✅ Directory already exists');
      }

      // Generate file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          '${_toSnakeCase(widgetName)}_generated_test_$timestamp.dart';
      final filePath = '$directory/$fileName';

      print('📝 Generating file: $filePath');

      // Generate file content
      final content = _generateTestFileContent(testSuites, widgetName);

      print('💾 Writing file (${content.length} bytes)...');

      // Write to file
      final file = File(filePath);
      await file.writeAsString(content);

      print('✅ File written successfully!');

      // Add to generated files list
      _generatedFiles.add(
        GeneratedTestFile(
          filePath: filePath,
          content: content,
          testCount: testSuites.length,
          widgetName: widgetName,
          createdAt: DateTime.now(),
        ),
      );

      print('✅ Generated test file: $filePath');
      print('   📊 Contains ${testSuites.length} test suites');
      print('   📏 File size: ${content.length} bytes');
    } catch (e, stackTrace) {
      final errorMsg = 'Failed to save test file: $e';
      _warnings.add(errorMsg);
      print('❌ $errorMsg');
      print('Stack trace: $stackTrace');

      // Fallback: Print generated code to console
      print('\n⚠️  FALLBACK: Printing generated code to console...\n');
      _printGeneratedCodeToConsole(testSuites, widgetName, directory);
    }
  }

  /// Print generated code to console as fallback
  void _printGeneratedCodeToConsole(
    List<TestSuite> testSuites,
    String widgetName,
    String directory,
  ) {
    print('\n${'=' * 70}');
    print('GENERATED TEST CODE (Copy to file manually)');
    print('=' * 70);
    print(
      'Suggested file path: $directory/${_toSnakeCase(widgetName)}_test.dart',
    );
    print('=' * 70);
    print('');

    final content = _generateTestFileContent(testSuites, widgetName);
    print(content);

    print('\n${'=' * 70}');
    print('END OF GENERATED CODE');
    print('=' * 70);
    print('');
    print('📋 Copy the code above and save it to your test directory.');
    print('');
  }

  /// Generate the content of the test file
  String _generateTestFileContent(
    List<TestSuite> testSuites,
    String widgetName,
  ) {
    final buffer = StringBuffer();

    final isIntegrationTest =
        config.outputMode == TestOutputMode.integrationTest;

    // File header
    buffer.writeln(
      '// AUTO-GENERATED ${isIntegrationTest ? 'INTEGRATION' : 'WIDGET'} TEST FILE',
    );
    buffer.writeln('// Generated by flutter_test_pilot on ${DateTime.now()}');
    buffer.writeln('// Widget: $widgetName');
    buffer.writeln('// Generation Strategy: ${config.strategy.name}');
    buffer.writeln(
      '// Test Mode: ${isIntegrationTest ? 'Integration Test (E2E)' : 'Widget Test (Unit)'}',
    );
    buffer.writeln('//');
    buffer.writeln('// ⚠️  HYBRID APPROACH RECOMMENDED:');
    buffer.writeln('// 1. Review generated tests carefully');
    buffer.writeln('// 2. Add business logic validations');
    buffer.writeln('// 3. Enhance assertions based on requirements');
    if (isIntegrationTest) {
      buffer.writeln('// 4. Configure real API endpoints or mocking');
      buffer.writeln('// 5. Test with real user flows on device/emulator');
      buffer.writeln('// 6. Add proper app initialization and teardown');
    } else {
      buffer.writeln('// 4. Add API mocking if needed');
      buffer.writeln('// 5. Test with mock data scenarios');
    }
    buffer.writeln('');

    // Imports
    buffer.writeln("import 'package:flutter/material.dart';");
    if (isIntegrationTest) {
      buffer.writeln("import 'package:flutter_test/flutter_test.dart';");
      buffer.writeln(
        "import 'package:integration_test/integration_test.dart';",
      );
    } else {
      buffer.writeln("import 'package:flutter_test/flutter_test.dart';");
    }
    buffer.writeln(
      "import 'package:flutter_test_pilot/flutter_test_pilot.dart';",
    );
    buffer.writeln('');

    // Add TODO comments
    buffer.writeln('// TODO: Import your app/widget here');
    if (isIntegrationTest) {
      buffer.writeln('// import \'package:your_app/main.dart\' as app;');
    } else {
      buffer.writeln(
        '// import \'package:your_app/screens/${_toSnakeCase(widgetName)}.dart\';',
      );
    }
    buffer.writeln('');

    // Main function
    buffer.writeln('void main() {');

    if (isIntegrationTest) {
      buffer.writeln('  // Setup integration test binding');
      buffer.writeln(
        '  IntegrationTestWidgetsFlutterBinding.ensureInitialized();',
      );
      buffer.writeln('');
    }

    // Group tests by type
    final testsByType = <String, List<TestSuite>>{};
    for (final suite in testSuites) {
      final type = suite.metadata?['test_type'] as String? ?? 'general';
      testsByType.putIfAbsent(type, () => []).add(suite);
    }

    // Generate test groups
    for (final entry in testsByType.entries) {
      final type = entry.key;
      final suites = entry.value;

      buffer.writeln(
        '  group(\'${_formatGroupName(type)} ${isIntegrationTest ? '(E2E)' : ''}\', () {',
      );
      buffer.writeln('    // Setup for this test group');
      buffer.writeln('    setUp(() {');
      buffer.writeln('      // TODO: Add setup code if needed');
      if (isIntegrationTest) {
        buffer.writeln('      // Example: Reset app state, clear cache, etc.');
      }
      buffer.writeln('    });');
      buffer.writeln('');

      if (isIntegrationTest) {
        buffer.writeln('    tearDown(() {');
        buffer.writeln('      // TODO: Cleanup after each test');
        buffer.writeln('      // Example: Clear test data, logout, etc.');
        buffer.writeln('    });');
        buffer.writeln('');
      }

      // Generate individual tests
      for (var i = 0; i < suites.length; i++) {
        final suite = suites[i];
        buffer.writeln(_generateTestMethod(suite, i, isIntegrationTest));
      }

      buffer.writeln('  });');
      buffer.writeln('');
    }

    // Add suggestions as comments
    if (_suggestions.isNotEmpty) {
      buffer.writeln('  // 💡 SUGGESTIONS FROM GENERATOR:');
      for (final suggestion in _suggestions) {
        buffer.writeln('  // • $suggestion');
      }
      buffer.writeln('');
    }

    buffer.writeln('}');
    buffer.writeln('');

    // Add helper methods section
    buffer.writeln('// ============================================');
    buffer.writeln('// HELPER METHODS (Customize as needed)');
    buffer.writeln('// ============================================');
    buffer.writeln('');

    if (isIntegrationTest) {
      buffer.writeln('/// Initialize the app for integration testing');
      buffer.writeln('Future<void> initializeApp(WidgetTester tester) async {');
      buffer.writeln('  // TODO: Replace with your actual app initialization');
      buffer.writeln('  // Example:');
      buffer.writeln('  // app.main();');
      buffer.writeln('  // await tester.pumpAndSettle();');
      buffer.writeln('  ');
      buffer.writeln('  // For now, using a simple MaterialApp');
      buffer.writeln('  await tester.pumpWidget(');
      buffer.writeln('    MaterialApp(');
      buffer.writeln('      navigatorKey: TestPilotNavigator.ownKey,');
      buffer.writeln('      home: Container(), // TODO: Replace with your app');
      buffer.writeln('    ),');
      buffer.writeln('  );');
      buffer.writeln('  await tester.pumpAndSettle();');
      buffer.writeln('  FlutterTestPilot.initialize(tester);');
      buffer.writeln('}');
    } else {
      buffer.writeln('/// Initialize the widget for testing');
      buffer.writeln(
        'Future<void> pumpTestWidget(WidgetTester tester) async {',
      );
      buffer.writeln(
        '  // TODO: Replace with your actual widget initialization',
      );
      buffer.writeln('  await tester.pumpWidget(');
      buffer.writeln('    MaterialApp(');
      buffer.writeln('      navigatorKey: TestPilotNavigator.ownKey,');
      buffer.writeln(
        '      home: Container(), // TODO: Replace with your widget',
      );
      buffer.writeln('    ),');
      buffer.writeln('  );');
      buffer.writeln('  await tester.pumpAndSettle();');
      buffer.writeln('  FlutterTestPilot.initialize(tester);');
      buffer.writeln('}');
    }
    buffer.writeln('');

    return buffer.toString();
  }

  /// Generate a test method for a test suite
  String _generateTestMethod(
    TestSuite suite,
    int index,
    bool isIntegrationTest,
  ) {
    final buffer = StringBuffer();

    buffer.writeln(
      '    testWidgets(\'${suite.name}\', (WidgetTester tester) async {',
    );
    buffer.writeln('      // ${suite.description ?? 'No description'}');
    if (isIntegrationTest) {
      buffer.writeln('      await initializeApp(tester);');
    } else {
      buffer.writeln('      await pumpTestWidget(tester);');
    }
    buffer.writeln('');

    // Add metadata comment
    if (suite.metadata != null && suite.metadata!.isNotEmpty) {
      buffer.writeln('      // Metadata: ${suite.metadata}');
    }

    buffer.writeln('      // TODO: Review and enhance this test');
    buffer.writeln(
      '      // Generated with: ${suite.steps.length} steps, ${suite.assertions.length} assertions',
    );
    buffer.writeln('');

    // Execute the test suite
    buffer.writeln(
      '      final result = await FlutterTestPilot.instance.runSuite(',
    );
    buffer.writeln('        TestSuite(');
    buffer.writeln('          name: \'${suite.name}\',');
    buffer.writeln('          description: \'${suite.description ?? ''}\',');

    // Add setup steps
    if (suite.setup.isNotEmpty) {
      buffer.writeln('          setup: [');
      for (final step in suite.setup) {
        buffer.writeln('            ${_generateActionCode(step)},');
      }
      buffer.writeln('          ],');
    }

    // Add main steps
    buffer.writeln('          steps: [');
    for (final step in suite.steps) {
      buffer.writeln('            ${_generateActionCode(step)},');
    }
    buffer.writeln('          ],');

    // Add assertions
    if (suite.assertions.isNotEmpty) {
      buffer.writeln('          assertions: [');
      for (final assertion in suite.assertions) {
        buffer.writeln('            ${_generateActionCode(assertion)},');
      }
      buffer.writeln('          ],');
    }

    buffer.writeln('        ),');
    buffer.writeln('      );');
    buffer.writeln('');

    buffer.writeln('      // Verify test passed');
    buffer.writeln(
      '      expect(result.status, TestStatus.passed, reason: result.error);',
    );
    buffer.writeln('');
    buffer.writeln('      // TODO: Add custom assertions here');
    if (isIntegrationTest) {
      buffer.writeln(
        '      // Example: Verify navigation, API responses, state changes',
      );
    } else {
      buffer.writeln(
        '      // Example: expect(find.text(\'Expected Text\'), findsOneWidget);',
      );
    }
    buffer.writeln('    });');
    buffer.writeln('');

    return buffer.toString();
  }

  /// Generate Dart code for a test action
  String _generateActionCode(TestAction action) {
    if (action is Tap) {
      return 'Tap.widget(\'${action.widgetText ?? 'button'}\')';
    } else if (action is type_action.Type) {
      return 'Type.into(\'${action.fieldIdentifier}\').text(\'${action.textToType}\')';
    } else if (action is WaitAction) {
      return 'WaitAction(duration: Duration(milliseconds: ${action.duration.inMilliseconds}))';
    } else if (action is VerifyWidget) {
      return 'VerifyWidget(finder: find.byType(Widget), customDescription: \'${action.customDescription ?? 'Verify widget'}\')';
    }
    return '// TODO: Implement action: ${action.runtimeType}';
  }

  /// Convert string to snake_case
  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceAll(RegExp(r'^_'), '')
        .toLowerCase();
  }

  /// Format group name
  String _formatGroupName(String type) {
    return type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Try to save to file (non-blocking, best effort)
  void _trySaveToFile(String content, String filePath) {
    try {
      // Run in separate zone to avoid blocking
      final dir = Directory(filePath.substring(0, filePath.lastIndexOf('/')));
      if (!dir.existsSync()) {
        dir.createSync();
      }

      final file = File(filePath);
      file.writeAsStringSync(content);

      final testType = config.outputMode == TestOutputMode.integrationTest
          ? 'Integration test'
          : 'Widget test';
      print('✅ $testType file saved: $filePath');
    } catch (e) {
      _warnings.add('Could not save file: $e (content available in memory)');
    }
  }

  /// Generate comprehensive test suite and optionally save to file
  static Future<GenerationResult> generateComprehensive(
    Widget widget, {
    String? name,
    String? outputDirectory,
    bool saveToFile = true,
    TestOutputMode mode =
        TestOutputMode.integrationTest, // DEFAULT: Integration
  }) async {
    final generator = TestGenerator(
      config: TestGenerationConfig(
        strategy: TestGenerationStrategy.comprehensive,
        outputMode: mode,
      ),
    );

    // Determine default directory based on mode
    final defaultDir = mode == TestOutputMode.integrationTest
        ? 'integration_test/generated'
        : 'test/generated';

    return generator.generateFromWidget(
      widget,
      customName: name,
      outputDirectory: outputDirectory ?? defaultDir,
      saveToFile: saveToFile,
    );
  }

  /// Generate minimal test suite (quick smoke tests) and optionally save to file
  static Future<GenerationResult> generateMinimal(
    Widget widget, {
    String? name,
    String? outputDirectory,
    bool saveToFile = true,
    TestOutputMode mode =
        TestOutputMode.integrationTest, // DEFAULT: Integration
  }) async {
    final generator = TestGenerator(
      config: TestGenerationConfig(
        strategy: TestGenerationStrategy.minimal,
        generateEdgeCases: false,
        generateNegativeTests: false,
        outputMode: mode,
      ),
    );

    // Determine default directory based on mode
    final defaultDir = mode == TestOutputMode.integrationTest
        ? 'integration_test/generated'
        : 'test/generated';

    return generator.generateFromWidget(
      widget,
      customName: name,
      outputDirectory: outputDirectory ?? defaultDir,
      saveToFile: saveToFile,
    );
  }
}
