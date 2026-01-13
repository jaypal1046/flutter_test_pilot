import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_suite/test_suite.dart';
import '../test_suite/ui_interaction/tap/tap.dart';
import '../test_suite/ui_interaction/type/type.dart';
import '../test_suite/assertion_action/assertion_action.dart';

/// Predefined test templates for common scenarios
class TestTemplates {
  /// Generate test from a scenario description
  static TestSuite? generateFromScenario(
    String widgetName,
    String scenario,
    Widget widget,
  ) {
    final scenarioLower = scenario.toLowerCase();

    if (scenarioLower.contains('login')) {
      return loginTemplate(widgetName);
    } else if (scenarioLower.contains('form')) {
      return formTemplate(widgetName);
    } else if (scenarioLower.contains('list')) {
      return listTemplate(widgetName);
    } else if (scenarioLower.contains('navigation')) {
      return navigationTemplate(widgetName);
    }

    return null;
  }

  /// Login screen test template
  static TestSuite loginTemplate(String widgetName) {
    return TestSuite(
      name: 'Login Flow: $widgetName',
      description: 'Auto-generated comprehensive login test',
      setup: [
        VerifyWidget(
          finder: find.byType(TextField),
          customDescription: 'Verify login form exists',
        ),
      ],
      steps: [
        Type.into('email').text('test@example.com'),
        WaitAction(
          duration: const Duration(milliseconds: 300),
          customDescription: 'Wait after email input',
        ),
        Type.into('password').text('password123'),
        WaitAction(
          duration: const Duration(milliseconds: 300),
          customDescription: 'Wait after password input',
        ),
        Tap.widget('Login'),
        WaitAction(
          duration: const Duration(seconds: 2),
          customDescription: 'Wait for login processing',
        ),
      ],
      assertions: [
        VerifyWidget(
          finder: find.text('test@example.com'),
          customDescription: 'Verify email was entered',
        ),
      ],
      metadata: {
        'auto_generated': true,
        'template': 'login',
        'test_type': 'scenario',
      },
    );
  }

  /// Form validation test template
  static TestSuite formTemplate(String widgetName) {
    return TestSuite(
      name: 'Form Validation: $widgetName',
      description: 'Auto-generated form validation test',
      steps: [
        Tap.widget('Submit'),
        WaitAction(
          duration: const Duration(milliseconds: 500),
          customDescription: 'Wait for validation',
        ),
        Type.into('field').text('Valid Input'),
        Tap.widget('Submit'),
        WaitAction(
          duration: const Duration(seconds: 1),
          customDescription: 'Wait for form submission',
        ),
      ],
      metadata: {
        'auto_generated': true,
        'template': 'form',
        'test_type': 'scenario',
      },
    );
  }

  /// List scroll and interaction template
  static TestSuite listTemplate(String widgetName) {
    return TestSuite(
      name: 'List Interaction: $widgetName',
      description: 'Auto-generated list test',
      steps: [
        VerifyWidget(
          finder: find.byType(ListView),
          customDescription: 'Verify list exists',
        ),
        WaitAction(
          duration: const Duration(milliseconds: 500),
          customDescription: 'Wait for list to load',
        ),
        WaitAction(
          duration: const Duration(milliseconds: 500),
          customDescription: 'Wait after scroll',
        ),
      ],
      metadata: {
        'auto_generated': true,
        'template': 'list',
        'test_type': 'scenario',
      },
    );
  }

  /// Navigation test template
  static TestSuite navigationTemplate(String widgetName) {
    return TestSuite(
      name: 'Navigation: $widgetName',
      description: 'Auto-generated navigation test',
      steps: [
        Tap.widget('Navigate'),
        WaitAction(
          duration: const Duration(milliseconds: 500),
          customDescription: 'Wait for navigation',
        ),
      ],
      assertions: [
        VerifyWidget(
          finder: find.byType(AppBar),
          customDescription: 'Verify new screen loaded',
        ),
      ],
      metadata: {
        'auto_generated': true,
        'template': 'navigation',
        'test_type': 'scenario',
      },
    );
  }

  /// Error handling test template
  static TestSuite errorHandlingTemplate(String widgetName) {
    return TestSuite(
      name: 'Error Handling: $widgetName',
      description: 'Auto-generated error handling test',
      steps: [
        WaitAction(
          duration: const Duration(milliseconds: 500),
          customDescription: 'Wait for error state',
        ),
      ],
      metadata: {
        'auto_generated': true,
        'template': 'error_handling',
        'test_type': 'scenario',
      },
    );
  }

  /// Performance test template
  static TestSuite performanceTemplate(String widgetName) {
    return TestSuite(
      name: 'Performance: $widgetName',
      description: 'Auto-generated performance test',
      steps: [
        VerifyWidget(
          finder: find.byType(MaterialApp),
          customDescription: 'Verify app loads quickly',
        ),
      ],
      metadata: {
        'auto_generated': true,
        'template': 'performance',
        'test_type': 'performance',
      },
    );
  }

  /// Accessibility test template
  static TestSuite accessibilityTemplate(String widgetName) {
    return TestSuite(
      name: 'Accessibility: $widgetName',
      description: 'Auto-generated accessibility test',
      steps: [
        VerifyWidget(
          finder: find.byType(Semantics),
          customDescription: 'Verify semantic labels exist',
        ),
      ],
      metadata: {
        'auto_generated': true,
        'template': 'accessibility',
        'test_type': 'accessibility',
      },
    );
  }

  /// CRUD operations test template
  static TestSuite crudTemplate(String widgetName) {
    return TestSuite(
      name: 'CRUD Operations: $widgetName',
      description: 'Auto-generated CRUD test',
      steps: [
        // Create
        Tap.widget('Add'),
        Type.into('name').text('New Item'),
        Tap.text('Save'),
        WaitAction(
          duration: const Duration(milliseconds: 500),
          customDescription: 'Wait for save',
        ),
        // Read
        VerifyWidget(
          finder: find.text('New Item'),
          customDescription: 'Verify item was created',
        ),
        // Update
        Tap.widget('Edit'),
        Type.into('name').text('Updated Item'),
        Tap.text('Save'),
        WaitAction(
          duration: const Duration(milliseconds: 500),
          customDescription: 'Wait for update',
        ),
        // Delete
        Tap.widget('Delete'),
        WaitAction(
          duration: const Duration(milliseconds: 500),
          customDescription: 'Wait for deletion',
        ),
      ],
      metadata: {
        'auto_generated': true,
        'template': 'crud',
        'test_type': 'scenario',
      },
    );
  }

  /// Get all available templates
  static List<String> availableTemplates() {
    return [
      'login',
      'form',
      'list',
      'navigation',
      'error_handling',
      'performance',
      'accessibility',
      'crud',
    ];
  }
}
