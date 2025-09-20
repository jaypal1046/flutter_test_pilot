// api_observer.dart
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../step_result.dart';
import '../test_action.dart';
import 'model/api_data.dart';
import 'model/api_validation_result.dart';

/// Base class for API validation checkers
abstract class ApiChecker {
  Future<ApiValidationResult> validate(String fieldPath, dynamic value);
  String get description;
}

/// Integer type checker with optional min/max validation
class IntChecker extends ApiChecker {
  final int? min;
  final int? max;

  IntChecker({this.min, this.max});

  @override
  Future<ApiValidationResult> validate(String fieldPath, dynamic value) async {
    if (value is! int) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected int, got ${value.runtimeType}',
      );
    }

    if (min != null && value < min!) {
      return ApiValidationResult.failure(
        fieldPath,
        'Value $value is less than minimum $min',
      );
    }

    if (max != null && value > max!) {
      return ApiValidationResult.failure(
        fieldPath,
        'Value $value is greater than maximum $max',
      );
    }

    return ApiValidationResult.success(fieldPath, 'Valid integer: $value');
  }

  @override
  String get description =>
      'Integer${min != null ? ' (min: $min)' : ''}${max != null ? ' (max: $max)' : ''}';
}

/// String type checker with optional length and pattern validation
class StringChecker extends ApiChecker {
  final int? minLength;
  final int? maxLength;
  final RegExp? pattern;

  StringChecker({this.minLength, this.maxLength, this.pattern});

  @override
  Future<ApiValidationResult> validate(String fieldPath, dynamic value) async {
    if (value is! String) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected string, got ${value.runtimeType}',
      );
    }

    if (minLength != null && value.length < minLength!) {
      return ApiValidationResult.failure(
        fieldPath,
        'String length ${value.length} is less than minimum $minLength',
      );
    }

    if (maxLength != null && value.length > maxLength!) {
      return ApiValidationResult.failure(
        fieldPath,
        'String length ${value.length} is greater than maximum $maxLength',
      );
    }

    if (pattern != null && !pattern!.hasMatch(value)) {
      return ApiValidationResult.failure(
        fieldPath,
        'String does not match required pattern',
      );
    }

    return ApiValidationResult.success(fieldPath, 'Valid string: $value');
  }

  @override
  String get description =>
      'String${minLength != null ? ' (min: $minLength)' : ''}${maxLength != null ? ' (max: $maxLength)' : ''}';
}

/// List type checker
class ListChecker extends ApiChecker {
  final ApiChecker? itemChecker;
  final int? minLength;
  final int? maxLength;

  ListChecker({this.itemChecker, this.minLength, this.maxLength});

  @override
  Future<ApiValidationResult> validate(String fieldPath, dynamic value) async {
    if (value is! List) {
      return ApiValidationResult.failure(
        fieldPath,
        'Expected list, got ${value.runtimeType}',
      );
    }

    if (minLength != null && value.length < minLength!) {
      return ApiValidationResult.failure(
        fieldPath,
        'List length ${value.length} is less than minimum $minLength',
      );
    }

    if (maxLength != null && value.length > maxLength!) {
      return ApiValidationResult.failure(
        fieldPath,
        'List length ${value.length} is greater than maximum $maxLength',
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
    );
  }

  @override
  String get description =>
      'List${minLength != null ? ' (min: $minLength)' : ''}${maxLength != null ? ' (max: $maxLength)' : ''}';
}

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
          );
        }
      }
    }

    return ApiValidationResult.success(fieldPath, 'Valid object');
  }

  @override
  String get description =>
      'Object with ${fieldCheckers.length} required fields';
}

/// Flexible checker that accepts any type
class AnyChecker extends ApiChecker {
  @override
  Future<ApiValidationResult> validate(String fieldPath, dynamic value) async {
    return ApiValidationResult.success(
      fieldPath,
      'Accepts any type: ${value.runtimeType}',
    );
  }

  @override
  String get description => 'Any type';
}

/// Custom checker with user-defined validation logic
class CustomChecker extends ApiChecker {
  final Future<ApiValidationResult> Function(String fieldPath, dynamic value)
  validator;
  final String _description;

  CustomChecker(this.validator, this._description);

  @override
  Future<ApiValidationResult> validate(String fieldPath, dynamic value) async {
    return await validator(fieldPath, value);
  }

  @override
  String get description => _description;
}

/// API Test Action that defines what to validate
abstract class ApiTestAction extends TestAction {
  final String apiId;
  final String? method;
  final String? urlPattern;
  final int? expectedStatusCode;
  final List<int>? acceptableStatusCodes;
  final Map<String, ApiChecker>? requestBodyCheckers;
  final Map<String, ApiChecker>? responseBodyCheckers;
  final Map<String, String>? expectedHeaders;
  final Duration? timeout;

  const ApiTestAction({
    required this.apiId,
    this.method,
    this.urlPattern,
    this.expectedStatusCode,
    this.acceptableStatusCodes,
    this.requestBodyCheckers,
    this.responseBodyCheckers,
    this.expectedHeaders,
    this.timeout,
  });

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    // This will be handled by the ApiObserver
    // Just register the test and return success
    ApiObserverManager.instance.registerApiTest(this);
    return StepResult.success(
      message: 'API test registered: $apiId',
      duration: Duration.zero,
    );
  }

  /// Check if this test matches the given API call
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

  /// Validate the API call against this test
  Future<List<ApiValidationResult>> validateApiCall(ApiCallData apiCall) async {
    final results = <ApiValidationResult>[];

    // Validate status code
    if (expectedStatusCode != null) {
      if (apiCall.statusCode == expectedStatusCode) {
        results.add(
          ApiValidationResult.success(
            'statusCode',
            'Status code matches expected: ${apiCall.statusCode}',
          ),
        );
      } else {
        results.add(
          ApiValidationResult.failure(
            'statusCode',
            'Expected status code $expectedStatusCode, got ${apiCall.statusCode}',
          ),
        );
      }
    }

    if (acceptableStatusCodes != null && acceptableStatusCodes!.isNotEmpty) {
      if (acceptableStatusCodes!.contains(apiCall.statusCode)) {
        results.add(
          ApiValidationResult.success(
            'statusCode',
            'Status code ${apiCall.statusCode} is acceptable',
          ),
        );
      } else {
        results.add(
          ApiValidationResult.failure(
            'statusCode',
            'Status code ${apiCall.statusCode} not in acceptable codes: $acceptableStatusCodes',
          ),
        );
      }
    }

    // Validate request body
    if (requestBodyCheckers != null && apiCall.requestBody != null) {
      final requestBody = apiCall.requestBody is String
          ? jsonDecode(apiCall.requestBody)
          : apiCall.requestBody;

      if (requestBody is Map) {
        for (final entry in requestBodyCheckers!.entries) {
          final fieldName = entry.key;
          final checker = entry.value;
          final fieldValue = requestBody[fieldName];

          final result = await checker.validate(
            'request.$fieldName',
            fieldValue,
          );
          results.add(result);
        }
      }
    }

    // Validate response body
    if (responseBodyCheckers != null && apiCall.responseBody != null) {
      final responseBody = apiCall.responseBody is String
          ? jsonDecode(apiCall.responseBody)
          : apiCall.responseBody;

      if (responseBody is Map) {
        for (final entry in responseBodyCheckers!.entries) {
          final fieldName = entry.key;
          final checker = entry.value;
          final fieldValue = responseBody[fieldName];

          final result = await checker.validate(
            'response.$fieldName',
            fieldValue,
          );
          results.add(result);
        }
      }
    }

    return results;
  }

  @override
  String get description => 'API test: $apiId';
}

/// Concrete implementation of ApiTestAction
class ApiTest extends ApiTestAction {
  const ApiTest({
    required super.apiId,
    super.method,
    super.urlPattern,
    super.expectedStatusCode,
    super.acceptableStatusCodes,
    super.requestBodyCheckers,
    super.responseBodyCheckers,
    super.expectedHeaders,
    super.timeout,
  });

  /// Create a simple API test for GET requests
  factory ApiTest.get({
    required String apiId,
    required String urlPattern,
    int? expectedStatusCode = 200,
    Map<String, ApiChecker>? responseCheckers,
  }) {
    return ApiTest(
      apiId: apiId,
      method: 'GET',
      urlPattern: urlPattern,
      expectedStatusCode: expectedStatusCode,
      responseBodyCheckers: responseCheckers,
    );
  }

  /// Create a simple API test for POST requests
  factory ApiTest.post({
    required String apiId,
    required String urlPattern,
    int? expectedStatusCode = 201,
    Map<String, ApiChecker>? requestCheckers,
    Map<String, ApiChecker>? responseCheckers,
  }) {
    return ApiTest(
      apiId: apiId,
      method: 'POST',
      urlPattern: urlPattern,
      expectedStatusCode: expectedStatusCode,
      requestBodyCheckers: requestCheckers,
      responseBodyCheckers: responseCheckers,
    );
  }
}

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
}

/// HTTP Interceptor for Dio to capture API calls
class ApiObserverInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final callData = _createApiCallData(options);
    ApiObserverManager.instance._onApiRequest(callData, options);
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    ApiObserverManager.instance._onApiResponse(response);
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    ApiObserverManager.instance._onApiError(err);
    super.onError(err, handler);
  }

  ApiCallData _createApiCallData(RequestOptions options) {
    return ApiCallData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      method: options.method,
      url: options.uri.toString(),
      headers: options.headers.cast<String, dynamic>(),
      requestBody: options.data,
      queryParameters: options.queryParameters,
      timestamp: DateTime.now(),
      duration: Duration.zero,
    );
  }
}

/// Singleton manager for API observation and testing
class ApiObserverManager {
  static final ApiObserverManager _instance = ApiObserverManager._internal();
  static ApiObserverManager get instance => _instance;
  ApiObserverManager._internal();

  final List<ApiTestAction> _registeredTests = [];
  final List<ApiCallData> _capturedCalls = [];
  final List<ApiTestResult> _testResults = [];
  final Map<String, ApiCallData> _pendingCalls = {};

  final StreamController<ApiTestResult> _resultController =
      StreamController<ApiTestResult>.broadcast();

  Stream<ApiTestResult> get testResults => _resultController.stream;
  List<ApiCallData> get capturedCalls => List.unmodifiable(_capturedCalls);
  List<ApiTestResult> get allTestResults => List.unmodifiable(_testResults);

  /// Register an API test
  void registerApiTest(ApiTestAction test) {
    _registeredTests.add(test);
  }

  /// Clear all registered tests
  void clearTests() {
    _registeredTests.clear();
    _capturedCalls.clear();
    _testResults.clear();
  }

  /// Internal method to handle API request
  void _onApiRequest(ApiCallData callData, RequestOptions options) {
    _pendingCalls[callData.id] = callData;
  }

  /// Internal method to handle API response
  void _onApiResponse(Response response) {
    final callId = _findCallId(response.requestOptions);
    if (callId != null) {
      final originalCall = _pendingCalls[callId];
      if (originalCall != null) {
        final completedCall = _completeApiCall(originalCall, response);
        _capturedCalls.add(completedCall);
        _pendingCalls.remove(callId);
        _runTestsForApiCall(completedCall);
      }
    }
  }

  /// Internal method to handle API error
  void _onApiError(DioException error) {
    final callId = _findCallId(error.requestOptions);
    if (callId != null) {
      final originalCall = _pendingCalls[callId];
      if (originalCall != null) {
        final completedCall = _completeApiCallWithError(originalCall, error);
        _capturedCalls.add(completedCall);
        _pendingCalls.remove(callId);
        _runTestsForApiCall(completedCall);
      }
    }
  }

  String? _findCallId(RequestOptions options) {
    // Find matching pending call based on URL and method
    for (final entry in _pendingCalls.entries) {
      final call = entry.value;
      if (call.method == options.method && call.url == options.uri.toString()) {
        return entry.key;
      }
    }
    return null;
  }

  ApiCallData _completeApiCall(ApiCallData originalCall, Response response) {
    return ApiCallData(
      id: originalCall.id,
      method: originalCall.method,
      url: originalCall.url,
      headers: originalCall.headers,
      requestBody: originalCall.requestBody,
      queryParameters: originalCall.queryParameters,
      statusCode: response.statusCode,
      responseBody: response.data,
      responseHeaders: response.headers.map.cast<String, dynamic>(),
      timestamp: originalCall.timestamp,
      duration: DateTime.now().difference(originalCall.timestamp),
    );
  }

  ApiCallData _completeApiCallWithError(
    ApiCallData originalCall,
    DioException error,
  ) {
    return ApiCallData(
      id: originalCall.id,
      method: originalCall.method,
      url: originalCall.url,
      headers: originalCall.headers,
      requestBody: originalCall.requestBody,
      queryParameters: originalCall.queryParameters,
      statusCode: error.response?.statusCode,
      responseBody: error.response?.data,
      responseHeaders: error.response?.headers.map.cast<String, dynamic>(),
      errorMessage: error.message,
      timestamp: originalCall.timestamp,
      duration: DateTime.now().difference(originalCall.timestamp),
    );
  }

  /// Run tests for a captured API call
  void _runTestsForApiCall(ApiCallData apiCall) async {
    for (final test in _registeredTests) {
      if (test.matches(apiCall)) {
        final validationResults = await test.validateApiCall(apiCall);
        final testResult = ApiTestResult(
          apiId: test.apiId,
          apiCall: apiCall,
          validationResults: validationResults,
          timestamp: DateTime.now(),
        );

        _testResults.add(testResult);
        _resultController.add(testResult);
      }
    }
  }

  /// Initialize API observer with Dio instance
  static void initialize(Dio dio) {
    dio.interceptors.add(ApiObserverInterceptor());
  }
}

/// Convenience methods for creating API tests
class Api {
  /// Create a GET API test
  static ApiTest get({
    required String id,
    required String urlPattern,
    int expectedStatus = 200,
    Map<String, ApiChecker>? responseCheckers,
  }) {
    return ApiTest.get(
      apiId: id,
      urlPattern: urlPattern,
      expectedStatusCode: expectedStatus,
      responseCheckers: responseCheckers,
    );
  }

  /// Create a POST API test
  static ApiTest post({
    required String id,
    required String urlPattern,
    int expectedStatus = 201,
    Map<String, ApiChecker>? requestCheckers,
    Map<String, ApiChecker>? responseCheckers,
  }) {
    return ApiTest.post(
      apiId: id,
      urlPattern: urlPattern,
      expectedStatusCode: expectedStatus,
      requestCheckers: requestCheckers,
      responseCheckers: responseCheckers,
    );
  }

  /// Create a PUT API test
  static ApiTest put({
    required String id,
    required String urlPattern,
    int expectedStatus = 200,
    Map<String, ApiChecker>? requestCheckers,
    Map<String, ApiChecker>? responseCheckers,
  }) {
    return ApiTest(
      apiId: id,
      method: 'PUT',
      urlPattern: urlPattern,
      expectedStatusCode: expectedStatus,
      requestBodyCheckers: requestCheckers,
      responseBodyCheckers: responseCheckers,
    );
  }

  /// Create a DELETE API test
  static ApiTest delete({
    required String id,
    required String urlPattern,
    int expectedStatus = 204,
  }) {
    return ApiTest(
      apiId: id,
      method: 'DELETE',
      urlPattern: urlPattern,
      expectedStatusCode: expectedStatus,
    );
  }

  

}
