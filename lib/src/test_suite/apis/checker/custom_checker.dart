import '../api_checker.dart';
import '../model/api_validation_result.dart';

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
