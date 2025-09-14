// flutter_test_pilot/lib/flutter_test_pilot.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Global variable tracker - this is what your app will use
class TestPilotGlobal {
  static final Map<String, dynamic> _variables = {};
  static final List<Map<String, dynamic>> _variableHistory = [];
  
  static void trackVariable(String name, dynamic value) {
    _variables[name] = value;
    _variableHistory.add({
      'name': name,
      'value': value,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    if (kDebugMode) {
      print('TestPilot Tracking: $name = $value');
    }
  }
  
  static dynamic getVariable(String name) => _variables[name];
  static Map<String, dynamic> getAllVariables() => Map.from(_variables);
  static List<Map<String, dynamic>> getVariableHistory() => List.from(_variableHistory);
  static void clearVariables() {
    _variables.clear();
    _variableHistory.clear();
  }
}

// Main Test Pilot Class
class FlutterTestPilot {
  late WidgetTester _tester;
  final List<TestStepResult> _results = [];
  
  // Initialize with the tester from testWidgets
  void initialize(WidgetTester tester) {
    _tester = tester;
    TestPilotGlobal.clearVariables();
  }
  
  // Load test configuration from JSON
  static Future<TestSuite> loadTestSuite(String configPath) async {
    final file = File(configPath);
    final jsonString = await file.readAsString();
    final jsonData = json.decode(jsonString);
    return TestSuite.fromJson(jsonData);
  }
  
  // Execute complete test suite
  Future<TestSuiteResult> runTestSuite(TestSuite suite) async {
    final results = <TestResult>[];
    
    for (final testCase in suite.testCases) {
      final result = await runTestCase(testCase);
      results.add(result);
      
      // Stop on failure if specified
      if (!result.passed && suite.stopOnFailure) {
        break;
      }
    }
    
    return TestSuiteResult(
      suiteName: suite.name,
      results: results,
      passed: results.every((r) => r.passed),
      htmlReport: _generateHtmlReport(suite.name, results),
    );
  }
  
  // Execute single test case
  Future<TestResult> runTestCase(TestCase testCase) async {
    final stepResults = <TestStepResult>[];
    
    print('\n=== Running Test Case: ${testCase.name} ===');
    
    try {
      for (int i = 0; i < testCase.steps.length; i++) {
        final step = testCase.steps[i];
        print('Step ${i + 1}: ${step.name}');
        
        final stepResult = await executeTestStep(step);
        stepResults.add(stepResult);
        
        if (!stepResult.passed) {
          print('❌ Step failed: ${stepResult.message}');
          break;
        } else {
          print('✅ Step passed: ${stepResult.message}');
        }
      }
      
      return TestResult(
        testName: testCase.name,
        steps: stepResults,
        passed: stepResults.every((s) => s.passed),
      );
    } catch (e) {
      return TestResult(
        testName: testCase.name,
        steps: stepResults,
        passed: false,
        error: e.toString(),
      );
    }
  }
  
  // Execute individual test step
  Future<TestStepResult> executeTestStep(TestStep step) async {
    try {
      // 1. Perform the action
      await _performAction(step.action);
      
      // 2. Wait if specified
      if (step.waitMs != null) {
        await Future.delayed(Duration(milliseconds: step.waitMs!));
      }
      
      // 3. Validate variables if specified
      if (step.variableValidation != null) {
        final validation = _validateVariables(step.variableValidation!);
        return TestStepResult(
          stepName: step.name,
          action: step.action.type.toString(),
          passed: validation.passed,
          message: validation.message,
          actualValues: validation.actualValues,
          expectedValues: validation.expectedValues,
        );
      }
      
      return TestStepResult(
        stepName: step.name,
        action: step.action.type.toString(),
        passed: true,
        message: 'Action completed successfully',
      );
    } catch (e) {
      return TestStepResult(
        stepName: step.name,
        action: step.action.type.toString(),
        passed: false,
        message: 'Step failed: $e',
      );
    }
  }
  
  // Perform UI actions programmatically
  Future<void> _performAction(TestAction action) async {
    switch (action.type) {
      case ActionType.tap:
        final finder = find.byKey(Key(action.target!));
        await _tester.ensureVisible(finder);
        await _tester.tap(finder);
        break;
        
      case ActionType.enterText:
        final finder = find.byKey(Key(action.target!));
        await _tester.ensureVisible(finder);
        await _tester.enterText(finder, action.value!);
        break;
        
      case ActionType.scroll:
        final finder = find.byKey(Key(action.target!));
        await _tester.drag(finder, Offset(0, action.scrollOffset ?? -200));
        break;
        
      case ActionType.wait:
        await Future.delayed(Duration(milliseconds: action.waitMs ?? 1000));
        break;
        
      case ActionType.navigate:
        // For navigation, we wait for the new page to appear
        if (action.target != null) {
          await _tester.pumpAndSettle();
          final finder = find.byKey(Key(action.target!));
          await _tester.pumpAndSettle(Duration(seconds: 2));
        }
        break;
    }
    
    // Always pump and settle after actions
    await _tester.pumpAndSettle();
  }
  
  // Validate variables against expected values
  ValidationResult _validateVariables(VariableValidation validation) {
    final actualValues = TestPilotGlobal.getAllVariables();
    final expectedValues = validation.expectedValues;
    final errors = <String>[];
    
    for (final expectedKey in expectedValues.keys) {
      final expectedValue = expectedValues[expectedKey];
      final actualValue = actualValues[expectedKey];
      
      // Handle special validation cases
      if (expectedValue == "not_null") {
        if (actualValue == null) {
          errors.add('Variable "$expectedKey": expected not null, got null');
        }
      } else if (expectedValue == "null") {
        if (actualValue != null) {
          errors.add('Variable "$expectedKey": expected null, got $actualValue');
        }
      } else if (expectedValue != actualValue) {
        errors.add('Variable "$expectedKey": expected $expectedValue, got $actualValue');
      }
    }
    
    return ValidationResult(
      passed: errors.isEmpty,
      message: errors.isEmpty 
        ? 'All variables validated successfully' 
        : 'Validation errors: ${errors.join(', ')}',
      actualValues: actualValues,
      expectedValues: expectedValues,
    );
  }
  
  // Generate HTML report
  String _generateHtmlReport(String suiteName, List<TestResult> results) {
    final passedCount = results.where((r) => r.passed).length;
    final totalCount = results.length;
    final timestamp = DateTime.now().toString();
    
    final html = '''
<!DOCTYPE html>
<html>
<head>
    <title>Flutter Test Pilot Report - $suiteName</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f5f5f5; padding: 20px; border-radius: 8px; }
        .passed { color: #28a745; }
        .failed { color: #dc3545; }
        .test-case { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .step { margin: 10px 0; padding: 10px; background: #f9f9f9; }
        .step.failed { background: #f8d7da; }
        .variables { margin: 10px 0; }
        .variable-item { margin: 5px 0; font-family: monospace; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Flutter Test Pilot Report</h1>
        <h2>$suiteName</h2>
        <p><strong>Generated:</strong> $timestamp</p>
        <p><strong>Results:</strong> <span class="${passedCount == totalCount ? 'passed' : 'failed'}">$passedCount/$totalCount tests passed</span></p>
    </div>
''';

    final testResults = results.map((result) {
      final stepResults = result.steps.map((step) {
        final statusClass = step.passed ? 'passed' : 'failed';
        final statusIcon = step.passed ? '✅' : '❌';
        
        String variablesHtml = '';
        if (step.actualValues != null && step.expectedValues != null) {
          variablesHtml = '''
            <div class="variables">
                <strong>Expected Variables:</strong>
                ${step.expectedValues!.entries.map((e) => '<div class="variable-item">${e.key}: ${e.value}</div>').join('')}
                <strong>Actual Variables:</strong>
                ${step.actualValues!.entries.map((e) => '<div class="variable-item">${e.key}: ${e.value}</div>').join('')}
            </div>
          ''';
        }
        
        return '''
          <div class="step ${step.passed ? '' : 'failed'}">
              <strong>$statusIcon ${step.stepName}</strong> (${step.action})
              <p>${step.message}</p>
              $variablesHtml
          </div>
        ''';
      }).join('');
      
      return '''
        <div class="test-case">
            <h3 class="${result.passed ? 'passed' : 'failed'}">${result.passed ? '✅' : '❌'} ${result.testName}</h3>
            $stepResults
        </div>
      ''';
    }).join('');

    return html + testResults + '''
    <div class="header">
        <h3>Variable History</h3>
        ${TestPilotGlobal.getVariableHistory().map((v) => '<div class="variable-item">${v['timestamp']}: ${v['name']} = ${v['value']}</div>').join('')}
    </div>
</body>
</html>''';
  }
}

// Data Models
class TestSuite {
  final String name;
  final List<TestCase> testCases;
  final bool stopOnFailure;
  
  TestSuite({
    required this.name,
    required this.testCases,
    this.stopOnFailure = true,
  });
  
  factory TestSuite.fromJson(Map<String, dynamic> json) {
    return TestSuite(
      name: json['name'],
      testCases: (json['test_cases'] as List).map((e) => TestCase.fromJson(e)).toList(),
      stopOnFailure: json['stop_on_failure'] ?? true,
    );
  }
}

class TestCase {
  final String name;
  final String description;
  final List<TestStep> steps;
  
  TestCase({
    required this.name,
    required this.description,
    required this.steps,
  });
  
  factory TestCase.fromJson(Map<String, dynamic> json) {
    return TestCase(
      name: json['name'],
      description: json['description'] ?? '',
      steps: (json['steps'] as List).map((e) => TestStep.fromJson(e)).toList(),
    );
  }
}

class TestStep {
  final String name;
  final TestAction action;
  final VariableValidation? variableValidation;
  final int? waitMs;
  
  TestStep({
    required this.name,
    required this.action,
    this.variableValidation,
    this.waitMs,
  });
  
  factory TestStep.fromJson(Map<String, dynamic> json) {
    return TestStep(
      name: json['name'],
      action: TestAction.fromJson(json['action']),
      variableValidation: json['variable_validation'] != null
          ? VariableValidation.fromJson(json['variable_validation'])
          : null,
      waitMs: json['wait_ms'],
    );
  }
}

class TestAction {
  final ActionType type;
  final String? target;
  final String? value;
  final int? waitMs;
  final double? scrollOffset;
  
  TestAction({
    required this.type,
    this.target,
    this.value,
    this.waitMs,
    this.scrollOffset,
  });
  
  factory TestAction.fromJson(Map<String, dynamic> json) {
    return TestAction(
      type: ActionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type']
      ),
      target: json['target'],
      value: json['value'],
      waitMs: json['wait_ms'],
      scrollOffset: json['scroll_offset']?.toDouble(),
    );
  }
}

class VariableValidation {
  final Map<String, dynamic> expectedValues;
  
  VariableValidation({required this.expectedValues});
  
  factory VariableValidation.fromJson(Map<String, dynamic> json) {
    return VariableValidation(expectedValues: json);
  }
}

enum ActionType {
  tap,
  enterText,
  scroll,
  wait,
  navigate,
}

// Result Models
class TestSuiteResult {
  final String suiteName;
  final List<TestResult> results;
  final bool passed;
  final String htmlReport;
  
  TestSuiteResult({
    required this.suiteName,
    required this.results,
    required this.passed,
    required this.htmlReport,
  });
  
  // Save HTML report to file
  Future<void> saveHtmlReport(String filePath) async {
    final file = File(filePath);
    await file.writeAsString(htmlReport);
  }
}

class TestResult {
  final String testName;
  final List<TestStepResult> steps;
  final bool passed;
  final String? error;
  
  TestResult({
    required this.testName,
    required this.steps,
    required this.passed,
    this.error,
  });
}

class TestStepResult {
  final String stepName;
  final String action;
  final bool passed;
  final String message;
  final Map<String, dynamic>? actualValues;
  final Map<String, dynamic>? expectedValues;
  
  TestStepResult({
    required this.stepName,
    required this.action,
    required this.passed,
    required this.message,
    this.actualValues,
    this.expectedValues,
  });
}

class ValidationResult {
  final bool passed;
  final String message;
  final Map<String, dynamic> actualValues;
  final Map<String, dynamic> expectedValues;
  
  ValidationResult({
    required this.passed,
    required this.message,
    required this.actualValues,
    required this.expectedValues,
  });
}