import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_test_pilot_method_channel.dart';

abstract class FlutterTestPilotPlatform extends PlatformInterface {
  /// Constructs a FlutterTestPilotPlatform.
  FlutterTestPilotPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterTestPilotPlatform _instance = MethodChannelFlutterTestPilot();

  /// The default instance of [FlutterTestPilotPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterTestPilot].
  static FlutterTestPilotPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterTestPilotPlatform] when
  /// they register themselves.
  static set instance(FlutterTestPilotPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
