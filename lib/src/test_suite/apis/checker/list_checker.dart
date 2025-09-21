import '../apis_checker.dart';
import '../model/api_validation_result.dart';

/// List type checker
class ListChecker extends ApiChecker {
  final ApiChecker? itemChecker;
  final int? minLength;
  final int? maxLength;
  final int? exactLength;

  ListChecker({
    this.itemChecker,
    this.minLength,
    this.maxLength,
    this.exactLength,
  });

  @override
  Future<ApiValidationResult> validate(String fieldPath, dynamic value) async {
    if (value is! List) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected list, got ${value.runtimeType}',
        expected: 'List',
        actual: value.runtimeType.toString(),
      );
    }

    if (exactLength != null && value.length != exactLength) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected exact length $exactLength, got ${value.length}',
        expected: exactLength,
        actual: value.length,
      );
    }

    if (minLength != null && value.length < minLength!) {
      return ApiValidationResult.failure(
        fieldPath,
        'List length ${value.length} is less than minimum $minLength',
        expected: 'min length: $minLength',
        actual: value.length,
      );
    }

    if (maxLength != null && value.length > maxLength!) {
      return ApiValidationResult.failure(
        fieldPath,
        'List length ${value.length} is greater than maximum $maxLength',
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
      'Valid list with ${value.length} items',
      value: value,
    );
  }

  @override
  String get description =>
      'List${exactLength != null ? ' (exact: $exactLength)' : ''}${minLength != null ? ' (min: $minLength)' : ''}${maxLength != null ? ' (max: $maxLength)' : ''}';
}
