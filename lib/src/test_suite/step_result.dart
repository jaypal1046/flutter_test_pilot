/// Result of executing a single test step
class StepResult {
  final bool success;
  final String? error;
  final String? message;
  final Duration duration;
  final Map<String, dynamic>? data;

  const StepResult({
    required this.success,
    this.error,
    this.message,
    required this.duration,
    this.data,
  });

  factory StepResult.success({
    String? message,
    Duration? duration,
    Map<String, dynamic>? data,
  }) {
    return StepResult(
      success: true,
      message: message,
      duration: duration ?? Duration.zero,
      data: data,
    );
  }

  factory StepResult.failure(String error, {Duration? duration}) {
    return StepResult(
      success: false,
      error: error,
      duration: duration ?? Duration.zero,
    );
  }
factory StepResult.warning({
  required String message,
  Duration? duration,
  Map<String, dynamic>? data,
}) {
  return StepResult(
    success: true,
    message: message,
    duration: duration ?? Duration.zero,
    data: data,
  );
}
}
