import '../step_result.dart';
import '../test_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class Type extends TestAction {
  final String fieldIdentifier;
  final String textToType;
  final bool clear;

  Type._(this.fieldIdentifier, this.textToType, {this.clear = true});

  /// Type into a field identified by key, hint text, label, or placeholder
  static _TypeBuilder into(String fieldIdentifier) {
    return _TypeBuilder(fieldIdentifier);
  }

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    try {
      final finder = _findTextField(tester, fieldIdentifier);
      
      if (!tester.any(finder)) {
        stopwatch.stop();
        return StepResult.failure(
          'No text field found with identifier: "$fieldIdentifier"',
          duration: stopwatch.elapsed,
        );
      }

      // Handle multiple matches
      final widgets = tester.widgetList(finder).toList();
      if (widgets.length > 1) {
        stopwatch.stop();
        return StepResult.failure(
          'Multiple text fields found with identifier: "$fieldIdentifier". Found ${widgets.length} matches.',
          duration: stopwatch.elapsed,
        );
      }

      // Clear or append text
      if (clear) {
        await tester.enterText(finder, textToType);
      } else {
        // Get current text from the field
        final currentText = _getCurrentText(tester, finder);
        await tester.enterText(finder, currentText + textToType);
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      return StepResult.success(
        message: 'Successfully typed "$textToType" into field identified by "$fieldIdentifier"',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Type action failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Find text field using comprehensive strategies
  Finder _findTextField(WidgetTester tester, String identifier) {
    final strategies = [
      () => _findByKeys(tester, identifier),
      () => _findByDecorationProperties(tester, identifier),
      () => _findBySemantics(tester, identifier),
      () => _findByTooltip(tester, identifier),
      () => _findByCupertinoProperties(tester, identifier),
      () => _findByTextContent(tester, identifier),
      () => _findByPosition(tester, identifier),
      () => _findBySize(tester, identifier),
      () => _findByWidgetIndex(tester, identifier),
      () => _findByTestSemantics(tester, identifier),
      // () => _findByParentProperties(tester, identifier),
      () => _findByChildProperties(tester, identifier),
      () => _findByControllerProperties(tester, identifier),
      // () => _findByFocusNodeProperties(tester, identifier),
      () => _findByCustomProperties(tester, identifier),
      () => _findByWidgetTree(tester, identifier),
    ];

    for (final strategy in strategies) {
      final finder = strategy();
      if (tester.any(finder)) {
        return finder;
      }
    }

    return find.byWidgetPredicate((widget) => false);
  }

  /// Strategy 1: Find by various key types
  Finder _findByKeys(WidgetTester tester, String identifier) {
    // Try different key types
    final keyTypes = [
      Key(identifier),
      ValueKey(identifier),
      ValueKey<String>(identifier),
      ObjectKey(identifier),
    ];

    for (final key in keyTypes) {
      final finder = find.byKey(key);
      if (tester.any(finder)) return finder;
    }

    // Try GlobalKey with debug label
    try {
      final globalKey = GlobalKey(debugLabel: identifier);
      final finder = find.byKey(globalKey);
      if (tester.any(finder)) return finder;
    } catch (e) {
      // Ignore GlobalKey creation errors
    }

    return find.byWidgetPredicate((widget) => false);
  }

  /// Strategy 2: Find by decoration properties (enhanced)
  Finder _findByDecorationProperties(WidgetTester tester, String identifier) {
    return find.byWidgetPredicate((widget) {
      InputDecoration? decoration;
      
      if (widget is TextField) {
        decoration = widget.decoration;
      } else if (widget is TextFormField) {
        // TextFormField doesn't have direct decoration access, need to check through FormField
        try {
          final dynamic formField = widget;
          decoration = formField.decoration as InputDecoration?;
        } catch (e) {
          decoration = null;
        }
      }

      if (decoration != null) {
        return decoration.hintText == identifier ||
            decoration.labelText == identifier ||
            decoration.helperText == identifier ||
            decoration.prefixText == identifier ||
            decoration.suffixText == identifier ||
            decoration.counterText == identifier ||
            decoration.errorText == identifier ||
            (decoration.icon?.toString().contains(identifier) ?? false) ||
            (decoration.prefixIcon?.toString().contains(identifier) ?? false) ||
            (decoration.suffixIcon?.toString().contains(identifier) ?? false);
      }
      return false;
    });
  }

  /// Strategy 3: Find by semantics (enhanced)
  Finder _findBySemantics(WidgetTester tester, String identifier) {
    // Try different semantic approaches
    final semanticFinders = [
      find.bySemanticsLabel(identifier),
      find.byWidgetPredicate((widget) {
        if (widget is Semantics) {
          final props = widget.properties;
          return props.label == identifier ||
              props.hint == identifier ||
              props.value == identifier ||
              props.increasedValue == identifier ||
              props.decreasedValue == identifier;
        }
        return false;
      }),
    ];

    for (final semanticFinder in semanticFinders) {
      if (tester.any(semanticFinder)) {
        final textFieldFinder = find.descendant(
          of: semanticFinder,
          matching: find.byWidgetPredicate((widget) => 
            widget is TextField || widget is TextFormField || 
            widget.runtimeType.toString().contains('TextField')),
        );
        if (tester.any(textFieldFinder)) return textFieldFinder;
        
        // If semantics widget itself is a text field
        if (tester.any(find.descendant(of: semanticFinder, matching: find.byType(EditableText)))) {
          return semanticFinder;
        }
      }
    }

    return find.byWidgetPredicate((widget) => false);
  }

  /// Strategy 4: Find by tooltip
  Finder _findByTooltip(WidgetTester tester, String identifier) {
    final tooltipFinder = find.byWidgetPredicate((widget) {
      return widget is Tooltip && widget.message == identifier;
    });

    if (tester.any(tooltipFinder)) {
      return find.descendant(
        of: tooltipFinder,
        matching: find.byWidgetPredicate((widget) => 
          widget is TextField || widget is TextFormField),
      );
    }

    return find.byWidgetPredicate((widget) => false);
  }

  /// Strategy 5: Find Cupertino text fields
  Finder _findByCupertinoProperties(WidgetTester tester, String identifier) {
    return find.byWidgetPredicate((widget) {
      final typeName = widget.runtimeType.toString();
      if (typeName.contains('CupertinoTextField') || typeName.contains('CupertinoTextFormField')) {
        try {
          final dynamic cupertinoWidget = widget;
          return (cupertinoWidget.placeholder == identifier) ||
              (cupertinoWidget.prefix?.toString().contains(identifier) ?? false) ||
              (cupertinoWidget.suffix?.toString().contains(identifier) ?? false);
        } catch (e) {
          return false;
        }
      }
      return false;
    });
  }

  /// Strategy 6: Find by text content
  Finder _findByTextContent(WidgetTester tester, String identifier) {
    return find.byWidgetPredicate((widget) {
      if (widget is TextField || widget is TextFormField) {
        final controller = (widget as dynamic).controller;
        final initialValue = widget is TextFormField ? widget.initialValue : null;
        return controller?.text == identifier || initialValue == identifier;
      }
      return false;
    });
  }

  /// Strategy 7: Find by position (index-based)
  Finder _findByPosition(WidgetTester tester, String identifier) {
    if (identifier.startsWith('index:')) {
      try {
        final index = int.parse(identifier.substring(6));
        final allTextFields = find.byWidgetPredicate((widget) => 
          widget is TextField || widget is TextFormField);
        
        final widgets = tester.widgetList(allTextFields).toList();
        if (index >= 0 && index < widgets.length) {
          return find.byWidget(widgets[index]);
        }
      } catch (e) {
        // Invalid index format
      }
    }
    return find.byWidgetPredicate((widget) => false);
  }

  /// Strategy 8: Find by size properties
  Finder _findBySize(WidgetTester tester, String identifier) {
    if (identifier.startsWith('size:')) {
      final sizeStr = identifier.substring(5);
      return find.byWidgetPredicate((widget) {
        if (widget is TextField || widget is TextFormField) {
          try {
            final context = tester.element(find.byWidget(widget));
            final renderBox = context.findRenderObject() as RenderBox?;
            return renderBox?.size.toString().contains(sizeStr) ?? false;
          } catch (e) {
            return false;
          }
        }
        return false;
      });
    }
    return find.byWidgetPredicate((widget) => false);
  }

  /// Strategy 9: Find by widget index in tree
  Finder _findByWidgetIndex(WidgetTester tester, String identifier) {
    final regex = RegExp(r'^(\w+):(\d+)$');
    final match = regex.firstMatch(identifier);
    
    if (match != null) {
      final widgetType = match.group(1)!;
      final index = int.tryParse(match.group(2)!) ?? -1;
      
      if (widgetType.toLowerCase().contains('textfield') && index >= 0) {
        final allTextFields = find.byWidgetPredicate((widget) => 
          widget.runtimeType.toString().toLowerCase().contains('textfield'));
        
        final widgets = tester.widgetList(allTextFields).toList();
        if (index < widgets.length) {
          return find.byWidget(widgets[index]);
        }
      }
    }
    return find.byWidgetPredicate((widget) => false);
  }

  /// Strategy 10: Find by test semantics
  Finder _findByTestSemantics(WidgetTester tester, String identifier) {
    if (identifier.startsWith('test:') || identifier.startsWith('testId:')) {
      final testId = identifier.contains(':') ? identifier.split(':')[1] : identifier;
      return find.byWidgetPredicate((widget) {
        return widget.key?.toString().contains(testId) ?? false;
      });
    }
    return find.byWidgetPredicate((widget) => false);
  }

  // /// Strategy 11: Find by parent widget properties
  // Finder _findByParentProperties(WidgetTester tester, String identifier) {
  //   if (identifier.startsWith('parent:')) {
  //     final parentInfo = identifier.substring(7);
      
  //     return find.byWidgetPredicate((widget) {
  //       if (widget is TextField || widget is TextFormField) {
  //         try {
  //           final element = tester.element(find.byWidget(widget));
  //           final parent = element.parent;
  //           return parent?.widget.toString().contains(parentInfo) ?? false;
  //         } catch (e) {
  //           return false;
  //         }
  //       }
  //       return false;
  //     });
  //   }
  //   return find.byWidgetPredicate((widget) => false);
  // }

  /// Strategy 12: Find by child properties
  Finder _findByChildProperties(WidgetTester tester, String identifier) {
    final textFinder = find.textContaining(identifier);
    if (tester.any(textFinder)) {
      return find.ancestor(
        of: textFinder,
        matching: find.byWidgetPredicate((widget) => 
          widget is TextField || widget is TextFormField),
      );
    }
    return find.byWidgetPredicate((widget) => false);
  }

  /// Strategy 13: Find by controller properties
  Finder _findByControllerProperties(WidgetTester tester, String identifier) {
    if (identifier.startsWith('controller:')) {
      final controllerInfo = identifier.substring(11);
      return find.byWidgetPredicate((widget) {
        if (widget is TextField) {
          return widget.controller?.toString().contains(controllerInfo) ?? false;
        } else if (widget is TextFormField) {
          return widget.controller?.toString().contains(controllerInfo) ?? false;
        }
        return false;
      });
    }
    return find.byWidgetPredicate((widget) => false);
  }

  // /// Strategy 14: Find by focus node properties
  // Finder _findByFocusNodeProperties(WidgetTester tester, String identifier) {
  //   if (identifier.startsWith('focus:')) {
  //     final focusInfo = identifier.substring(6);
  //     return find.byWidgetPredicate((widget) {
  //       if (widget is TextField) {
  //         return widget.focusNode?.debugLabel?.contains(focusInfo) ?? false;
  //       } else if (widget is TextFormField) {
  //         return widget.focusNode?.debugLabel?.contains(focusInfo) ?? false;
  //       }
  //       return false;
  //     });
  //   }
  //   return find.byWidgetPredicate((widget) => false);
  // }
  

  /// Strategy 15: Find by custom widget properties
  Finder _findByCustomProperties(WidgetTester tester, String identifier) {
    return find.byWidgetPredicate((widget) {
      if (widget is TextField || widget is TextFormField) {
        final widgetString = widget.toString();
        return widgetString.contains(identifier) ||
            widget.runtimeType.toString().contains(identifier);
      }
      return false;
    });
  }

  /// Strategy 16: Find by widget tree traversal
  Finder _findByWidgetTree(WidgetTester tester, String identifier) {
    // Find any widget that contains the identifier and has a text field descendant
    final containerFinder = find.byWidgetPredicate((widget) {
      final widgetStr = widget.toString();
      return widgetStr.contains(identifier);
    });

    if (tester.any(containerFinder)) {
      final textFieldFinder = find.descendant(
        of: containerFinder,
        matching: find.byWidgetPredicate((widget) => 
          widget is TextField || widget is TextFormField ||
          widget.runtimeType.toString().contains('TextField')),
      );
      
      if (tester.any(textFieldFinder)) {
        return textFieldFinder;
      }
    }

    return find.byWidgetPredicate((widget) => false);
  }

  /// Get current text from the text field
  String _getCurrentText(WidgetTester tester, Finder finder) {
    try {
      final widget = tester.widget(finder);
      
      if (widget is TextField) {
        return widget.controller?.text ?? '';
      } else if (widget is TextFormField) {
        return widget.controller?.text ?? widget.initialValue ?? '';
      }
      
      // For other text input widgets, try to get text through EditableText
      final editableTextFinder = find.descendant(
        of: finder,
        matching: find.byType(EditableText),
      );
      
      if (tester.any(editableTextFinder)) {
        final editableText = tester.widget<EditableText>(editableTextFinder);
        return editableText.controller.text;
      }
      
      return '';
    } catch (e) {
      return '';
    }
  }

  @override
  String get description => 'Type "$textToType" into field identified by "$fieldIdentifier"';
}

class _TypeBuilder {
  final String fieldIdentifier;

  const _TypeBuilder(this.fieldIdentifier);

  /// Type text into the field, optionally clearing existing text
  Type text(String text, {bool clear = true}) {
    return Type._(fieldIdentifier, text, clear: clear);
  }

  /// Type text and clear existing content (default behavior)
  Type clearAndType(String text) {
    return Type._(fieldIdentifier, text, clear: true);
  }

  /// Append text to existing content
  Type append(String text) {
    return Type._(fieldIdentifier, text, clear: false);
  }
}

/// Additional factory methods for common identification patterns
extension TypeExtensions on Type {
  /// Find text field by hint text
  static _TypeBuilder hint(String hintText) => _TypeBuilder(hintText);
  
  /// Find text field by label text
  static _TypeBuilder label(String labelText) => _TypeBuilder(labelText);
  
  /// Find text field by key
  static _TypeBuilder key(String keyValue) => _TypeBuilder(keyValue);
  
  /// Find text field by semantic label
  static _TypeBuilder semantic(String semanticLabel) => _TypeBuilder(semanticLabel);
  
  /// Find text field by index (0-based)
  static _TypeBuilder index(int index) => _TypeBuilder('index:$index');
  
  /// Find text field by test ID (prefixed automatically)
  static _TypeBuilder testId(String testId) => _TypeBuilder('testId:$testId');
  
  /// Find text field by controller reference
  static _TypeBuilder controller(String controllerInfo) => _TypeBuilder('controller:$controllerInfo');
  
  /// Find text field by focus node debug label
  static _TypeBuilder focus(String focusLabel) => _TypeBuilder('focus:$focusLabel');
  
  /// Find text field by parent widget information
  static _TypeBuilder parent(String parentInfo) => _TypeBuilder('parent:$parentInfo');
  
  /// Find text field containing specific text content
  static _TypeBuilder content(String textContent) => _TypeBuilder(textContent);
  
  /// Find Cupertino text field by placeholder
  static _TypeBuilder placeholder(String placeholderText) => _TypeBuilder(placeholderText);
  
  /// Find text field by position relative to other elements
  static _TypeBuilder position(String positionInfo) => _TypeBuilder('position:$positionInfo');
}

