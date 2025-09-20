/// Validation result for API tests
class ApiValidationResult {
  final bool isSuccess;
  final String message;
  final String fieldPath;

  ApiValidationResult({
    required this.isSuccess,
    required this.message,
    required this.fieldPath,
  });

  factory ApiValidationResult.success(String fieldPath, String message) {
    return ApiValidationResult(
      isSuccess: true,
      message: message,
      fieldPath: fieldPath,
    );
  }

  factory ApiValidationResult.failure(String fieldPath, String message) {
    return ApiValidationResult(
      isSuccess: false,
      message: message,
      fieldPath: fieldPath,
    );
  }
}