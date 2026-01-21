import 'model/api_validation_result.dart';

/// Base class for API validation checkers
abstract class ApiChecker {
  Future<ApiValidationResult> validate(String fieldPath, dynamic value);
  String get description;

  /// Get the expected type name for this checker
  String get expectedType => 'dynamic';
}

/// ═══════════════════════════════════════════════════════════════
/// CHECK FACTORY - Main entry point for all validation types
/// ═══════════════════════════════════════════════════════════════
///
/// Usage examples:
/// ```dart
/// // Universal validators (work with any type)
/// Check.isNull()
/// Check.isNotNull()
/// Check.isEmpty()
/// Check.isNotEmpty()
/// Check.equals('expected')
///
/// // Type-specific validators with builder pattern
/// Check.string().minLength(5).maxLength(50).build()
/// Check.integer().min(0).max(100).build()
/// Check.number().min(0.0).describe('Price').build()
/// Check.boolean().exactValue(true).build()
/// Check.list().minLength(1).items(Check.string()).build()
/// Check.object().field('name', Check.string()).build()
///
/// // Convenience shortcuts
/// Check.isEmail()
/// Check.isUrl()
/// Check.isPositive()
/// ```
class Check {
  // ═══════════════════════════════════════════════════════════════
  // UNIVERSAL VALIDATORS (work with all types)
  // ═══════════════════════════════════════════════════════════════

  /// Check if value is null
  static ApiChecker isNull() => _UniversalNullChecker(expectNull: true);

  /// Check if value is not null
  static ApiChecker isNotNull() => _UniversalNullChecker(expectNull: false);

  /// Check if value equals expected (works for all types)
  static ApiChecker equals(dynamic expected) =>
      _UniversalEqualsChecker(expected);

  /// Check if value is empty (String, List, Map, or null)
  static ApiChecker isEmpty() => _UniversalEmptyChecker(expectEmpty: true);

  /// Check if value is not empty (String, List, Map must have content)
  static ApiChecker isNotEmpty() => _UniversalEmptyChecker(expectEmpty: false);

  // ═══════════════════════════════════════════════════════════════
  // TYPE-SPECIFIC VALIDATORS (explicit type checking with builders)
  // ═══════════════════════════════════════════════════════════════

  /// Validate as String - use builder pattern for constraints
  /// Example: Check.string().minLength(5).maxLength(50).pattern(r'^\w+$').build()
  static StringCheckerBuilder string() => StringCheckerBuilder();

  /// Validate as Integer - use builder pattern for constraints
  /// Example: Check.integer().min(0).max(100).build()
  static IntCheckerBuilder integer() => IntCheckerBuilder();

  /// Validate as Number (int or double) - use builder pattern
  /// Example: Check.number().min(0.0).max(100.0).build()
  static NumberCheckerBuilder number() => NumberCheckerBuilder();

  /// Validate as Boolean - optionally with exact value
  /// Example: Check.boolean().exactValue(true).build()
  static BoolCheckerBuilder boolean() => BoolCheckerBuilder();

  /// Validate as List - optionally with item validation
  /// Example: Check.list().minLength(1).items(Check.string()).build()
  static ListCheckerBuilder list() => ListCheckerBuilder();

  /// Validate as Object/Map - with field validation
  /// Example: Check.object().field('name', Check.string()).build()
  static ObjectCheckerBuilder object() => ObjectCheckerBuilder();

  /// Accept any type without validation
  static ApiChecker any() => _AnyTypeChecker();

  // ═══════════════════════════════════════════════════════════════
  // CONVENIENCE SHORTCUTS
  // ═══════════════════════════════════════════════════════════════

  /// Quick email validation
  static ApiChecker isEmail() => StringCheckerBuilder()
      .pattern(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$')
      .describe('Valid email')
      .build();

  /// Quick URL validation
  static ApiChecker isUrl() => StringCheckerBuilder()
      .pattern(r'^https?:\/\/.+')
      .describe('Valid URL')
      .build();

  /// Quick UUID validation
  static ApiChecker isUuid() => StringCheckerBuilder()
      .pattern(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      )
      .describe('Valid UUID')
      .build();

  /// Quick phone validation (basic 10-15 digits)
  static ApiChecker isPhone() => StringCheckerBuilder()
      .pattern(r'^\d{10,15}$')
      .describe('Valid phone')
      .build();

  /// Quick boolean check
  static ApiChecker isBoolean() => BoolCheckerBuilder().build();

  /// Check if string contains substring
  static ApiChecker contains(String substring) => StringCheckerBuilder()
      .contains(substring)
      .describe('Contains "$substring"')
      .build();

  /// Check string has exact length
  static ApiChecker hasLength(int length) => StringCheckerBuilder()
      .exactLength(length)
      .describe('Length = $length')
      .build();

  /// Check if number is positive (>= 0)
  static ApiChecker isPositive() =>
      NumberCheckerBuilder().min(0).describe('Positive number').build();

  /// Check if number is negative (<= 0)
  static ApiChecker isNegative() =>
      NumberCheckerBuilder().max(0).describe('Negative number').build();
}

// ═══════════════════════════════════════════════════════════════
// UNIVERSAL CHECKERS (work with any type)
// ═══════════════════════════════════════════════════════════════

class _UniversalNullChecker extends ApiChecker {
  final bool expectNull;

  _UniversalNullChecker({required this.expectNull});

  @override
  Future<ApiValidationResult> validate(String fieldPath, dynamic value) async {
    final isNull = value == null;

    if (expectNull && !isNull) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected null, got ${value.runtimeType}',
        expected: 'null',
        actual: value.runtimeType.toString(),
      );
    }

    if (!expectNull && isNull) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected non-null value, got null',
        expected: 'non-null',
        actual: 'null',
      );
    }

    return ApiValidationResult.success(
      fieldPath,
      expectNull ? 'Value is null ✓' : 'Value is not null ✓',
      value: value,
    );
  }

  @override
  String get description => expectNull ? 'null' : 'not null';

  @override
  String get expectedType => 'any';
}

class _UniversalEqualsChecker extends ApiChecker {
  final dynamic expected;

  _UniversalEqualsChecker(this.expected);

  @override
  Future<ApiValidationResult> validate(String fieldPath, dynamic value) async {
    if (value != expected) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected "$expected", got "$value"',
        expected: expected,
        actual: value,
      );
    }

    return ApiValidationResult.success(
      fieldPath,
      'Value equals "$expected" ✓',
      value: value,
    );
  }

  @override
  String get description => 'equals "$expected"';

  @override
  String get expectedType => expected?.runtimeType.toString() ?? 'any';
}

class _UniversalEmptyChecker extends ApiChecker {
  final bool expectEmpty;

  _UniversalEmptyChecker({required this.expectEmpty});

  @override
  Future<ApiValidationResult> validate(String fieldPath, dynamic value) async {
    bool isEmpty;

    if (value == null) {
      isEmpty = true;
    } else if (value is String) {
      isEmpty = value.isEmpty;
    } else if (value is List) {
      isEmpty = value.isEmpty;
    } else if (value is Map) {
      isEmpty = value.isEmpty;
    } else {
      return ApiValidationResult.failure(
        fieldPath,
        'Cannot check isEmpty on type ${value.runtimeType}',
        expected: 'String, List, Map, or null',
        actual: value.runtimeType.toString(),
      );
    }

    if (expectEmpty && !isEmpty) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected empty, got non-empty ${value.runtimeType}',
        expected: 'empty',
        actual: value,
      );
    }

    if (!expectEmpty && isEmpty) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected non-empty, got empty ${value.runtimeType}',
        expected: 'non-empty',
        actual: 'empty',
      );
    }

    return ApiValidationResult.success(
      fieldPath,
      expectEmpty ? 'Value is empty ✓' : 'Value is not empty ✓',
      value: value,
    );
  }

  @override
  String get description => expectEmpty ? 'empty' : 'not empty';

  @override
  String get expectedType => 'String|List|Map';
}

class _AnyTypeChecker extends ApiChecker {
  @override
  Future<ApiValidationResult> validate(String fieldPath, dynamic value) async {
    return ApiValidationResult.success(
      fieldPath,
      'Accepts any type: ${value.runtimeType} ✓',
      value: value,
    );
  }

  @override
  String get description => 'Any type';

  @override
  String get expectedType => 'any';
}

// ═══════════════════════════════════════════════════════════════
// BUILDER CLASSES FOR TYPE-SPECIFIC VALIDATION
// ═══════════════════════════════════════════════════════════════

/// Builder for String validation
class StringCheckerBuilder {
  int? _minLength;
  int? _maxLength;
  int? _exactLength;
  RegExp? _pattern;
  String? _exactValue;
  String? _containsSubstring;
  String _description = 'String';

  StringCheckerBuilder minLength(int min) {
    _minLength = min;
    return this;
  }

  StringCheckerBuilder maxLength(int max) {
    _maxLength = max;
    return this;
  }

  StringCheckerBuilder exactLength(int length) {
    _exactLength = length;
    return this;
  }

  StringCheckerBuilder pattern(String regex) {
    _pattern = RegExp(regex);
    return this;
  }

  StringCheckerBuilder exactValue(String value) {
    _exactValue = value;
    return this;
  }

  StringCheckerBuilder contains(String substring) {
    _containsSubstring = substring;
    return this;
  }

  StringCheckerBuilder describe(String desc) {
    _description = desc;
    return this;
  }

  ApiChecker build() {
    return _TypedStringChecker(
      minLength: _minLength,
      maxLength: _maxLength,
      exactLength: _exactLength,
      pattern: _pattern,
      exactValue: _exactValue,
      containsSubstring: _containsSubstring,
      customDescription: _description,
    );
  }
}

class _TypedStringChecker extends ApiChecker {
  final int? minLength;
  final int? maxLength;
  final int? exactLength;
  final RegExp? pattern;
  final String? exactValue;
  final String? containsSubstring;
  final String customDescription;

  _TypedStringChecker({
    this.minLength,
    this.maxLength,
    this.exactLength,
    this.pattern,
    this.exactValue,
    this.containsSubstring,
    required this.customDescription,
  });

  @override
  String get expectedType => 'String';

  @override
  Future<ApiValidationResult> validate(String fieldPath, dynamic value) async {
    if (value is! String) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected String, got ${value.runtimeType}',
        expected: 'String',
        actual: value.runtimeType.toString(),
      );
    }

    if (exactValue != null && value != exactValue) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected exact value "$exactValue", got "$value"',
        expected: exactValue,
        actual: value,
      );
    }

    if (exactLength != null && value.length != exactLength) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected length $exactLength, got ${value.length}',
        expected: exactLength,
        actual: value.length,
      );
    }

    if (minLength != null && value.length < minLength!) {
      return ApiValidationResult.failure(
        fieldPath,
        'Length ${value.length} < minimum $minLength',
        expected: 'min length: $minLength',
        actual: value.length,
      );
    }

    if (maxLength != null && value.length > maxLength!) {
      return ApiValidationResult.failure(
        fieldPath,
        'Length ${value.length} > maximum $maxLength',
        expected: 'max length: $maxLength',
        actual: value.length,
      );
    }

    if (containsSubstring != null && !value.contains(containsSubstring!)) {
      return ApiValidationResult.failure(
        fieldPath,
        'Does not contain "$containsSubstring"',
        expected: 'contains: $containsSubstring',
        actual: value,
      );
    }

    if (pattern != null && !pattern!.hasMatch(value)) {
      return ApiValidationResult.failure(
        fieldPath,
        'Does not match pattern',
        expected: 'pattern: ${pattern!.pattern}',
        actual: value,
      );
    }

    return ApiValidationResult.success(
      fieldPath,
      'Valid string ✓',
      value: value,
    );
  }

  @override
  String get description => customDescription;
}

/// Builder for Integer validation
class IntCheckerBuilder {
  int? _min;
  int? _max;
  int? _exactValue;
  String _description = 'Integer';

  IntCheckerBuilder min(int value) {
    _min = value;
    return this;
  }

  IntCheckerBuilder max(int value) {
    _max = value;
    return this;
  }

  IntCheckerBuilder exactValue(int value) {
    _exactValue = value;
    return this;
  }

  IntCheckerBuilder describe(String desc) {
    _description = desc;
    return this;
  }

  ApiChecker build() {
    return _TypedIntChecker(
      min: _min,
      max: _max,
      exactValue: _exactValue,
      customDescription: _description,
    );
  }
}

class _TypedIntChecker extends ApiChecker {
  final int? min;
  final int? max;
  final int? exactValue;
  final String customDescription;

  _TypedIntChecker({
    this.min,
    this.max,
    this.exactValue,
    required this.customDescription,
  });

  @override
  String get expectedType => 'int';

  @override
  Future<ApiValidationResult> validate(String fieldPath, dynamic value) async {
    if (value is! int) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected int, got ${value.runtimeType}',
        expected: 'int',
        actual: value.runtimeType.toString(),
      );
    }

    if (exactValue != null && value != exactValue) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected $exactValue, got $value',
        expected: exactValue,
        actual: value,
      );
    }

    if (min != null && value < min!) {
      return ApiValidationResult.failure(
        fieldPath,
        'Value $value < minimum $min',
        expected: 'min: $min',
        actual: value,
      );
    }

    if (max != null && value > max!) {
      return ApiValidationResult.failure(
        fieldPath,
        'Value $value > maximum $max',
        expected: 'max: $max',
        actual: value,
      );
    }

    return ApiValidationResult.success(
      fieldPath,
      'Valid integer ✓',
      value: value,
    );
  }

  @override
  String get description => customDescription;
}

/// Builder for Number (int or double) validation
class NumberCheckerBuilder {
  num? _min;
  num? _max;
  num? _exactValue;
  String _description = 'Number';

  NumberCheckerBuilder min(num value) {
    _min = value;
    return this;
  }

  NumberCheckerBuilder max(num value) {
    _max = value;
    return this;
  }

  NumberCheckerBuilder exactValue(num value) {
    _exactValue = value;
    return this;
  }

  NumberCheckerBuilder describe(String desc) {
    _description = desc;
    return this;
  }

  ApiChecker build() {
    return _TypedNumberChecker(
      min: _min,
      max: _max,
      exactValue: _exactValue,
      customDescription: _description,
    );
  }
}

class _TypedNumberChecker extends ApiChecker {
  final num? min;
  final num? max;
  final num? exactValue;
  final String customDescription;

  _TypedNumberChecker({
    this.min,
    this.max,
    this.exactValue,
    required this.customDescription,
  });

  @override
  String get expectedType => 'num';

  @override
  Future<ApiValidationResult> validate(String fieldPath, dynamic value) async {
    if (value is! num) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected number, got ${value.runtimeType}',
        expected: 'int or double',
        actual: value.runtimeType.toString(),
      );
    }

    if (exactValue != null && value != exactValue) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected $exactValue, got $value',
        expected: exactValue,
        actual: value,
      );
    }

    if (min != null && value < min!) {
      return ApiValidationResult.failure(
        fieldPath,
        'Value $value < minimum $min',
        expected: 'min: $min',
        actual: value,
      );
    }

    if (max != null && value > max!) {
      return ApiValidationResult.failure(
        fieldPath,
        'Value $value > maximum $max',
        expected: 'max: $max',
        actual: value,
      );
    }

    return ApiValidationResult.success(
      fieldPath,
      'Valid number ✓',
      value: value,
    );
  }

  @override
  String get description => customDescription;
}

/// Builder for Boolean validation
class BoolCheckerBuilder {
  bool? _exactValue;
  String _description = 'Boolean';

  BoolCheckerBuilder exactValue(bool value) {
    _exactValue = value;
    return this;
  }

  BoolCheckerBuilder describe(String desc) {
    _description = desc;
    return this;
  }

  ApiChecker build() {
    return _TypedBoolChecker(
      exactValue: _exactValue,
      customDescription: _description,
    );
  }
}

class _TypedBoolChecker extends ApiChecker {
  final bool? exactValue;
  final String customDescription;

  _TypedBoolChecker({this.exactValue, required this.customDescription});

  @override
  String get expectedType => 'bool';

  @override
  Future<ApiValidationResult> validate(String fieldPath, dynamic value) async {
    if (value is! bool) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected bool, got ${value.runtimeType}',
        expected: 'bool',
        actual: value.runtimeType.toString(),
      );
    }

    if (exactValue != null && value != exactValue) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected $exactValue, got $value',
        expected: exactValue,
        actual: value,
      );
    }

    return ApiValidationResult.success(
      fieldPath,
      'Valid boolean ✓',
      value: value,
    );
  }

  @override
  String get description => customDescription;
}

/// Builder for List validation
class ListCheckerBuilder {
  ApiChecker? _itemChecker;
  int? _minLength;
  int? _maxLength;
  int? _exactLength;
  String _description = 'List';

  ListCheckerBuilder items(ApiChecker checker) {
    _itemChecker = checker;
    return this;
  }

  ListCheckerBuilder minLength(int min) {
    _minLength = min;
    return this;
  }

  ListCheckerBuilder maxLength(int max) {
    _maxLength = max;
    return this;
  }

  ListCheckerBuilder exactLength(int length) {
    _exactLength = length;
    return this;
  }

  ListCheckerBuilder describe(String desc) {
    _description = desc;
    return this;
  }

  ApiChecker build() {
    return _TypedListChecker(
      itemChecker: _itemChecker,
      minLength: _minLength,
      maxLength: _maxLength,
      exactLength: _exactLength,
      customDescription: _description,
    );
  }
}

class _TypedListChecker extends ApiChecker {
  final ApiChecker? itemChecker;
  final int? minLength;
  final int? maxLength;
  final int? exactLength;
  final String customDescription;

  _TypedListChecker({
    this.itemChecker,
    this.minLength,
    this.maxLength,
    this.exactLength,
    required this.customDescription,
  });

  @override
  String get expectedType => 'List';

  @override
  Future<ApiValidationResult> validate(String fieldPath, dynamic value) async {
    if (value is! List) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected List, got ${value.runtimeType}',
        expected: 'List',
        actual: value.runtimeType.toString(),
      );
    }

    if (exactLength != null && value.length != exactLength) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected length $exactLength, got ${value.length}',
        expected: exactLength,
        actual: value.length,
      );
    }

    if (minLength != null && value.length < minLength!) {
      return ApiValidationResult.failure(
        fieldPath,
        'Length ${value.length} < minimum $minLength',
        expected: 'min length: $minLength',
        actual: value.length,
      );
    }

    if (maxLength != null && value.length > maxLength!) {
      return ApiValidationResult.failure(
        fieldPath,
        'Length ${value.length} > maximum $maxLength',
        expected: 'max length: $maxLength',
        actual: value.length,
      );
    }

    if (itemChecker != null) {
      for (int i = 0; i < value.length; i++) {
        final itemResult = await itemChecker!.validate(
          '$fieldPath[$i]',
          value[i],
        );
        if (!itemResult.isSuccess) {
          return itemResult;
        }
      }
    }

    return ApiValidationResult.success(
      fieldPath,
      'Valid list (${value.length} items) ✓',
      value: value,
    );
  }

  @override
  String get description => customDescription;
}

/// Builder for Object/Map validation
class ObjectCheckerBuilder {
  final Map<String, ApiChecker> _fields = {};
  bool _allowExtraFields = true;
  String _description = 'Object';

  ObjectCheckerBuilder field(String name, ApiChecker checker) {
    _fields[name] = checker;
    return this;
  }

  ObjectCheckerBuilder fields(Map<String, ApiChecker> fields) {
    _fields.addAll(fields);
    return this;
  }

  ObjectCheckerBuilder strictFields() {
    _allowExtraFields = false;
    return this;
  }

  ObjectCheckerBuilder describe(String desc) {
    _description = desc;
    return this;
  }

  ApiChecker build() {
    return _TypedObjectChecker(
      fieldCheckers: _fields,
      allowExtraFields: _allowExtraFields,
      customDescription: _description,
    );
  }
}

class _TypedObjectChecker extends ApiChecker {
  final Map<String, ApiChecker> fieldCheckers;
  final bool allowExtraFields;
  final String customDescription;

  _TypedObjectChecker({
    required this.fieldCheckers,
    required this.allowExtraFields,
    required this.customDescription,
  });

  @override
  String get expectedType => 'Map/Object';

  @override
  Future<ApiValidationResult> validate(String fieldPath, dynamic value) async {
    if (value is! Map) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected Map/Object, got ${value.runtimeType}',
        expected: 'Map/Object',
        actual: value.runtimeType.toString(),
      );
    }

    for (final entry in fieldCheckers.entries) {
      final fieldName = entry.key;
      final checker = entry.value;
      final fieldValue = value[fieldName];

      if (fieldValue == null) {
        return ApiValidationResult.failure(
          '$fieldPath.$fieldName',
          'Required field is missing',
          expected: 'field present',
          actual: 'null',
        );
      }

      final result = await checker.validate(
        '$fieldPath.$fieldName',
        fieldValue,
      );
      if (!result.isSuccess) {
        return result;
      }
    }

    if (!allowExtraFields) {
      for (final key in value.keys) {
        if (!fieldCheckers.containsKey(key)) {
          return ApiValidationResult.failure(
            '$fieldPath.$key',
            'Unexpected field found',
            expected: 'field not present',
            actual: key,
          );
        }
      }
    }

    return ApiValidationResult.success(
      fieldPath,
      'Valid object ✓',
      value: value,
    );
  }

  @override
  String get description => customDescription;
}
