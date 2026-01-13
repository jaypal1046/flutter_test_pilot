import 'package:flutter_test/flutter_test.dart';
import '../step_result.dart';
import '../test_action.dart';

/// Assertion action for verifying widgets exist and have expected properties
class VerifyWidget extends TestAction {
  final Finder finder;
  final String? customDescription;
  final bool shouldExist;
  final int? expectedCount;

  const VerifyWidget({
    required this.finder,
    this.customDescription,
    this.shouldExist = true,
    this.expectedCount,
  });

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    try {
      final count = tester.widgetList(finder).length;

      if (!shouldExist && count > 0) {
        stopwatch.stop();
        return StepResult.failure(
          'Widget should not exist but found $count instances',
          duration: stopwatch.elapsed,
        );
      }

      if (shouldExist && count == 0) {
        stopwatch.stop();
        return StepResult.failure(
          'Widget not found: ${customDescription ?? finder.toString()}',
          duration: stopwatch.elapsed,
        );
      }

      if (expectedCount != null && count != expectedCount) {
        stopwatch.stop();
        return StepResult.failure(
          'Expected $expectedCount widgets but found $count',
          duration: stopwatch.elapsed,
        );
      }

      stopwatch.stop();
      return StepResult.success(
        message: 'Verified: ${customDescription ?? finder.toString()}',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Verification failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  @override
  String get description => customDescription ?? 'Verify widget exists';
}

/// Action for waiting
class WaitAction extends TestAction {
  final Duration duration;
  final String? customDescription;

  const WaitAction({
    required this.duration,
    this.customDescription,
  });

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    await Future.delayed(duration);
    
    // CRITICAL FIX: Use bounded pump instead of pumpAndSettle
    // pumpAndSettle will hang if there are continuous animations
    try {
      // Pump frames to allow UI updates during the wait
      final pumpCount = (duration.inMilliseconds / 100).ceil().clamp(1, 10);
      for (int i = 0; i < pumpCount; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    } catch (e) {
      // If pump fails, log but don't fail the test
      print('⚠️  Pump warning during wait (non-fatal): $e');
    }

    stopwatch.stop();
    return StepResult.success(
      message: 'Waited for ${duration.inMilliseconds}ms',
      duration: stopwatch.elapsed,
    );
  }

  @override
  String get description => customDescription ?? 'Wait ${duration.inMilliseconds}ms';
}
