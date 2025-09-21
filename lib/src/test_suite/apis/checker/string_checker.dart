import '../apis_checker.dart';
import '../model/api_validation_result.dart';

/// String type checker with optional length and pattern validation
class StringChecker extends ApiChecker {
  final int? minLength;
  final int? maxLength;
  final RegExp? pattern;
  final String? exactValue;

  StringChecker({
    this.minLength,
    this.maxLength,
    this.pattern,
    this.exactValue,
  });

  @override
  Future<ApiValidationResult> validate(String fieldPath, dynamic value) async {
    if (value is! String) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected string, got ${value.runtimeType}',
        expected: 'String',
        actual: value.runtimeType.toString(),
      );
    }

    if (exactValue != null) {
      if (value != exactValue) {
        return ApiValidationResult.failure(
          fieldPath,
          'Expected exact value "$exactValue", got "$value"',
          expected: exactValue,
          actual: value,
        );
      }
      return ApiValidationResult.success(
        fieldPath,
        'Exact value match: "$value"',
        value: value,
      );
    }

    if (minLength != null && value.length < minLength!) {
      return ApiValidationResult.failure(
        fieldPath,
        'String length ${value.length} is less than minimum $minLength',
        expected: 'min length: $minLength',
        actual: value.length,
      );
    }

    if (maxLength != null && value.length > maxLength!) {
      return ApiValidationResult.failure(
        fieldPath,
        'String length ${value.length} is greater than maximum $maxLength',
        expected: 'max length: $maxLength',
        actual: value.length,
      );
    }

    if (pattern != null && !pattern!.hasMatch(value)) {
      return ApiValidationResult.failure(
        fieldPath,
        'String does not match required pattern: "$value"',
        expected: 'pattern: ${pattern!.pattern}',
        actual: value,
      );
    }

    return ApiValidationResult.success(
      fieldPath,
      'Valid string: "$value"',
      value: value,
    );
  }

  @override
  String get description => exactValue != null
      ? 'String (exact: "$exactValue")'
      : 'String${minLength != null ? ' (min: $minLength)' : ''}${maxLength != null ? ' (max: $maxLength)' : ''}';
}
