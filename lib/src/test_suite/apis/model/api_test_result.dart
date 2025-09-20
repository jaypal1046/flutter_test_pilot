import 'api_call_data.dart';
import 'api_validation_result.dart';

/// Result of API test execution
class ApiTestResult {
  final String apiId;
  final ApiCallData apiCall;
  final List<ApiValidationResult> validationResults;
  final bool isSuccess;
  final DateTime timestamp;

  ApiTestResult({
    required this.apiId,
    required this.apiCall,
    required this.validationResults,
    required this.timestamp,
  }) : isSuccess = validationResults.every((result) => result.isSuccess);

  int get passedValidations =>
      validationResults.where((r) => r.isSuccess).length;
  int get failedValidations =>
      validationResults.where((r) => !r.isSuccess).length;
  int get totalValidations => validationResults.length;

  List<ApiValidationResult> get failures =>
      validationResults.where((r) => !r.isSuccess).toList();

  /// Convert to map for sending to test site
  Map<String, dynamic> toJson() {
    return {
      'apiId': apiId,
      'isSuccess': isSuccess,
      'timestamp': timestamp.toIso8601String(),
      'apiCall': {
        'method': apiCall.method,
        'url': apiCall.url,
        'statusCode': apiCall.statusCode,
        'duration': apiCall.duration.inMilliseconds,
        'requestBody': apiCall.requestBody,
        'responseBody': apiCall.responseBody,
        'headers': apiCall.headers,
        'responseHeaders': apiCall.responseHeaders,
        'errorMessage': apiCall.errorMessage,
      },
      'validations': {
        'total': totalValidations,
        'passed': passedValidations,
        'failed': failedValidations,
        'results': validationResults
            .map(
              (r) => {
                'fieldPath': r.fieldPath,
                'isSuccess': r.isSuccess,
                'message': r.message,
                'expectedValue': r.expectedValue,
                'actualValue': r.actualValue,
              },
            )
            .toList(),
      },
    };
  }
}
