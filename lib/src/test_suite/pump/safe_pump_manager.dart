// =============================================================================
// SAFE PUMP MANAGER
// Centralized pumping logic that prevents conflicts and hangs
// =============================================================================

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import '../native_actions/native_action_handler.dart';

/// Strategy for pumping frames
enum PumpStrategy {
  /// Single frame pump (fastest)
  single,

  /// Multiple bounded pumps (safe for animations)
  bounded,

  /// Pump until idle OR timeout (replaces pumpAndSettle)
  untilIdleOrTimeout,

  /// Aggressive pumping for navigation (handles route transitions)
  navigation,

  /// Smart pumping with animation detection
  smart,
}

/// Result of a pump operation
class PumpResult {
  final bool success;
  final int framesPumped;
  final Duration duration;
  final String? error;
  final bool timedOut;
  final bool conflictDetected;

  const PumpResult({
    required this.success,
    required this.framesPumped,
    required this.duration,
    this.error,
    this.timedOut = false,
    this.conflictDetected = false,
  });

  factory PumpResult.success({
    required int framesPumped,
    required Duration duration,
  }) {
    return PumpResult(
      success: true,
      framesPumped: framesPumped,
      duration: duration,
    );
  }

  factory PumpResult.failure({
    required String error,
    required Duration duration,
    int framesPumped = 0,
    bool timedOut = false,
    bool conflictDetected = false,
  }) {
    return PumpResult(
      success: false,
      framesPumped: framesPumped,
      duration: duration,
      error: error,
      timedOut: timedOut,
      conflictDetected: conflictDetected,
    );
  }
}

/// Configuration for pump operations
class PumpConfig {
  final Duration frameDuration;
  final int maxFrames;
  final Duration timeout;
  final bool pauseNativeHandler;
  final bool retryOnConflict;
  final int maxConflictRetries;
  final Duration conflictRetryDelay;

  const PumpConfig({
    this.frameDuration = const Duration(milliseconds: 100),
    this.maxFrames = 50,
    this.timeout = const Duration(seconds: 10),
    this.pauseNativeHandler = true,
    this.retryOnConflict = true,
    this.maxConflictRetries = 3,
    this.conflictRetryDelay = const Duration(milliseconds: 100),
  });

  /// Quick config for single pump
  static const single = PumpConfig(maxFrames: 1, timeout: Duration(seconds: 1));

  /// Config for bounded pumping (safe default)
  static const bounded = PumpConfig(
    maxFrames: 20,
    timeout: Duration(seconds: 5),
  );

  /// Config for navigation transitions
  static const navigation = PumpConfig(
    frameDuration: Duration(milliseconds: 50),
    maxFrames: 60,
    timeout: Duration(seconds: 10),
  );

  /// Config for aggressive settling
  static const aggressive = PumpConfig(
    frameDuration: Duration(milliseconds: 16),
    maxFrames: 100,
    timeout: Duration(seconds: 15),
  );
}

/// Centralized pump manager that prevents conflicts and hangs
class SafePumpManager {
  static final SafePumpManager _instance = SafePumpManager._internal();
  static SafePumpManager get instance => _instance;

  SafePumpManager._internal();

  bool _isPumping = false;
  int _totalFramesPumped = 0;
  int _conflictCount = 0;
  int _successfulPumps = 0;
  int _failedPumps = 0;

  /// Get statistics
  Map<String, dynamic> get statistics => {
    'total_frames_pumped': _totalFramesPumped,
    'conflicts_detected': _conflictCount,
    'successful_pumps': _successfulPumps,
    'failed_pumps': _failedPumps,
    'currently_pumping': _isPumping,
  };

  /// Reset statistics
  void resetStatistics() {
    _totalFramesPumped = 0;
    _conflictCount = 0;
    _successfulPumps = 0;
    _failedPumps = 0;
  }

  /// Check if currently pumping
  bool get isPumping => _isPumping;

  /// Pump frames with the specified strategy
  Future<PumpResult> pump(
    WidgetTester tester, {
    PumpStrategy strategy = PumpStrategy.bounded,
    PumpConfig? config,
    String? debugLabel,
  }) async {
    final effectiveConfig = config ?? _getDefaultConfig(strategy);
    final stopwatch = Stopwatch()..start();
    int framesPumped = 0;

    if (_isPumping) {
      return PumpResult.failure(
        error: 'Pump already in progress',
        duration: stopwatch.elapsed,
        conflictDetected: true,
      );
    }

    _isPumping = true;

    try {
      // Pause native handler to avoid conflicts
      if (effectiveConfig.pauseNativeHandler) {
        NativeActionHandler.instance.pause();
      }

      switch (strategy) {
        case PumpStrategy.single:
          framesPumped = await _pumpSingle(tester, effectiveConfig);
          break;

        case PumpStrategy.bounded:
          framesPumped = await _pumpBounded(tester, effectiveConfig);
          break;

        case PumpStrategy.untilIdleOrTimeout:
          framesPumped = await _pumpUntilIdleOrTimeout(tester, effectiveConfig);
          break;

        case PumpStrategy.navigation:
          framesPumped = await _pumpNavigation(tester, effectiveConfig);
          break;

        case PumpStrategy.smart:
          framesPumped = await _pumpSmart(tester, effectiveConfig);
          break;
      }

      _totalFramesPumped += framesPumped;
      _successfulPumps++;

      stopwatch.stop();

      if (debugLabel != null) {
        print(
          '✅ SafePump ($debugLabel): $framesPumped frames in ${stopwatch.elapsedMilliseconds}ms',
        );
      }

      return PumpResult.success(
        framesPumped: framesPumped,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      _failedPumps++;

      if (e.toString().contains('Guarded function conflict')) {
        _conflictCount++;

        // Retry on conflict if enabled
        if (effectiveConfig.retryOnConflict) {
          return await _retryOnConflict(
            tester,
            strategy,
            effectiveConfig,
            debugLabel,
          );
        }

        return PumpResult.failure(
          error: 'Guarded function conflict',
          duration: stopwatch.elapsed,
          framesPumped: framesPumped,
          conflictDetected: true,
        );
      }

      return PumpResult.failure(
        error: e.toString(),
        duration: stopwatch.elapsed,
        framesPumped: framesPumped,
      );
    } finally {
      _isPumping = false;

      // Resume native handler
      if (effectiveConfig.pauseNativeHandler) {
        NativeActionHandler.instance.resume();
      }
    }
  }

  /// Retry pump operation after conflict
  Future<PumpResult> _retryOnConflict(
    WidgetTester tester,
    PumpStrategy strategy,
    PumpConfig config,
    String? debugLabel,
  ) async {
    for (int retry = 1; retry <= config.maxConflictRetries; retry++) {
      if (debugLabel != null) {
        print('🔄 SafePump ($debugLabel): Retry $retry after conflict');
      }

      await Future.delayed(config.conflictRetryDelay);

      final result = await pump(
        tester,
        strategy: strategy,
        config: config.copyWith(
          retryOnConflict: false,
        ), // Prevent infinite retry
        debugLabel: debugLabel,
      );

      if (result.success) {
        return result;
      }
    }

    return PumpResult.failure(
      error: 'Failed after ${config.maxConflictRetries} conflict retries',
      duration: Duration(
        milliseconds:
            config.maxConflictRetries *
            config.conflictRetryDelay.inMilliseconds,
      ),
      conflictDetected: true,
    );
  }

  /// Single frame pump
  Future<int> _pumpSingle(WidgetTester tester, PumpConfig config) async {
    await tester.pump(Duration.zero);
    return 1;
  }

  /// Bounded pumping (safe alternative to pumpAndSettle)
  Future<int> _pumpBounded(WidgetTester tester, PumpConfig config) async {
    int framesPumped = 0;

    for (int i = 0; i < config.maxFrames; i++) {
      await tester.pump(config.frameDuration);
      framesPumped++;

      // Check if we should stop early
      if (i > 5 && _isLikelySettled(tester)) {
        break;
      }
    }

    return framesPumped;
  }

  /// Pump until idle OR timeout (safe pumpAndSettle replacement)
  Future<int> _pumpUntilIdleOrTimeout(
    WidgetTester tester,
    PumpConfig config,
  ) async {
    int framesPumped = 0;
    final endTime = DateTime.now().add(config.timeout);

    try {
      // Try pumpAndSettle with timeout
      await tester.pumpAndSettle(config.frameDuration).timeout(config.timeout);

      // If successful, estimate frames pumped
      framesPumped = 10; // Estimate
    } catch (e) {
      if (e is TimeoutException) {
        // Timeout - fall back to bounded pumping
        while (DateTime.now().isBefore(endTime) &&
            framesPumped < config.maxFrames) {
          await tester.pump(config.frameDuration);
          framesPumped++;

          if (_isLikelySettled(tester)) {
            break;
          }
        }
      } else {
        rethrow;
      }
    }

    return framesPumped;
  }

  /// Pump for navigation transitions
  Future<int> _pumpNavigation(WidgetTester tester, PumpConfig config) async {
    int framesPumped = 0;

    // Initial pump to start transition
    await tester.pump(Duration.zero);
    framesPumped++;

    // Pump animation frames
    for (int i = 0; i < config.maxFrames - 1; i++) {
      await tester.pump(config.frameDuration);
      framesPumped++;

      // Navigation transitions typically complete within 300-400ms
      if (i > 6 && _isLikelySettled(tester)) {
        break;
      }
    }

    // Final stabilization pumps
    for (int i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      framesPumped++;
    }

    return framesPumped;
  }

  /// Smart pumping with animation detection
  Future<int> _pumpSmart(WidgetTester tester, PumpConfig config) async {
    int framesPumped = 0;
    bool hasAnimations = false;

    // Try to detect continuous animations
    try {
      // Quick check: pump a few frames and see if we can settle
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        framesPumped++;
      }

      // Try to settle - if it times out quickly, we have continuous animations
      await tester
          .pumpAndSettle(const Duration(milliseconds: 16))
          .timeout(const Duration(milliseconds: 500));

      framesPumped += 5; // Estimate
    } on TimeoutException {
      // Continuous animation detected
      hasAnimations = true;
    } catch (e) {
      // Other error - assume animations
      hasAnimations = true;
    }

    if (hasAnimations) {
      // Use bounded pumping for continuous animations
      final remainingFrames = config.maxFrames - framesPumped;
      for (int i = 0; i < remainingFrames; i++) {
        await tester.pump(config.frameDuration);
        framesPumped++;
      }
    }

    return framesPumped;
  }

  /// Check if UI is likely settled
  bool _isLikelySettled(WidgetTester tester) {
    // This is a heuristic - in practice, you might check for:
    // - No pending timers
    // - No active animations
    // - No pending microtasks
    // For now, we rely on the bounded frame count
    return false; // Conservative: keep pumping until max frames
  }

  /// Get default config for strategy
  PumpConfig _getDefaultConfig(PumpStrategy strategy) {
    switch (strategy) {
      case PumpStrategy.single:
        return PumpConfig.single;
      case PumpStrategy.bounded:
        return PumpConfig.bounded;
      case PumpStrategy.navigation:
        return PumpConfig.navigation;
      case PumpStrategy.untilIdleOrTimeout:
      case PumpStrategy.smart:
        return PumpConfig.aggressive;
    }
  }

  /// Wait with pumping
  Future<PumpResult> waitAndPump(
    WidgetTester tester, {
    required Duration duration,
    PumpStrategy strategy = PumpStrategy.bounded,
    PumpConfig? config,
    String? debugLabel,
  }) async {
    await Future.delayed(duration);
    return await pump(
      tester,
      strategy: strategy,
      config: config,
      debugLabel: debugLabel,
    );
  }

  /// Pump frames in a loop with condition
  Future<PumpResult> pumpUntil(
    WidgetTester tester, {
    required bool Function() condition,
    PumpStrategy strategy = PumpStrategy.bounded,
    PumpConfig? config,
    Duration checkInterval = const Duration(milliseconds: 500),
    Duration timeout = const Duration(seconds: 30),
    String? debugLabel,
  }) async {
    final stopwatch = Stopwatch()..start();
    final endTime = DateTime.now().add(timeout);
    int totalFrames = 0;

    while (DateTime.now().isBefore(endTime)) {
      if (condition()) {
        return PumpResult.success(
          framesPumped: totalFrames,
          duration: stopwatch.elapsed,
        );
      }

      final result = await pump(
        tester,
        strategy: strategy,
        config: config,
        debugLabel: debugLabel,
      );

      totalFrames += result.framesPumped;

      if (!result.success) {
        return result;
      }

      await Future.delayed(checkInterval);
    }

    return PumpResult.failure(
      error: 'Condition not met within timeout',
      duration: stopwatch.elapsed,
      framesPumped: totalFrames,
      timedOut: true,
    );
  }

  /// Print statistics
  void printStatistics() {
    print('');
    print('═══════════════════════════════════════════════════════');
    print('📊 Safe Pump Manager Statistics');
    print('═══════════════════════════════════════════════════════');
    print('Total frames pumped: $_totalFramesPumped');
    print('Successful pumps: $_successfulPumps');
    print('Failed pumps: $_failedPumps');
    print('Conflicts detected: $_conflictCount');
    print('Currently pumping: $_isPumping');
    print('═══════════════════════════════════════════════════════');
    print('');
  }
}

/// Extension for copyWith on PumpConfig
extension PumpConfigExtension on PumpConfig {
  PumpConfig copyWith({
    Duration? frameDuration,
    int? maxFrames,
    Duration? timeout,
    bool? pauseNativeHandler,
    bool? retryOnConflict,
    int? maxConflictRetries,
    Duration? conflictRetryDelay,
  }) {
    return PumpConfig(
      frameDuration: frameDuration ?? this.frameDuration,
      maxFrames: maxFrames ?? this.maxFrames,
      timeout: timeout ?? this.timeout,
      pauseNativeHandler: pauseNativeHandler ?? this.pauseNativeHandler,
      retryOnConflict: retryOnConflict ?? this.retryOnConflict,
      maxConflictRetries: maxConflictRetries ?? this.maxConflictRetries,
      conflictRetryDelay: conflictRetryDelay ?? this.conflictRetryDelay,
    );
  }
}

/// Extension methods on WidgetTester for safe pumping
extension SafePumpExtensions on WidgetTester {
  /// Safe single pump
  Future<PumpResult> safePump({String? debugLabel}) async {
    return await SafePumpManager.instance.pump(
      this,
      strategy: PumpStrategy.single,
      debugLabel: debugLabel,
    );
  }

  /// Safe bounded pump (replaces manual loops)
  Future<PumpResult> safePumpBounded({
    int? maxFrames,
    Duration? frameDuration,
    String? debugLabel,
  }) async {
    return await SafePumpManager.instance.pump(
      this,
      strategy: PumpStrategy.bounded,
      config: PumpConfig.bounded.copyWith(
        maxFrames: maxFrames,
        frameDuration: frameDuration,
      ),
      debugLabel: debugLabel,
    );
  }

  /// Safe pump and settle (with timeout protection)
  Future<PumpResult> safePumpAndSettle({
    Duration? timeout,
    String? debugLabel,
  }) async {
    return await SafePumpManager.instance.pump(
      this,
      strategy: PumpStrategy.untilIdleOrTimeout,
      config: PumpConfig.aggressive.copyWith(timeout: timeout),
      debugLabel: debugLabel,
    );
  }

  /// Safe pump for navigation
  Future<PumpResult> safePumpNavigation({String? debugLabel}) async {
    return await SafePumpManager.instance.pump(
      this,
      strategy: PumpStrategy.navigation,
      debugLabel: debugLabel,
    );
  }

  /// Safe smart pump (auto-detects animations)
  Future<PumpResult> safePumpSmart({String? debugLabel}) async {
    return await SafePumpManager.instance.pump(
      this,
      strategy: PumpStrategy.smart,
      debugLabel: debugLabel,
    );
  }

  /// Wait and then pump
  Future<PumpResult> waitAndPump(
    Duration duration, {
    PumpStrategy strategy = PumpStrategy.bounded,
    String? debugLabel,
  }) async {
    return await SafePumpManager.instance.waitAndPump(
      this,
      duration: duration,
      strategy: strategy,
      debugLabel: debugLabel,
    );
  }

  /// Pump until condition is met
  Future<PumpResult> pumpUntil(
    bool Function() condition, {
    Duration? timeout,
    String? debugLabel,
  }) async {
    return await SafePumpManager.instance.pumpUntil(
      this,
      condition: condition,
      timeout: timeout ?? const Duration(seconds: 30),
      debugLabel: debugLabel,
    );
  }
}
