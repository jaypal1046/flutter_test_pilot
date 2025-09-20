import '../api_checker.dart';
import '../model/api_validation_result.dart';

/// Boolean checker
class BoolChecker extends ApiChecker {
  final bool? exactValue;

  BoolChecker({this.exactValue});

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
      'Valid boolean: $value',
      value: value,
    );
  }

  @override
  String get description =>
      exactValue != null ? 'Boolean (exact: $exactValue)' : 'Boolean';
}
