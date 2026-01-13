import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_suite/test_suite.dart';
import '../test_suite/test_action.dart';
import '../test_suite/ui_interaction/tap/tap.dart';
import '../test_suite/ui_interaction/type/type.dart' as type_action;
import '../test_suite/assertion_action/assertion_action.dart';
import '../test_suite/wait_action/wait_action.dart';
import '../test_suite/nav_action/navigator.dart';
import 'code_analyzer.dart';
import 'test_generator.dart'; // Import to use TestOutputMode

/// Configuration for flow-based test generation
class FlowTestConfig {
  final bool analyzeRoutes;
  final bool analyzeStateFlow;
  final bool generateUserJourneys;
  final bool analyzeApiCalls;
  final bool generateEdgeCases;
  final int maxFlowDepth;
  final TestOutputMode outputMode;

  const FlowTestConfig({
    this.analyzeRoutes = true,
    this.analyzeStateFlow = true,
    this.generateUserJourneys = true,
    this.analyzeApiCalls = true,
    this.generateEdgeCases = true,
    this.maxFlowDepth = 5,
    this.outputMode = TestOutputMode.integrationTest,
  });
}

/// Represents a user flow through the app
class UserFlow {
  final String name;
  final String description;
  final List<FlowStep> steps;
  final List<String> routes;
  final Map<String, dynamic> metadata;

  const UserFlow({
    required this.name,
    required this.description,
    required this.steps,
    required this.routes,
    this.metadata = const {},
  });
}

/// A single step in a user flow
class FlowStep {
  final String action;
  final String target;
  final String? inputData;
  final String? expectedResult;
  final Duration? waitTime;

  const FlowStep({
    required this.action,
    required this.target,
    this.inputData,
    this.expectedResult,
    this.waitTime,
  });
}

/// Represents a page/screen in the app
class AppPage {
  final String route;
  final String name;
  final Type widgetType;
  final List<InteractiveElement> elements;
  final List<String> connectedRoutes;
  final List<String> stateVariables;
  final bool hasAsyncOperations;

  const AppPage({
    required this.route,
    required this.name,
    required this.widgetType,
    required this.elements,
    required this.connectedRoutes,
    required this.stateVariables,
    this.hasAsyncOperations = false,
  });
}

/// Result of flow analysis
class FlowAnalysisResult {
  final List<AppPage> pages;
  final List<UserFlow> userFlows;
  final Map<String, List<String>> routeMap;
  final List<String> apiEndpoints;
  final Map<String, dynamic> stateMap;

  const FlowAnalysisResult({
    required this.pages,
    required this.userFlows,
    required this.routeMap,
    required this.apiEndpoints,
    required this.stateMap,
  });
}

/// Advanced flow-based test generator
class FlowTestGenerator {
  final FlowTestConfig config;

  FlowTestGenerator({this.config = const FlowTestConfig()});

  /// Analyze entire app starting from main.dart and routes
  Future<FlowAnalysisResult> analyzeAppFlow(
    Map<String, WidgetBuilder> routes,
    BuildContext? context,
  ) async {
    final pages = <AppPage>[];
    final userFlows = <UserFlow>[];
    final routeMap = <String, List<String>>{};
    final apiEndpoints = <String>[];
    final stateMap = <String, dynamic>{};

    print('🔍 Analyzing app flow...');

    // Analyze each route
    for (final entry in routes.entries) {
      final route = entry.key;
      final builder = entry.value;

      print('  📄 Analyzing route: $route');

      try {
        // Build widget to analyze it
        final widget = builder(context ?? _createDummyContext());
        final elements = CodeAnalyzer.detectInteractiveElements(widget);

        // Extract navigation connections
        final connectedRoutes = _extractNavigationTargets(widget, routes);

        // Extract state variables
        final stateVars = _extractStateVariables(widget);

        // Check for async operations
        final hasAsync = _hasAsyncOperations(widget);

        final page = AppPage(
          route: route,
          name: _routeToName(route),
          widgetType: widget.runtimeType,
          elements: elements,
          connectedRoutes: connectedRoutes,
          stateVariables: stateVars,
          hasAsyncOperations: hasAsync,
        );

        pages.add(page);
        routeMap[route] = connectedRoutes;

        print('    ✅ Found ${elements.length} interactive elements');
        print('    🔗 Connects to: ${connectedRoutes.join(', ')}');
      } catch (e) {
        print('    ⚠️  Error analyzing route: $e');
      }
    }

    // Generate user flows
    if (config.generateUserJourneys) {
      userFlows.addAll(_generateUserFlows(pages, routeMap));
    }

    print('✅ Analysis complete!');
    print('   📊 Total pages: ${pages.length}');
    print('   🎯 User flows: ${userFlows.length}');

    return FlowAnalysisResult(
      pages: pages,
      userFlows: userFlows,
      routeMap: routeMap,
      apiEndpoints: apiEndpoints,
      stateMap: stateMap,
    );
  }

  /// Generate comprehensive tests from app flow analysis
  Future<String> generateFlowTests(
    FlowAnalysisResult analysis, {
    String? outputPath,
  }) async {
    final buffer = StringBuffer();
    final timestamp = DateTime.now();

    // File header
    _writeFileHeader(buffer, timestamp, analysis);

    // Imports
    _writeImports(buffer);

    // Main function
    buffer.writeln('void main() {');
    if (config.outputMode == TestOutputMode.integrationTest) {
      buffer.writeln(
        '  IntegrationTestWidgetsFlutterBinding.ensureInitialized();',
      );
      buffer.writeln('');
    }

    // Generate page tests
    _generatePageTests(buffer, analysis.pages);

    // Generate navigation flow tests
    _generateNavigationFlowTests(buffer, analysis.routeMap);

    // Generate user journey tests
    _generateUserJourneyTests(buffer, analysis.userFlows);

    // Generate edge case tests
    if (config.generateEdgeCases) {
      _generateEdgeCaseTests(buffer, analysis.pages);
    }

    buffer.writeln('}');
    buffer.writeln('');

    // Helper methods
    _writeHelperMethods(buffer);

    final content = buffer.toString();

    // Save to file if path provided
    if (outputPath != null) {
      await _saveToFile(content, outputPath);
    }

    return content;
  }

  /// Write file header
  void _writeFileHeader(
    StringBuffer buffer,
    DateTime timestamp,
    FlowAnalysisResult analysis,
  ) {
    buffer.writeln(
      '// ═══════════════════════════════════════════════════════════════',
    );
    buffer.writeln('// AUTO-GENERATED FLOW-BASED INTEGRATION TESTS');
    buffer.writeln(
      '// ═══════════════════════════════════════════════════════════════',
    );
    buffer.writeln('// Generated: ${timestamp.toIso8601String()}');
    buffer.writeln('// Generator: FlutterTestPilot Flow Analyzer');
    buffer.writeln('//');
    buffer.writeln('// 📊 Analysis Summary:');
    buffer.writeln('//    - Pages analyzed: ${analysis.pages.length}');
    buffer.writeln('//    - User flows: ${analysis.userFlows.length}');
    buffer.writeln('//    - Routes mapped: ${analysis.routeMap.length}');
    buffer.writeln('//');
    buffer.writeln('// ⚠️  IMPORTANT: Review and customize these tests!');
    buffer.writeln(
      '// This is an intelligent starting point, not a complete solution.',
    );
    buffer.writeln(
      '// Add business logic validations, API mocking, and data scenarios.',
    );
    buffer.writeln(
      '// ═══════════════════════════════════════════════════════════════',
    );
    buffer.writeln('');
  }

  /// Write imports
  void _writeImports(StringBuffer buffer) {
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln("import 'package:flutter_test/flutter_test.dart';");
    if (config.outputMode == TestOutputMode.integrationTest) {
      buffer.writeln(
        "import 'package:integration_test/integration_test.dart';",
      );
    }
    buffer.writeln(
      "import 'package:flutter_test_pilot/flutter_test_pilot.dart';",
    );
    buffer.writeln('');
    buffer.writeln('// TODO: Import your app');
    buffer.writeln("// import 'package:your_app/main.dart' as app;");
    buffer.writeln('');
  }

  /// Generate tests for each page
  void _generatePageTests(StringBuffer buffer, List<AppPage> pages) {
    buffer.writeln(
      '  // ═══════════════════════════════════════════════════════════════',
    );
    buffer.writeln('  // PAGE-LEVEL TESTS');
    buffer.writeln(
      '  // ═══════════════════════════════════════════════════════════════',
    );
    buffer.writeln('');

    for (final page in pages) {
      buffer.writeln("  group('${page.name} Page Tests', () {");
      buffer.writeln('    testWidgets(');
      buffer.writeln("      'Should render ${page.name} page correctly',");
      buffer.writeln('      (WidgetTester tester) async {');
      buffer.writeln('        await initializeApp(tester);');
      buffer.writeln("        await navigateToPage(tester, '${page.route}');");
      buffer.writeln('');

      // Generate verification steps for all elements
      if (page.elements.isNotEmpty) {
        buffer.writeln(
          '        final result = await FlutterTestPilot.instance.runSuite(',
        );
        buffer.writeln('          TestSuite(');
        buffer.writeln("            name: '${page.name} Page Rendering',");
        buffer.writeln(
          "            description: 'Verify all elements on ${page.name} page',",
        );
        buffer.writeln('            steps: [');

        for (final element in page.elements) {
          buffer.writeln('              VerifyWidget(');
          if (element.identifier != null) {
            if (element.type == 'button' || element.type == 'appBar') {
              buffer.writeln(
                "                finder: find.text('${element.identifier}'),",
              );
            } else if (element.identifier!.contains('_')) {
              buffer.writeln(
                "                finder: find.byKey(Key('${element.identifier}')),",
              );
            } else {
              buffer.writeln(
                "                finder: find.text('${element.identifier}'),",
              );
            }
          } else {
            buffer.writeln(
              '                finder: find.byType(${_getWidgetType(element.type)}),',
            );
          }
          buffer.writeln(
            "                customDescription: 'Verify ${element.type} exists',",
          );
          buffer.writeln('              ),');
        }

        buffer.writeln('            ],');
        buffer.writeln('          ),');
        buffer.writeln('        );');
        buffer.writeln('');
        buffer.writeln(
          '        expect(result.status, TestStatus.passed, reason: result.error);',
        );
      }

      buffer.writeln('      },');
      buffer.writeln('    );');
      buffer.writeln('');

      // Generate interaction tests for each element
      for (final element in page.elements) {
        if (element.type == 'button') {
          _generateButtonTest(buffer, page, element);
        } else if (element.type == 'textField') {
          _generateTextFieldTest(buffer, page, element);
        } else if (element.type == 'toggle') {
          _generateToggleTest(buffer, page, element);
        }
      }

      buffer.writeln('  });');
      buffer.writeln('');
    }
  }

  /// Generate button interaction test
  void _generateButtonTest(
    StringBuffer buffer,
    AppPage page,
    InteractiveElement element,
  ) {
    if (element.identifier == null) return;

    buffer.writeln('    testWidgets(');
    buffer.writeln(
      "      'Should interact with ${element.identifier} button',",
    );
    buffer.writeln('      (WidgetTester tester) async {');
    buffer.writeln('        await initializeApp(tester);');
    buffer.writeln("        await navigateToPage(tester, '${page.route}');");
    buffer.writeln('');
    buffer.writeln(
      '        final result = await FlutterTestPilot.instance.runSuite(',
    );
    buffer.writeln('          TestSuite(');
    buffer.writeln(
      "            name: '${element.identifier} Button Interaction',",
    );
    buffer.writeln('            steps: [');

    if (element.identifier!.contains('_')) {
      buffer.writeln("              Tap.key('${element.identifier}'),");
    } else {
      buffer.writeln("              Tap.text('${element.identifier}'),");
    }

    buffer.writeln(
      '              Wait.forDuration(Duration(milliseconds: 500)),',
    );
    buffer.writeln('            ],');
    buffer.writeln('          ),');
    buffer.writeln('        );');
    buffer.writeln('');
    buffer.writeln(
      '        expect(result.status, TestStatus.passed, reason: result.error);',
    );
    buffer.writeln(
      '        // TODO: Add assertions for expected behavior after button tap',
    );
    buffer.writeln('      },');
    buffer.writeln('    );');
    buffer.writeln('');
  }

  /// Generate text field test
  void _generateTextFieldTest(
    StringBuffer buffer,
    AppPage page,
    InteractiveElement element,
  ) {
    if (element.identifier == null) return;

    buffer.writeln('    testWidgets(');
    buffer.writeln("      'Should type text into ${element.identifier}',");
    buffer.writeln('      (WidgetTester tester) async {');
    buffer.writeln('        await initializeApp(tester);');
    buffer.writeln("        await navigateToPage(tester, '${page.route}');");
    buffer.writeln('');
    buffer.writeln(
      '        final result = await FlutterTestPilot.instance.runSuite(',
    );
    buffer.writeln('          TestSuite(');
    buffer.writeln("            name: '${element.identifier} Text Input',");
    buffer.writeln('            steps: [');
    buffer.writeln(
      "              Type.into('${element.identifier}').text('Test Input'),",
    );
    buffer.writeln(
      '              Wait.forDuration(Duration(milliseconds: 300)),',
    );
    buffer.writeln('            ],');
    buffer.writeln('          ),');
    buffer.writeln('        );');
    buffer.writeln('');
    buffer.writeln(
      '        expect(result.status, TestStatus.passed, reason: result.error);',
    );
    buffer.writeln('      },');
    buffer.writeln('    );');
    buffer.writeln('');
  }

  /// Generate toggle test
  void _generateToggleTest(
    StringBuffer buffer,
    AppPage page,
    InteractiveElement element,
  ) {
    if (element.identifier == null) return;

    buffer.writeln('    testWidgets(');
    buffer.writeln("      'Should toggle ${element.identifier}',");
    buffer.writeln('      (WidgetTester tester) async {');
    buffer.writeln('        await initializeApp(tester);');
    buffer.writeln("        await navigateToPage(tester, '${page.route}');");
    buffer.writeln('');
    buffer.writeln(
      '        final result = await FlutterTestPilot.instance.runSuite(',
    );
    buffer.writeln('          TestSuite(');
    buffer.writeln("            name: 'Toggle ${element.identifier}',");
    buffer.writeln('            steps: [');
    buffer.writeln("              Tap.key('${element.identifier}'),");
    buffer.writeln(
      '              Wait.forDuration(Duration(milliseconds: 300)),',
    );
    buffer.writeln('            ],');
    buffer.writeln('          ),');
    buffer.writeln('        );');
    buffer.writeln('');
    buffer.writeln(
      '        expect(result.status, TestStatus.passed, reason: result.error);',
    );
    buffer.writeln('      },');
    buffer.writeln('    );');
    buffer.writeln('');
  }

  /// Generate navigation flow tests
  void _generateNavigationFlowTests(
    StringBuffer buffer,
    Map<String, List<String>> routeMap,
  ) {
    if (routeMap.isEmpty) return;

    buffer.writeln(
      '  // ═══════════════════════════════════════════════════════════════',
    );
    buffer.writeln('  // NAVIGATION FLOW TESTS');
    buffer.writeln(
      '  // ═══════════════════════════════════════════════════════════════',
    );
    buffer.writeln('');
    buffer.writeln("  group('Navigation Flow Tests', () {");

    for (final entry in routeMap.entries) {
      final from = entry.key;
      final destinations = entry.value;

      for (final to in destinations) {
        buffer.writeln('    testWidgets(');
        buffer.writeln(
          "      'Should navigate from ${_routeToName(from)} to ${_routeToName(to)}',",
        );
        buffer.writeln('      (WidgetTester tester) async {');
        buffer.writeln('        await initializeApp(tester);');
        buffer.writeln("        await navigateToPage(tester, '$from');");
        buffer.writeln('');
        buffer.writeln(
          '        // TODO: Tap the navigation element that leads to $to',
        );
        buffer.writeln("        await navigateToPage(tester, '$to');");
        buffer.writeln('');
        buffer.writeln(
          "        expect(find.text('${_routeToName(to)}'), findsOneWidget);",
        );
        buffer.writeln('      },');
        buffer.writeln('    );');
        buffer.writeln('');
      }
    }

    buffer.writeln('  });');
    buffer.writeln('');
  }

  /// Generate user journey tests
  void _generateUserJourneyTests(StringBuffer buffer, List<UserFlow> flows) {
    if (flows.isEmpty) return;

    buffer.writeln(
      '  // ═══════════════════════════════════════════════════════════════',
    );
    buffer.writeln('  // USER JOURNEY TESTS');
    buffer.writeln(
      '  // ═══════════════════════════════════════════════════════════════',
    );
    buffer.writeln('');
    buffer.writeln("  group('User Journey Tests', () {");

    for (final flow in flows) {
      buffer.writeln('    testWidgets(');
      buffer.writeln("      '${flow.name}',");
      buffer.writeln('      (WidgetTester tester) async {');
      buffer.writeln('        await initializeApp(tester);');
      buffer.writeln('');
      buffer.writeln('        // ${flow.description}');
      buffer.writeln(
        '        final result = await FlutterTestPilot.instance.runSuite(',
      );
      buffer.writeln('          TestSuite(');
      buffer.writeln("            name: '${flow.name}',");
      buffer.writeln("            description: '${flow.description}',");
      buffer.writeln('            steps: [');

      for (final step in flow.steps) {
        if (step.action == 'navigate') {
          buffer.writeln("              Tap.key('nav_${step.target}'),");
          buffer.writeln(
            '              Wait.forDuration(Duration(milliseconds: 500)),',
          );
        } else if (step.action == 'tap') {
          buffer.writeln("              Tap.key('${step.target}'),");
          buffer.writeln(
            '              Wait.forDuration(Duration(milliseconds: 300)),',
          );
        } else if (step.action == 'type' && step.inputData != null) {
          buffer.writeln(
            "              Type.into('${step.target}').text('${step.inputData}'),",
          );
          buffer.writeln(
            '              Wait.forDuration(Duration(milliseconds: 200)),',
          );
        } else if (step.action == 'verify') {
          buffer.writeln('              VerifyWidget(');
          buffer.writeln(
            "                finder: find.text('${step.expectedResult}'),",
          );
          buffer.writeln(
            "                customDescription: 'Verify ${step.expectedResult}',",
          );
          buffer.writeln('              ),');
        }
      }

      buffer.writeln('            ],');
      buffer.writeln('          ),');
      buffer.writeln('        );');
      buffer.writeln('');
      buffer.writeln(
        '        expect(result.status, TestStatus.passed, reason: result.error);',
      );
      buffer.writeln('      },');
      buffer.writeln('    );');
      buffer.writeln('');
    }

    buffer.writeln('  });');
    buffer.writeln('');
  }

  /// Generate edge case tests
  void _generateEdgeCaseTests(StringBuffer buffer, List<AppPage> pages) {
    buffer.writeln(
      '  // ═══════════════════════════════════════════════════════════════',
    );
    buffer.writeln('  // EDGE CASE TESTS');
    buffer.writeln(
      '  // ═══════════════════════════════════════════════════════════════',
    );
    buffer.writeln('');
    buffer.writeln("  group('Edge Case Tests', () {");
    buffer.writeln('    testWidgets(');
    buffer.writeln("      'Should handle rapid navigation',");
    buffer.writeln('      (WidgetTester tester) async {');
    buffer.writeln('        await initializeApp(tester);');
    buffer.writeln('');
    buffer.writeln('        // Rapidly navigate through pages');
    for (final page in pages.take(3)) {
      if (page.route != '/') {
        buffer.writeln(
          "        await navigateToPage(tester, '${page.route}');",
        );
        buffer.writeln(
          '        await tester.pump(Duration(milliseconds: 100));',
        );
      }
    }
    buffer.writeln('      },');
    buffer.writeln('    );');
    buffer.writeln('  });');
    buffer.writeln('');
  }

  /// Write helper methods
  void _writeHelperMethods(StringBuffer buffer) {
    buffer.writeln(
      '// ═══════════════════════════════════════════════════════════════',
    );
    buffer.writeln('// HELPER METHODS');
    buffer.writeln(
      '// ═══════════════════════════════════════════════════════════════',
    );
    buffer.writeln('');
    buffer.writeln('Future<void> initializeApp(WidgetTester tester) async {');
    buffer.writeln('  // TODO: Initialize your app');
    buffer.writeln('  // app.main();');
    buffer.writeln('  // await tester.pumpAndSettle();');
    buffer.writeln('  // FlutterTestPilot.initialize(tester);');
    buffer.writeln('}');
    buffer.writeln('');
    buffer.writeln(
      'Future<void> navigateToPage(WidgetTester tester, String route) async {',
    );
    buffer.writeln("  if (route == '/') return;");
    buffer.writeln("  final key = 'nav_\$route';");
    buffer.writeln('  await tester.tap(find.byKey(Key(key)));');
    buffer.writeln('  await tester.pumpAndSettle();');
    buffer.writeln('  FlutterTestPilot.initialize(tester);');
    buffer.writeln('}');
    buffer.writeln('');
  }

  /// Generate user flows from pages
  List<UserFlow> _generateUserFlows(
    List<AppPage> pages,
    Map<String, List<String>> routeMap,
  ) {
    final flows = <UserFlow>[];

    // Generate common user journeys
    flows.add(_generateCompleteAppTourFlow(pages));
    flows.add(_generateFormSubmissionFlow(pages));
    flows.add(_generateBackNavigationFlow(pages));

    return flows;
  }

  /// Generate complete app tour flow
  UserFlow _generateCompleteAppTourFlow(List<AppPage> pages) {
    final steps = <FlowStep>[];
    final routes = <String>[];

    for (final page in pages) {
      if (page.route != '/') {
        steps.add(
          FlowStep(
            action: 'navigate',
            target: page.route,
            expectedResult: '${page.name} page loads',
            waitTime: Duration(milliseconds: 500),
          ),
        );
        routes.add(page.route);
      }
    }

    return UserFlow(
      name: 'Complete App Tour',
      description: 'Navigate through all pages in the app',
      steps: steps,
      routes: routes,
      metadata: {'type': 'navigation_tour'},
    );
  }

  /// Generate form submission flow
  UserFlow _generateFormSubmissionFlow(List<AppPage> pages) {
    final steps = <FlowStep>[];
    final formPage = pages.firstWhere(
      (p) => p.elements.any((e) => e.type == 'textField'),
      orElse: () => pages.first,
    );

    // Navigate to form page
    if (formPage.route != '/') {
      steps.add(
        FlowStep(
          action: 'navigate',
          target: formPage.route,
          expectedResult: '${formPage.name} page loads',
        ),
      );
    }

    // Fill form fields
    for (final element in formPage.elements) {
      if (element.type == 'textField' && element.identifier != null) {
        steps.add(
          FlowStep(
            action: 'type',
            target: element.identifier!,
            inputData: 'Test Input',
          ),
        );
      } else if (element.type == 'button' && element.identifier != null) {
        steps.add(
          FlowStep(
            action: 'tap',
            target: element.identifier!,
            expectedResult: 'Form submitted',
          ),
        );
      }
    }

    return UserFlow(
      name: 'Form Submission Flow',
      description: 'Fill and submit a form',
      steps: steps,
      routes: [formPage.route],
      metadata: {'type': 'form_interaction'},
    );
  }

  /// Generate back navigation flow
  UserFlow _generateBackNavigationFlow(List<AppPage> pages) {
    final steps = <FlowStep>[];

    // Navigate forward
    for (final page in pages.take(3)) {
      if (page.route != '/') {
        steps.add(FlowStep(action: 'navigate', target: page.route));
      }
    }

    // Navigate back
    for (var i = 0; i < 2; i++) {
      steps.add(FlowStep(action: 'back', target: 'previous_page'));
    }

    return UserFlow(
      name: 'Back Navigation Flow',
      description: 'Navigate forward and back through pages',
      steps: steps,
      routes: pages.take(3).map((p) => p.route).toList(),
      metadata: {'type': 'navigation_back'},
    );
  }

  /// Extract navigation targets from widget
  List<String> _extractNavigationTargets(
    Widget widget,
    Map<String, WidgetBuilder> routes,
  ) {
    final targets = <String>[];

    // This is a simplified version - in production you'd analyze the widget tree
    // for Navigator.pushNamed calls and route references
    for (final route in routes.keys) {
      if (route != '/') {
        targets.add(route);
      }
    }

    return targets;
  }

  /// Extract state variables from widget
  List<String> _extractStateVariables(Widget widget) {
    final vars = <String>[];

    // In production, you'd analyze the State class fields
    if (widget is StatefulWidget) {
      vars.add('state_detected');
    }

    return vars;
  }

  /// Check if widget has async operations
  bool _hasAsyncOperations(Widget widget) {
    // Check for FutureBuilder, StreamBuilder, or State methods with async
    return widget is FutureBuilder || widget is StreamBuilder;
  }

  /// Convert route to readable name
  String _routeToName(String route) {
    if (route == '/') return 'Home';
    return route
        .replaceAll('/', '')
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Get widget type for element
  String _getWidgetType(String elementType) {
    switch (elementType) {
      case 'button':
        return 'ElevatedButton';
      case 'textField':
        return 'TextField';
      case 'appBar':
        return 'AppBar';
      case 'iconButton':
        return 'IconButton';
      case 'scrollable':
        return 'ListView';
      case 'toggle':
        return 'Checkbox';
      default:
        return 'Widget';
    }
  }

  /// Create dummy context for building widgets
  BuildContext _createDummyContext() {
    // Return a simple MaterialApp context for analysis purposes
    // This is a workaround for static analysis - in production use proper test environment
    return _DummyBuildContext();
  }

  /// Save content to file
  Future<void> _saveToFile(String content, String path) async {
    try {
      final file = File(path);
      final dir = file.parent;

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      await file.writeAsString(content);
      print('✅ Generated test file: $path');
    } catch (e) {
      print('⚠️  Could not save file: $e');
      print('Content:\n$content');
    }
  }
}

/// Dummy BuildContext for creating widgets during analysis
class _DummyBuildContext implements BuildContext {
  @override
  bool get debugDoingBuild => false;

  @override
  bool get mounted => true;

  @override
  InheritedWidget dependOnInheritedElement(
    InheritedElement ancestor, {
    Object? aspect,
  }) {
    throw UnimplementedError('DummyBuildContext is for analysis only');
  }

  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({
    Object? aspect,
  }) => null;

  @override
  T? getInheritedWidgetOfExactType<T extends InheritedWidget>() => null;

  @override
  InheritedElement?
  getElementForInheritedWidgetOfExactType<T extends InheritedWidget>() => null;

  @override
  T? findAncestorWidgetOfExactType<T extends Widget>() => null;

  @override
  T? findAncestorStateOfType<T extends State<StatefulWidget>>() => null;

  @override
  T? findRootAncestorStateOfType<T extends State<StatefulWidget>>() => null;

  @override
  T? findAncestorRenderObjectOfType<T extends RenderObject>() => null;

  @override
  RenderObject? findRenderObject() => null;

  @override
  void visitAncestorElements(bool Function(Element element) visitor) {}

  @override
  void visitChildElements(void Function(Element element) visitor) {}

  @override
  void dispatchNotification(Notification notification) {}

  @override
  DiagnosticsNode describeElement(
    String name, {
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty,
  }) {
    return DiagnosticsProperty<String>(name, 'DummyBuildContext');
  }

  @override
  DiagnosticsNode describeWidget(
    String name, {
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty,
  }) {
    return DiagnosticsProperty<String>(name, 'DummyBuildContext');
  }

  @override
  List<DiagnosticsNode> describeMissingAncestor({
    required Type expectedAncestorType,
  }) => [];

  @override
  DiagnosticsNode describeOwnershipChain(String name) {
    return DiagnosticsProperty<String>(name, 'DummyBuildContext');
  }

  @override
  Widget get widget => Container();

  @override
  BuildOwner? get owner => null;

  @override
  Size? get size => null;
}
