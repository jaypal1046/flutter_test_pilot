import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as path;

/// Test cache for storing and retrieving test results
class TestCache {
  static TestCache? _instance;
  static TestCache get instance => _instance ??= TestCache._();

  TestCache._();

  late final Database _db;
  bool _initialized = false;

  /// Initialize the cache database
  Future<void> initialize() async {
    if (_initialized) return;

    final cacheDir = path.join(Directory.current.path, '.testpilot', 'cache');
    await Directory(cacheDir).create(recursive: true);

    final dbPath = path.join(cacheDir, 'test_cache.db');
    _db = sqlite3.open(dbPath);

    // Create tables
    _db.execute('''
      CREATE TABLE IF NOT EXISTS test_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        test_path TEXT NOT NULL,
        test_hash TEXT NOT NULL,
        result TEXT NOT NULL,
        passed INTEGER NOT NULL,
        duration INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        UNIQUE(test_path, test_hash)
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS test_dependencies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        test_path TEXT NOT NULL,
        dependency_path TEXT NOT NULL,
        dependency_hash TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    _db.execute('''
      CREATE INDEX IF NOT EXISTS idx_test_path 
      ON test_results(test_path)
    ''');

    _db.execute('''
      CREATE INDEX IF NOT EXISTS idx_test_hash 
      ON test_results(test_hash)
    ''');

    _initialized = true;
  }

  /// Compute hash of a file
  Future<String> _computeFileHash(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  /// Get cached test result
  Future<CachedTestResult?> getCachedResult(String testPath) async {
    await initialize();

    final testFile = File(testPath);
    if (!testFile.existsSync()) return null;

    final currentHash = await _computeFileHash(testFile);

    final result = _db.select(
      'SELECT * FROM test_results WHERE test_path = ? AND test_hash = ? ORDER BY timestamp DESC LIMIT 1',
      [testPath, currentHash],
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return CachedTestResult(
      testPath: row['test_path'] as String,
      testHash: row['test_hash'] as String,
      result: row['result'] as String,
      passed: (row['passed'] as int) == 1,
      duration: Duration(milliseconds: row['duration'] as int),
      timestamp: DateTime.parse(row['timestamp'] as String),
    );
  }

  /// Cache a test result
  Future<void> cacheResult({
    required String testPath,
    required bool passed,
    required Duration duration,
    String? errorMessage,
  }) async {
    await initialize();

    final testFile = File(testPath);
    if (!testFile.existsSync()) return;

    final testHash = await _computeFileHash(testFile);

    _db.execute(
      '''
      INSERT OR REPLACE INTO test_results 
      (test_path, test_hash, result, passed, duration, timestamp)
      VALUES (?, ?, ?, ?, ?, ?)
      ''',
      [
        testPath,
        testHash,
        errorMessage ?? 'success',
        passed ? 1 : 0,
        duration.inMilliseconds,
        DateTime.now().toIso8601String(),
      ],
    );
  }

  /// Invalidate cache for a specific test
  Future<void> invalidate(String testPath) async {
    await initialize();

    _db.execute('DELETE FROM test_results WHERE test_path = ?', [testPath]);
  }

  /// Clear all cache
  Future<void> clearAll() async {
    await initialize();

    _db.execute('DELETE FROM test_results');
    _db.execute('DELETE FROM test_dependencies');
  }

  /// Get cache statistics
  Future<CacheStats> getStats() async {
    await initialize();

    final totalTests =
        _db.select('SELECT COUNT(*) as count FROM test_results').first['count']
            as int;

    final passedTests =
        _db
                .select(
                  'SELECT COUNT(*) as count FROM test_results WHERE passed = 1',
                )
                .first['count']
            as int;

    final failedTests = totalTests - passedTests;

    final avgDuration =
        _db.select('SELECT AVG(duration) as avg FROM test_results').first['avg']
            as double?;

    return CacheStats(
      totalTests: totalTests,
      passedTests: passedTests,
      failedTests: failedTests,
      averageDuration: Duration(milliseconds: (avgDuration ?? 0).toInt()),
    );
  }

  /// Close the database
  void close() {
    if (_initialized) {
      _db.dispose();
      _initialized = false;
    }
  }
}

/// Cached test result model
class CachedTestResult {
  final String testPath;
  final String testHash;
  final String result;
  final bool passed;
  final Duration duration;
  final DateTime timestamp;

  CachedTestResult({
    required this.testPath,
    required this.testHash,
    required this.result,
    required this.passed,
    required this.duration,
    required this.timestamp,
  });

  bool isStale(Duration maxAge) {
    return DateTime.now().difference(timestamp) > maxAge;
  }
}

/// Cache statistics
class CacheStats {
  final int totalTests;
  final int passedTests;
  final int failedTests;
  final Duration averageDuration;

  CacheStats({
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.averageDuration,
  });

  double get hitRate => totalTests > 0 ? passedTests / totalTests : 0.0;
}
