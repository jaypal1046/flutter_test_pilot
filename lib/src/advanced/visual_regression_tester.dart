// visual_regression_tester.dart - Visual regression testing with screenshot comparison
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

/// Visual regression testing system
class VisualRegressionTester {
  static final VisualRegressionTester _instance =
      VisualRegressionTester._internal();
  factory VisualRegressionTester() => _instance;
  VisualRegressionTester._internal();

  final String _baselinePath = 'test/golden/baselines';
  final String _actualPath = 'test/golden/actuals';
  final String _diffPath = 'test/golden/diffs';

  double _pixelDifferenceThreshold = 0.1; // 10% difference threshold
  bool _autoUpdateBaselines = false;

  final List<VisualTestResult> _results = [];

  /// Configure visual testing
  void configure({
    double? pixelDifferenceThreshold,
    bool? autoUpdateBaselines,
  }) {
    if (pixelDifferenceThreshold != null) {
      _pixelDifferenceThreshold = pixelDifferenceThreshold;
    }
    if (autoUpdateBaselines != null) {
      _autoUpdateBaselines = autoUpdateBaselines;
    }
  }

  /// Capture and compare screenshot
  Future<VisualTestResult> compareScreenshot(
    WidgetTester tester,
    String testName, {
    Finder? finder,
    double? customThreshold,
  }) async {
    print('📸 Capturing screenshot for: $testName');

    // Ensure directories exist
    await _ensureDirectoriesExist();

    // Capture current screenshot
    final actualBytes = await _captureScreenshot(tester, finder);

    // Save actual screenshot
    final actualFile = File('$_actualPath/$testName.png');
    await actualFile.writeAsBytes(actualBytes);

    // Load baseline screenshot
    final baselineFile = File('$_baselinePath/$testName.png');

    if (!await baselineFile.exists()) {
      if (_autoUpdateBaselines) {
        print('📝 Creating new baseline for: $testName');
        await _saveBaseline(testName, actualBytes);
        return VisualTestResult(
          testName: testName,
          status: VisualTestStatus.baselineCreated,
          message: 'New baseline created',
        );
      } else {
        return VisualTestResult(
          testName: testName,
          status: VisualTestStatus.noBaseline,
          message:
              'No baseline found - run with autoUpdateBaselines=true to create',
        );
      }
    }

    // Compare screenshots
    final baselineBytes = await baselineFile.readAsBytes();
    final comparison = await _compareImages(
      baselineBytes,
      actualBytes,
      customThreshold ?? _pixelDifferenceThreshold,
    );

    final result = VisualTestResult(
      testName: testName,
      status: comparison.isPassed
          ? VisualTestStatus.passed
          : VisualTestStatus.failed,
      differencePercentage: comparison.differencePercentage,
      pixelDifferences: comparison.pixelDifferences,
      message: comparison.message,
    );

    // Generate diff image if failed
    if (!comparison.isPassed) {
      print(
        '⚠️ Visual regression detected: ${comparison.differencePercentage.toStringAsFixed(2)}% difference',
      );
      await _generateDiffImage(baselineBytes, actualBytes, testName);
    } else {
      print('✅ Visual test passed: $testName');
    }

    _results.add(result);
    return result;
  }

  /// Capture screenshot of widget or full screen
  Future<Uint8List> _captureScreenshot(
    WidgetTester tester,
    Finder? finder,
  ) async {
    await tester.pumpAndSettle();

    RenderObject renderObject;

    if (finder != null) {
      renderObject = tester.renderObject(finder);
    } else {
      // Capture full screen - use the root render object
      renderObject = tester.binding.renderViews.first;
    }

    // Find the RenderRepaintBoundary to capture
    RenderRepaintBoundary? boundary;

    if (renderObject is RenderRepaintBoundary) {
      boundary = renderObject;
    } else {
      // Walk up the tree to find a RenderRepaintBoundary
      RenderObject? current = renderObject;
      while (current != null) {
        if (current is RenderRepaintBoundary) {
          boundary = current;
          break;
        }
        current = current.parent;
      }
    }

    if (boundary == null) {
      throw Exception(
        'Failed to find RenderRepaintBoundary for screenshot capture',
      );
    }

    final image = await boundary.toImage();
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to convert image to byte data');
    }

    return byteData.buffer.asUint8List();
  }

  /// Compare two images pixel by pixel
  Future<ImageComparison> _compareImages(
    Uint8List baseline,
    Uint8List actual,
    double threshold,
  ) async {
    try {
      // Decode images
      final baselineImage = await _decodeImage(baseline);
      final actualImage = await _decodeImage(actual);

      // Check dimensions
      if (baselineImage.width != actualImage.width ||
          baselineImage.height != actualImage.height) {
        return ImageComparison(
          isPassed: false,
          differencePercentage: 100.0,
          pixelDifferences: 0,
          message:
              'Image dimensions differ: '
              '${baselineImage.width}x${baselineImage.height} vs '
              '${actualImage.width}x${actualImage.height}',
        );
      }

      // Compare pixels
      int differentPixels = 0;
      final totalPixels = baselineImage.width * baselineImage.height;
      final baselineData = await baselineImage.toByteData();
      final actualData = await actualImage.toByteData();

      if (baselineData == null || actualData == null) {
        return ImageComparison(
          isPassed: false,
          differencePercentage: 100.0,
          pixelDifferences: 0,
          message: 'Failed to extract pixel data',
        );
      }

      for (int i = 0; i < totalPixels * 4; i += 4) {
        final br = baselineData.getUint8(i);
        final bg = baselineData.getUint8(i + 1);
        final bb = baselineData.getUint8(i + 2);
        final ba = baselineData.getUint8(i + 3);

        final ar = actualData.getUint8(i);
        final ag = actualData.getUint8(i + 1);
        final ab = actualData.getUint8(i + 2);
        final aa = actualData.getUint8(i + 3);

        // Calculate color difference
        final diff = _colorDifference(br, bg, bb, ba, ar, ag, ab, aa);
        if (diff > 10) {
          // Threshold for considering pixels different
          differentPixels++;
        }
      }

      final differencePercentage = (differentPixels / totalPixels) * 100;
      final isPassed = differencePercentage <= (threshold * 100);

      return ImageComparison(
        isPassed: isPassed,
        differencePercentage: differencePercentage,
        pixelDifferences: differentPixels,
        message: isPassed
            ? 'Visual test passed'
            : 'Visual regression detected: ${differencePercentage.toStringAsFixed(2)}% different',
      );
    } catch (e) {
      return ImageComparison(
        isPassed: false,
        differencePercentage: 100.0,
        pixelDifferences: 0,
        message: 'Error comparing images: $e',
      );
    }
  }

  /// Decode image bytes to ui.Image
  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Calculate color difference between two pixels
  double _colorDifference(
    int r1,
    int g1,
    int b1,
    int a1,
    int r2,
    int g2,
    int b2,
    int a2,
  ) {
    final dr = (r1 - r2).abs();
    final dg = (g1 - g2).abs();
    final db = (b1 - b2).abs();
    final da = (a1 - a2).abs();
    return (dr + dg + db + da) / 4;
  }

  /// Generate diff image highlighting differences
  Future<void> _generateDiffImage(
    Uint8List baseline,
    Uint8List actual,
    String testName,
  ) async {
    // Simplified - in production you'd generate a proper diff image
    // showing highlighted differences in red/yellow
    final diffFile = File('$_diffPath/$testName.diff.txt');
    await diffFile.writeAsString(
      'Visual regression detected\n'
      'Baseline: $_baselinePath/$testName.png\n'
      'Actual: $_actualPath/$testName.png\n'
      'See screenshots for comparison',
    );
  }

  /// Save baseline screenshot
  Future<void> _saveBaseline(String testName, Uint8List bytes) async {
    final file = File('$_baselinePath/$testName.png');
    await file.writeAsBytes(bytes);
  }

  /// Ensure test directories exist
  Future<void> _ensureDirectoriesExist() async {
    await Directory(_baselinePath).create(recursive: true);
    await Directory(_actualPath).create(recursive: true);
    await Directory(_diffPath).create(recursive: true);
  }

  /// Update baseline for a specific test
  Future<void> updateBaseline(String testName) async {
    final actualFile = File('$_actualPath/$testName.png');
    if (!await actualFile.exists()) {
      throw Exception('No actual screenshot found for: $testName');
    }

    final bytes = await actualFile.readAsBytes();
    await _saveBaseline(testName, bytes);
    print('✅ Baseline updated for: $testName');
  }

  /// Get all test results
  List<VisualTestResult> get results => List.unmodifiable(_results);

  /// Clear results
  void clearResults() {
    _results.clear();
  }

  /// Generate visual regression report
  String generateReport() {
    final buffer = StringBuffer();
    buffer.writeln('═' * 80);
    buffer.writeln('📊 VISUAL REGRESSION TEST REPORT');
    buffer.writeln('═' * 80);
    buffer.writeln();

    final passed = _results
        .where((r) => r.status == VisualTestStatus.passed)
        .length;
    final failed = _results
        .where((r) => r.status == VisualTestStatus.failed)
        .length;
    final noBaseline = _results
        .where((r) => r.status == VisualTestStatus.noBaseline)
        .length;
    final created = _results
        .where((r) => r.status == VisualTestStatus.baselineCreated)
        .length;

    buffer.writeln('Summary:');
    buffer.writeln('  ✅ Passed: $passed');
    buffer.writeln('  ❌ Failed: $failed');
    buffer.writeln('  📝 Baselines Created: $created');
    buffer.writeln('  ⚠️  No Baseline: $noBaseline');
    buffer.writeln();

    if (failed > 0) {
      buffer.writeln('Failed Tests:');
      for (final result in _results.where(
        (r) => r.status == VisualTestStatus.failed,
      )) {
        buffer.writeln('  ❌ ${result.testName}');
        buffer.writeln(
          '     Difference: ${result.differencePercentage?.toStringAsFixed(2)}%',
        );
        buffer.writeln('     Pixels: ${result.pixelDifferences}');
        buffer.writeln('     Diff: $_diffPath/${result.testName}.diff.txt');
      }
    }

    buffer.writeln('═' * 80);
    return buffer.toString();
  }
}

/// Visual test result
class VisualTestResult {
  final String testName;
  final VisualTestStatus status;
  final double? differencePercentage;
  final int? pixelDifferences;
  final String message;

  VisualTestResult({
    required this.testName,
    required this.status,
    this.differencePercentage,
    this.pixelDifferences,
    required this.message,
  });
}

/// Visual test status
enum VisualTestStatus { passed, failed, noBaseline, baselineCreated }

/// Image comparison result
class ImageComparison {
  final bool isPassed;
  final double differencePercentage;
  final int pixelDifferences;
  final String message;

  ImageComparison({
    required this.isPassed,
    required this.differencePercentage,
    required this.pixelDifferences,
    required this.message,
  });
}
