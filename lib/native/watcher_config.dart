import 'dart:convert';
import 'dart:io';
import 'adb_commander.dart';

/// Configuration for native dialog watcher behavior
/// This allows tests to control how the watcher handles dialogs
class WatcherConfig {
  final AdbCommander _adb;

  WatcherConfig(this._adb);

  /// Configure watcher behavior for the next test
  Future<void> configure({
    required String deviceId,
    DialogAction permissionAction = DialogAction.allow,
    LocationPrecision locationPrecision = LocationPrecision.precise,
    DialogAction notificationAction = DialogAction.allow,
    DialogAction systemDialogAction = DialogAction.dismiss,
    bool dismissGooglePicker = true,
    Map<String, String>? customActions,
  }) async {
    final config = {
      'permissions': _actionToString(permissionAction),
      'location': _precisionToString(locationPrecision),
      'notifications': _actionToString(notificationAction),
      'systemDialogs': _actionToString(systemDialogAction),
      'googlePicker': dismissGooglePicker ? 'dismiss' : 'ignore',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'custom': customActions ?? {},
    };

    final configJson = jsonEncode(config);
    final configPath = '/sdcard/flutter_test_pilot_watcher_config.json';

    print('📝 Configuring native watcher...');
    print('   Permissions: ${config['permissions']}');
    print('   Location: ${config['location']}');
    print('   Notifications: ${config['notifications']}');

    // Write config to device
    await _adb.run([
      'shell',
      'echo',
      "'$configJson'",
      '>',
      configPath,
    ], deviceId: deviceId);

    print('   ✅ Configuration written to device');
  }

  /// Clear watcher configuration
  Future<void> clear(String deviceId) async {
    await _adb.run(
      ['shell', 'rm', '-f', '/sdcard/flutter_test_pilot_watcher_config.json'],
      deviceId: deviceId,
      throwOnError: false,
    );

    print('🗑️  Watcher configuration cleared');
  }

  String _actionToString(DialogAction action) {
    switch (action) {
      case DialogAction.allow:
        return 'allow';
      case DialogAction.deny:
        return 'deny';
      case DialogAction.dismiss:
        return 'dismiss';
      case DialogAction.ignore:
        return 'ignore';
    }
  }

  String _precisionToString(LocationPrecision precision) {
    switch (precision) {
      case LocationPrecision.precise:
        return 'precise';
      case LocationPrecision.approximate:
        return 'approximate';
    }
  }
}

/// Actions the watcher can take on dialogs
enum DialogAction {
  allow, // Click "Allow" / positive action
  deny, // Click "Deny" / negative action
  dismiss, // Dismiss via back button
  ignore, // Don't handle this type
}

/// Location precision preference
enum LocationPrecision {
  precise, // Select "Precise" location
  approximate, // Select "Approximate" location
}
