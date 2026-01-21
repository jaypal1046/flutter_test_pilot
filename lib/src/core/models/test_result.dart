import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;

/// Test result model
class TestResult {
  final String testPath;
  final String testHash;
  final bool passed;
  final Duration duration;
  final DateTime timestamp;
  final String? deviceId;
  final String? errorMessage;
  final List<String> screenshots;

  TestResult({
    required this.testPath,
    required this.testHash,
    required this.passed,
    required this.duration,
    required this.timestamp,
    this.deviceId,
    this.errorMessage,
    this.screenshots = const [],
  });

  Map<String, dynamic> toJson() => {
    'testPath': testPath,
    'testHash': testHash,
    'passed': passed,
    'duration': duration.inMilliseconds,
    'timestamp': timestamp.toIso8601String(),
    'deviceId': deviceId,
    'errorMessage': errorMessage,
    'screenshots': screenshots,
  };

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      testPath: json['testPath'] as String,
      testHash: json['testHash'] as String,
      passed: json['passed'] as bool,
      duration: Duration(milliseconds: json['duration'] as int),
      timestamp: DateTime.parse(json['timestamp'] as String),
      deviceId: json['deviceId'] as String?,
      errorMessage: json['errorMessage'] as String?,
      screenshots: (json['screenshots'] as List?)?.cast<String>() ?? [],
    );
  }
}

/// Device information model
class DeviceInfo {
  final String id;
  final String name;
  final String platform;
  final String? model;
  final String? osVersion;
  final bool isAvailable;

  DeviceInfo({
    required this.id,
    required this.name,
    required this.platform,
    this.model,
    this.osVersion,
    this.isAvailable = true,
  });

  @override
  String toString() {
    return '$name ($platform${model != null ? " - $model" : ""})';
  }
}
