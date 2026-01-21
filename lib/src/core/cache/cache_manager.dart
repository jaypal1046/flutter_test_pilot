import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:meta/meta.dart';
import '../models/test_result.dart';

/// Generic cache entry used by the caching layer.
@immutable
class CacheEntry {
  final String key; // logical key (e.g. test path, artifact id)
  final String hash; // content hash for invalidation
  final DateTime timestamp;
  final Map<String, dynamic> payload; // arbitrary JSON-serializable data
  final String? namespace; // optional logical namespace (e.g. "test_results")

  const CacheEntry({
    required this.key,
    required this.hash,
    required this.timestamp,
    required this.payload,
    this.namespace,
  });

  CacheEntry copyWith({
    String? key,
    String? hash,
    DateTime? timestamp,
    Map<String, dynamic>? payload,
    String? namespace,
  }) {
    return CacheEntry(
      key: key ?? this.key,
      hash: hash ?? this.hash,
      timestamp: timestamp ?? this.timestamp,
      payload: payload ?? this.payload,
      namespace: namespace ?? this.namespace,
    );
  }

  Map<String, Object?> toRow() {
    return <String, Object?>{
      'key': key,
      'hash': hash,
      'timestamp': timestamp.toIso8601String(),
      'payload': jsonEncode(payload),
      'namespace': namespace,
    };
  }

  static CacheEntry fromRow(Map<String, Object?> row) {
    return CacheEntry(
      key: row['key'] as String,
      hash: row['hash'] as String,
      timestamp: DateTime.parse(row['timestamp'] as String),
      payload: jsonDecode(row['payload'] as String) as Map<String, dynamic>,
      namespace: row['namespace'] as String?,
    );
  }
}

/// SQLite-based cache manager for test results and other payloads.
class CacheManager {
  static CacheManager? _instance;
  late Database _db;
  late String _cachePath;

  CacheManager._();

  static CacheManager get instance {
    _instance ??= CacheManager._();
    return _instance!;
  }

  /// Initialize the cache database
  Future<void> initialize() async {
    final cacheDir = path.join(
      Directory.current.path,
      '.dart_tool',
      'flutter_test_pilot',
    );

    await Directory(cacheDir).create(recursive: true);
    _cachePath = path.join(cacheDir, 'test_cache.db');

    _db = sqlite3.open(_cachePath);
    _createTables();
  }

  void _createTables() {
    // Legacy table for test results (kept for backward compatibility)
    _db.execute('''
      CREATE TABLE IF NOT EXISTS test_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        test_path TEXT NOT NULL,
        test_hash TEXT NOT NULL,
        passed INTEGER NOT NULL,
        duration_ms INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        device_id TEXT,
        error_message TEXT,
        screenshots TEXT,
        UNIQUE(test_path, test_hash)
      )
    ''');

    _db.execute('''
      CREATE INDEX IF NOT EXISTS idx_test_path 
      ON test_cache(test_path)
    ''');

    _db.execute('''
      CREATE INDEX IF NOT EXISTS idx_timestamp 
      ON test_cache(timestamp)
    ''');

    // New generic cache table used by broader caching layer.
    _db.execute('''
      CREATE TABLE IF NOT EXISTS cache_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        namespace TEXT,
        key TEXT NOT NULL,
        hash TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        payload TEXT NOT NULL,
        UNIQUE(namespace, key, hash)
      )
    ''');

    _db.execute('''
      CREATE INDEX IF NOT EXISTS idx_cache_namespace_key
      ON cache_entries(namespace, key)
    ''');

    _db.execute('''
      CREATE INDEX IF NOT EXISTS idx_cache_timestamp
      ON cache_entries(timestamp)
    ''');
  }

  /// Calculate SHA-256 hash of a file
  String calculateFileHash(File file) {
    final bytes = file.readAsBytesSync();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generic APIs -----------------------------------------------------------

  /// Save a generic cache entry.
  Future<void> saveEntry(CacheEntry entry) async {
    _db.execute(
      '''
      INSERT OR REPLACE INTO cache_entries 
      (namespace, key, hash, timestamp, payload)
      VALUES (?, ?, ?, ?, ?)
    ''',
      [
        entry.namespace,
        entry.key,
        entry.hash,
        entry.timestamp.toIso8601String(),
        jsonEncode(entry.payload),
      ],
    );
  }

  /// Get a generic cache entry for a given namespace/key/hash.
  CacheEntry? getEntry({
    required String key,
    required String hash,
    String? namespace,
  }) {
    final result = _db.select(
      '''
      SELECT * FROM cache_entries
      WHERE key = ? AND hash = ? AND (namespace IS ? OR namespace = ?)
      ORDER BY timestamp DESC
      LIMIT 1
    ''',
      [key, hash, namespace, namespace],
    );

    if (result.isEmpty) return null;
    return CacheEntry.fromRow(result.first);
  }

  /// Clear all entries for a given namespace (or all if null).
  Future<void> clearNamespace(String? namespace) async {
    if (namespace == null) {
      _db.execute('DELETE FROM cache_entries');
    } else {
      _db.execute('DELETE FROM cache_entries WHERE namespace = ?', [namespace]);
    }
  }

  /// Clean up old generic entries (older than [maxAgeDays]).
  Future<void> cleanupOldGenericEntries({int maxAgeDays = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeDays));
    _db.execute('DELETE FROM cache_entries WHERE timestamp < ?', [
      cutoffDate.toIso8601String(),
    ]);
    _db.execute('VACUUM');
  }

  /// Legacy TestResult-specific APIs --------------------------------------

  /// Check if test result is cached and valid
  Future<TestResult?> getCachedResult(File testFile) async {
    final testPath = testFile.path;
    final currentHash = calculateFileHash(testFile);

    final result = _db.select(
      '''
      SELECT * FROM test_cache 
      WHERE test_path = ? AND test_hash = ?
      ORDER BY timestamp DESC
      LIMIT 1
    ''',
      [testPath, currentHash],
    );

    if (result.isEmpty) {
      return null;
    }

    final row = result.first;
    return TestResult(
      testPath: row['test_path'] as String,
      testHash: row['test_hash'] as String,
      passed: (row['passed'] as int) == 1,
      duration: Duration(milliseconds: row['duration_ms'] as int),
      timestamp: DateTime.parse(row['timestamp'] as String),
      deviceId: row['device_id'] as String?,
      errorMessage: row['error_message'] as String?,
      screenshots: _decodeScreenshots(row['screenshots'] as String?),
    );
  }

  /// Save test result to cache
  Future<void> saveResult(TestResult result) async {
    final screenshots = jsonEncode(result.screenshots);

    _db.execute(
      '''
      INSERT OR REPLACE INTO test_cache 
      (test_path, test_hash, passed, duration_ms, timestamp, device_id, error_message, screenshots)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''',
      [
        result.testPath,
        result.testHash,
        result.passed ? 1 : 0,
        result.duration.inMilliseconds,
        result.timestamp.toIso8601String(),
        result.deviceId,
        result.errorMessage,
        screenshots,
      ],
    );
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final totalTests = _db
        .select('SELECT COUNT(*) as count FROM test_cache')
        .first['count'];
    final passedTests = _db
        .select('SELECT COUNT(*) as count FROM test_cache WHERE passed = 1')
        .first['count'];
    final failedTests = _db
        .select('SELECT COUNT(*) as count FROM test_cache WHERE passed = 0')
        .first['count'];

    final sizeBytes = File(_cachePath).lengthSync();
    final sizeMB = (sizeBytes / (1024 * 1024)).toStringAsFixed(2);

    return {
      'total_cached_results': totalTests,
      'passed': passedTests,
      'failed': failedTests,
      'cache_size_mb': sizeMB,
      'cache_path': _cachePath,
    };
  }

  /// Clear all cached results (legacy + generic)
  Future<void> clearAll() async {
    _db.execute('DELETE FROM test_cache');
    _db.execute('DELETE FROM cache_entries');
    _db.execute('VACUUM');
  }

  /// Clear cache for specific test
  Future<void> clearTest(String testPath) async {
    _db.execute('DELETE FROM test_cache WHERE test_path = ?', [testPath]);
  }

  /// Clean up old cache entries (older than 30 days)
  Future<void> cleanupOldEntries({int maxAgeDays = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeDays));
    _db.execute('DELETE FROM test_cache WHERE timestamp < ?', [
      cutoffDate.toIso8601String(),
    ]);
    _db.execute('VACUUM');
  }

  /// Get all cached test paths
  List<String> getCachedTestPaths() {
    final result = _db.select(
      'SELECT DISTINCT test_path FROM test_cache ORDER BY test_path',
    );
    return result.map((row) => row['test_path'] as String).toList();
  }

  List<String> _decodeScreenshots(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return (jsonDecode(json) as List).cast<String>();
    } catch (e) {
      return [];
    }
  }

  /// Close the database
  void close() {
    _db.dispose();
  }
}
