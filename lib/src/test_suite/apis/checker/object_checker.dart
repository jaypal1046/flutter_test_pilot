import '../apis_checker.dart';
import '../model/api_validation_result.dart';

/// Object type checker
class ObjectChecker extends ApiChecker {
  final Map<String, ApiChecker> fieldCheckers;
  final bool allowExtraFields;

  ObjectChecker(this.fieldCheckers, {this.allowExtraFields = true});

  @override
  Future<ApiValidationResult> validate(String fieldPath, dynamic value) async {
    if (value is! Map) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected object, got ${value.runtimeType}',
        expected: 'Map/Object',
        actual: value.runtimeType.toString(),
      );
    }

    // Check required fields
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

    // Check for unexpected fields if not allowed
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

    return ApiValidationResult.success(fieldPath, 'Valid object', value: value);
  }

  @override
  String get description =>
      'Object with ${fieldCheckers.length} required fields';
}
