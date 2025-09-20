/// Validation result for API tests
class ApiValidationResult {
  final bool isSuccess;
  final String message;
  final String fieldPath;
  final dynamic expectedValue;
  final dynamic actualValue;

  ApiValidationResult({
    required this.isSuccess,
    required this.message,
    required this.fieldPath,
    this.expectedValue,
    this.actualValue,
  });

  factory ApiValidationResult.success(
    String fieldPath,
    String message, {
    dynamic value,
  }) {
    return ApiValidationResult(
      isSuccess: true,
      message: message,
      fieldPath: fieldPath,
      actualValue: value,
    );
  }

  factory ApiValidationResult.failure(
    String fieldPath,
    String message, {
    dynamic expected,
    dynamic actual,
  }) {
    return ApiValidationResult(
      isSuccess: false,
      message: message,
      fieldPath: fieldPath,
      expectedValue: expected,
      actualValue: actual,
    );
  }
}
