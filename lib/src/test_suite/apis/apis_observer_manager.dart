import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

import 'apis_observer.dart';
import 'model/api_call_data.dart';
import 'model/api_test_result.dart';

/// HTTP Interceptor for Dio to capture API calls
class ApiObserverInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final timestamp = DateTime.now().toIso8601String();
    print('');
    print('🌐 [API Observer] [$timestamp] REQUEST INTERCEPTED');
    print('   Method: ${options.method}');
    print('   URL: ${options.uri}');
    print('   Headers: ${options.headers.keys.length} headers');
    if (options.data != null) {
      print('   Body: ${_truncateData(options.data)}');
    }
    if (options.queryParameters.isNotEmpty) {
      print('   Query Params: ${options.queryParameters.keys.join(", ")}');
    }

    final callData = _createApiCallData(options);
    ApiObserverManager.instance._onApiRequest(callData, options);
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final timestamp = DateTime.now().toIso8601String();
    final duration = response.requestOptions.extra['start_time'] != null
        ? DateTime.now().difference(
            response.requestOptions.extra['start_time'] as DateTime,
          )
        : Duration.zero;

    print('');
    print('✅ [API Observer] [$timestamp] RESPONSE RECEIVED');
    print('   Status: ${response.statusCode}');
    print('   URL: ${response.requestOptions.uri}');
    print('   Duration: ${duration.inMilliseconds}ms');
    if (response.data != null) {
      print('   Response: ${_truncateData(response.data)}');
    }

    ApiObserverManager.instance._onApiResponse(response);
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final timestamp = DateTime.now().toIso8601String();
    print('');
    print('❌ [API Observer] [$timestamp] ERROR INTERCEPTED');
    print('   Status: ${err.response?.statusCode ?? "N/A"}');
    print('   URL: ${err.requestOptions.uri}');
    print('   Error: ${err.message}');
    if (err.response?.data != null) {
      print('   Response: ${_truncateData(err.response!.data)}');
    }

    ApiObserverManager.instance._onApiError(err);
    super.onError(err, handler);
  }

  ApiCallData _createApiCallData(RequestOptions options) {
    // Store start time in extra data for duration tracking
    options.extra['start_time'] = DateTime.now();

    return ApiCallData(
      id: '${DateTime.now().millisecondsSinceEpoch}_${options.uri.path.hashCode}',
      method: options.method,
      url: options.uri.toString(),
      headers: options.headers.cast<String, dynamic>(),
      requestBody: options.data,
      queryParameters: options.queryParameters,
      timestamp: DateTime.now(),
      duration: Duration.zero,
    );
  }

  /// Truncate large data for logging
  String _truncateData(dynamic data) {
    final str = data.toString();
    return str.length > 100 ? '${str.substring(0, 100)}...' : str;
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
    print(
      '🔍 [API Observer] Checking if API call matches any registered tests...',
    );
    print('   API: ${apiCall.method} ${apiCall.url}');
    print('   Registered tests: ${_registeredTests.length}');

    bool matchFound = false;

    // Run validations asynchronously without blocking
    final validationFutures = <Future<void>>[];

    for (final test in _registeredTests) {
      final matches = test.matches(apiCall);

      if (matches) {
        matchFound = true;
        print('   ✅ MATCH found for test: ${test.apiId}');

        // Run each validation in parallel - don't await immediately
        final validationFuture = _runSingleTestValidation(test, apiCall);
        validationFutures.add(validationFuture);
      }
    }

    if (!matchFound) {
      print('   ℹ️  No matching test found for this API call');
    } else {
      // Wait for all validations to complete in parallel
      await Future.wait(validationFutures);
    }
  }

  /// Run a single test validation asynchronously
  Future<void> _runSingleTestValidation(
    ApiTestAction test,
    ApiCallData apiCall,
  ) async {
    try {
      final validationResults = await test.validateApiCall(apiCall);
      final testResult = ApiTestResult(
        apiId: test.apiId,
        apiCall: apiCall,
        validationResults: validationResults,
        timestamp: DateTime.now(),
      );

      _testResults.add(testResult);
      _resultController.add(testResult);

      // Log the result immediately
      if (testResult.isSuccess) {
        print('   ✅ Test PASSED: ${test.apiId}');
        print(
          '      Validations: ${testResult.passedValidations}/${testResult.totalValidations}',
        );
      } else {
        print('   ❌ Test FAILED: ${test.apiId}');
        print('      Failed validations: ${testResult.failures.length}');
        for (final failure in testResult.failures.take(3)) {
          print('         • ${failure.fieldPath}: ${failure.message}');
        }
        if (testResult.failures.length > 3) {
          print('         ... and ${testResult.failures.length - 3} more');
        }
      }
    } catch (e, stackTrace) {
      print('   ❌ Validation error for ${test.apiId}: $e');
      print(
        '      Stack trace: ${stackTrace.toString().split('\n').take(3).join('\n')}',
      );

      // Create a failed test result for the error
      final errorResult = ApiTestResult(
        apiId: test.apiId,
        apiCall: apiCall,
        validationResults: [
          ApiValidationResult.failure(
            'validation_exception',
            'Validation threw exception: $e',
            expected: 'successful validation',
            actual: 'exception: ${e.runtimeType}',
          ),
        ],
        timestamp: DateTime.now(),
      );

      _testResults.add(errorResult);
      _resultController.add(errorResult);
    }
  }

  static void initialize(Dio dio) {
    dio.interceptors.add(ApiObserverInterceptor());
  }

  /// Diagnostic method to check if API Observer is properly configured
  static Future<void> runDiagnostics() async {
    print('');
    print('═' * 60);
    print('🔍 API OBSERVER DIAGNOSTICS');
    print('═' * 60);
    print('');
    print('📊 Current State:');
    print('   • Registered API tests: ${_instance._registeredTests.length}');
    print('   • Captured API calls: ${_instance._capturedCalls.length}');
    print('   • Test results: ${_instance._testResults.length}');
    print('   • Pending calls: ${_instance._pendingCalls.length}');
    print('');

    if (_instance._registeredTests.isNotEmpty) {
      print('📋 Registered Tests:');
      for (final test in _instance._registeredTests) {
        print('   • ${test.apiId}');
        print('     Method: ${test.method ?? "ANY"}');
        print('     URL Pattern: ${test.urlPattern ?? "ANY"}');
        print('     Expected Status: ${test.expectedStatusCode ?? "ANY"}');
      }
      print('');
    } else {
      print('⚠️  No API tests registered yet!');
      print(
        '   Call ApiObserverManager.instance.registerApiTest() to add tests',
      );
      print('');
    }

    if (_instance._capturedCalls.isNotEmpty) {
      print('📡 Captured API Calls (last 10):');
      final recentCalls = _instance._capturedCalls.reversed.take(10);
      for (final call in recentCalls) {
        print('   • ${call.method} ${call.url}');
        print(
          '     Status: ${call.statusCode ?? "N/A"} | ${call.duration.inMilliseconds}ms',
        );
      }
      print('');
    } else {
      print('⚠️  No API calls captured yet!');
      print('   Possible reasons:');
      print('   1. Interceptor not attached to Dio');
      print('   2. No API calls made yet');
      print('   3. Using different HTTP client');
      print('');
    }

    if (_instance._testResults.isNotEmpty) {
      print('✅ Test Results Summary:');
      final passed = _instance._testResults.where((r) => r.isSuccess).length;
      final failed = _instance._testResults.where((r) => !r.isSuccess).length;
      print('   • Total: ${_instance._testResults.length}');
      print('   • Passed: $passed');
      print('   • Failed: $failed');
      print('');
    }

    print('═' * 60);
    print('');
  }
}
