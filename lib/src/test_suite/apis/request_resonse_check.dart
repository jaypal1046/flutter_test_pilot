import 'apis_checker.dart';
import 'model/api_validation_result.dart';

/// Request check for validating API request data
class RequestCheck {
  final String path; // e.g., "data/user/email" or "email"
  final ApiChecker checker;
  final bool required;
  final String? description;

  const RequestCheck(
    this.path,
    this.checker, {
    this.required = true,
    this.description,
  });

  /// Validate the request data at the specified path
  Future<ApiValidationResult> validate(dynamic requestData) async {
    final value = JsonPathNavigator.getValue(requestData, path);

    // Check if required field is missing
    if (required && value == null) {
      return ApiValidationResult.failure(
        'request.$path',
        'Required request field is missing',
        expected: 'field present',
        actual: 'null',
      );
    }

    // Skip validation if optional field is missing
    if (!required && value == null) {
      return ApiValidationResult.success(
        'request.$path',
        'Optional field not present',
        value: null,
      );
    }

    // Validate using the provided checker
    return await checker.validate('request.$path', value);
  }
}

/// Response check for validating API response data
class ResponseCheck {
  final String path; // e.g., "data/user/email" or "token"
  final ApiChecker checker;
  final bool required;
  final String? description;

  const ResponseCheck(
    this.path,
    this.checker, {
    this.required = true,
    this.description,
  });

  /// Validate the response data at the specified path
  Future<ApiValidationResult> validate(dynamic responseData) async {
    final value = JsonPathNavigator.getValue(responseData, path);

    // Check if required field is missing
    if (required && value == null) {
      return ApiValidationResult.failure(
        'response.$path',
        'Required response field is missing',
        expected: 'field present',
        actual: 'null',
      );
    }

    // Skip validation if optional field is missing
    if (!required && value == null) {
      return ApiValidationResult.success(
        'response.$path',
        'Optional field not present',
        value: null,
      );
    }

    // Validate using the provided checker
    return await checker.validate('response.$path', value);
  }
}

/// Helper class to navigate nested JSON paths
class JsonPathNavigator {
  /// Get value from nested JSON using path notation
  /// Supports:
  /// - Dot notation: "user.profile.name"
  /// - Slash notation: "user/profile/name"
  /// - Array indexing: "users[0].name" or "users/0/name"
  static dynamic getValue(dynamic data, String path) {
    if (path.isEmpty) return data;

    // Normalize path - support both '.' and '/' separators
    String normalizedPath = path.replaceAll('.', '/');

    // Handle array notation like [0] -> /0
    normalizedPath = normalizedPath.replaceAllMapped(
      RegExp(r'\[(\d+)\]'),
      (match) => '/${match.group(1)}',
    );

    final parts = normalizedPath.split('/').where((p) => p.isNotEmpty).toList();
    dynamic current = data;

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];

      if (current == null) {
        print(
          '   ⚠️  Path navigation stopped at null (part ${i + 1}/${parts.length}: "$part")',
        );
        return null;
      }

      if (current is Map) {
        // Case-insensitive key matching for flexibility
        String? actualKey;
        for (final key in current.keys) {
          if (key.toString().toLowerCase() == part.toLowerCase()) {
            actualKey = key.toString();
            break;
          }
        }

        if (actualKey != null) {
          current = current[actualKey];
        } else {
          print(
            '   ⚠️  Key "$part" not found in Map (available keys: ${current.keys.take(5).join(", ")})',
          );
          return null;
        }
      } else if (current is List) {
        final index = int.tryParse(part);
        if (index != null && index >= 0 && index < current.length) {
          current = current[index];
        } else {
          print(
            '   ⚠️  Invalid array index "$part" (array length: ${current.length})',
          );
          return null;
        }
      } else {
        print('   ⚠️  Cannot navigate "$part" in ${current.runtimeType}');
        return null;
      }
    }

    return current;
  }

  /// Check if a path exists in the data
  static bool pathExists(dynamic data, String path) {
    return getValue(data, path) != null;
  }

  /// Get all values matching a wildcard path (e.g., "users/*/name")
  static List<dynamic> getValuesWithWildcard(dynamic data, String path) {
    final results = <dynamic>[];
    _collectWildcardValues(data, path.split('/'), 0, results);
    return results;
  }

  static void _collectWildcardValues(
    dynamic current,
    List<String> parts,
    int index,
    List<dynamic> results,
  ) {
    if (index >= parts.length) {
      results.add(current);
      return;
    }

    final part = parts[index];

    if (part == '*') {
      // Wildcard - collect from all items
      if (current is List) {
        for (var item in current) {
          _collectWildcardValues(item, parts, index + 1, results);
        }
      } else if (current is Map) {
        for (var value in current.values) {
          _collectWildcardValues(value, parts, index + 1, results);
        }
      }
    } else {
      // Regular navigation
      if (current is Map && current.containsKey(part)) {
        _collectWildcardValues(current[part], parts, index + 1, results);
      } else if (current is List) {
        final idx = int.tryParse(part);
        if (idx != null && idx >= 0 && idx < current.length) {
          _collectWildcardValues(current[idx], parts, index + 1, results);
        }
      }
    }
  }
}

/// Batch validator for multiple checks
class ApiCheckValidator {
  /// Validate multiple request checks
  static Future<List<ApiValidationResult>> validateRequests(
    List<RequestCheck> checks,
    dynamic requestData,
  ) async {
    final results = <ApiValidationResult>[];

    for (final check in checks) {
      final result = await check.validate(requestData);
      results.add(result);

      // Stop on first failure if needed
      if (!result.isSuccess) {
        // You can add a stopOnFailure flag if needed
      }
    }

    return results;
  }

  /// Validate multiple response checks
  static Future<List<ApiValidationResult>> validateResponses(
    List<ResponseCheck> checks,
    dynamic responseData,
  ) async {
    final results = <ApiValidationResult>[];

    for (final check in checks) {
      final result = await check.validate(responseData);
      results.add(result);

      // Stop on first failure if needed
      if (!result.isSuccess) {
        // You can add a stopOnFailure flag if needed
      }
    }

    return results;
  }

  /// Get summary of validation results
  static ValidationSummary getSummary(List<ApiValidationResult> results) {
    final passed = results.where((r) => r.isSuccess).length;
    final failed = results.where((r) => !r.isSuccess).length;

    return ValidationSummary(
      total: results.length,
      passed: passed,
      failed: failed,
      results: results,
    );
  }
}

/// Summary of validation results
class ValidationSummary {
  final int total;
  final int passed;
  final int failed;
  final List<ApiValidationResult> results;

  const ValidationSummary({
    required this.total,
    required this.passed,
    required this.failed,
    required this.results,
  });

  bool get isSuccess => failed == 0;
  double get successRate => total > 0 ? passed / total : 0.0;

  List<ApiValidationResult> get failures =>
      results.where((r) => !r.isSuccess).toList();

  @override
  String toString() {
    return 'ValidationSummary(total: $total, passed: $passed, failed: $failed, '
        'success rate: ${(successRate * 100).toStringAsFixed(1)}%)';
  }
}
