// pilot_finder.dart - Advanced custom finder for Flutter Test Pilot
// Extends Flutter's Finder with intelligent, efficient, and self-healing capabilities

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'finder_strategies.dart';
import 'finder_cache.dart';
import 'finder_context.dart';

/// Advanced custom finder that extends Flutter's Finder with intelligent capabilities
///
/// Features:
/// - Multi-strategy finding (17+ strategies)
/// - Intelligent caching for performance
/// - Self-healing when UI changes
/// - Fuzzy matching
/// - Context-aware searching
/// - Performance optimizations
class PilotFinder extends Finder {
  final String identifier;
  final FinderContext context;
  final List<FinderStrategy> strategies;
  final bool enableCache;
  final bool enableSelfHealing;
  final WidgetTester tester;

  // Cache for found widgets
  static final FinderCache _cache = FinderCache();

  // Performance tracking
  static final Map<String, Duration> _performanceMetrics = {};

  PilotFinder({
    required this.identifier,
    required this.tester,
    this.context = const FinderContext(),
    List<FinderStrategy>? strategies,
    this.enableCache = true,
    this.enableSelfHealing = true,
  }) : strategies = strategies ?? FinderStrategy.defaultStrategies();

  @override
  String get description =>
      'PilotFinder: $identifier (${strategies.length} strategies)';

  @override
  Iterable<Element> apply(Iterable<Element> candidates) {
    final stopwatch = Stopwatch()..start();

    try {
      // Check cache first
      if (enableCache) {
        final cached = _cache.get(identifier, context);
        if (cached != null && _isValidElement(cached)) {
          print(
            '✅ Cache hit for: $identifier (${stopwatch.elapsedMicroseconds}μs)',
          );
          return [cached];
        }
      }

      // Try each strategy in order
      Element? found;
      FinderStrategy? successfulStrategy;

      for (final strategy in strategies) {
        try {
          found = strategy.find(tester, identifier, context, candidates);
          if (found != null && _isValidElement(found)) {
            successfulStrategy = strategy;
            break;
          }
        } catch (e) {
          // Strategy failed, try next
          continue;
        }
      }

      if (found != null && successfulStrategy != null) {
        // Cache the result
        if (enableCache) {
          _cache.put(identifier, context, found, successfulStrategy);
        }

        // Record performance
        stopwatch.stop();
        _performanceMetrics[identifier] = stopwatch.elapsed;

        print(
          '✅ Found "$identifier" using ${successfulStrategy.name} (${stopwatch.elapsedMilliseconds}ms)',
        );
        return [found];
      }

      // Self-healing: try fuzzy strategies
      if (enableSelfHealing) {
        found = _attemptSelfHealing(candidates);
        if (found != null) {
          stopwatch.stop();
          print(
            '🔧 Self-healed "$identifier" (${stopwatch.elapsedMilliseconds}ms)',
          );
          return [found];
        }
      }

      // Nothing found
      stopwatch.stop();
      print(
        '❌ Not found: "$identifier" after ${strategies.length} strategies (${stopwatch.elapsedMilliseconds}ms)',
      );
      return <Element>[];
    } catch (e) {
      stopwatch.stop();
      print('❌ Error finding "$identifier": $e');
      return <Element>[];
    }
  }

  /// Validate that element is still in the tree and visible
  bool _isValidElement(Element element) {
    try {
      if (!element.mounted) return false;

      final renderObject = element.renderObject;
      if (renderObject == null) return false;

      // Check if widget is visible (has size)
      if (renderObject is RenderBox) {
        return renderObject.hasSize &&
            renderObject.size.width > 0 &&
            renderObject.size.height > 0;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Attempt self-healing with fuzzy strategies
  Element? _attemptSelfHealing(Iterable<Element> candidates) {
    final healingStrategies = [
      FuzzyTextStrategy(),
      PartialMatchStrategy(),
      SimilarWidgetStrategy(),
      DescendantSearchStrategy(),
    ];

    for (final strategy in healingStrategies) {
      try {
        final found = strategy.find(tester, identifier, context, candidates);
        if (found != null && _isValidElement(found)) {
          print('🔧 Healed with: ${strategy.name}');
          return found;
        }
      } catch (e) {
        continue;
      }
    }

    return null;
  }

  /// Clear cache (useful for dynamic UIs)
  static void clearCache() {
    _cache.clear();
    print('🗑️ Finder cache cleared');
  }

  /// Get performance metrics
  static Map<String, Duration> getPerformanceMetrics() {
    return Map.unmodifiable(_performanceMetrics);
  }

  /// Print performance report
  static void printPerformanceReport() {
    if (_performanceMetrics.isEmpty) {
      print('📊 No performance metrics recorded');
      return;
    }

    print('\n📊 PILOT FINDER PERFORMANCE REPORT');
    print('═' * 60);

    final sorted = _performanceMetrics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sorted) {
      final ms = entry.value.inMilliseconds;
      final icon = ms < 50
          ? '🟢'
          : ms < 200
          ? '🟡'
          : '🔴';
      print('$icon ${entry.key}: ${ms}ms');
    }

    final avg =
        _performanceMetrics.values
            .map((d) => d.inMilliseconds)
            .reduce((a, b) => a + b) /
        _performanceMetrics.length;

    print('─' * 60);
    print('Average: ${avg.toStringAsFixed(1)}ms');
    print('Total searches: ${_performanceMetrics.length}');
    print('Cache hits: ${_cache.hitCount}');
    print('Cache misses: ${_cache.missCount}');
    print('Hit rate: ${_cache.hitRate.toStringAsFixed(1)}%');
    print('═' * 60 + '\n');
  }
}

/// Fluent API for creating PilotFinders
class PilotFind {
  final WidgetTester tester;

  const PilotFind(this.tester);

  /// Find by text (with fuzzy matching)
  PilotFinder text(String text, {bool exact = false}) {
    return PilotFinder(
      identifier: text,
      tester: tester,
      context: FinderContext(findType: FindType.text, exact: exact),
      strategies: exact
          ? [ExactTextStrategy(), TextStrategy()]
          : FinderStrategy.textStrategies(),
    );
  }

  /// Find by key
  PilotFinder key(String key) {
    return PilotFinder(
      identifier: key,
      tester: tester,
      context: FinderContext(findType: FindType.key),
      strategies: FinderStrategy.keyStrategies(),
    );
  }

  /// Find by semantic label
  PilotFinder semantic(String label) {
    return PilotFinder(
      identifier: label,
      tester: tester,
      context: FinderContext(findType: FindType.semantic),
      strategies: FinderStrategy.semanticStrategies(),
    );
  }

  /// Find by widget type
  PilotFinder type(Type widgetType) {
    return PilotFinder(
      identifier: widgetType.toString(),
      tester: tester,
      context: FinderContext(findType: FindType.type),
      strategies: FinderStrategy.typeStrategies(),
    );
  }

  /// Find by hint text (for TextFields)
  PilotFinder hint(String hint) {
    return PilotFinder(
      identifier: hint,
      tester: tester,
      context: FinderContext(findType: FindType.hint),
      strategies: FinderStrategy.inputStrategies(),
    );
  }

  /// Find by label text (for TextFields)
  PilotFinder label(String label) {
    return PilotFinder(
      identifier: label,
      tester: tester,
      context: FinderContext(findType: FindType.label),
      strategies: FinderStrategy.inputStrategies(),
    );
  }

  /// Find by icon
  PilotFinder icon(IconData icon) {
    return PilotFinder(
      identifier: icon.codePoint.toString(),
      tester: tester,
      context: FinderContext(findType: FindType.icon),
      strategies: FinderStrategy.iconStrategies(),
    );
  }

  /// Find by tooltip
  PilotFinder tooltip(String message) {
    return PilotFinder(
      identifier: message,
      tester: tester,
      context: FinderContext(findType: FindType.tooltip),
      strategies: [TooltipStrategy()],
    );
  }

  /// Smart find - tries all strategies
  PilotFinder smart(String identifier) {
    return PilotFinder(
      identifier: identifier,
      tester: tester,
      context: FinderContext(findType: FindType.smart),
      strategies: FinderStrategy.defaultStrategies(),
    );
  }

  /// Find by custom predicate
  PilotFinder where(bool Function(Widget) predicate, String description) {
    return PilotFinder(
      identifier: description,
      tester: tester,
      context: FinderContext(findType: FindType.custom),
      strategies: [CustomPredicateStrategy(predicate)],
    );
  }

  /// Find descendant (child of parent)
  PilotFinder descendant({required String parent, required String child}) {
    return PilotFinder(
      identifier: child,
      tester: tester,
      context: FinderContext(findType: FindType.descendant, parent: parent),
      strategies: [DescendantStrategy(parent)],
    );
  }

  /// Find ancestor (parent of child)
  PilotFinder ancestor({required String child, required String parent}) {
    return PilotFinder(
      identifier: parent,
      tester: tester,
      context: FinderContext(findType: FindType.ancestor, child: child),
      strategies: [AncestorStrategy(child)],
    );
  }

  /// Find by position (index)
  PilotFinder atIndex(int index, {FindType? ofType}) {
    return PilotFinder(
      identifier: 'index:$index',
      tester: tester,
      context: FinderContext(findType: FindType.byIndex, index: index),
      strategies: [IndexStrategy(index)],
    );
  }

  /// Find first matching widget
  PilotFinder first(String identifier) {
    return PilotFinder(
      identifier: identifier,
      tester: tester,
      context: FinderContext(
        findType: FindType.smart,
        position: Position.first,
      ),
    );
  }

  /// Find last matching widget
  PilotFinder last(String identifier) {
    return PilotFinder(
      identifier: identifier,
      tester: tester,
      context: FinderContext(findType: FindType.smart, position: Position.last),
    );
  }
}

/// Extension to add PilotFind to WidgetTester
extension PilotFinderExtension on WidgetTester {
  /// Access Pilot Finder
  PilotFind get pilot => PilotFind(this);
}
