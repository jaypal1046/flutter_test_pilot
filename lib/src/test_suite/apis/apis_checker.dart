import 'model/api_validation_result.dart';

/// Base class for API validation checkers
abstract class ApiChecker {
  Future<ApiValidationResult> validate(String fieldPath, dynamic value);
  String get description;
}
