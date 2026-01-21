// accessibility_tester.dart - Comprehensive accessibility testing
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Accessibility testing utilities
class AccessibilityTester {
  static final AccessibilityTester _instance = AccessibilityTester._internal();
  factory AccessibilityTester() => _instance;
  AccessibilityTester._internal();

  bool _enabled = true;
  final List<AccessibilityIssue> _issues = [];

  // Accessibility standards
  double _minimumTouchTargetSize = 48.0; // Material Design minimum
  double _minimumTextSize = 12.0;

  /// Configure accessibility testing
  void configure({
    bool? enabled,
    double? minimumTouchTargetSize,
    double? minimumTextSize,
    double? minimumContrast,
  }) {
    if (enabled != null) _enabled = enabled;
    if (minimumTouchTargetSize != null)
      _minimumTouchTargetSize = minimumTouchTargetSize;
    if (minimumTextSize != null) _minimumTextSize = minimumTextSize;
    // minimumContrast parameter available for future use
  }

  /// Run comprehensive accessibility audit
  Future<AccessibilityReport> audit(WidgetTester tester) async {
    if (!_enabled) {
      return AccessibilityReport(issues: [], passed: true);
    }

    print('♿️ Running accessibility audit...');

    _issues.clear();

    // Check semantic labels
    await _checkSemanticLabels(tester);

    // Check touch target sizes
    await _checkTouchTargets(tester);

    // Check text contrast
    await _checkTextContrast(tester);

    // Check keyboard navigation
    await _checkKeyboardNavigation(tester);

    // Check screen reader support
    await _checkScreenReaderSupport(tester);

    final report = AccessibilityReport(
      issues: List.from(_issues),
      passed: _issues.isEmpty,
    );

    if (_issues.isEmpty) {
      print('✅ Accessibility audit passed');
    } else {
      print(
        '⚠️  Found ${_issues.length} accessibility ${_issues.length == 1 ? 'issue' : 'issues'}',
      );
    }

    return report;
  }

  /// Check semantic labels
  Future<void> _checkSemanticLabels(WidgetTester tester) async {
    // Find all interactive widgets
    final buttons = find.byType(ElevatedButton);
    final textButtons = find.byType(TextButton);
    final iconButtons = find.byType(IconButton);

    final allInteractive = [
      ...buttons.evaluate(),
      ...textButtons.evaluate(),
      ...iconButtons.evaluate(),
    ];

    for (final element in allInteractive) {
      final semantics = tester.getSemantics(find.byWidget(element.widget));

      if (semantics.label.isEmpty) {
        _issues.add(
          AccessibilityIssue(
            severity: IssueSeverity.warning,
            type: IssueType.missingLabel,
            message: 'Interactive widget missing semantic label',
            widget: element.widget.runtimeType.toString(),
            recommendation: 'Add Semantics widget with a descriptive label',
          ),
        );
      }
    }
  }

  /// Check touch target sizes
  Future<void> _checkTouchTargets(WidgetTester tester) async {
    final buttons = find.byType(GestureDetector);

    for (final element in buttons.evaluate()) {
      final renderBox = element.renderObject as RenderBox?;
      if (renderBox != null) {
        final size = renderBox.size;

        if (size.width < _minimumTouchTargetSize ||
            size.height < _minimumTouchTargetSize) {
          _issues.add(
            AccessibilityIssue(
              severity: IssueSeverity.error,
              type: IssueType.touchTargetTooSmall,
              message: 'Touch target too small: ${size.width}x${size.height}',
              widget: element.widget.runtimeType.toString(),
              recommendation:
                  'Increase size to at least ${_minimumTouchTargetSize}x$_minimumTouchTargetSize',
              details: {
                'current_width': size.width,
                'current_height': size.height,
                'minimum_size': _minimumTouchTargetSize,
              },
            ),
          );
        }
      }
    }
  }

  /// Check text contrast
  Future<void> _checkTextContrast(WidgetTester tester) async {
    final textWidgets = find.byType(Text);

    for (final element in textWidgets.evaluate()) {
      final text = element.widget as Text;
      final style = text.style;

      if (style != null) {
        // Check font size
        final fontSize = style.fontSize ?? 14.0;
        if (fontSize < _minimumTextSize) {
          _issues.add(
            AccessibilityIssue(
              severity: IssueSeverity.warning,
              type: IssueType.textTooSmall,
              message: 'Text size too small: ${fontSize}sp',
              widget: 'Text',
              recommendation:
                  'Increase font size to at least ${_minimumTextSize}sp',
              details: {
                'current_size': fontSize,
                'minimum_size': _minimumTextSize,
                'text_content': text.data?.substring(0, 20) ?? '',
              },
            ),
          );
        }

        // Note: Actual contrast checking would require background color analysis
        // This is a simplified check
        if (style.color != null && style.color!.alpha < 200) {
          _issues.add(
            AccessibilityIssue(
              severity: IssueSeverity.info,
              type: IssueType.lowContrast,
              message: 'Text color may have insufficient contrast',
              widget: 'Text',
              recommendation:
                  'Verify text meets WCAG AA contrast ratio of 4.5:1',
            ),
          );
        }
      }
    }
  }

  /// Check keyboard navigation
  Future<void> _checkKeyboardNavigation(WidgetTester tester) async {
    // Check if widgets have proper focus handling
    final focusableWidgets = find.byType(TextField);

    for (final element in focusableWidgets.evaluate()) {
      final widget = element.widget as TextField;

      if (widget.focusNode == null) {
        _issues.add(
          AccessibilityIssue(
            severity: IssueSeverity.info,
            type: IssueType.keyboardNavigation,
            message: 'TextField without explicit FocusNode',
            widget: 'TextField',
            recommendation:
                'Add FocusNode for better keyboard navigation control',
          ),
        );
      }
    }
  }

  /// Check screen reader support
  Future<void> _checkScreenReaderSupport(WidgetTester tester) async {
    final images = find.byType(Image);

    for (final element in images.evaluate()) {
      final semantics = tester.getSemantics(find.byWidget(element.widget));

      if (semantics.label.isEmpty) {
        _issues.add(
          AccessibilityIssue(
            severity: IssueSeverity.error,
            type: IssueType.missingLabel,
            message: 'Image without semantic label',
            widget: 'Image',
            recommendation:
                'Wrap Image in Semantics widget with descriptive label',
          ),
        );
      }
    }
  }

  /// Check specific widget accessibility
  Future<List<AccessibilityIssue>> checkWidget(
    WidgetTester tester,
    Finder finder,
  ) async {
    if (!_enabled) return [];

    final widgetIssues = <AccessibilityIssue>[];
    final element = finder.evaluate().firstOrNull;

    if (element == null) {
      return [
        AccessibilityIssue(
          severity: IssueSeverity.error,
          type: IssueType.other,
          message: 'Widget not found',
          widget: 'Unknown',
          recommendation: 'Verify widget exists in the tree',
        ),
      ];
    }

    // Check semantic label
    try {
      final semantics = tester.getSemantics(finder);
      if (semantics.label.isEmpty) {
        widgetIssues.add(
          AccessibilityIssue(
            severity: IssueSeverity.warning,
            type: IssueType.missingLabel,
            message: 'Widget missing semantic label',
            widget: element.widget.runtimeType.toString(),
            recommendation: 'Add semantic label for screen readers',
          ),
        );
      }
    } catch (e) {
      // Widget doesn't have semantics
      widgetIssues.add(
        AccessibilityIssue(
          severity: IssueSeverity.warning,
          type: IssueType.missingLabel,
          message: 'Widget has no semantic information',
          widget: element.widget.runtimeType.toString(),
          recommendation: 'Wrap in Semantics widget',
        ),
      );
    }

    return widgetIssues;
  }

  /// Get all issues
  List<AccessibilityIssue> get issues => List.unmodifiable(_issues);

  /// Generate accessibility report
  String generateReport() {
    if (_issues.isEmpty) {
      return '♿️ No accessibility issues found';
    }

    final buffer = StringBuffer();
    buffer.writeln('═' * 80);
    buffer.writeln('♿️ ACCESSIBILITY TESTING REPORT');
    buffer.writeln('═' * 80);
    buffer.writeln();

    // Group by severity
    final errors = _issues
        .where((i) => i.severity == IssueSeverity.error)
        .toList();
    final warnings = _issues
        .where((i) => i.severity == IssueSeverity.warning)
        .toList();
    final info = _issues
        .where((i) => i.severity == IssueSeverity.info)
        .toList();

    buffer.writeln('Summary:');
    buffer.writeln('  ❌ Errors: ${errors.length}');
    buffer.writeln('  ⚠️  Warnings: ${warnings.length}');
    buffer.writeln('  ℹ️  Info: ${info.length}');
    buffer.writeln();

    if (errors.isNotEmpty) {
      buffer.writeln('❌ ERRORS (must fix):');
      for (final issue in errors) {
        buffer.writeln('  • ${issue.message}');
        buffer.writeln('    Widget: ${issue.widget}');
        buffer.writeln('    Fix: ${issue.recommendation}');
        buffer.writeln();
      }
    }

    if (warnings.isNotEmpty) {
      buffer.writeln('⚠️  WARNINGS (should fix):');
      for (final issue in warnings) {
        buffer.writeln('  • ${issue.message}');
        buffer.writeln('    Widget: ${issue.widget}');
        buffer.writeln('    Fix: ${issue.recommendation}');
        buffer.writeln();
      }
    }

    if (info.isNotEmpty) {
      buffer.writeln('ℹ️  INFO (consider fixing):');
      for (final issue in info) {
        buffer.writeln('  • ${issue.message}');
        buffer.writeln('    Widget: ${issue.widget}');
        buffer.writeln();
      }
    }

    buffer.writeln('═' * 80);
    return buffer.toString();
  }

  /// Clear issues
  void clearIssues() {
    _issues.clear();
  }
}

/// Accessibility issue
class AccessibilityIssue {
  final IssueSeverity severity;
  final IssueType type;
  final String message;
  final String widget;
  final String recommendation;
  final Map<String, dynamic>? details;

  AccessibilityIssue({
    required this.severity,
    required this.type,
    required this.message,
    required this.widget,
    required this.recommendation,
    this.details,
  });

  @override
  String toString() {
    return '${_severityIcon(severity)} $message - $widget';
  }

  String _severityIcon(IssueSeverity severity) {
    switch (severity) {
      case IssueSeverity.error:
        return '❌';
      case IssueSeverity.warning:
        return '⚠️';
      case IssueSeverity.info:
        return 'ℹ️';
    }
  }
}

/// Issue severity
enum IssueSeverity { error, warning, info }

/// Issue type
enum IssueType {
  missingLabel,
  touchTargetTooSmall,
  textTooSmall,
  lowContrast,
  keyboardNavigation,
  other,
}

/// Accessibility report
class AccessibilityReport {
  final List<AccessibilityIssue> issues;
  final bool passed;

  AccessibilityReport({required this.issues, required this.passed});

  int get errorCount =>
      issues.where((i) => i.severity == IssueSeverity.error).length;
  int get warningCount =>
      issues.where((i) => i.severity == IssueSeverity.warning).length;
  int get infoCount =>
      issues.where((i) => i.severity == IssueSeverity.info).length;

  @override
  String toString() {
    return 'Accessibility Report: ${passed ? 'PASSED' : 'FAILED'} '
        '(Errors: $errorCount, Warnings: $warningCount, Info: $infoCount)';
  }
}
