import 'dart:io';

/// Device information model
class DeviceInfo {
  final String id;
  final String name;
  final String platform;
  final String status;
  final String? version;

  DeviceInfo({
    required this.id,
    required this.name,
    required this.platform,
    required this.status,
    this.version,
  });

  bool get isAvailable =>
      status.toLowerCase() == 'device' || status.toLowerCase() == 'booted';

  @override
  String toString() {
    return '$name ($id) - $status${version != null ? ' [$version]' : ''}';
  }
}

/// Device manager for discovering and managing test devices
class DeviceManager {
  static DeviceManager? _instance;
  static DeviceManager get instance => _instance ??= DeviceManager._();

  DeviceManager._();

  /// Get all available Android devices
  Future<List<DeviceInfo>> getAndroidDevices() async {
    try {
      final result = await Process.run('adb', ['devices', '-l']);
      if (result.exitCode != 0) {
        return [];
      }

      final output = result.stdout.toString();
      final lines = output
          .split('\n')
          .skip(1)
          .where((l) => l.trim().isNotEmpty)
          .toList();

      final devices = <DeviceInfo>[];
      for (final line in lines) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length < 2) continue;

        final id = parts[0];
        final status = parts[1];

        // Extract device name from the line
        String name = 'Android Device';
        final modelMatch = RegExp(r'model:(\S+)').firstMatch(line);
        if (modelMatch != null) {
          name = modelMatch.group(1)!.replaceAll('_', ' ');
        }

        // Extract Android version
        String? version;
        try {
          final versionResult = await Process.run('adb', [
            '-s',
            id,
            'shell',
            'getprop',
            'ro.build.version.release',
          ]);
          if (versionResult.exitCode == 0) {
            version = versionResult.stdout.toString().trim();
          }
        } catch (_) {}

        devices.add(
          DeviceInfo(
            id: id,
            name: name,
            platform: 'android',
            status: status,
            version: version,
          ),
        );
      }

      return devices;
    } catch (e) {
      return [];
    }
  }

  /// Get all available iOS devices (simulators)
  Future<List<DeviceInfo>> getIOSDevices() async {
    if (!Platform.isMacOS) return [];

    try {
      final result = await Process.run('xcrun', [
        'simctl',
        'list',
        'devices',
        'available',
        '--json',
      ]);
      if (result.exitCode != 0) {
        return [];
      }

      // TODO: Parse JSON output properly
      // For now, use simple text parsing
      final listResult = await Process.run('xcrun', [
        'simctl',
        'list',
        'devices',
        'available',
      ]);
      final output = listResult.stdout.toString();
      final lines = output
          .split('\n')
          .where((l) => l.contains('iPhone') || l.contains('iPad'))
          .toList();

      final devices = <DeviceInfo>[];
      for (final line in lines) {
        final nameMatch = RegExp(r'^\s*([^(]+)').firstMatch(line);
        final idMatch = RegExp(r'\(([A-F0-9-]+)\)').firstMatch(line);
        final statusMatch = RegExp(r'\((Booted|Shutdown)\)').firstMatch(line);

        if (nameMatch != null && idMatch != null) {
          devices.add(
            DeviceInfo(
              id: idMatch.group(1)!,
              name: nameMatch.group(1)!.trim(),
              platform: 'ios',
              status: statusMatch?.group(1) ?? 'Shutdown',
            ),
          );
        }
      }

      return devices;
    } catch (e) {
      return [];
    }
  }

  /// Get all available devices (both Android and iOS)
  Future<List<DeviceInfo>> getAllDevices() async {
    final androidDevices = await getAndroidDevices();
    final iosDevices = await getIOSDevices();
    return [...androidDevices, ...iosDevices];
  }

  /// Select best available device for platform
  Future<DeviceInfo?> selectBestDevice({String platform = 'android'}) async {
    final devices = platform == 'android'
        ? await getAndroidDevices()
        : await getIOSDevices();

    // First try to find a booted/available device
    final available = devices.where((d) => d.isAvailable).toList();
    if (available.isNotEmpty) {
      return available.first;
    }

    // Return first device if any exists
    return devices.isNotEmpty ? devices.first : null;
  }

  /// Boot an iOS simulator
  Future<bool> bootIOSSimulator(String deviceId) async {
    if (!Platform.isMacOS) return false;

    try {
      final result = await Process.run('xcrun', ['simctl', 'boot', deviceId]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Check if ADB is installed
  Future<bool> isAdbInstalled() async {
    try {
      final result = await Process.run('adb', ['version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Check if Xcode is installed
  Future<bool> isXcodeInstalled() async {
    if (!Platform.isMacOS) return false;

    try {
      final result = await Process.run('xcrun', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
