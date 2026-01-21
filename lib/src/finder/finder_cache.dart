// finder_cache.dart - Intelligent caching system for PilotFinder
import 'package:flutter/widgets.dart';
import 'finder_context.dart';
import 'finder_strategies.dart';

/// Intelligent cache for PilotFinder to improve performance
class FinderCache {
  final Map<String, CacheEntry> _cache = {};
  final int _maxSize;
  final Duration _ttl;

  int _hitCount = 0;
  int _missCount = 0;

  FinderCache({int maxSize = 100, Duration ttl = const Duration(seconds: 30)})
    : _maxSize = maxSize,
      _ttl = ttl;

  /// Get cached element
  Element? get(String identifier, FinderContext context) {
    final key = _generateKey(identifier, context);
    final entry = _cache[key];

    if (entry == null) {
      _missCount++;
      return null;
    }

    // Check if expired
    if (DateTime.now().difference(entry.timestamp) > _ttl) {
      _cache.remove(key);
      _missCount++;
      return null;
    }

    // Check if element is still valid
    if (!entry.element.mounted) {
      _cache.remove(key);
      _missCount++;
      return null;
    }

    _hitCount++;
    return entry.element;
  }

  /// Put element in cache
  void put(
    String identifier,
    FinderContext context,
    Element element,
    FinderStrategy strategy,
  ) {
    // Evict oldest entry if cache is full
    if (_cache.length >= _maxSize) {
      _evictOldest();
    }

    final key = _generateKey(identifier, context);
    _cache[key] = CacheEntry(
      element: element,
      strategy: strategy,
      timestamp: DateTime.now(),
    );
  }

  /// Clear entire cache
  void clear() {
    _cache.clear();
    _hitCount = 0;
    _missCount = 0;
  }

  /// Evict oldest entry
  void _evictOldest() {
    if (_cache.isEmpty) return;

    var oldestKey = _cache.keys.first;
    var oldestTime = _cache[oldestKey]!.timestamp;

    for (final entry in _cache.entries) {
      if (entry.value.timestamp.isBefore(oldestTime)) {
        oldestKey = entry.key;
        oldestTime = entry.value.timestamp;
      }
    }

    _cache.remove(oldestKey);
  }

  /// Generate cache key
  String _generateKey(String identifier, FinderContext context) {
    return '$identifier-${context.findType.name}-${context.exact}-${context.parent}-${context.child}-${context.index}';
  }

  /// Get cache statistics
  int get hitCount => _hitCount;
  int get missCount => _missCount;
  int get size => _cache.length;
  double get hitRate => (_hitCount + _missCount) == 0
      ? 0.0
      : (_hitCount / (_hitCount + _missCount)) * 100;

  /// Print cache statistics
  void printStats() {
    print('📊 Cache Stats:');
    print('   Size: $_cache.length / $_maxSize');
    print('   Hits: $_hitCount');
    print('   Misses: $_missCount');
    print('   Hit Rate: ${hitRate.toStringAsFixed(1)}%');
  }
}

/// Cache entry
class CacheEntry {
  final Element element;
  final FinderStrategy strategy;
  final DateTime timestamp;

  CacheEntry({
    required this.element,
    required this.strategy,
    required this.timestamp,
  });
}
