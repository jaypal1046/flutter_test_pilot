import 'dart:io';
import 'package:path/path.dart' as path;
import '../native/adb_commander.dart';

/// Captures screenshots and videos during test execution
class ScreenshotCapturer {
  final AdbCommander _adb;
  final String outputDirectory;

  ScreenshotCapturer(this._adb, {String? outputDirectory})
    : outputDirectory =
          outputDirectory ??
          path.join(Directory.current.path, 'test_reports', 'screenshots');

  /// Capture screenshot from device
  Future<String> captureScreenshot(
    String deviceId,
    String testName, {
    String? label,
  }) async {
    // Ensure output directory exists
    await Directory(outputDirectory).create(recursive: true);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedTestName = _sanitizeFileName(testName);
    final labelSuffix = label != null ? '_$label' : '';
    final fileName = '${sanitizedTestName}_${timestamp}${labelSuffix}.png';
    final localPath = path.join(outputDirectory, fileName);
    final remotePath = '/sdcard/$fileName';

    try {
      print('  📸 Capturing screenshot: $fileName');

      // Take screenshot on device
      await _adb.takeScreenshot(deviceId, remotePath);

      // Pull to local machine
      await _adb.pullFile(deviceId, remotePath, localPath);

      // Clean up remote file
      await _adb.run(
        ['shell', 'rm', remotePath],
        deviceId: deviceId,
        throwOnError: false,
      );

      print('  ✅ Screenshot saved: $localPath');
      return localPath;
    } catch (e) {
      print('  ⚠️  Failed to capture screenshot: $e');
      return '';
    }
  }

  /// Capture screenshot on test failure
  Future<String> captureOnFailure(
    String deviceId,
    String testName,
    String? errorMessage,
  ) async {
    print('  🚨 Test failed - capturing screenshot');
    return await captureScreenshot(deviceId, testName, label: 'failure');
  }

  /// Start video recording
  Future<Process> startRecording(String deviceId, String testName) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedTestName = _sanitizeFileName(testName);
    final remotePath = '/sdcard/${sanitizedTestName}_${timestamp}.mp4';

    print('  🎥 Starting video recording: $remotePath');

    final process = await _adb.startScreenRecord(deviceId, remotePath);

    // Store remote path for later retrieval
    process.stdin.writeln(remotePath);

    return process;
  }

  /// Stop video recording and pull to local machine
  Future<String> stopRecording(
    String deviceId,
    Process recordingProcess,
    String testName,
  ) async {
    try {
      print('  ⏹️  Stopping video recording...');

      // Stop recording (Ctrl+C)
      recordingProcess.kill(ProcessSignal.sigint);

      // Wait a bit for file to be written
      await Future.delayed(Duration(seconds: 2));

      // Get remote path (we stored it in stdin earlier)
      final remotePath = '/sdcard/${_sanitizeFileName(testName)}_*.mp4';

      // Find the actual file
      final result = await _adb.run(
        ['shell', 'ls', '/sdcard/', '|', 'grep', _sanitizeFileName(testName)],
        deviceId: deviceId,
        throwOnError: false,
      );

      final output = result.stdout.toString().trim();
      if (output.isEmpty) {
        print('  ⚠️  Video file not found');
        return '';
      }

      final actualRemotePath = '/sdcard/${output.split('\n').last}';

      // Ensure output directory exists
      await Directory(
        path.join(outputDirectory, 'videos'),
      ).create(recursive: true);

      final localPath = path.join(
        outputDirectory,
        'videos',
        path.basename(actualRemotePath),
      );

      // Pull video to local machine
      print('  📥 Downloading video...');
      await _adb.pullFile(deviceId, actualRemotePath, localPath);

      // Clean up remote file
      await _adb.run(
        ['shell', 'rm', actualRemotePath],
        deviceId: deviceId,
        throwOnError: false,
      );

      print('  ✅ Video saved: $localPath');
      return localPath;
    } catch (e) {
      print('  ⚠️  Failed to stop recording: $e');
      return '';
    }
  }

  /// Capture multiple screenshots at intervals during test
  Future<List<String>> captureSequence(
    String deviceId,
    String testName,
    Duration duration, {
    Duration interval = const Duration(seconds: 2),
  }) async {
    final screenshots = <String>[];
    final endTime = DateTime.now().add(duration);
    var count = 1;

    while (DateTime.now().isBefore(endTime)) {
      final screenshot = await captureScreenshot(
        deviceId,
        testName,
        label: 'seq_$count',
      );

      if (screenshot.isNotEmpty) {
        screenshots.add(screenshot);
      }

      count++;
      await Future.delayed(interval);
    }

    return screenshots;
  }

  /// Create a GIF from multiple screenshots (requires ImageMagick)
  Future<String?> createGif(
    List<String> screenshotPaths,
    String outputName, {
    int delay = 50, // 100ths of a second
  }) async {
    if (screenshotPaths.isEmpty) {
      return null;
    }

    try {
      final gifPath = path.join(outputDirectory, 'gifs', '$outputName.gif');
      await Directory(path.dirname(gifPath)).create(recursive: true);

      print('  🎬 Creating GIF: $outputName.gif');

      final result = await Process.run('convert', [
        '-delay',
        delay.toString(),
        ...screenshotPaths,
        gifPath,
      ]);

      if (result.exitCode == 0) {
        print('  ✅ GIF created: $gifPath');
        return gifPath;
      } else {
        print('  ⚠️  Failed to create GIF: ${result.stderr}');
        return null;
      }
    } catch (e) {
      print('  ⚠️  ImageMagick not available or error: $e');
      return null;
    }
  }

  /// Get screenshot metadata
  Future<ScreenshotInfo> getScreenshotInfo(String screenshotPath) async {
    final file = File(screenshotPath);

    if (!await file.exists()) {
      throw Exception('Screenshot not found: $screenshotPath');
    }

    final stat = await file.stat();

    return ScreenshotInfo(
      path: screenshotPath,
      fileName: path.basename(screenshotPath),
      size: stat.size,
      timestamp: stat.modified,
    );
  }

  /// Clean old screenshots
  Future<void> cleanOldScreenshots({
    Duration maxAge = const Duration(days: 7),
  }) async {
    final dir = Directory(outputDirectory);

    if (!await dir.exists()) {
      return;
    }

    final cutoffTime = DateTime.now().subtract(maxAge);
    var deletedCount = 0;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final stat = await entity.stat();

        if (stat.modified.isBefore(cutoffTime)) {
          await entity.delete();
          deletedCount++;
        }
      }
    }

    print('🧹 Cleaned up $deletedCount old screenshot(s)');
  }

  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }

  /// Get all screenshots for a test
  Future<List<String>> getScreenshotsForTest(String testName) async {
    final dir = Directory(outputDirectory);

    if (!await dir.exists()) {
      return [];
    }

    final sanitizedName = _sanitizeFileName(testName);
    final screenshots = <String>[];

    await for (final entity in dir.list()) {
      if (entity is File && entity.path.contains(sanitizedName)) {
        screenshots.add(entity.path);
      }
    }

    return screenshots..sort();
  }
}

/// Screenshot metadata
class ScreenshotInfo {
  final String path;
  final String fileName;
  final int size;
  final DateTime timestamp;

  ScreenshotInfo({
    required this.path,
    required this.fileName,
    required this.size,
    required this.timestamp,
  });

  String get sizeFormatted {
    final kb = size / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  String toString() {
    return 'ScreenshotInfo($fileName: $sizeFormatted)';
  }
}
