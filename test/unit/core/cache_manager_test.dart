import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_pilot/src/core/cache/cache_manager.dart';
import 'package:flutter_test_pilot/src/core/models/test_result.dart';

void main() {
  group('CacheManager', () {
    late CacheManager cacheManager;

    setUp(() async {
      cacheManager = CacheManager.instance;
      await cacheManager.initialize();
    });

    tearDown(() async {
      // Clean up test cache
      await cacheManager.clearAll();
    });

    test('should initialize successfully', () {
      expect(cacheManager, isNotNull);
    });

    test('should save and retrieve cache entry', () async {
      final entry = CacheEntry(
        key: 'test_key',
        hash: 'abc123',
        timestamp: DateTime.now(),
        payload: {'result': 'success'},
        namespace: 'test',
      );

      await cacheManager.saveEntry(entry);
      final retrieved = cacheManager.getEntry(
        key: 'test_key',
        hash: 'abc123',
        namespace: 'test',
      );

      expect(retrieved, isNotNull);
      expect(retrieved?.key, equals('test_key'));
      expect(retrieved?.hash, equals('abc123'));
    });

    test('should return null for non-existent entry', () {
      final retrieved = cacheManager.getEntry(
        key: 'non_existent',
        hash: 'xyz',
        namespace: 'test',
      );

      expect(retrieved, isNull);
    });

    test('should get cache statistics', () {
      final stats = cacheManager.getStats();

      expect(stats, isNotNull);
      expect(stats.containsKey('total_cached_results'), isTrue);
      expect(stats.containsKey('passed'), isTrue);
      expect(stats.containsKey('failed'), isTrue);
      expect(stats.containsKey('cache_size_mb'), isTrue);
    });

    test('should clear all cache', () async {
      final entry = CacheEntry(
        key: 'test_key',
        hash: 'abc123',
        timestamp: DateTime.now(),
        payload: {'data': 'test'},
        namespace: 'test',
      );

      await cacheManager.saveEntry(entry);
      await cacheManager.clearAll();

      final retrieved = cacheManager.getEntry(
        key: 'test_key',
        hash: 'abc123',
        namespace: 'test',
      );

      expect(retrieved, isNull);
    });

    test('should clear namespace', () async {
      final entry1 = CacheEntry(
        key: 'test_key_1',
        hash: 'abc123',
        timestamp: DateTime.now(),
        payload: {'data': 'test1'},
        namespace: 'namespace1',
      );

      final entry2 = CacheEntry(
        key: 'test_key_2',
        hash: 'def456',
        timestamp: DateTime.now(),
        payload: {'data': 'test2'},
        namespace: 'namespace2',
      );

      await cacheManager.saveEntry(entry1);
      await cacheManager.saveEntry(entry2);
      await cacheManager.clearNamespace('namespace1');

      final retrieved1 = cacheManager.getEntry(
        key: 'test_key_1',
        hash: 'abc123',
        namespace: 'namespace1',
      );

      final retrieved2 = cacheManager.getEntry(
        key: 'test_key_2',
        hash: 'def456',
        namespace: 'namespace2',
      );

      expect(retrieved1, isNull);
      expect(retrieved2, isNotNull);
    });
  });
}
