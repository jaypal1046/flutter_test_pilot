import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_test_pilot_platform_interface.dart';

/// An implementation of [FlutterTestPilotPlatform] that uses method channels.
class MethodChannelFlutterTestPilot extends FlutterTestPilotPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_test_pilot');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
