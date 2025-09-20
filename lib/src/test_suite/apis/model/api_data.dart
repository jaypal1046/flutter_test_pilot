/// API call data structure
class ApiCallData {
  final String id;
  final String method;
  final String url;
  final Map<String, dynamic>? headers;
  final dynamic requestBody;
  final Map<String, dynamic>? queryParameters;
  final int? statusCode;
  final dynamic responseBody;
  final Map<String, dynamic>? responseHeaders;
  final String? errorMessage;
  final DateTime timestamp;
  final Duration duration;

  ApiCallData({
    required this.id,
    required this.method,
    required this.url,
    this.headers,
    this.requestBody,
    this.queryParameters,
    this.statusCode,
    this.responseBody,
    this.responseHeaders,
    this.errorMessage,
    required this.timestamp,
    required this.duration,
  });

  bool get isSuccess => statusCode != null && statusCode! >= 200 && statusCode! < 300;
  bool get isError => statusCode == null || statusCode! >= 400 || errorMessage != null;
}