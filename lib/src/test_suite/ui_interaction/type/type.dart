import '../../step_result.dart';
import '../../test_action.dart';
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
        message:
            'Successfully typed "$textToType" into field identified by "$fieldIdentifier"',
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
      () => _findByParentProperties(tester, identifier),
      () => _findByChildProperties(tester, identifier),
      () => _findByControllerProperties(tester, identifier),
      () => _findByFocusNodeProperties(tester, identifier),
      () => _findByCustomProperties(tester, identifier),
      () => _findByWidgetTree(tester, identifier),
      () => _findFocusNodeThroughElements(tester, identifier),
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
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is TextField ||
                widget is TextFormField ||
                widget.runtimeType.toString().contains('TextField'),
          ),
        );
        if (tester.any(textFieldFinder)) return textFieldFinder;

        // If semantics widget itself is a text field
        if (tester.any(
          find.descendant(
            of: semanticFinder,
            matching: find.byType(EditableText),
          ),
        )) {
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
        matching: find.byWidgetPredicate(
          (widget) => widget is TextField || widget is TextFormField,
        ),
      );
    }

    return find.byWidgetPredicate((widget) => false);
  }

  /// Strategy 5: Find Cupertino text fields
  Finder _findByCupertinoProperties(WidgetTester tester, String identifier) {
    return find.byWidgetPredicate((widget) {
      final typeName = widget.runtimeType.toString();
      if (typeName.contains('CupertinoTextField') ||
          typeName.contains('CupertinoTextFormField')) {
        try {
          final dynamic cupertinoWidget = widget;
          return (cupertinoWidget.placeholder == identifier) ||
              (cupertinoWidget.prefix?.toString().contains(identifier) ??
                  false) ||
              (cupertinoWidget.suffix?.toString().contains(identifier) ??
                  false);
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
        final initialValue = widget is TextFormField
            ? widget.initialValue
            : null;
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
        final allTextFields = find.byWidgetPredicate(
          (widget) => widget is TextField || widget is TextFormField,
        );

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
        final allTextFields = find.byWidgetPredicate(
          (widget) =>
              widget.runtimeType.toString().toLowerCase().contains('textfield'),
        );

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
      final testId = identifier.contains(':')
          ? identifier.split(':')[1]
          : identifier;
      return find.byWidgetPredicate((widget) {
        return widget.key?.toString().contains(testId) ?? false;
      });
    }
    return find.byWidgetPredicate((widget) => false);
  }

  /// Strategy 11: Find by parent widget properties
  /// Alternative Fix 4: Using visitAncestorElements for safer traversal
  Finder _findByParentProperties(WidgetTester tester, String identifier) {
    if (identifier.startsWith('parent:')) {
      final parentInfo = identifier.substring(7);

      return find.byWidgetPredicate((widget) {
        if (widget is TextField || widget is TextFormField) {
          try {
            final element = tester.element(find.byWidget(widget));
            bool found = false;

            element.visitAncestorElements((ancestor) {
              if (ancestor.widget.toString().contains(parentInfo)) {
                found = true;
                return false; // Stop traversal
              }
              return true; // Continue traversal
            });

            return found;
          } catch (e) {
            return false;
          }
        }
        return false;
      });
    }
    return find.byWidgetPredicate((widget) => false);
  }

  /// Strategy 12: Find by child properties
  Finder _findByChildProperties(WidgetTester tester, String identifier) {
    final textFinder = find.textContaining(identifier);
    if (tester.any(textFinder)) {
      return find.ancestor(
        of: textFinder,
        matching: find.byWidgetPredicate(
          (widget) => widget is TextField || widget is TextFormField,
        ),
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
          return widget.controller?.toString().contains(controllerInfo) ??
              false;
        } else if (widget is TextFormField) {
          return widget.controller?.toString().contains(controllerInfo) ??
              false;
        }
        return false;
      });
    }
    return find.byWidgetPredicate((widget) => false);
  }

  /// Strategy 14: Enhanced Focus Node Finding (Corrected)
  /// This approach properly handles different widget types and their actual properties
  Finder _findByFocusNodeProperties(WidgetTester tester, String identifier) {
    if (identifier.startsWith('focus:')) {
      final focusInfo = identifier.substring(6);

      // Strategy 1: Find TextField with correct focus node property
      final textFieldFinder = find.byWidgetPredicate((widget) {
        if (widget is TextField && widget.focusNode != null) {
          return widget.focusNode!.debugLabel?.contains(focusInfo) ?? false;
        }
        return false;
      });

      if (tester.any(textFieldFinder)) {
        return textFieldFinder;
      }

      // Strategy 2: Find TextFormField (access focus node through FormField)
      final textFormFieldFinder = find.byWidgetPredicate((widget) {
        if (widget is TextFormField) {
          try {
            // TextFormField extends FormField<String>
            // We need to check if it has a focus node through its decoration or other means
            final dynamic formField = widget;

            // Try to access focus node through reflection/dynamic access
            if (formField.focusNode != null) {
              return formField.focusNode.debugLabel?.contains(focusInfo) ??
                  false;
            }
          } catch (e) {
            // If direct access fails, widget might not have focus node set
          }
        }
        return false;
      });

      if (tester.any(textFormFieldFinder)) {
        return textFormFieldFinder;
      }

      // Strategy 3: Find Focus widgets that wrap text fields
      final focusWrapperFinder = find.byWidgetPredicate((widget) {
        if (widget is Focus && widget.focusNode != null) {
          return widget.focusNode!.debugLabel?.contains(focusInfo) ?? false;
        }
        return false;
      });

      if (tester.any(focusWrapperFinder)) {
        // Look for text fields inside Focus widgets
        final wrappedTextFieldFinder = find.descendant(
          of: focusWrapperFinder,
          matching: find.byWidgetPredicate(
            (widget) => widget is TextField || widget is TextFormField,
          ),
        );

        if (tester.any(wrappedTextFieldFinder)) {
          return wrappedTextFieldFinder;
        }
      }

      // Strategy 4: Find FocusScope with correct property name
      final focusScopeFinder = find.byWidgetPredicate((widget) {
        if (widget is FocusScope && widget.focusNode != null) {
          return widget.focusNode!.debugLabel?.contains(focusInfo) ?? false;
        }
        return false;
      });

      if (tester.any(focusScopeFinder)) {
        final scopedTextFieldFinder = find.descendant(
          of: focusScopeFinder,
          matching: find.byWidgetPredicate(
            (widget) => widget is TextField || widget is TextFormField,
          ),
        );

        if (tester.any(scopedTextFieldFinder)) {
          return scopedTextFieldFinder;
        }
      }

      // Strategy 5: Global focus node search through widget tree
      final globalFocusNodeFinder = _findFocusNodeGlobally(tester, focusInfo);
      if (tester.any(globalFocusNodeFinder)) {
        return globalFocusNodeFinder;
      }
    }

    return find.byWidgetPredicate((widget) => false);
  }

  /// Global search for focus nodes by traversing the entire widget tree
  Finder _findFocusNodeGlobally(WidgetTester tester, String focusInfo) {
    final Map<FocusNode, List<Widget>> focusNodeToTextFields = {};

    try {
      // Step 1: Collect all widgets in the current tree
      final allWidgets = <Widget>[];
      final rootElement = tester.binding.rootElement;

      if (rootElement != null) {
        _collectAllWidgets(rootElement, allWidgets);
      }

      // Step 2: Build mapping of focus nodes to text fields
      for (final widget in allWidgets) {
        if (widget is TextField && widget.focusNode != null) {
          focusNodeToTextFields
              .putIfAbsent(widget.focusNode!, () => [])
              .add(widget);
        } else if (widget is Focus && widget.focusNode != null) {
          // Find any text fields that might be children of this Focus
          final textFields = _findTextFieldsInWidget(tester, widget);
          if (textFields.isNotEmpty) {
            focusNodeToTextFields
                .putIfAbsent(widget.focusNode!, () => [])
                .addAll(textFields);
          }
        }
      }

      // Step 3: Find matching focus node and return associated text field
      for (final entry in focusNodeToTextFields.entries) {
        final focusNode = entry.key;
        final textFields = entry.value;

        if (focusNode.debugLabel?.contains(focusInfo) ?? false) {
          // Return the first text field associated with this focus node
          if (textFields.isNotEmpty) {
            return find.byWidget(textFields.first);
          }
        }
      }
    } catch (e) {
      // Handle any errors during tree traversal
    }

    return find.byWidgetPredicate((widget) => false);
  }

  /// Recursively collect all widgets in the tree
  void _collectAllWidgets(Element element, List<Widget> widgets) {
    try {
      widgets.add(element.widget);
      element.visitChildren((child) {
        _collectAllWidgets(child, widgets);
      });
    } catch (e) {
      // Handle traversal errors
    }
  }

  /// Find text fields that are children of a given widget
  List<Widget> _findTextFieldsInWidget(
    WidgetTester tester,
    Widget parentWidget,
  ) {
    final textFields = <Widget>[];

    try {
      final descendantFinder = find.descendant(
        of: find.byWidget(parentWidget),
        matching: find.byWidgetPredicate(
          (widget) => widget is TextField || widget is TextFormField,
        ),
      );

      if (tester.any(descendantFinder)) {
        textFields.addAll(tester.widgetList(descendantFinder));
      }
    } catch (e) {
      // Handle finder errors
    }

    return textFields;
  }

  /// Strategy for finding focus nodes through Element inspection
  /// This bypasses widget property limitations by examining the element tree
  Finder _findFocusNodeThroughElements(WidgetTester tester, String focusInfo) {
    return find.byWidgetPredicate((widget) {
      try {
        final element = tester.element(find.byWidget(widget));

        // Check if this element has focus-related render objects
        final renderObject = element.renderObject;
        if (renderObject != null) {
          final renderString = renderObject.toString();
          if (renderString.contains(focusInfo) &&
              (renderString.contains('Focus') ||
                  renderString.contains('Editable'))) {
            // Verify this is actually a text field
            return widget is TextField || widget is TextFormField;
          }
        }

        // Check element properties
        final elementString = element.toString();
        if (elementString.contains(focusInfo) &&
            elementString.contains('Focus')) {
          return widget is TextField || widget is TextFormField;
        }
      } catch (e) {
        // Handle element access errors
      }

      return false;
    });
  }

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
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is TextField ||
              widget is TextFormField ||
              widget.runtimeType.toString().contains('TextField'),
        ),
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
  String get description =>
      'Type "$textToType" into field identified by "$fieldIdentifier"';
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
  static _TypeBuilder semantic(String semanticLabel) =>
      _TypeBuilder(semanticLabel);

  /// Find text field by index (0-based)
  static _TypeBuilder index(int index) => _TypeBuilder('index:$index');

  /// Find text field by test ID (prefixed automatically)
  static _TypeBuilder testId(String testId) => _TypeBuilder('testId:$testId');

  /// Find text field by controller reference
  static _TypeBuilder controller(String controllerInfo) =>
      _TypeBuilder('controller:$controllerInfo');

  /// Find text field by focus node debug label
  static _TypeBuilder focus(String focusLabel) =>
      _TypeBuilder('focus:$focusLabel');

  /// Find text field by parent widget information
  static _TypeBuilder parent(String parentInfo) =>
      _TypeBuilder('parent:$parentInfo');

  /// Find text field containing specific text content
  static _TypeBuilder content(String textContent) => _TypeBuilder(textContent);

  /// Find Cupertino text field by placeholder
  static _TypeBuilder placeholder(String placeholderText) =>
      _TypeBuilder(placeholderText);

  /// Find text field by position relative to other elements
  static _TypeBuilder position(String positionInfo) =>
      _TypeBuilder('position:$positionInfo');
}
