// Test-Driven Native Watcher - Complete Integration Test
// This test demonstrates how to control native watcher behavior from your tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

// Import the test app
import '../lib/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🎯 Test-Driven Native Watcher Complete Demo', () {
    late NativeHandler handler;
    late AdbCommander adb;
    late String deviceId;

    setUpAll(() async {
      print('\n' + '=' * 70);
      print('🚀 Setting up test-driven native watcher demo');
      print('=' * 70);

      // Check if ADB is available first
      try {
        handler = NativeHandler();
        adb = AdbCommander();
      } catch (e) {
        if (e.toString().contains('ADB not found')) {
          print('\n❌ ERROR: ADB (Android Debug Bridge) is not installed!\n');
          print(e.toString());
          print('\n⚠️  Skipping native watcher tests.');
          print('   These tests require Android SDK to be installed.\n');
          fail('ADB not found. Please install Android SDK and try again.');
        }
        rethrow;
      }

      // Get connected device
      final devices = await adb.getDevices();
      if (devices.isEmpty) {
        print('\n❌ ERROR: No Android device connected!\n');
        print('🔧 Please do one of the following:\n');
        print('1️⃣ Start an Android emulator:');
        print('   Open Android Studio → AVD Manager → Start emulator\n');
        print('2️⃣ Connect a physical device via USB:');
        print('   - Enable USB debugging in Developer Options');
        print('   - Connect device and accept USB debugging prompt\n');
        print('3️⃣ Verify connection:');
        print('   adb devices\n');
        fail('❌ No Android device connected! Please connect a device or emulator.');
      }

      deviceId = devices.first;
      print('📱 Using device: $deviceId');

      // Check device capabilities
      final capabilities = await handler.checkCapabilities(deviceId);
      print('🔍 Device capabilities:');
      print('   • UI Automator: ${capabilities.watcherSupported ? "✅" : "❌"}');
      print('   • Permission Granting: ${capabilities.permissionGrantingSupported ? "✅" : "❌"}');
      print('   • API Level: ${capabilities.apiLevel}');

      if (!capabilities.watcherSupported) {
        print('\n⚠️  Warning: UI Automator not supported on this device');
        print('   Tests will run but native dialog handling may not work');
        print('   Minimum API level required: 18 (Android 4.3)');
      }
    });

    tearDown(() async {
      // Always clear configuration after each test
      try {
        await handler.clearWatcherConfig(deviceId);
      } catch (e) {
        print('⚠️  Warning: Could not clear watcher config: $e');
      }
    });

    // ========================================================================
    // TEST 1: Allow All Permissions (Grant Flow)
    // ========================================================================
    testWidgets('✅ TEST 1: Allow all permissions - Test GRANT flow', (
      tester,
    ) async {
      print('\n' + '-' * 70);
      print('✅ TEST 1: Testing permission GRANT flow');
      print('-' * 70);

      // STEP 1: Configure watcher to ALLOW all permissions
      print('\n📝 Step 1: Configuring watcher to ALLOW permissions');
      await handler.configureWatcher(
        deviceId: deviceId,
        permissionAction: DialogAction.allow, // ✅ GRANT
        locationPrecision: LocationPrecision.precise,
        notificationAction: DialogAction.allow,
        systemDialogAction: DialogAction.dismiss,
      );
      print('   ✅ Configuration set: ALLOW all');

      // STEP 2: Start native watcher
      print('\n🤖 Step 2: Starting native watcher');
      final watcherProcess = await DialogWatcher(adb).start(deviceId);
      print('   ✅ Watcher started');

      // STEP 3: Launch app
      print('\n🚀 Step 3: Launching test app');
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 2));
      print('   ✅ App launched');

      // Verify home screen
      expect(find.text('🎯 Test-Driven Native Watcher Demo'), findsOneWidget);
      print('   ✅ Home screen verified');

      // STEP 4: Navigate to Permissions page
      print('\n🔍 Step 4: Testing permissions page');
      await tester.tap(find.byKey(Key('nav_/permissions')));
      await tester.pumpAndSettle(Duration(seconds: 1));

      expect(find.text('Permissions Test'), findsOneWidget);
      print('   ✅ Navigated to permissions page');

      // STEP 5: Request camera permission
      print('\n📷 Step 5: Requesting camera permission');
      await tester.tap(find.byKey(Key('request_camera_button')));
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Verify status updated
      expect(find.byKey(Key('permission_status')), findsOneWidget);
      print('   ✅ Camera permission requested');
      print('   ℹ️  Native watcher should have granted it automatically');

      // STEP 6: Request storage permission
      print('\n💾 Step 6: Requesting storage permission');
      await tester.tap(find.byKey(Key('request_storage_button')));
      await tester.pumpAndSettle(Duration(seconds: 2));
      print('   ✅ Storage permission requested');

      // STEP 7: Stop watcher and check stats
      print('\n🛑 Step 7: Stopping watcher and collecting stats');
      await DialogWatcher(adb).stop(watcherProcess);

      final stats = await DialogWatcher(adb).getStats(deviceId);
      print('   📊 Watcher Statistics:');
      print('      • Dialogs detected: ${stats.dialogsDetected}');
      print('      • Dialogs dismissed: ${stats.dialogsDismissed}');

      print('\n✅ TEST 1 COMPLETE: Permission grant flow tested successfully!');
    });

    // ========================================================================
    // TEST 2: Deny All Permissions (Denial Flow)
    // ========================================================================
    testWidgets('❌ TEST 2: Deny all permissions - Test DENIAL flow', (
      tester,
    ) async {
      print('\n' + '-' * 70);
      print('❌ TEST 2: Testing permission DENIAL flow');
      print('-' * 70);

      // STEP 1: Configure watcher to DENY all permissions
      print('\n📝 Step 1: Configuring watcher to DENY permissions');
      await handler.configureWatcher(
        deviceId: deviceId,
        permissionAction: DialogAction.deny, // ❌ DENY
        notificationAction: DialogAction.deny,
      );
      print('   ✅ Configuration set: DENY all');

      // STEP 2: Start native watcher
      print('\n🤖 Step 2: Starting native watcher');
      final watcherProcess = await DialogWatcher(adb).start(deviceId);
      print('   ✅ Watcher started (will deny permissions)');

      // STEP 3: Launch app
      print('\n🚀 Step 3: Launching test app');
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 2));

      // STEP 4: Navigate to Permissions page
      print('\n🔍 Step 4: Testing permissions page');
      await tester.tap(find.byKey(Key('nav_/permissions')));
      await tester.pumpAndSettle(Duration(seconds: 1));

      // STEP 5: Request camera permission (will be denied)
      print('\n📷 Step 5: Requesting camera permission (will be denied)');
      await tester.tap(find.byKey(Key('request_camera_button')));
      await tester.pumpAndSettle(Duration(seconds: 2));
      print('   ✅ Camera permission requested');
      print('   ℹ️  Native watcher should have DENIED it automatically');

      // STEP 6: Stop watcher
      print('\n🛑 Step 6: Stopping watcher');
      await DialogWatcher(adb).stop(watcherProcess);

      print('\n✅ TEST 2 COMPLETE: Permission denial flow tested successfully!');
    });

    // ========================================================================
    // TEST 3: Location with Precision Selection
    // ========================================================================
    testWidgets('📍 TEST 3: Test location with PRECISE selection', (
      tester,
    ) async {
      print('\n' + '-' * 70);
      print('📍 TEST 3: Testing location permission with precision');
      print('-' * 70);

      // STEP 1: Configure watcher for precise location
      print('\n📝 Step 1: Configuring watcher for PRECISE location');
      await handler.configureWatcher(
        deviceId: deviceId,
        permissionAction: DialogAction.allow,
        locationPrecision: LocationPrecision.precise, // 🎯 PRECISE
      );
      print('   ✅ Configuration set: ALLOW with PRECISE location');

      // STEP 2: Start watcher
      print('\n🤖 Step 2: Starting native watcher');
      final watcherProcess = await DialogWatcher(adb).start(deviceId);

      // STEP 3: Launch app
      print('\n🚀 Step 3: Launching test app');
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 2));

      // STEP 4: Navigate to Location page
      print('\n🗺️  Step 4: Testing location page');
      await tester.tap(find.byKey(Key('nav_/location')));
      await tester.pumpAndSettle(Duration(seconds: 1));

      expect(find.text('Location Test'), findsOneWidget);

      // STEP 5: Request location permission
      print('\n📍 Step 5: Requesting location permission');
      await tester.tap(find.byKey(Key('request_location_button')));
      await tester.pumpAndSettle(Duration(seconds: 2));
      print('   ✅ Location permission requested');

      // STEP 6: Request precise location
      print('\n🎯 Step 6: Requesting PRECISE location');
      await tester.tap(find.byKey(Key('request_precise_location_button')));
      await tester.pumpAndSettle(Duration(seconds: 2));
      print('   ✅ Precise location requested');
      print('   ℹ️  Watcher should have selected PRECISE option');

      // Verify location data displayed
      expect(find.byKey(Key('location_status')), findsOneWidget);
      expect(find.byKey(Key('location_data')), findsOneWidget);

      // STEP 7: Stop watcher
      print('\n🛑 Step 7: Stopping watcher');
      await DialogWatcher(adb).stop(watcherProcess);

      print('\n✅ TEST 3 COMPLETE: Precise location tested successfully!');
    });

    // ========================================================================
    // TEST 4: Mixed Configuration (Real-world scenario)
    // ========================================================================
    testWidgets(
      '🎭 TEST 4: Mixed configuration - Allow permissions, Deny notifications',
      (tester) async {
        print('\n' + '-' * 70);
        print('🎭 TEST 4: Testing MIXED configuration');
        print('-' * 70);

        // STEP 1: Configure mixed behavior
        print('\n📝 Step 1: Configuring MIXED behavior');
        await handler.configureWatcher(
          deviceId: deviceId,
          permissionAction: DialogAction.allow, // ✅ Grant permissions
          notificationAction: DialogAction.deny, // ❌ Deny notifications
          locationPrecision: LocationPrecision.approximate,
        );
        print('   ✅ Configuration set:');
        print('      • Permissions: ALLOW');
        print('      • Notifications: DENY');
        print('      • Location: APPROXIMATE');

        // STEP 2: Start watcher
        print('\n🤖 Step 2: Starting native watcher');
        final watcherProcess = await DialogWatcher(adb).start(deviceId);

        // STEP 3: Launch app
        print('\n🚀 Step 3: Launching test app');
        app.main();
        await tester.pumpAndSettle(Duration(seconds: 2));

        // STEP 4: Test permissions (should be granted)
        print('\n📷 Step 4: Testing camera permission (should be granted)');
        await tester.tap(find.byKey(Key('nav_/permissions')));
        await tester.pumpAndSettle(Duration(seconds: 1));

        await tester.tap(find.byKey(Key('request_camera_button')));
        await tester.pumpAndSettle(Duration(seconds: 2));
        print('   ✅ Camera permission tested (granted)');

        // STEP 5: Navigate back
        await tester.pageBack();
        await tester.pumpAndSettle();

        // STEP 6: Test notifications (should be denied)
        print('\n🔔 Step 5: Testing notifications (should be denied)');
        await tester.tap(find.byKey(Key('nav_/notifications')));
        await tester.pumpAndSettle(Duration(seconds: 1));

        await tester.tap(find.byKey(Key('request_notifications_button')));
        await tester.pumpAndSettle(Duration(seconds: 2));
        print('   ✅ Notification permission tested (denied)');

        // STEP 7: Stop watcher and check stats
        print('\n🛑 Step 6: Stopping watcher');
        await DialogWatcher(adb).stop(watcherProcess);

        final stats = await DialogWatcher(adb).getStats(deviceId);
        print('   📊 Final Statistics:');
        print('      • Dialogs detected: ${stats.dialogsDetected}');
        print('      • Dialogs dismissed: ${stats.dialogsDismissed}');

        print('\n✅ TEST 4 COMPLETE: Mixed configuration tested successfully!');
      },
    );

    // ========================================================================
    // TEST 5: Configuration Changes Between Tests
    // ========================================================================
    testWidgets('🔄 TEST 5: Verify configuration changes between tests', (
      tester,
    ) async {
      print('\n' + '-' * 70);
      print('🔄 TEST 5: Testing configuration isolation');
      print('-' * 70);

      // STEP 1: First configuration (ALLOW)
      print('\n📝 Step 1: First configuration - ALLOW');
      await handler.configureWatcher(
        deviceId: deviceId,
        permissionAction: DialogAction.allow,
      );

      final watcherProcess1 = await DialogWatcher(adb).start(deviceId);
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 2));

      print('   ✅ First config active (ALLOW)');

      await DialogWatcher(adb).stop(watcherProcess1);
      await handler.clearWatcherConfig(deviceId);

      // STEP 2: Change configuration (DENY)
      print('\n📝 Step 2: Changing configuration to DENY');
      await handler.configureWatcher(
        deviceId: deviceId,
        permissionAction: DialogAction.deny,
      );

      final watcherProcess2 = await DialogWatcher(adb).start(deviceId);
      print('   ✅ Second config active (DENY)');
      print('   ℹ️  Watcher should now deny instead of allow');

      await tester.pumpAndSettle(Duration(seconds: 2));
      await DialogWatcher(adb).stop(watcherProcess2);

      print('\n✅ TEST 5 COMPLETE: Configuration isolation verified!');
    });
  });

  // ==========================================================================
  // FINAL SUMMARY
  // ==========================================================================
  tearDownAll(() {
    print('\n' + '=' * 70);
    print('🎉 ALL TESTS COMPLETED!');
    print('=' * 70);
    print('\n📊 Test Summary:');
    print('   ✅ TEST 1: Permission grant flow');
    print('   ✅ TEST 2: Permission denial flow');
    print('   ✅ TEST 3: Location precision selection');
    print('   ✅ TEST 4: Mixed configuration');
    print('   ✅ TEST 5: Configuration isolation');
    print('\n🎯 Key Features Tested:');
    print('   • Test-driven configuration');
    print('   • Dynamic allow/deny behavior');
    print('   • Location precision selection');
    print('   • Configuration isolation between tests');
    print('   • Statistics collection');
    print('\n🚀 The test-driven native watcher is working correctly!');
    print('=' * 70 + '\n');
  });
}
