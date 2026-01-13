// test_recorder.dart - Intelligent test recorder for automatic test generation
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'dart:io';

/// Records user interactions and generates test code automatically
class TestRecorder {
  static final TestRecorder _instance = TestRecorder._();
  TestRecorder._();

  static TestRecorder get instance => _instance;

  final List<RecordedAction> _actions = [];
  bool _isRecording = false;
  DateTime? _recordingStartTime;

  /// Start recording
  void startRecording() {
    _isRecording = true;
    _recordingStartTime = DateTime.now();
    _actions.clear();
    print('🎬 Recording started...');
  }

  /// Stop recording
  RecordingSession stopRecording() {
    _isRecording = false;
    final session = RecordingSession(
      actions: List.from(_actions),
      startTime: _recordingStartTime!,
      endTime: DateTime.now(),
    );
    print('⏹️  Recording stopped. Captured ${_actions.length} actions.');
    return session;
  }

  /// Record a tap action
  void recordTap(String description, {String? key, String? text}) {
    if (!_isRecording) return;

    _actions.add(
      RecordedAction(
        type: ActionType.tap,
        description: description,
        key: key,
        text: text,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Record text input
  void recordTextInput(String text, {String? fieldKey}) {
    if (!_isRecording) return;

    _actions.add(
      RecordedAction(
        type: ActionType.input,
        description: 'Enter text: $text',
        key: fieldKey,
        text: text,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Record navigation
  void recordNavigation(String route) {
    if (!_isRecording) return;

    _actions.add(
      RecordedAction(
        type: ActionType.navigate,
        description: 'Navigate to: $route',
        text: route,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Record assertion
  void recordAssertion(String description, {bool passed = true}) {
    if (!_isRecording) return;

    _actions.add(
      RecordedAction(
        type: ActionType.assertion,
        description: description,
        data: {'passed': passed},
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Record wait action
  void recordWait(Duration duration) {
    if (!_isRecording) return;

    _actions.add(
      RecordedAction(
        type: ActionType.wait,
        description: 'Wait for ${duration.inMilliseconds}ms',
        data: {'durationMs': duration.inMilliseconds},
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Record custom action
  void recordCustom(String description, Map<String, dynamic>? data) {
    if (!_isRecording) return;

    _actions.add(
      RecordedAction(
        type: ActionType.custom,
        description: description,
        data: data,
        timestamp: DateTime.now(),
      ),
    );
  }

  bool get isRecording => _isRecording;
  List<RecordedAction> get actions => List.from(_actions);
}

/// Recorded action
class RecordedAction {
  final ActionType type;
  final String description;
  final String? key;
  final String? text;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  RecordedAction({
    required this.type,
    required this.description,
    this.key,
    this.text,
    this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'description': description,
      'key': key,
      'text': text,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Action types
enum ActionType { tap, input, navigate, assertion, wait, scroll, swipe, custom }

/// Recording session
class RecordingSession {
  final List<RecordedAction> actions;
  final DateTime startTime;
  final DateTime endTime;

  RecordingSession({
    required this.actions,
    required this.startTime,
    required this.endTime,
  });

  Duration get duration => endTime.difference(startTime);

  /// Generate Dart test code from recording
  String generateTestCode({String testName = 'recorded_test'}) {
    final buffer = StringBuffer();

    buffer.writeln("import 'package:flutter_test/flutter_test.dart';");
    buffer.writeln(
      "import 'package:flutter_test_pilot/flutter_test_pilot.dart';",
    );
    buffer.writeln();
    buffer.writeln("void main() {");
    buffer.writeln("  testWidgets('$testName', (WidgetTester tester) async {");
    buffer.writeln("    // Auto-generated test from recording");
    buffer.writeln("    // Recording duration: ${duration.inSeconds}s");
    buffer.writeln();

    for (int i = 0; i < actions.length; i++) {
      final action = actions[i];
      buffer.writeln("    // Step ${i + 1}: ${action.description}");

      switch (action.type) {
        case ActionType.tap:
          if (action.key != null) {
            buffer.writeln(
              "    await tester.tap(find.byKey(Key('${action.key}')));",
            );
          } else if (action.text != null) {
            buffer.writeln(
              "    await tester.tap(find.text('${action.text}'));",
            );
          }
          buffer.writeln("    await tester.pumpAndSettle();");
          break;

        case ActionType.input:
          if (action.key != null) {
            buffer.writeln(
              "    await tester.enterText(find.byKey(Key('${action.key}')), '${action.text}');",
            );
          } else {
            buffer.writeln(
              "    await tester.enterText(find.byType(TextField), '${action.text}');",
            );
          }
          buffer.writeln("    await tester.pumpAndSettle();");
          break;

        case ActionType.navigate:
          buffer.writeln("    // Navigation to: ${action.text}");
          break;

        case ActionType.assertion:
          buffer.writeln("    // Assertion: ${action.description}");
          buffer.writeln(
            "    expect(true, isTrue); // TODO: Implement actual assertion",
          );
          break;

        case ActionType.wait:
          final ms = action.data?['durationMs'] ?? 0;
          buffer.writeln("    await tester.pump(Duration(milliseconds: $ms));");
          break;

        default:
          buffer.writeln("    // Custom action: ${action.description}");
      }

      buffer.writeln();
    }

    buffer.writeln("  });");
    buffer.writeln("}");

    return buffer.toString();
  }

  /// Save recording to file
  Future<void> saveToFile(String path) async {
    final file = File(path);

    // Save as JSON
    if (path.endsWith('.json')) {
      final json = {
        'recording': {
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
          'duration': duration.inMilliseconds,
          'actions': actions.map((a) => a.toJson()).toList(),
        },
      };
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(json),
      );
    }
    // Save as Dart test code
    else {
      final code = generateTestCode(
        testName: path.split('/').last.replaceAll('.dart', ''),
      );
      await file.writeAsString(code);
    }

    print('💾 Recording saved to: $path');
  }

  /// Load recording from file
  static Future<RecordingSession?> loadFromFile(String path) async {
    try {
      final file = File(path);
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final recording = json['recording'] as Map<String, dynamic>;

      final actions = (recording['actions'] as List)
          .map(
            (a) => RecordedAction(
              type: ActionType.values.firstWhere((t) => t.name == a['type']),
              description: a['description'],
              key: a['key'],
              text: a['text'],
              data: a['data'],
              timestamp: DateTime.parse(a['timestamp']),
            ),
          )
          .toList();

      return RecordingSession(
        actions: actions,
        startTime: DateTime.parse(recording['startTime']),
        endTime: DateTime.parse(recording['endTime']),
      );
    } catch (e) {
      print('❌ Failed to load recording: $e');
      return null;
    }
  }
}
