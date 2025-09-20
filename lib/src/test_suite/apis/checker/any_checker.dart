import '../api_checker.dart';
import '../model/api_validation_result.dart';

/// Flexible checker that accepts any type
class AnyChecker extends ApiChecker {
  @override
  Future<ApiValidationResult> validate(String fieldPath, dynamic value) async {
    return ApiValidationResult.success(
      fieldPath,
      'Accepts any type: ${value.runtimeType}',
      value: value,
    );
  }

  @override
  String get description => 'Any type';
}
