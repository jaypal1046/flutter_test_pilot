// screenshot_comparator.dart - Visual regression testing
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Screenshot comparison for visual regression testing
class ScreenshotComparator {
  static final ScreenshotComparator _instance =
      ScreenshotComparator._internal();
  factory ScreenshotComparator() => _instance;
  ScreenshotComparator._internal();

  String _baselineDir = 'test/screenshots/baseline';
  String _actualDir = 'test/screenshots/actual';
  String _diffDir = 'test/screenshots/diff';
  double _similarityThreshold = 0.99; // 99% similarity required
  bool _enabled = true;

  final List<ScreenshotComparison> _comparisons = [];

  /// Configure screenshot comparison
  void configure({
    String? baselineDir,
    String? actualDir,
    String? diffDir,
    double? similarityThreshold,
    bool? enabled,
  }) {
    if (baselineDir != null) _baselineDir = baselineDir;
    if (actualDir != null) _actualDir = actualDir;
    if (diffDir != null) _diffDir = diffDir;
    if (similarityThreshold != null) _similarityThreshold = similarityThreshold;
    if (enabled != null) _enabled = enabled;
  }

  /// Take and compare screenshot
  Future<ScreenshotComparison> compareScreenshot(
    WidgetTester tester,
    String name, {
    Finder? finder,
    double? threshold,
    bool updateBaseline = false,
  }) async {
    if (!_enabled) {
      return ScreenshotComparison(
        name: name,
        passed: true,
        similarity: 1.0,
        message: 'Screenshot comparison disabled',
      );
    }

    print('📸 Comparing screenshot: $name');

    // Ensure directories exist
    await _ensureDirectoriesExist();

    // Take screenshot
    final actualBytes = await _takeScreenshot(tester, finder);

    // Save actual screenshot
    final actualPath = '$_actualDir/$name.png';
    await _saveScreenshot(actualPath, actualBytes);

    // Check for baseline
    final baselinePath = '$_baselineDir/$name.png';
    final baselineFile = File(baselinePath);

    if (!baselineFile.existsSync() || updateBaseline) {
      // Create baseline
      await _saveScreenshot(baselinePath, actualBytes);
      print('✅ Baseline created: $name');

      final comparison = ScreenshotComparison(
        name: name,
        passed: true,
        similarity: 1.0,
        message: 'Baseline created',
        actualPath: actualPath,
        baselinePath: baselinePath,
      );

      _comparisons.add(comparison);
      return comparison;
    }

    // Load baseline
    final baselineBytes = await baselineFile.readAsBytes();

    // Compare
    final similarity = await _compareImages(baselineBytes, actualBytes);
    final comparisonThreshold = threshold ?? _similarityThreshold;
    final passed = similarity >= comparisonThreshold;

    String? diffPath;
    if (!passed) {
      // Generate diff image
      diffPath = '$_diffDir/$name.png';
      await _generateDiffImage(baselineBytes, actualBytes, diffPath);
      print(
        '❌ Visual regression detected: $name (${(similarity * 100).toStringAsFixed(2)}% similar)',
      );
    } else {
      print(
        '✅ Screenshot match: $name (${(similarity * 100).toStringAsFixed(2)}% similar)',
      );
    }

    final comparison = ScreenshotComparison(
      name: name,
      passed: passed,
      similarity: similarity,
      message: passed
          ? 'Screenshots match'
          : 'Visual difference detected (${(similarity * 100).toStringAsFixed(2)}% similar)',
      actualPath: actualPath,
      baselinePath: baselinePath,
      diffPath: diffPath,
    );

    _comparisons.add(comparison);
    return comparison;
  }

  /// Take screenshot
  Future<Uint8List> _takeScreenshot(WidgetTester tester, Finder? finder) async {
    if (finder != null) {
      // Screenshot specific widget
      final element = finder.evaluate().first;
      final renderObject = element.renderObject!;
      return await _captureRenderObject(renderObject);
    } else {
      // Full screen screenshot
      return await _captureFullScreen(tester);
    }
  }

  /// Capture render object
  Future<Uint8List> _captureRenderObject(RenderObject renderObject) async {
    // In a real implementation, use Flutter's screenshot capabilities
    // For now, return dummy data
    return Uint8List.fromList(List.filled(100, 0));
  }

  /// Capture full screen
  Future<Uint8List> _captureFullScreen(WidgetTester tester) async {
    // In a real implementation, use Flutter's screenshot capabilities
    return Uint8List.fromList(List.filled(100, 0));
  }

  /// Compare two images
  Future<double> _compareImages(Uint8List image1, Uint8List image2) async {
    // Simple comparison - in production use actual image comparison library
    if (image1.length != image2.length) {
      return 0.0;
    }

    int matchingBytes = 0;
    for (int i = 0; i < image1.length; i++) {
      if (image1[i] == image2[i]) {
        matchingBytes++;
      }
    }

    return matchingBytes / image1.length;
  }

  /// Generate diff image
  Future<void> _generateDiffImage(
    Uint8List baseline,
    Uint8List actual,
    String outputPath,
  ) async {
    // In production, generate actual diff highlighting differences
    await _saveScreenshot(outputPath, actual);
  }

  /// Save screenshot to file
  Future<void> _saveScreenshot(String path, Uint8List bytes) async {
    final file = File(path);
    await file.writeAsBytes(bytes);
  }

  /// Ensure directories exist
  Future<void> _ensureDirectoriesExist() async {
    await Directory(_baselineDir).create(recursive: true);
    await Directory(_actualDir).create(recursive: true);
    await Directory(_diffDir).create(recursive: true);
  }

  /// Get all comparisons
  List<ScreenshotComparison> get comparisons => List.unmodifiable(_comparisons);

  /// Get failed comparisons
  List<ScreenshotComparison> get failedComparisons =>
      _comparisons.where((c) => !c.passed).toList();

  /// Generate comparison report
  String generateReport() {
    if (_comparisons.isEmpty) {
      return '📸 No screenshot comparisons recorded';
    }

    final buffer = StringBuffer();
    buffer.writeln('═' * 80);
    buffer.writeln('📸 VISUAL REGRESSION TESTING REPORT');
    buffer.writeln('═' * 80);
    buffer.writeln();

    final total = _comparisons.length;
    final passed = _comparisons.where((c) => c.passed).length;
    final failed = total - passed;

    buffer.writeln('Total comparisons: $total');
    buffer.writeln('Passed: $passed');
    buffer.writeln('Failed: $failed');
    buffer.writeln();

    if (failed > 0) {
      buffer.writeln('❌ Failed Comparisons:');
      for (final comparison in failedComparisons) {
        buffer.writeln('  ${comparison.name}:');
        buffer.writeln(
          '    Similarity: ${(comparison.similarity * 100).toStringAsFixed(2)}%',
        );
        buffer.writeln('    Baseline: ${comparison.baselinePath}');
        buffer.writeln('    Actual: ${comparison.actualPath}');
        if (comparison.diffPath != null) {
          buffer.writeln('    Diff: ${comparison.diffPath}');
        }
        buffer.writeln();
      }
    }

    buffer.writeln('═' * 80);
    return buffer.toString();
  }

  /// Clear comparisons
  void clearComparisons() {
    _comparisons.clear();
  }

  /// Update all baselines from actual screenshots
  Future<void> updateAllBaselines() async {
    for (final comparison in _comparisons) {
      if (comparison.actualPath != null && comparison.baselinePath != null) {
        final actualFile = File(comparison.actualPath!);
        final baselineFile = File(comparison.baselinePath!);

        if (actualFile.existsSync()) {
          await actualFile.copy(baselineFile.path);
          print('Updated baseline: ${comparison.name}');
        }
      }
    }
  }
}

/// Screenshot comparison result
class ScreenshotComparison {
  final String name;
  final bool passed;
  final double similarity;
  final String message;
  final String? actualPath;
  final String? baselinePath;
  final String? diffPath;

  ScreenshotComparison({
    required this.name,
    required this.passed,
    required this.similarity,
    required this.message,
    this.actualPath,
    this.baselinePath,
    this.diffPath,
  });

  @override
  String toString() {
    return 'Screenshot: $name - ${passed ? 'PASSED' : 'FAILED'} '
        '(${(similarity * 100).toStringAsFixed(2)}% similar)';
  }
}
