// api_observer.dart - Enhanced API Testing Framework
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import '../step_result.dart';
import '../test_action.dart';
import 'apis_observer_manager.dart';
import 'model/api_call_data.dart';

import 'model/api_validation_result.dart';
import 'request_resonse_check.dart';

/// API Test Scenario Type - User can specify what they want to test
enum ApiScenario {
  /// Test for successful API response (2xx status codes)
  success,

  /// Test for API failure/error response (4xx, 5xx status codes)
  failure,

  /// Test for any response (don't validate success/failure)
  any,
}

/// API Test Mode - Controls how validation failures are handled
enum ApiTestMode {
  /// Test must pass all validations (strict mode)
  strict,

  /// Test passes if at least one validation passes (lenient mode)
  lenient,

  /// Test always reports results but doesn't fail (monitoring mode)
  monitor,
}

/// Retry strategy for API tests
class ApiRetryStrategy {
  final int maxRetries;
  final Duration retryDelay;
  final bool retryOnFailure;
  final List<int> retryableStatusCodes;

  const ApiRetryStrategy({
    this.maxRetries = 0,
    this.retryDelay = const Duration(seconds: 1),
    this.retryOnFailure = false,
    this.retryableStatusCodes = const [500, 502, 503, 504],
  });

  bool shouldRetry(int? statusCode, int currentAttempt) {
    if (currentAttempt >= maxRetries) return false;
    if (statusCode == null) return retryOnFailure;
    return retryableStatusCodes.contains(statusCode);
  }
}

/// Response time validation
class ResponseTimeConstraint {
  final Duration? maxDuration;
  final Duration? minDuration;
  final Duration? expectedDuration;
  final Duration? tolerance;

  const ResponseTimeConstraint({
    this.maxDuration,
    this.minDuration,
    this.expectedDuration,
    this.tolerance,
  });

  bool validate(Duration actual) {
    if (maxDuration != null && actual > maxDuration!) return false;
    if (minDuration != null && actual < minDuration!) return false;

    if (expectedDuration != null) {
      final tolerance = this.tolerance ?? Duration(milliseconds: 100);
      final diff = (actual - expectedDuration!).abs();
      return diff <= tolerance;
    }

    return true;
  }

  String get description {
    if (expectedDuration != null) {
      return 'Expected ${expectedDuration!.inMilliseconds}ms ±${(tolerance ?? Duration(milliseconds: 100)).inMilliseconds}ms';
    }
    if (maxDuration != null && minDuration != null) {
      return 'Between ${minDuration!.inMilliseconds}ms and ${maxDuration!.inMilliseconds}ms';
    }
    if (maxDuration != null) {
      return 'Max ${maxDuration!.inMilliseconds}ms';
    }
    if (minDuration != null) {
      return 'Min ${minDuration!.inMilliseconds}ms';
    }
    return 'No constraint';
  }
}

/// Enhanced API Test Action with powerful features
abstract class ApiTestAction extends TestAction {
  final String apiId;
  final String? method;
  final String? urlPattern;
  final int? expectedStatusCode;
  final List<int>? acceptableStatusCodes;

  // Scenario validation
  final ApiScenario scenario;
  final ApiTestMode mode;

  // Validation rules
  final List<RequestCheck>? requestChecks;
  final List<ResponseCheck>? responseChecks;

  final Map<String, dynamic>? exactRequestBody;
  final Map<String, dynamic>? exactResponseBody;

  // Header validation
  final Map<String, String>? expectedHeaders;
  final Map<String, String>? expectedResponseHeaders;
  final List<String>? requiredResponseHeaders;

  // Performance validation
  final ResponseTimeConstraint? responseTimeConstraint;
  final Duration? timeout;

  // Retry configuration
  final ApiRetryStrategy? retryStrategy;

  // Custom validation hooks
  final Future<ApiValidationResult> Function(ApiCallData)? customValidator;
  final Future<void> Function(ApiCallData)? onSuccess;
  final Future<void> Function(ApiCallData, List<ApiValidationResult>)?
  onFailure;

  // Conditional execution
  final bool Function()? shouldExecute;
  final String? testDescription;
  final Map<String, dynamic>? metadata;

  const ApiTestAction({
    required this.apiId,
    this.method,
    this.urlPattern,
    this.expectedStatusCode,
    this.acceptableStatusCodes,
    this.requestChecks,
    this.responseChecks,
    this.exactRequestBody,
    this.exactResponseBody,
    this.expectedHeaders,
    this.expectedResponseHeaders,
    this.requiredResponseHeaders,
    this.responseTimeConstraint,
    this.timeout,
    this.retryStrategy,
    this.customValidator,
    this.onSuccess,
    this.onFailure,
    this.shouldExecute,
    this.testDescription,
    this.metadata,
    this.scenario = ApiScenario.success,
    this.mode = ApiTestMode.strict,
  });

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    // Check if test should execute
    if (shouldExecute != null && !shouldExecute!()) {
      return StepResult.success(
        message: 'API test skipped (condition not met): $apiId',
        duration: Duration.zero,
      );
    }

    ApiObserverManager.instance.registerApiTest(this);
    return StepResult.success(
      message: testDescription != null 
          ? 'API test registered: $apiId - $testDescription'
          : 'API test registered: $apiId',
      duration: Duration.zero,
    );
  }

  bool matches(ApiCallData apiCall) {
    if (method != null &&
        apiCall.method.toUpperCase() != method!.toUpperCase()) {
      return false;
    }

    if (urlPattern != null && !RegExp(urlPattern!).hasMatch(apiCall.url)) {
      return false;
    }

    return true;
  }

  Future<List<ApiValidationResult>> validateApiCall(ApiCallData apiCall) async {
    final results = <ApiValidationResult>[];

    try {
      // 1. Validate scenario (success/failure/any)
      results.addAll(_validateScenario(apiCall));

      // 2. Validate status code
      results.addAll(_validateStatusCode(apiCall));

      // 3. Validate response time
      if (responseTimeConstraint != null) {
        results.add(_validateResponseTime(apiCall));
      }

      // 4. Validate request headers
      if (expectedHeaders != null) {
        results.addAll(_validateRequestHeaders(apiCall));
      }

      // 5. Validate response headers
      if (expectedResponseHeaders != null || requiredResponseHeaders != null) {
        results.addAll(_validateResponseHeaders(apiCall));
      }

      // 6. Validate exact request body if specified
      if (exactRequestBody != null && apiCall.requestBody != null) {
        results.add(_validateExactRequestBody(apiCall));
      }

      // 7. Validate exact response body if specified
      if (exactResponseBody != null && apiCall.responseBody != null) {
        results.add(_validateExactResponseBody(apiCall));
      }

      // 8. Validate specific request fields
      if (requestChecks != null && apiCall.requestBody != null) {
        results.addAll(await _validateRequestFields(apiCall));
      }

      // 9. Validate specific response fields
      if (responseChecks != null && apiCall.responseBody != null) {
        results.addAll(await _validateResponseFields(apiCall));
      }

      // 10. Run custom validator if provided
      if (customValidator != null) {
        final customResult = await customValidator!(apiCall);
        results.add(customResult);
      }

      // 11. Call success/failure hooks
      final hasFailures = results.any((r) => !r.isSuccess);

      if (!hasFailures && onSuccess != null) {
        await onSuccess!(apiCall);
      } else if (hasFailures && onFailure != null) {
        await onFailure!(apiCall, results);
      }
    } catch (e, stackTrace) {
      results.add(
        ApiValidationResult.failure(
          'validation_error',
          'Validation threw exception: $e',
          expected: 'successful validation',
          actual: e.toString(),
        ),
      );
      print('⚠️ API validation error: $e\n$stackTrace');
    }

    return results;
  }

  /// Validate the API scenario (success/failure)
  List<ApiValidationResult> _validateScenario(ApiCallData apiCall) {
    final results = <ApiValidationResult>[];
    final statusCode = apiCall.statusCode ?? 0;

    switch (scenario) {
      case ApiScenario.success:
        if (statusCode >= 200 && statusCode < 300) {
          results.add(
            ApiValidationResult.success(
              'scenario',
              '✅ API Success: Status $statusCode (Expected: Success scenario)',
              value: statusCode,
            ),
          );
        } else {
          results.add(
            ApiValidationResult.failure(
              'scenario',
              '❌ API Failed: Expected success (2xx) but got $statusCode',
              expected: 'Success (200-299)',
              actual: statusCode,
            ),
          );
        }
        break;

      case ApiScenario.failure:
        if (statusCode >= 400) {
          results.add(
            ApiValidationResult.success(
              'scenario',
              '✅ API Failure Validated: Status $statusCode (Expected: Failure scenario)',
              value: statusCode,
            ),
          );
        } else {
          results.add(
            ApiValidationResult.failure(
              'scenario',
              '❌ Expected API failure (4xx/5xx) but got $statusCode',
              expected: 'Failure (400+)',
              actual: statusCode,
            ),
          );
        }
        break;

      case ApiScenario.any:
        results.add(
          ApiValidationResult.success(
            'scenario',
            'ℹ️ API Response: Status $statusCode (Testing any scenario)',
            value: statusCode,
          ),
        );
        break;
    }

    return results;
  }

  /// Validate status code
  List<ApiValidationResult> _validateStatusCode(ApiCallData apiCall) {
    final results = <ApiValidationResult>[];

    if (expectedStatusCode != null) {
      if (apiCall.statusCode == expectedStatusCode) {
        results.add(
          ApiValidationResult.success(
            'statusCode',
            'Status code matches expected: ${apiCall.statusCode}',
            value: apiCall.statusCode,
          ),
        );
      } else {
        results.add(
          ApiValidationResult.failure(
            'statusCode',
            'Expected status code $expectedStatusCode, got ${apiCall.statusCode}',
            expected: expectedStatusCode,
            actual: apiCall.statusCode,
          ),
        );
      }
    }

    if (acceptableStatusCodes != null && acceptableStatusCodes!.isNotEmpty) {
      if (acceptableStatusCodes!.contains(apiCall.statusCode)) {
        results.add(
          ApiValidationResult.success(
            'statusCode.acceptable',
            'Status code ${apiCall.statusCode} is in acceptable list',
            value: apiCall.statusCode,
          ),
        );
      } else {
        results.add(
          ApiValidationResult.failure(
            'statusCode.acceptable',
            'Status code ${apiCall.statusCode} not in acceptable codes: $acceptableStatusCodes',
            expected: acceptableStatusCodes,
            actual: apiCall.statusCode,
          ),
        );
      }
    }

    return results;
  }

  /// Validate response time
  ApiValidationResult _validateResponseTime(ApiCallData apiCall) {
    final isValid = responseTimeConstraint!.validate(apiCall.duration);

    if (isValid) {
      return ApiValidationResult.success(
        'responseTime',
        'Response time ${apiCall.duration.inMilliseconds}ms is within constraint: ${responseTimeConstraint!.description}',
        value: apiCall.duration.inMilliseconds,
      );
    } else {
      return ApiValidationResult.failure(
        'responseTime',
        'Response time ${apiCall.duration.inMilliseconds}ms violates constraint',
        expected: responseTimeConstraint!.description,
        actual: '${apiCall.duration.inMilliseconds}ms',
      );
    }
  }

  /// Validate request headers
  List<ApiValidationResult> _validateRequestHeaders(ApiCallData apiCall) {
    final results = <ApiValidationResult>[];

    for (final entry in expectedHeaders!.entries) {
      final actualValue = apiCall.headers?[entry.key];
      if (actualValue == entry.value) {
        results.add(
          ApiValidationResult.success(
            'request.header.${entry.key}',
            'Header "${entry.key}" matches expected value',
            value: actualValue,
          ),
        );
      } else {
        results.add(
          ApiValidationResult.failure(
            'request.header.${entry.key}',
            'Header "${entry.key}" does not match',
            expected: entry.value,
            actual: actualValue,
          ),
        );
      }
    }

    return results;
  }

  /// Validate response headers
  List<ApiValidationResult> _validateResponseHeaders(ApiCallData apiCall) {
    final results = <ApiValidationResult>[];

    // Check expected response headers
    if (expectedResponseHeaders != null) {
      for (final entry in expectedResponseHeaders!.entries) {
        final actualValue = apiCall.responseHeaders?[entry.key];
        if (actualValue == entry.value) {
          results.add(
            ApiValidationResult.success(
              'response.header.${entry.key}',
              'Response header "${entry.key}" matches expected value',
              value: actualValue,
            ),
          );
        } else {
          results.add(
            ApiValidationResult.failure(
              'response.header.${entry.key}',
              'Response header "${entry.key}" does not match',
              expected: entry.value,
              actual: actualValue,
            ),
          );
        }
      }
    }

    // Check required response headers
    if (requiredResponseHeaders != null) {
      for (final headerName in requiredResponseHeaders!) {
        final hasHeader =
            apiCall.responseHeaders?.containsKey(headerName) ?? false;
        if (hasHeader) {
          results.add(
            ApiValidationResult.success(
              'response.header.required.$headerName',
              'Required response header "$headerName" is present',
              value: apiCall.responseHeaders![headerName],
            ),
          );
        } else {
          results.add(
            ApiValidationResult.failure(
              'response.header.required.$headerName',
              'Required response header "$headerName" is missing',
              expected: 'header present',
              actual: 'header missing',
            ),
          );
        }
      }
    }

    return results;
  }

  /// Validate exact request body
  ApiValidationResult _validateExactRequestBody(ApiCallData apiCall) {
    final requestBody = _parseJsonSafely(apiCall.requestBody);
    if (_deepEquals(requestBody, exactRequestBody)) {
      return ApiValidationResult.success(
        'request.body.exact',
        'Request body matches exactly',
        value: requestBody,
      );
    } else {
      return ApiValidationResult.failure(
        'request.body.exact',
        'Request body does not match expected',
        expected: exactRequestBody,
        actual: requestBody,
      );
    }
  }

  /// Validate exact response body
  ApiValidationResult _validateExactResponseBody(ApiCallData apiCall) {
    final responseBody = _parseJsonSafely(apiCall.responseBody);
    if (_deepEquals(responseBody, exactResponseBody)) {
      return ApiValidationResult.success(
        'response.body.exact',
        'Response body matches exactly',
        value: responseBody,
      );
    } else {
      return ApiValidationResult.failure(
        'response.body.exact',
        'Response body does not match expected',
        expected: exactResponseBody,
        actual: responseBody,
      );
    }
  }

  /// Validate request fields
  Future<List<ApiValidationResult>> _validateRequestFields(
    ApiCallData apiCall,
  ) async {
    final results = <ApiValidationResult>[];
    final requestBody = _parseJsonSafely(apiCall.requestBody);

    for (final check in requestChecks!) {
      final value = JsonPathNavigator.getValue(requestBody, check.path);
      final result = await check.checker.validate(
        'request.${check.path}',
        value,
      );
      results.add(result);
    }

    return results;
  }

  /// Validate response fields
  Future<List<ApiValidationResult>> _validateResponseFields(
    ApiCallData apiCall,
  ) async {
    final results = <ApiValidationResult>[];
    final responseBody = _parseJsonSafely(apiCall.responseBody);

    for (final check in responseChecks!) {
      final value = JsonPathNavigator.getValue(responseBody, check.path);
      final result = await check.checker.validate(
        'response.${check.path}',
        value,
      );
      results.add(result);
    }

    return results;
  }

  dynamic _parseJsonSafely(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (e) {
        return data;
      }
    }
    return data;
  }

  bool _deepEquals(dynamic a, dynamic b) {
    if (a.runtimeType != b.runtimeType) return false;

    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) {
          return false;
        }
      }
      return true;
    }

    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }

    return a == b;
  }

  @override
  String get description => testDescription ?? 'API test: $apiId';
}

/// Concrete implementation of ApiTestAction with all enhanced features
class ApiTest extends ApiTestAction {
  const ApiTest({
    required super.apiId,
    super.method,
    super.urlPattern,
    super.expectedStatusCode,
    super.acceptableStatusCodes,
    super.requestChecks,
    super.responseChecks,
    super.exactRequestBody,
    super.exactResponseBody,
    super.expectedHeaders,
    super.expectedResponseHeaders,
    super.requiredResponseHeaders,
    super.responseTimeConstraint,
    super.timeout,
    super.retryStrategy,
    super.customValidator,
    super.onSuccess,
    super.onFailure,
    super.shouldExecute,
    super.testDescription,
    super.metadata,
    super.scenario,
    super.mode,
  });
}

/// Advanced API Test Builder for complex scenarios
class ApiTestBuilder {
  String? _apiId;
  String? _method;
  String? _urlPattern;
  int? _expectedStatusCode;
  List<int>? _acceptableStatusCodes;
  List<RequestCheck>? _requestChecks;
  List<ResponseCheck>? _responseChecks;
  Map<String, dynamic>? _exactRequestBody;
  Map<String, dynamic>? _exactResponseBody;
  Map<String, String>? _expectedHeaders;
  Map<String, String>? _expectedResponseHeaders;
  List<String>? _requiredResponseHeaders;
  ResponseTimeConstraint? _responseTimeConstraint;
  Duration? _timeout;
  ApiRetryStrategy? _retryStrategy;
  Future<ApiValidationResult> Function(ApiCallData)? _customValidator;
  Future<void> Function(ApiCallData)? _onSuccess;
  Future<void> Function(ApiCallData, List<ApiValidationResult>)? _onFailure;
  bool Function()? _shouldExecute;
  String? _description;
  Map<String, dynamic>? _metadata;
  ApiScenario _scenario = ApiScenario.success;
  ApiTestMode _mode = ApiTestMode.strict;

  ApiTestBuilder id(String id) {
    _apiId = id;
    return this;
  }

  ApiTestBuilder get(String urlPattern) {
    _method = 'GET';
    _urlPattern = urlPattern;
    return this;
  }

  ApiTestBuilder post(String urlPattern) {
    _method = 'POST';
    _urlPattern = urlPattern;
    return this;
  }

  ApiTestBuilder put(String urlPattern) {
    _method = 'PUT';
    _urlPattern = urlPattern;
    return this;
  }

  ApiTestBuilder delete(String urlPattern) {
    _method = 'DELETE';
    _urlPattern = urlPattern;
    return this;
  }

  ApiTestBuilder patch(String urlPattern) {
    _method = 'PATCH';
    _urlPattern = urlPattern;
    return this;
  }

  ApiTestBuilder expectStatus(int statusCode) {
    _expectedStatusCode = statusCode;
    return this;
  }

  ApiTestBuilder acceptStatuses(List<int> statusCodes) {
    _acceptableStatusCodes = statusCodes;
    return this;
  }

  ApiTestBuilder validateRequest(List<RequestCheck> checks) {
    _requestChecks = checks;
    return this;
  }

  ApiTestBuilder validateResponse(List<ResponseCheck> checks) {
    _responseChecks = checks;
    return this;
  }

  ApiTestBuilder expectExactRequest(Map<String, dynamic> body) {
    _exactRequestBody = body;
    return this;
  }

  ApiTestBuilder expectExactResponse(Map<String, dynamic> body) {
    _exactResponseBody = body;
    return this;
  }

  ApiTestBuilder withRequestHeaders(Map<String, String> headers) {
    _expectedHeaders = headers;
    return this;
  }

  ApiTestBuilder expectResponseHeaders(Map<String, String> headers) {
    _expectedResponseHeaders = headers;
    return this;
  }

  ApiTestBuilder requireHeaders(List<String> headerNames) {
    _requiredResponseHeaders = headerNames;
    return this;
  }

  ApiTestBuilder maxResponseTime(Duration duration) {
    _responseTimeConstraint = ResponseTimeConstraint(maxDuration: duration);
    return this;
  }

  ApiTestBuilder responseTimeBetween(Duration min, Duration max) {
    _responseTimeConstraint = ResponseTimeConstraint(
      minDuration: min,
      maxDuration: max,
    );
    return this;
  }

  ApiTestBuilder expectResponseTime(Duration duration, {Duration? tolerance}) {
    _responseTimeConstraint = ResponseTimeConstraint(
      expectedDuration: duration,
      tolerance: tolerance,
    );
    return this;
  }

  ApiTestBuilder withTimeout(Duration timeout) {
    _timeout = timeout;
    return this;
  }

  ApiTestBuilder withRetry({
    int maxRetries = 3,
    Duration? retryDelay,
    List<int>? retryableStatusCodes,
  }) {
    _retryStrategy = ApiRetryStrategy(
      maxRetries: maxRetries,
      retryDelay: retryDelay ?? const Duration(seconds: 1),
      retryableStatusCodes: retryableStatusCodes ?? [500, 502, 503, 504],
    );
    return this;
  }

  ApiTestBuilder customValidation(
    Future<ApiValidationResult> Function(ApiCallData) validator,
  ) {
    _customValidator = validator;
    return this;
  }

  ApiTestBuilder onSuccessCallback(
    Future<void> Function(ApiCallData) callback,
  ) {
    _onSuccess = callback;
    return this;
  }

  ApiTestBuilder onFailureCallback(
    Future<void> Function(ApiCallData, List<ApiValidationResult>) callback,
  ) {
    _onFailure = callback;
    return this;
  }

  ApiTestBuilder executeIf(bool Function() condition) {
    _shouldExecute = condition;
    return this;
  }

  ApiTestBuilder describe(String description) {
    _description = description;
    return this;
  }

  ApiTestBuilder addMetadata(Map<String, dynamic> metadata) {
    _metadata = metadata;
    return this;
  }

  ApiTestBuilder expectSuccess() {
    _scenario = ApiScenario.success;
    return this;
  }

  ApiTestBuilder expectFailure() {
    _scenario = ApiScenario.failure;
    return this;
  }

  ApiTestBuilder anyScenario() {
    _scenario = ApiScenario.any;
    return this;
  }

  ApiTestBuilder strictMode() {
    _mode = ApiTestMode.strict;
    return this;
  }

  ApiTestBuilder lenientMode() {
    _mode = ApiTestMode.lenient;
    return this;
  }

  ApiTestBuilder monitorMode() {
    _mode = ApiTestMode.monitor;
    return this;
  }

  ApiTest build() {
    if (_apiId == null) {
      throw ArgumentError('API test ID is required');
    }

    return ApiTest(
      apiId: _apiId!,
      method: _method,
      urlPattern: _urlPattern,
      expectedStatusCode: _expectedStatusCode,
      acceptableStatusCodes: _acceptableStatusCodes,
      requestChecks: _requestChecks,
      responseChecks: _responseChecks,
      exactRequestBody: _exactRequestBody,
      exactResponseBody: _exactResponseBody,
      expectedHeaders: _expectedHeaders,
      expectedResponseHeaders: _expectedResponseHeaders,
      requiredResponseHeaders: _requiredResponseHeaders,
      responseTimeConstraint: _responseTimeConstraint,
      timeout: _timeout,
      retryStrategy: _retryStrategy,
      customValidator: _customValidator,
      onSuccess: _onSuccess,
      onFailure: _onFailure,
      shouldExecute: _shouldExecute,
      testDescription: _description,
      metadata: _metadata,
      scenario: _scenario,
      mode: _mode,
    );
  }
}

/// Convenience methods for creating API tests
class Api {
  /// Create an API test builder for complex scenarios
  static ApiTestBuilder builder() => ApiTestBuilder();

  /// Create a GET API test with specific field checks
  static ApiTest get({
    required String id,
    required String urlPattern,
    int expectedStatus = 200,
    List<ResponseCheck>? responseChecks,
    Map<String, dynamic>? exactResponse,
    ApiScenario scenario = ApiScenario.success,
    ResponseTimeConstraint? responseTime,
    List<String>? requiredHeaders,
    String? description,
  }) {
    return ApiTest(
      apiId: id,
      method: 'GET',
      urlPattern: urlPattern,
      expectedStatusCode: expectedStatus,
      responseChecks: responseChecks,
      exactResponseBody: exactResponse,
      scenario: scenario,
      responseTimeConstraint: responseTime,
      requiredResponseHeaders: requiredHeaders,
      testDescription: description,
    );
  }

  /// Create a POST API test with specific field checks
  static ApiTest post({
    required String id,
    required String urlPattern,
    int expectedStatus = 201,
    List<RequestCheck>? requestChecks,
    List<ResponseCheck>? responseChecks,
    Map<String, dynamic>? exactRequest,
    Map<String, dynamic>? exactResponse,
    ApiScenario scenario = ApiScenario.success,
    ResponseTimeConstraint? responseTime,
    String? description,
  }) {
    return ApiTest(
      apiId: id,
      method: 'POST',
      urlPattern: urlPattern,
      expectedStatusCode: expectedStatus,
      requestChecks: requestChecks,
      responseChecks: responseChecks,
      exactRequestBody: exactRequest,
      exactResponseBody: exactResponse,
      scenario: scenario,
      responseTimeConstraint: responseTime,
      testDescription: description,
    );
  }

  /// Create a PUT API test
  static ApiTest put({
    required String id,
    required String urlPattern,
    int expectedStatus = 200,
    List<RequestCheck>? requestChecks,
    List<ResponseCheck>? responseChecks,
    Map<String, dynamic>? exactRequest,
    Map<String, dynamic>? exactResponse,
    ApiScenario scenario = ApiScenario.success,
    String? description,
  }) {
    return ApiTest(
      apiId: id,
      method: 'PUT',
      urlPattern: urlPattern,
      expectedStatusCode: expectedStatus,
      requestChecks: requestChecks,
      responseChecks: responseChecks,
      exactRequestBody: exactRequest,
      exactResponseBody: exactResponse,
      scenario: scenario,
      testDescription: description,
    );
  }

  /// Create a PATCH API test
  static ApiTest patch({
    required String id,
    required String urlPattern,
    int expectedStatus = 200,
    List<RequestCheck>? requestChecks,
    List<ResponseCheck>? responseChecks,
    ApiScenario scenario = ApiScenario.success,
    String? description,
  }) {
    return ApiTest(
      apiId: id,
      method: 'PATCH',
      urlPattern: urlPattern,
      expectedStatusCode: expectedStatus,
      requestChecks: requestChecks,
      responseChecks: responseChecks,
      scenario: scenario,
      testDescription: description,
    );
  }

  /// Create a DELETE API test
  static ApiTest delete({
    required String id,
    required String urlPattern,
    int expectedStatus = 204,
    List<ResponseCheck>? responseChecks,
    ApiScenario scenario = ApiScenario.success,
    String? description,
  }) {
    return ApiTest(
      apiId: id,
      method: 'DELETE',
      urlPattern: urlPattern,
      expectedStatusCode: expectedStatus,
      responseChecks: responseChecks,
      scenario: scenario,
      testDescription: description,
    );
  }

  // NEW: Convenience methods for testing specific scenarios

  /// Test API success scenario - expects 2xx status codes
  static ApiTest expectSuccess({
    required String id,
    required String urlPattern,
    String method = 'GET',
    int? expectedStatus,
    List<RequestCheck>? requestChecks,
    List<ResponseCheck>? responseChecks,
    Map<String, dynamic>? exactResponse,
    ResponseTimeConstraint? responseTime,
    String? description,
  }) {
    return ApiTest(
      apiId: id,
      method: method,
      urlPattern: urlPattern,
      expectedStatusCode: expectedStatus,
      requestChecks: requestChecks,
      responseChecks: responseChecks,
      exactResponseBody: exactResponse,
      scenario: ApiScenario.success,
      responseTimeConstraint: responseTime,
      testDescription: description,
    );
  }

  /// Test API failure scenario - expects 4xx or 5xx status codes
  static ApiTest expectFailure({
    required String id,
    required String urlPattern,
    String method = 'GET',
    int? expectedStatus,
    List<RequestCheck>? requestChecks,
    List<ResponseCheck>? responseChecks,
    Map<String, dynamic>? expectedErrorResponse,
    String? description,
  }) {
    return ApiTest(
      apiId: id,
      method: method,
      urlPattern: urlPattern,
      expectedStatusCode: expectedStatus,
      requestChecks: requestChecks,
      responseChecks: responseChecks,
      exactResponseBody: expectedErrorResponse,
      scenario: ApiScenario.failure,
      testDescription: description,
    );
  }

  /// Test error handling - specifically for 400 Bad Request
  static ApiTest expectBadRequest({
    required String id,
    required String urlPattern,
    String method = 'POST',
    List<ResponseCheck>? errorChecks,
    Map<String, dynamic>? expectedErrorBody,
    String? description,
  }) {
    return ApiTest(
      apiId: id,
      method: method,
      urlPattern: urlPattern,
      expectedStatusCode: 400,
      responseChecks: errorChecks,
      exactResponseBody: expectedErrorBody,
      scenario: ApiScenario.failure,
      testDescription: description ?? 'Bad Request validation',
    );
  }

  /// Test error handling - specifically for 401 Unauthorized
  static ApiTest expectUnauthorized({
    required String id,
    required String urlPattern,
    String method = 'GET',
    List<ResponseCheck>? errorChecks,
    String? description,
  }) {
    return ApiTest(
      apiId: id,
      method: method,
      urlPattern: urlPattern,
      expectedStatusCode: 401,
      responseChecks: errorChecks,
      scenario: ApiScenario.failure,
      testDescription: description ?? 'Unauthorized access validation',
    );
  }

  /// Test error handling - specifically for 403 Forbidden
  static ApiTest expectForbidden({
    required String id,
    required String urlPattern,
    String method = 'GET',
    List<ResponseCheck>? errorChecks,
    String? description,
  }) {
    return ApiTest(
      apiId: id,
      method: method,
      urlPattern: urlPattern,
      expectedStatusCode: 403,
      responseChecks: errorChecks,
      scenario: ApiScenario.failure,
      testDescription: description ?? 'Forbidden access validation',
    );
  }

  /// Test error handling - specifically for 404 Not Found
  static ApiTest expectNotFound({
    required String id,
    required String urlPattern,
    String method = 'GET',
    List<ResponseCheck>? errorChecks,
    String? description,
  }) {
    return ApiTest(
      apiId: id,
      method: method,
      urlPattern: urlPattern,
      expectedStatusCode: 404,
      responseChecks: errorChecks,
      scenario: ApiScenario.failure,
      testDescription: description ?? 'Not Found validation',
    );
  }

  /// Test error handling - specifically for 500 Internal Server Error
  static ApiTest expectServerError({
    required String id,
    required String urlPattern,
    String method = 'GET',
    List<ResponseCheck>? errorChecks,
    String? description,
  }) {
    return ApiTest(
      apiId: id,
      method: method,
      urlPattern: urlPattern,
      expectedStatusCode: 500,
      responseChecks: errorChecks,
      scenario: ApiScenario.failure,
      testDescription: description ?? 'Server Error validation',
    );
  }

  /// Test error handling - specifically for 503 Service Unavailable
  static ApiTest expectServiceUnavailable({
    required String id,
    required String urlPattern,
    String method = 'GET',
    List<ResponseCheck>? errorChecks,
    String? description,
  }) {
    return ApiTest(
      apiId: id,
      method: method,
      urlPattern: urlPattern,
      expectedStatusCode: 503,
      responseChecks: errorChecks,
      scenario: ApiScenario.failure,
      testDescription: description ?? 'Service Unavailable validation',
    );
  }

  /// Test API performance - monitor response time
  static ApiTest performanceTest({
    required String id,
    required String urlPattern,
    String method = 'GET',
    required Duration maxResponseTime,
    List<ResponseCheck>? responseChecks,
    String? description,
  }) {
    return ApiTest(
      apiId: id,
      method: method,
      urlPattern: urlPattern,
      responseTimeConstraint: ResponseTimeConstraint(
        maxDuration: maxResponseTime,
      ),
      responseChecks: responseChecks,
      mode: ApiTestMode.monitor,
      testDescription: description ?? 'Performance monitoring',
    );
  }

  /// Test API with retry logic for flaky endpoints
  static ApiTest withRetry({
    required String id,
    required String urlPattern,
    String method = 'GET',
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    List<int> retryableStatusCodes = const [500, 502, 503, 504],
    List<ResponseCheck>? responseChecks,
    String? description,
  }) {
    return ApiTest(
      apiId: id,
      method: method,
      urlPattern: urlPattern,
      retryStrategy: ApiRetryStrategy(
        maxRetries: maxRetries,
        retryDelay: retryDelay,
        retryableStatusCodes: retryableStatusCodes,
      ),
      responseChecks: responseChecks,
      testDescription: description ?? 'Retry-enabled API test',
    );
  }
}
