
import 'api_checker.dart';

/// Request/Response check for specific field validation
class RequestCheck {
  final String path; // e.g., "data/user/email" or "email"
  final ApiChecker checker;

  const RequestCheck(this.path, this.checker);
}

class ResponseCheck {
  final String path; // e.g., "data/user/email" or "token"
  final ApiChecker checker;

  const ResponseCheck(this.path, this.checker);
}

/// Helper class to navigate nested JSON paths
class JsonPathNavigator {
  static dynamic getValue(dynamic data, String path) {
    if (path.isEmpty) return data;

    final parts = path.split('/');
    dynamic current = data;

    for (final part in parts) {
      if (current == null) return null;

      if (current is Map) {
        current = current[part];
      } else if (current is List) {
        final index = int.tryParse(part);
        if (index != null && index >= 0 && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }

    return current;
  }
}
