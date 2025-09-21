import '../apis_checker.dart';
import '../model/api_validation_result.dart';

/// Integer type checker with optional min/max validation
class IntChecker extends ApiChecker {
  final int? min;
  final int? max;
  final int? exactValue;

  IntChecker({this.min, this.max, this.exactValue});

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

    if (exactValue != null) {
      if (value != exactValue) {
        return ApiValidationResult.failure(
          fieldPath,
          'Expected exact value $exactValue, got $value',
          expected: exactValue,
          actual: value,
        );
      }
      return ApiValidationResult.success(
        fieldPath,
        'Exact value match: $value',
        value: value,
      );
    }

    if (min != null && value < min!) {
      return ApiValidationResult.failure(
        fieldPath,
        'Value $value is less than minimum $min',
        expected: 'min: $min',
        actual: value,
      );
    }

    if (max != null && value > max!) {
      return ApiValidationResult.failure(
        fieldPath,
        'Value $value is greater than maximum $max',
        expected: 'max: $max',
        actual: value,
      );
    }

    return ApiValidationResult.success(
      fieldPath,
      'Valid integer: $value',
      value: value,
    );
  }

  @override
  String get description => exactValue != null
      ? 'Integer (exact: $exactValue)'
      : 'Integer${min != null ? ' (min: $min)' : ''}${max != null ? ' (max: $max)' : ''}';
}
