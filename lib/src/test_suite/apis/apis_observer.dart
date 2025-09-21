// api_observer.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import '../step_result.dart';
import '../test_action.dart';
import 'apis_observer_manager.dart';
import 'model/api_call_data.dart';

import 'model/api_validation_result.dart';
import 'request_resonse_check.dart';

/// Enhanced API Test Action
abstract class ApiTestAction extends TestAction {
  final String apiId;
  final String? method;
  final String? urlPattern;
  final int? expectedStatusCode;
  final List<int>? acceptableStatusCodes;

  // New simplified validation approach
  final List<RequestCheck>? requestChecks;
  final List<ResponseCheck>? responseChecks;

  // For exact JSON matching
  final Map<String, dynamic>? exactRequestBody;
  final Map<String, dynamic>? exactResponseBody;

  final Map<String, String>? expectedHeaders;
  final Duration? timeout;

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
    this.timeout,
  });

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    ApiObserverManager.instance.registerApiTest(this);
    return StepResult.success(
      message: 'API test registered: $apiId',
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

    // Validate status code
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
            'statusCode',
            'Status code ${apiCall.statusCode} is acceptable',
            value: apiCall.statusCode,
          ),
        );
      } else {
        results.add(
          ApiValidationResult.failure(
            'statusCode',
            'Status code ${apiCall.statusCode} not in acceptable codes: $acceptableStatusCodes',
            expected: acceptableStatusCodes,
            actual: apiCall.statusCode,
          ),
        );
      }
    }

    // Validate exact request body if specified
    if (exactRequestBody != null && apiCall.requestBody != null) {
      final requestBody = _parseJsonSafely(apiCall.requestBody);
      if (_deepEquals(requestBody, exactRequestBody)) {
        results.add(
          ApiValidationResult.success(
            'request.body',
            'Request body matches exactly',
            value: requestBody,
          ),
        );
      } else {
        results.add(
          ApiValidationResult.failure(
            'request.body',
            'Request body does not match expected',
            expected: exactRequestBody,
            actual: requestBody,
          ),
        );
      }
    }

    // Validate exact response body if specified
    if (exactResponseBody != null && apiCall.responseBody != null) {
      final responseBody = _parseJsonSafely(apiCall.responseBody);
      if (_deepEquals(responseBody, exactResponseBody)) {
        results.add(
          ApiValidationResult.success(
            'response.body',
            'Response body matches exactly',
            value: responseBody,
          ),
        );
      } else {
        results.add(
          ApiValidationResult.failure(
            'response.body',
            'Response body does not match expected',
            expected: exactResponseBody,
            actual: responseBody,
          ),
        );
      }
    }

    // Validate specific request fields
    if (requestChecks != null && apiCall.requestBody != null) {
      final requestBody = _parseJsonSafely(apiCall.requestBody);

      for (final check in requestChecks!) {
        final value = JsonPathNavigator.getValue(requestBody, check.path);
        final result = await check.checker.validate(
          'request.${check.path}',
          value,
        );
        results.add(result);
      }
    }

    // Validate specific response fields
    if (responseChecks != null && apiCall.responseBody != null) {
      final responseBody = _parseJsonSafely(apiCall.responseBody);

      for (final check in responseChecks!) {
        final value = JsonPathNavigator.getValue(responseBody, check.path);
        final result = await check.checker.validate(
          'response.${check.path}',
          value,
        );
        results.add(result);
      }
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
    super.requestChecks,
    super.responseChecks,
    super.exactRequestBody,
    super.exactResponseBody,
    super.expectedHeaders,
    super.timeout,
  });
}

/// Convenience methods for creating API tests
class Api {
  /// Create a GET API test with specific field checks
  static ApiTest get({
    required String id,
    required String urlPattern,
    int expectedStatus = 200,
    List<ResponseCheck>? responseChecks,
    Map<String, dynamic>? exactResponse,
  }) {
    return ApiTest(
      apiId: id,
      method: 'GET',
      urlPattern: urlPattern,
      expectedStatusCode: expectedStatus,
      responseChecks: responseChecks,
      exactResponseBody: exactResponse,
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
    );
  }

  /// Create a DELETE API test
  static ApiTest delete({
    required String id,
    required String urlPattern,
    int expectedStatus = 204,
    List<ResponseCheck>? responseChecks,
  }) {
    return ApiTest(
      apiId: id,
      method: 'DELETE',
      urlPattern: urlPattern,
      expectedStatusCode: expectedStatus,
      responseChecks: responseChecks,
    );
  }
}
