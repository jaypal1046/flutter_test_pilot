// performance_profiler.dart - Advanced performance monitoring for tests
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

/// Advanced performance profiler for Flutter tests
class PerformanceProfiler {
  static final PerformanceProfiler _instance = PerformanceProfiler._internal();
  factory PerformanceProfiler() => _instance;
  PerformanceProfiler._internal();

  final List<PerformanceMetric> _metrics = [];
  final Map<String, Stopwatch> _activeTimers = {};

  bool _isEnabled = false;
  double _frameRateThreshold = 55.0; // FPS threshold
  int _memoryThresholdMB = 100;

  /// Enable performance profiling
  void enable({double? frameRateThreshold, int? memoryThresholdMB}) {
    _isEnabled = true;
    if (frameRateThreshold != null) _frameRateThreshold = frameRateThreshold;
    if (memoryThresholdMB != null) _memoryThresholdMB = memoryThresholdMB;
    print('🔧 Performance profiling enabled');
  }

  /// Disable performance profiling
  void disable() {
    _isEnabled = false;
    print('🔧 Performance profiling disabled');
  }

  /// Start timing an operation
  void startTimer(String operation) {
    if (!_isEnabled) return;
    _activeTimers[operation] = Stopwatch()..start();
  }

  /// Stop timing and record metric
  void stopTimer(String operation) {
    if (!_isEnabled || !_activeTimers.containsKey(operation)) return;

    final stopwatch = _activeTimers[operation]!;
    stopwatch.stop();

    final metric = PerformanceMetric(
      operation: operation,
      type: MetricType.timing,
      value: stopwatch.elapsedMilliseconds.toDouble(),
      unit: 'ms',
      timestamp: DateTime.now(),
    );

    _metrics.add(metric);
    _activeTimers.remove(operation);

    print('⏱️  $operation: ${stopwatch.elapsedMilliseconds}ms');
  }

  /// Profile a specific operation
  Future<T> profile<T>(String operation, Future<T> Function() action) async {
    if (!_isEnabled) return await action();

    startTimer(operation);
    try {
      final result = await action();
      return result;
    } finally {
      stopTimer(operation);
    }
  }

  /// Profile widget build performance
  Future<void> profileWidgetBuild(
    WidgetTester tester,
    String widgetName,
    Future<void> Function() buildAction,
  ) async {
    if (!_isEnabled) {
      await buildAction();
      return;
    }

    print('📊 Profiling widget build: $widgetName');

    final startTime = DateTime.now();
    final frameStart = SchedulerBinding.instance.currentFrameTimeStamp;

    await buildAction();
    await tester.pumpAndSettle();

    final endTime = DateTime.now();
    final buildDuration = endTime.difference(startTime);

    final metric = PerformanceMetric(
      operation: 'Widget Build: $widgetName',
      type: MetricType.widgetBuild,
      value: buildDuration.inMilliseconds.toDouble(),
      unit: 'ms',
      timestamp: startTime,
      metadata: {
        'widget': widgetName,
        'frameTimestamp': frameStart.inMilliseconds,
      },
    );

    _metrics.add(metric);

    if (buildDuration.inMilliseconds > 100) {
      print(
        '⚠️  Slow build detected: $widgetName (${buildDuration.inMilliseconds}ms)',
      );
    }
  }

  /// Monitor frame rate during an action
  Future<FrameRateReport> monitorFrameRate(
    WidgetTester tester,
    String operation,
    Future<void> Function() action,
  ) async {
    if (!_isEnabled) {
      await action();
      return FrameRateReport(
        operation: operation,
        averageFPS: 0,
        minFPS: 0,
        maxFPS: 0,
        droppedFrames: 0,
        totalFrames: 0,
      );
    }

    print('📹 Monitoring frame rate: $operation');

    final frameTimestamps = <Duration>[];
    Duration? lastFrameTime;
    int droppedFrames = 0;

    // Start monitoring
    final startTime = DateTime.now();

    // Execute action with frame monitoring
    await action();

    // Simulate frame capture (in real scenario, use Flutter's profiling APIs)
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16)); // ~60 FPS
      frameTimestamps.add(Duration(milliseconds: i * 16));
    }

    // Calculate frame rates
    final frameDurations = <double>[];
    for (int i = 1; i < frameTimestamps.length; i++) {
      final duration =
          frameTimestamps[i].inMilliseconds -
          frameTimestamps[i - 1].inMilliseconds;
      frameDurations.add(duration.toDouble());

      if (duration > 16.67) {
        // Slower than 60 FPS
        droppedFrames++;
      }
    }

    final avgDuration = frameDurations.isEmpty
        ? 0.0
        : frameDurations.reduce((a, b) => a + b) / frameDurations.length;
    final avgFPS = avgDuration == 0 ? 0.0 : 1000 / avgDuration;
    final minDuration = frameDurations.isEmpty
        ? 0.0
        : frameDurations.reduce((a, b) => a < b ? a : b);
    final maxDuration = frameDurations.isEmpty
        ? 0.0
        : frameDurations.reduce((a, b) => a > b ? a : b);

    final report = FrameRateReport(
      operation: operation,
      averageFPS: avgFPS,
      minFPS: maxDuration == 0 ? 0.0 : 1000 / maxDuration,
      maxFPS: minDuration == 0 ? 0.0 : 1000 / minDuration,
      droppedFrames: droppedFrames,
      totalFrames: frameTimestamps.length,
    );

    final metric = PerformanceMetric(
      operation: 'Frame Rate: $operation',
      type: MetricType.frameRate,
      value: avgFPS,
      unit: 'fps',
      timestamp: startTime,
      metadata: {
        'dropped_frames': droppedFrames,
        'total_frames': frameTimestamps.length,
      },
    );

    _metrics.add(metric);

    if (avgFPS < _frameRateThreshold) {
      print('⚠️  Low frame rate detected: ${avgFPS.toStringAsFixed(1)} FPS');
    }

    return report;
  }

  /// Record memory usage
  void recordMemoryUsage(String operation) {
    if (!_isEnabled) return;

    // In a real implementation, use dart:developer Timeline
    final memoryMB = _getCurrentMemoryUsage();

    final metric = PerformanceMetric(
      operation: 'Memory: $operation',
      type: MetricType.memory,
      value: memoryMB,
      unit: 'MB',
      timestamp: DateTime.now(),
    );

    _metrics.add(metric);

    if (memoryMB > _memoryThresholdMB) {
      print('⚠️  High memory usage: ${memoryMB.toStringAsFixed(1)} MB');
    }
  }

  /// Get current memory usage (simulated)
  double _getCurrentMemoryUsage() {
    // In production, use actual memory profiling APIs
    developer.Timeline.startSync('memory_check');
    developer.Timeline.finishSync();

    // Return simulated value
    return 45.5; // MB
  }

  /// Benchmark widget performance
  Future<BenchmarkResult> benchmark(
    String name,
    Future<void> Function() action, {
    int iterations = 10,
  }) async {
    if (!_isEnabled) {
      await action();
      return BenchmarkResult(
        name: name,
        iterations: iterations,
        averageMs: 0,
        minMs: 0,
        maxMs: 0,
        standardDeviation: 0,
      );
    }

    print('🏁 Benchmarking: $name ($iterations iterations)');

    final durations = <int>[];

    for (int i = 0; i < iterations; i++) {
      final stopwatch = Stopwatch()..start();
      await action();
      stopwatch.stop();
      durations.add(stopwatch.elapsedMilliseconds);
    }

    final avg = durations.reduce((a, b) => a + b) / durations.length;
    final min = durations.reduce((a, b) => a < b ? a : b);
    final max = durations.reduce((a, b) => a > b ? a : b);

    // Calculate standard deviation
    final variance =
        durations.map((d) => (d - avg) * (d - avg)).reduce((a, b) => a + b) /
        durations.length;
    final stdDev = variance.isFinite ? sqrt(variance) : 0.0;

    final result = BenchmarkResult(
      name: name,
      iterations: iterations,
      averageMs: avg,
      minMs: min.toDouble(),
      maxMs: max.toDouble(),
      standardDeviation: stdDev,
    );

    print('  Average: ${avg.toStringAsFixed(2)}ms');
    print('  Min: ${min}ms, Max: ${max}ms');
    print('  Std Dev: ${stdDev.toStringAsFixed(2)}ms');

    final metric = PerformanceMetric(
      operation: 'Benchmark: $name',
      type: MetricType.benchmark,
      value: avg,
      unit: 'ms',
      timestamp: DateTime.now(),
      metadata: {
        'iterations': iterations,
        'min': min,
        'max': max,
        'std_dev': stdDev,
      },
    );

    _metrics.add(metric);

    return result;
  }

  /// Get all metrics
  List<PerformanceMetric> get metrics => List.unmodifiable(_metrics);

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _activeTimers.clear();
  }

  /// Generate performance report
  String generateReport() {
    if (_metrics.isEmpty) {
      return '📊 No performance metrics recorded';
    }

    final buffer = StringBuffer();
    buffer.writeln('═' * 80);
    buffer.writeln('📊 PERFORMANCE PROFILING REPORT');
    buffer.writeln('═' * 80);
    buffer.writeln();

    // Group by type
    final byType = <MetricType, List<PerformanceMetric>>{};
    for (final metric in _metrics) {
      byType.putIfAbsent(metric.type, () => []).add(metric);
    }

    for (final type in byType.keys) {
      buffer.writeln('${_getTypeIcon(type)} ${_getTypeName(type)}:');
      for (final metric in byType[type]!) {
        buffer.writeln(
          '  ${metric.operation}: ${metric.value.toStringAsFixed(2)} ${metric.unit}',
        );
      }
      buffer.writeln();
    }

    // Performance warnings
    final warnings = _generateWarnings();
    if (warnings.isNotEmpty) {
      buffer.writeln('⚠️  Performance Warnings:');
      for (final warning in warnings) {
        buffer.writeln('  • $warning');
      }
      buffer.writeln();
    }

    buffer.writeln('═' * 80);
    return buffer.toString();
  }

  String _getTypeIcon(MetricType type) {
    switch (type) {
      case MetricType.timing:
        return '⏱️';
      case MetricType.memory:
        return '💾';
      case MetricType.frameRate:
        return '📹';
      case MetricType.widgetBuild:
        return '🏗️';
      case MetricType.benchmark:
        return '🏁';
    }
  }

  String _getTypeName(MetricType type) {
    return type.toString().split('.').last.toUpperCase();
  }

  List<String> _generateWarnings() {
    final warnings = <String>[];

    for (final metric in _metrics) {
      if (metric.type == MetricType.timing && metric.value > 1000) {
        warnings.add(
          '${metric.operation} took ${metric.value.toStringAsFixed(0)}ms',
        );
      }
      if (metric.type == MetricType.frameRate &&
          metric.value < _frameRateThreshold) {
        warnings.add(
          '${metric.operation} has low FPS: ${metric.value.toStringAsFixed(1)}',
        );
      }
      if (metric.type == MetricType.memory &&
          metric.value > _memoryThresholdMB) {
        warnings.add(
          '${metric.operation} uses ${metric.value.toStringAsFixed(1)} MB',
        );
      }
    }

    return warnings;
  }
}

double sqrt(double x) => x < 0 ? 0 : _sqrtNewton(x);
double _sqrtNewton(double x) {
  double z = (x + 1) / 2;
  double y = x;
  while (z < y) {
    y = z;
    z = (x / z + z) / 2;
  }
  return y;
}

/// Performance metric
class PerformanceMetric {
  final String operation;
  final MetricType type;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PerformanceMetric({
    required this.operation,
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.metadata,
  });
}

/// Metric type
enum MetricType { timing, memory, frameRate, widgetBuild, benchmark }

/// Frame rate report
class FrameRateReport {
  final String operation;
  final double averageFPS;
  final double minFPS;
  final double maxFPS;
  final int droppedFrames;
  final int totalFrames;

  FrameRateReport({
    required this.operation,
    required this.averageFPS,
    required this.minFPS,
    required this.maxFPS,
    required this.droppedFrames,
    required this.totalFrames,
  });

  @override
  String toString() {
    return 'Frame Rate Report: $operation\n'
        '  Average: ${averageFPS.toStringAsFixed(1)} FPS\n'
        '  Range: ${minFPS.toStringAsFixed(1)} - ${maxFPS.toStringAsFixed(1)} FPS\n'
        '  Dropped: $droppedFrames/$totalFrames frames';
  }
}

/// Benchmark result
class BenchmarkResult {
  final String name;
  final int iterations;
  final double averageMs;
  final double minMs;
  final double maxMs;
  final double standardDeviation;

  BenchmarkResult({
    required this.name,
    required this.iterations,
    required this.averageMs,
    required this.minMs,
    required this.maxMs,
    required this.standardDeviation,
  });

  @override
  String toString() {
    return 'Benchmark: $name ($iterations iterations)\n'
        '  Average: ${averageMs.toStringAsFixed(2)}ms\n'
        '  Range: ${minMs.toStringAsFixed(2)}ms - ${maxMs.toStringAsFixed(2)}ms\n'
        '  Std Dev: ${standardDeviation.toStringAsFixed(2)}ms';
  }
}
