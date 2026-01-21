// finder_strategies.dart - Different strategies for finding widgets
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide find;
import 'package:flutter_test/flutter_test.dart' as flutter_test;
import 'finder_context.dart';

/// Base class for all finder strategies
abstract class FinderStrategy {
  String get name;
  int get priority => 10; // Lower = higher priority

  /// Find an element using this strategy
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  );

  /// Default strategies in priority order
  static List<FinderStrategy> defaultStrategies() {
    return [
      // High priority - most specific
      KeyStrategy(),
      ValueKeyStrategy(),
      ObjectKeyStrategy(),
      GlobalKeyStrategy(),

      // Medium priority - common patterns
      ExactTextStrategy(),
      SemanticLabelStrategy(),
      HintTextStrategy(),
      LabelTextStrategy(),

      // Lower priority - broader searches
      TextStrategy(),
      IconStrategy(),
      TooltipStrategy(),
      WidgetTypeStrategy(),

      // Fallback strategies
      PartialMatchStrategy(),
      FuzzyTextStrategy(),
      DescendantSearchStrategy(),
    ]..sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// Strategies optimized for text finding
  static List<FinderStrategy> textStrategies() {
    return [
      ExactTextStrategy(),
      TextStrategy(),
      PartialMatchStrategy(),
      FuzzyTextStrategy(),
    ];
  }

  /// Strategies optimized for key finding
  static List<FinderStrategy> keyStrategies() {
    return [
      KeyStrategy(),
      ValueKeyStrategy(),
      ObjectKeyStrategy(),
      GlobalKeyStrategy(),
    ];
  }

  /// Strategies for semantic labels
  static List<FinderStrategy> semanticStrategies() {
    return [
      SemanticLabelStrategy(),
      SemanticHintStrategy(),
      SemanticValueStrategy(),
    ];
  }

  /// Strategies for widget types
  static List<FinderStrategy> typeStrategies() {
    return [WidgetTypeStrategy(), SubtypeStrategy()];
  }

  /// Strategies for input fields
  static List<FinderStrategy> inputStrategies() {
    return [
      HintTextStrategy(),
      LabelTextStrategy(),
      PlaceholderStrategy(),
      PrefixTextStrategy(),
    ];
  }

  /// Strategies for icons
  static List<FinderStrategy> iconStrategies() {
    return [IconStrategy(), IconDataStrategy()];
  }
}

/// Find by Key (exact match)
class KeyStrategy extends FinderStrategy {
  @override
  String get name => 'Key';
  @override
  int get priority => 1; // Highest priority

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    try {
      final finder = flutter_test.find.byKey(Key(identifier));
      return tester.element(finder);
    } catch (e) {
      return null;
    }
  }
}

/// Find by ValueKey
class ValueKeyStrategy extends FinderStrategy {
  @override
  String get name => 'ValueKey';
  @override
  int get priority => 1;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    try {
      final finder = flutter_test.find.byKey(ValueKey(identifier));
      return tester.element(finder);
    } catch (e) {
      return null;
    }
  }
}

/// Find by ObjectKey
class ObjectKeyStrategy extends FinderStrategy {
  @override
  String get name => 'ObjectKey';
  @override
  int get priority => 1;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    try {
      final finder = flutter_test.find.byKey(ObjectKey(identifier));
      return tester.element(finder);
    } catch (e) {
      return null;
    }
  }
}

/// Find by GlobalKey (with debug label)
class GlobalKeyStrategy extends FinderStrategy {
  @override
  String get name => 'GlobalKey';
  @override
  int get priority => 1;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    for (final element in candidates) {
      final key = element.widget.key;
      if (key is GlobalKey && key.toString().contains(identifier)) {
        return element;
      }
    }
    return null;
  }
}

/// Find by exact text match
class ExactTextStrategy extends FinderStrategy {
  @override
  String get name => 'ExactText';
  @override
  int get priority => 2;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    try {
      final finder = flutter_test.find.text(identifier, findRichText: true);
      return tester.element(finder);
    } catch (e) {
      return null;
    }
  }
}

/// Find by text (includes partial matches)
class TextStrategy extends FinderStrategy {
  @override
  String get name => 'Text';
  @override
  int get priority => 5;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    try {
      // Try exact match first
      var finder = flutter_test.find.text(identifier, findRichText: true);
      if (tester.any(finder)) {
        return tester.element(finder);
      }

      // Try case-insensitive
      for (final element in candidates) {
        final widget = element.widget;
        if (widget is Text && widget.data != null) {
          if (widget.data!.toLowerCase() == identifier.toLowerCase()) {
            return element;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Find by semantic label
class SemanticLabelStrategy extends FinderStrategy {
  @override
  String get name => 'SemanticLabel';
  @override
  int get priority => 3;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    try {
      final finder = flutter_test.find.bySemanticsLabel(identifier);
      return tester.element(finder);
    } catch (e) {
      return null;
    }
  }
}

/// Find by semantic hint
class SemanticHintStrategy extends FinderStrategy {
  @override
  String get name => 'SemanticHint';
  @override
  int get priority => 4;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    for (final element in candidates) {
      try {
        final finder = flutter_test.find.byWidget(element.widget);
        final semantics = tester.getSemantics(finder);
        if (semantics.hint == identifier) {
          return element;
        }
      } catch (e) {
        continue;
      }
    }
    return null;
  }
}

/// Find by semantic value
class SemanticValueStrategy extends FinderStrategy {
  @override
  String get name => 'SemanticValue';
  @override
  int get priority => 4;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    for (final element in candidates) {
      try {
        final finder = flutter_test.find.byWidget(element.widget);
        final semantics = tester.getSemantics(finder);
        if (semantics.value == identifier) {
          return element;
        }
      } catch (e) {
        continue;
      }
    }
    return null;
  }
}

/// Find by hint text (TextField)
class HintTextStrategy extends FinderStrategy {
  @override
  String get name => 'HintText';
  @override
  int get priority => 3;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    for (final element in candidates) {
      final widget = element.widget;
      if (widget is TextField && widget.decoration?.hintText == identifier) {
        return element;
      }
      if (widget is TextFormField) {
        try {
          final decoration = (widget as dynamic).decoration as InputDecoration?;
          if (decoration?.hintText == identifier) {
            return element;
          }
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }
}

/// Find by label text (TextField)
class LabelTextStrategy extends FinderStrategy {
  @override
  String get name => 'LabelText';
  @override
  int get priority => 3;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    for (final element in candidates) {
      final widget = element.widget;
      if (widget is TextField && widget.decoration?.labelText == identifier) {
        return element;
      }
      if (widget is TextFormField) {
        try {
          final decoration = (widget as dynamic).decoration as InputDecoration?;
          if (decoration?.labelText == identifier) {
            return element;
          }
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }
}

/// Find by placeholder (CupertinoTextField)
class PlaceholderStrategy extends FinderStrategy {
  @override
  String get name => 'Placeholder';
  @override
  int get priority => 3;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    for (final element in candidates) {
      final widget = element.widget;
      // Check for CupertinoTextField
      if (widget.runtimeType.toString() == 'CupertinoTextField') {
        try {
          final placeholder = (widget as dynamic).placeholder;
          if (placeholder == identifier) {
            return element;
          }
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }
}

/// Find by prefix text (TextField)
class PrefixTextStrategy extends FinderStrategy {
  @override
  String get name => 'PrefixText';
  @override
  int get priority => 4;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    for (final element in candidates) {
      final widget = element.widget;
      if (widget is TextField) {
        final prefixText = widget.decoration?.prefixText;
        if (prefixText?.contains(identifier) ?? false) {
          return element;
        }
      }
    }
    return null;
  }
}

/// Find by icon
class IconStrategy extends FinderStrategy {
  @override
  String get name => 'Icon';
  @override
  int get priority => 4;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    for (final element in candidates) {
      final widget = element.widget;
      if (widget is Icon && widget.icon != null) {
        if (widget.icon.toString().contains(identifier)) {
          return element;
        }
      }
    }
    return null;
  }
}

/// Find by icon data (codePoint)
class IconDataStrategy extends FinderStrategy {
  @override
  String get name => 'IconData';
  @override
  int get priority => 4;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    try {
      final codePoint = int.tryParse(identifier);
      if (codePoint != null) {
        final finder = flutter_test.find.byIcon(IconData(codePoint));
        return tester.element(finder);
      }
    } catch (e) {
      // Not a valid code point
    }
    return null;
  }
}

/// Find by tooltip
class TooltipStrategy extends FinderStrategy {
  @override
  String get name => 'Tooltip';
  @override
  int get priority => 4;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    for (final element in candidates) {
      final widget = element.widget;
      if (widget is Tooltip && widget.message == identifier) {
        // Find descendant interactive widget
        Element? descendant;
        element.visitChildren((child) {
          if (child.widget is GestureDetector ||
              child.widget is InkWell ||
              child.widget is IconButton) {
            descendant = child;
          }
        });
        return descendant ?? element;
      }
    }
    return null;
  }
}

/// Find by widget type
class WidgetTypeStrategy extends FinderStrategy {
  @override
  String get name => 'WidgetType';
  @override
  int get priority => 6;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    for (final element in candidates) {
      if (element.widget.runtimeType.toString() == identifier) {
        return element;
      }
    }
    return null;
  }
}

/// Find by widget subtype
class SubtypeStrategy extends FinderStrategy {
  @override
  String get name => 'Subtype';
  @override
  int get priority => 7;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    for (final element in candidates) {
      if (element.widget.runtimeType.toString().contains(identifier)) {
        return element;
      }
    }
    return null;
  }
}

/// Find by partial text match
class PartialMatchStrategy extends FinderStrategy {
  @override
  String get name => 'PartialMatch';
  @override
  int get priority => 8;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    try {
      final finder = flutter_test.find.textContaining(
        identifier,
        findRichText: true,
      );
      return tester.element(finder);
    } catch (e) {
      return null;
    }
  }
}

/// Find by fuzzy text matching (Levenshtein distance)
class FuzzyTextStrategy extends FinderStrategy {
  @override
  String get name => 'FuzzyText';
  @override
  int get priority => 9;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    Element? bestMatch;
    double bestSimilarity = 0.0;

    for (final element in candidates) {
      final widget = element.widget;
      String? text;

      if (widget is Text) {
        text = widget.data;
      } else if (widget is ElevatedButton || widget is TextButton) {
        // Try to extract text from button child
        final child = (widget as dynamic).child;
        if (child is Text) {
          text = child.data;
        }
      }

      if (text != null) {
        final similarity = _calculateSimilarity(identifier, text);
        if (similarity > bestSimilarity && similarity > 0.7) {
          bestSimilarity = similarity;
          bestMatch = element;
        }
      }
    }

    return bestMatch;
  }

  double _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final longer = s1.length > s2.length ? s1 : s2;
    final shorter = s1.length > s2.length ? s2 : s1;
    final longerLength = longer.length;

    if (longerLength == 0) return 1.0;

    final distance = _levenshteinDistance(longer, shorter);
    return (longerLength - distance) / longerLength;
  }

  int _levenshteinDistance(String s1, String s2) {
    final costs = List<int>.filled(s2.length + 1, 0);

    for (var i = 0; i <= s1.length; i++) {
      var lastValue = i;
      for (var j = 0; j <= s2.length; j++) {
        if (i == 0) {
          costs[j] = j;
        } else if (j > 0) {
          var newValue = costs[j - 1];
          if (s1[i - 1] != s2[j - 1]) {
            newValue =
                [
                  newValue,
                  lastValue,
                  costs[j],
                ].reduce((a, b) => a < b ? a : b) +
                1;
          }
          costs[j - 1] = lastValue;
          lastValue = newValue;
        }
      }
      if (i > 0) costs[s2.length] = lastValue;
    }

    return costs[s2.length];
  }
}

/// Find similar widgets (by type and properties)
class SimilarWidgetStrategy extends FinderStrategy {
  @override
  String get name => 'SimilarWidget';
  @override
  int get priority => 10;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    // Find widgets of similar types that might match
    final commonTypes = [
      ElevatedButton,
      TextButton,
      IconButton,
      TextField,
      Text,
      Container,
    ];

    for (final type in commonTypes) {
      for (final element in candidates) {
        if (element.widget.runtimeType == type) {
          // Check if this widget's string representation contains identifier
          if (element.widget.toString().toLowerCase().contains(
            identifier.toLowerCase(),
          )) {
            return element;
          }
        }
      }
    }

    return null;
  }
}

/// Deep search in widget descendants
class DescendantSearchStrategy extends FinderStrategy {
  @override
  String get name => 'DescendantSearch';
  @override
  int get priority => 11;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    for (final element in candidates) {
      Element? found;

      element.visitChildren((child) {
        // Check text
        if (child.widget is Text) {
          final text = (child.widget as Text).data;
          if (text?.contains(identifier) ?? false) {
            found = child;
          }
        }

        // Check key
        if (child.widget.key.toString().contains(identifier)) {
          found = child;
        }
      });

      if (found != null) return found;
    }

    return null;
  }
}

/// Find descendant of a specific parent
class DescendantStrategy extends FinderStrategy {
  final String parentIdentifier;

  DescendantStrategy(this.parentIdentifier);

  @override
  String get name => 'Descendant($parentIdentifier)';
  @override
  int get priority => 5;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    // First find parent
    try {
      final parentFinder = flutter_test.find.text(parentIdentifier);
      if (!tester.any(parentFinder)) return null;

      final parent = tester.element(parentFinder);

      // Search children
      Element? found;
      parent.visitChildren((child) {
        if (child.widget.toString().contains(identifier)) {
          found = child;
        }
      });

      return found;
    } catch (e) {
      return null;
    }
  }
}

/// Find ancestor of a specific child
class AncestorStrategy extends FinderStrategy {
  final String childIdentifier;

  AncestorStrategy(this.childIdentifier);

  @override
  String get name => 'Ancestor($childIdentifier)';
  @override
  int get priority => 6;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    // First find child
    try {
      final childFinder = flutter_test.find.text(childIdentifier);
      if (!tester.any(childFinder)) return null;

      final child = tester.element(childFinder);

      // Walk up to find ancestor using visitAncestorElements
      Element? found;
      child.visitAncestorElements((ancestor) {
        if (ancestor.widget.toString().contains(identifier)) {
          found = ancestor;
          return false; // Stop visiting
        }
        return true; // Continue visiting
      });

      return found;
    } catch (e) {
      return null;
    }
  }
}

/// Find by index position
class IndexStrategy extends FinderStrategy {
  final int index;

  IndexStrategy(this.index);

  @override
  String get name => 'Index($index)';
  @override
  int get priority => 7;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    if (index < 0 || index >= candidates.length) return null;
    return candidates.elementAt(index);
  }
}

/// Find by custom predicate
class CustomPredicateStrategy extends FinderStrategy {
  final bool Function(Widget) predicate;

  CustomPredicateStrategy(this.predicate);

  @override
  String get name => 'CustomPredicate';
  @override
  int get priority => 8;

  @override
  Element? find(
    WidgetTester tester,
    String identifier,
    FinderContext context,
    Iterable<Element> candidates,
  ) {
    for (final element in candidates) {
      if (predicate(element.widget)) {
        return element;
      }
    }
    return null;
  }
}
