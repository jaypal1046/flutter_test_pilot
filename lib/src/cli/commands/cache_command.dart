import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../../core/cache/cache_manager.dart';

/// Cache command - manages test result cache
class CacheCommand extends Command<int> {
  CacheCommand() {
    argParser
      ..addFlag('stats', negatable: false, help: 'Show cache statistics.')
      ..addFlag('clear', negatable: false, help: 'Clear cached test results.')
      ..addOption('test', help: 'Specific test file to clear from cache.')
      ..addFlag(
        'cleanup',
        negatable: false,
        help: 'Remove old cache entries (>30 days).',
      );
  }

  @override
  String get description => 'Manage test result cache';

  @override
  String get name => 'cache';

  @override
  Future<int> run() async {
    final logger = Logger();
    final showStats = argResults?['stats'] as bool? ?? false;
    final clearCache = argResults?['clear'] as bool? ?? false;
    final testPath = argResults?['test'] as String?;
    final cleanup = argResults?['cleanup'] as bool? ?? false;

    try {
      final cacheManager = CacheManager.instance;
      await cacheManager.initialize();

      if (clearCache) {
        return await _clearCache(logger, cacheManager, testPath);
      }

      if (cleanup) {
        return await _cleanupCache(logger, cacheManager);
      }

      if (showStats || (!clearCache && !cleanup)) {
        return await _showStats(logger, cacheManager);
      }

      return 0;
    } catch (e) {
      logger.err('❌ Error managing cache: $e');
      return 1;
    }
  }

  Future<int> _showStats(Logger logger, CacheManager cacheManager) async {
    logger.info('📊 Cache Statistics\n');

    final stats = cacheManager.getStats();

    logger.info('Total cached results: ${stats['total_cached_results']}');
    logger.success('  ✅ Passed: ${stats['passed']}');
    logger.err('  ❌ Failed: ${stats['failed']}');
    logger.info('Cache size: ${stats['cache_size_mb']} MB');
    logger.info('Cache location: ${stats['cache_path']}\n');

    // Show cached test files
    final cachedTests = cacheManager.getCachedTestPaths();
    if (cachedTests.isNotEmpty) {
      logger.info('Cached test files:');
      for (final test in cachedTests) {
        logger.info('  • $test');
      }
    }

    return 0;
  }

  Future<int> _clearCache(
    Logger logger,
    CacheManager cacheManager,
    String? testPath,
  ) async {
    if (testPath != null) {
      final progress = logger.progress('Clearing cache for $testPath');
      await cacheManager.clearTest(testPath);
      progress.complete('✅ Cache cleared for $testPath');
    } else {
      final confirmed = logger.confirm(
        'Are you sure you want to clear all cached results?',
      );

      if (!confirmed) {
        logger.info('Cache clear cancelled');
        return 0;
      }

      final progress = logger.progress('Clearing all cache');
      await cacheManager.clearAll();
      progress.complete('✅ All cache cleared');
    }

    return 0;
  }

  Future<int> _cleanupCache(Logger logger, CacheManager cacheManager) async {
    final progress = logger.progress('Cleaning up old cache entries');
    await cacheManager.cleanupOldEntries();
    progress.complete('✅ Old cache entries removed');
    return 0;
  }
}
