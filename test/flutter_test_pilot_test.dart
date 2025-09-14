// import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter_test_pilot/flutter_test_pilot.dart';
// import 'package:flutter_test_pilot/flutter_test_pilot_platform_interface.dart';
// import 'package:flutter_test_pilot/flutter_test_pilot_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockFlutterTestPilotPlatform
//     with MockPlatformInterfaceMixin
//     implements FlutterTestPilotPlatform {

//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

// void main() {
//   final FlutterTestPilotPlatform initialPlatform = FlutterTestPilotPlatform.instance;

//   test('$MethodChannelFlutterTestPilot is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelFlutterTestPilot>());
//   });

//   test('getPlatformVersion', () async {
//     FlutterTestPilot flutterTestPilotPlugin = FlutterTestPilot();
//     MockFlutterTestPilotPlatform fakePlatform = MockFlutterTestPilotPlatform();
//     FlutterTestPilotPlatform.instance = fakePlatform;

//     expect(await flutterTestPilotPlugin.getPlatformVersion(), '42');
//   });
// }
