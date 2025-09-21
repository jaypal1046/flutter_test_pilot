import 'dart:async';

import 'package:dio/dio.dart';

import 'apis_observer.dart';
import 'model/api_call_data.dart';
import 'model/api_test_result.dart';

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

  void registerApiTest(ApiTestAction test) {
    _registeredTests.add(test);
  }

  void clearTests() {
    _registeredTests.clear();
    _capturedCalls.clear();
    _testResults.clear();
  }

  /// Get all test results for sending to test site
  List<Map<String, dynamic>> getAllTestResultsJson() {
    return _testResults.map((result) => result.toJson()).toList();
  }

  void _onApiRequest(ApiCallData callData, RequestOptions options) {
    _pendingCalls[callData.id] = callData;
  }

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

  static void initialize(Dio dio) {
    dio.interceptors.add(ApiObserverInterceptor());
  }
}
