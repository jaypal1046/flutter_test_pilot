import 'adb_commander.dart';

/// Manages Android permission granting before test execution
class PermissionGranter {
  final AdbCommander _adb;

  PermissionGranter(this._adb);

  /// Common permissions needed by most apps
  static const commonPermissions = [
    'ACCESS_FINE_LOCATION',
    'ACCESS_COARSE_LOCATION',
    'CAMERA',
    'READ_EXTERNAL_STORAGE',
    'WRITE_EXTERNAL_STORAGE',
    'RECORD_AUDIO',
    'READ_CONTACTS',
    'WRITE_CONTACTS',
    'READ_CALENDAR',
    'WRITE_CALENDAR',
    'READ_PHONE_STATE',
    'CALL_PHONE',
    'READ_SMS',
    'SEND_SMS',
    'RECEIVE_SMS',
    'POST_NOTIFICATIONS',
  ];

  /// Grant common permissions (most frequently needed)
  Future<void> grantCommon(String deviceId, String packageName) async {
    print('📋 Granting common permissions for: $packageName');

    int granted = 0;
    int failed = 0;

    for (final permission in commonPermissions) {
      try {
        await _adb.grantPermission(deviceId, packageName, permission);
        granted++;
      } catch (e) {
        // Permission might not be declared in manifest, that's okay
        failed++;
        print('  ⚠️  Could not grant: $permission (not in manifest?)');
      }
    }

    print(
      '  ✅ Granted $granted permissions${failed > 0 ? " ($failed skipped)" : ""}',
    );
  }

  /// Grant all permissions declared in app manifest
  Future<void> grantAll(String deviceId, String packageName) async {
    print('📋 Granting all permissions for: $packageName');

    try {
      // Get list of permissions from package
      final result = await _adb.run([
        'shell',
        'dumpsys',
        'package',
        packageName,
      ], deviceId: deviceId);

      final output = result.stdout as String;
      final permissions = _extractPermissions(output);

      if (permissions.isEmpty) {
        print('  ℹ️  No permissions found in manifest');
        return;
      }

      print('  📄 Found ${permissions.length} permissions in manifest');

      int granted = 0;
      for (final permission in permissions) {
        try {
          await _adb.grantPermission(deviceId, packageName, permission);
          granted++;
        } catch (e) {
          print('  ⚠️  Failed to grant: $permission');
        }
      }

      print('  ✅ Granted $granted/${permissions.length} permissions');
    } catch (e) {
      print('  ❌ Failed to grant permissions: $e');
      rethrow;
    }
  }

  /// Grant specific custom permissions
  Future<void> grantCustom(
    String deviceId,
    String packageName,
    List<String> permissions,
  ) async {
    print('📋 Granting custom permissions for: $packageName');

    int granted = 0;
    for (final permission in permissions) {
      try {
        await _adb.grantPermission(deviceId, packageName, permission);
        granted++;
      } catch (e) {
        print('  ⚠️  Failed to grant: $permission - $e');
      }
    }

    print('  ✅ Granted $granted/${permissions.length} permissions');
  }

  /// Revoke all permissions (useful for testing permission flows)
  Future<void> revokeAll(String deviceId, String packageName) async {
    print('🚫 Revoking all permissions for: $packageName');

    try {
      final result = await _adb.run([
        'shell',
        'dumpsys',
        'package',
        packageName,
      ], deviceId: deviceId);

      final output = result.stdout as String;
      final permissions = _extractPermissions(output);

      int revoked = 0;
      for (final permission in permissions) {
        try {
          await _adb.run([
            'shell',
            'pm',
            'revoke',
            packageName,
            permission,
          ], deviceId: deviceId);
          revoked++;
        } catch (e) {
          // Ignore errors
        }
      }

      print('  ✅ Revoked $revoked permissions');
    } catch (e) {
      print('  ❌ Failed to revoke permissions: $e');
    }
  }

  /// Extract permissions from dumpsys output
  List<String> _extractPermissions(String dumpsysOutput) {
    final permissions = <String>[];
    final lines = dumpsysOutput.split('\n');

    bool inRequestedPermissions = false;
    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.startsWith('requested permissions:')) {
        inRequestedPermissions = true;
        continue;
      }

      if (inRequestedPermissions) {
        if (trimmed.isEmpty || trimmed.startsWith('install permissions:')) {
          break;
        }

        // Permission lines look like: "android.permission.CAMERA"
        if (trimmed.startsWith('android.permission.')) {
          permissions.add(trimmed);
        }
      }
    }

    return permissions;
  }

  /// Check if a permission is granted
  Future<bool> isPermissionGranted(
    String deviceId,
    String packageName,
    String permission,
  ) async {
    try {
      final result = await _adb.run(
        ['shell', 'dumpsys', 'package', packageName, '|', 'grep', permission],
        deviceId: deviceId,
        throwOnError: false,
      );

      final output = result.stdout as String;
      return output.contains('granted=true');
    } catch (e) {
      return false;
    }
  }

  /// Grant permissions based on mode
  Future<void> grantByMode(
    String deviceId,
    String packageName,
    PermissionMode mode, {
    List<String>? customPermissions,
  }) async {
    switch (mode) {
      case PermissionMode.none:
        print('ℹ️  Permission granting disabled');
        break;
      case PermissionMode.common:
        await grantCommon(deviceId, packageName);
        break;
      case PermissionMode.all:
        await grantAll(deviceId, packageName);
        break;
      case PermissionMode.custom:
        if (customPermissions != null && customPermissions.isNotEmpty) {
          await grantCustom(deviceId, packageName, customPermissions);
        } else {
          print('⚠️  Custom mode selected but no permissions provided');
        }
        break;
    }
  }
}

/// Permission granting modes
enum PermissionMode { none, common, all, custom }
