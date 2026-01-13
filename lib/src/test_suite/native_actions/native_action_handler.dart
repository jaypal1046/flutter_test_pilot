// =============================================================================
// NATIVE ACTION HANDLER
// Handles ANR, crashes, permissions, dialogs, bottom sheets, and all native UI
// =============================================================================

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../step_result.dart';

/// Handles native platform actions like permissions, ANR, crashes, bottom sheets
class NativeActionHandler {
  static final NativeActionHandler _instance = NativeActionHandler._internal();
  static NativeActionHandler get instance => _instance;

  NativeActionHandler._internal();

  bool _isMonitoring = false;
  Timer? _monitoringTimer;
  final Set<String> _handledDialogs = {};
  int _checkCounter = 0;
  bool _isPaused = false; // NEW: Flag to pause monitoring temporarily

  /// Get the count of handled dialogs (public accessor)
  int get handledDialogCount => _handledDialogs.length;

  /// Pause monitoring temporarily (to avoid conflicts with test actions)
  void pause() {
    _isPaused = true;
  }

  /// Resume monitoring after pausing
  void resume() {
    _isPaused = false;
  }

  /// Start monitoring for native dialogs and issues
  void startMonitoring(WidgetTester tester) {
    if (_isMonitoring) return;

    _isMonitoring = true;
    print(
      '🛡️  Native Action Handler: Comprehensive monitoring started (checking every 300ms)',
    );

    // ULTRA FAST: Check every 300ms for immediate response
    _monitoringTimer = Timer.periodic(
      const Duration(milliseconds: 300),
      (_) => _checkForNativeElements(tester),
    );
  }

  /// Stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _handledDialogs.clear();
    _checkCounter = 0;
    print('🛡️  Native Action Handler: Monitoring stopped');
  }

  /// COMPREHENSIVE: Check for all types of native UI elements
  Future<void> _checkForNativeElements(WidgetTester tester) async {
    if (_isPaused) return; // Skip checks if paused

    try {
      _checkCounter++;

      // Pump once to capture any new UI changes
      await tester.pump(Duration.zero);

      // Priority handling order:
      // 🔥 HIGHEST PRIORITY: Phone picker bottom sheet (blocks UI completely)
      await _handlePhonePickerBottomSheet(tester);

      // 1. Bottom sheets (most common for permissions on mobile)
      await _handleBottomSheets(tester);

      // 2. Permission dialogs (text-based)
      await _handlePermissionDialogs(tester);

      // 3. Icon-based permissions (visual cues)
      await _handleIconBasedPermissions(tester);

      // 4. System dialogs and alerts
      await _handleSystemDialogs(tester);

      // 5. Native platform views (less frequent check)
      if (_checkCounter % 3 == 0) {
        await _handleNativePlatformViews(tester);
      }

      // 6. Check for ANR (every 4th check)
      if (_checkCounter % 4 == 0) {
        await _checkForANR(tester);
      }

      // Log every 33 checks (10 seconds)
      if (_checkCounter % 33 == 0) {
        print(
          '🛡️  Native Handler: Active... (${_handledDialogs.length} elements handled)',
        );
      }
    } catch (e) {
      // Silent catch - don't interrupt the test
      if (_checkCounter % 50 == 0) {
        print('⚠️  Native Handler: Error during check: $e');
      }
    }
  }

  /// 🔥 CRITICAL: Handle phone picker bottom sheet (Android auto-fill)
  Future<void> _handlePhonePickerBottomSheet(WidgetTester tester) async {
    // Look for the specific text that appears in phone picker
    final phonePickerTexts = [
      'Choose a phone number',
      'Choose an account',
      'Select a phone number',
    ];

    for (final text in phonePickerTexts) {
      final textFinder = find.textContaining(text, skipOffstage: false);

      if (tester.any(textFinder)) {
        final sheetKey = 'phone-picker-sheet';

        if (!_handledDialogs.contains(sheetKey)) {
          print('📱🔥 CRITICAL: Phone picker bottom sheet detected!');

          bool sheetClosed = false;

          // Strategy 1: Close button
          final closeButton = find.byIcon(Icons.close, skipOffstage: false);
          if (tester.any(closeButton)) {
            print('   Trying close button...');
            if (await _tryTapElement(tester, closeButton, 'Close')) {
              await tester.pump(const Duration(milliseconds: 500));
              sheetClosed = !tester.any(textFinder);
              if (sheetClosed) print('   ✅ Closed via close button');
            }
          }

          // Strategy 2: Tap barrier (outside sheet)
          if (!sheetClosed) {
            try {
              print('   Trying barrier tap...');
              final view = tester.view;
              final size = view.physicalSize / view.devicePixelRatio;
              await tester.tapAt(Offset(size.width / 2, 50));
              await tester.pump(const Duration(milliseconds: 500));
              sheetClosed = !tester.any(textFinder);
              if (sheetClosed) print('   ✅ Dismissed via barrier tap');
            } catch (e) {
              // Continue to next strategy
            }
          }

          // Strategy 3: Back button
          if (!sheetClosed) {
            try {
              print('   Trying back button...');
              await tester.pageBack();
              await tester.pump(const Duration(milliseconds: 500));
              sheetClosed = !tester.any(textFinder);
              if (sheetClosed) print('   ✅ Closed via back button');
            } catch (e) {
              // Continue to next strategy
            }
          }

          if (sheetClosed) {
            _handledDialogs.add(sheetKey);
            // Stabilize UI
            for (int i = 0; i < 3; i++) {
              await tester.pump(const Duration(milliseconds: 200));
            }
            print('✅ Phone picker sheet fully dismissed');
          } else {
            print('❌ WARNING: Could not dismiss phone picker sheet');
          }

          return;
        }
      }
    }
  }

  /// NEW: Handle bottom sheets (common for Android permissions)
  Future<void> _handleBottomSheets(WidgetTester tester) async {
    // Detect BottomSheet widgets
    final bottomSheetFinder = find.byWidgetPredicate(
      (widget) =>
          widget is BottomSheet ||
          widget.runtimeType.toString().contains('BottomSheet') ||
          widget.runtimeType.toString().contains('ModalBottomSheet'),
      skipOffstage: false,
    );

    if (tester.any(bottomSheetFinder)) {
      final sheetKey = 'bottomsheet-${DateTime.now().millisecondsSinceEpoch}';

      if (!_handledDialogs.contains(sheetKey)) {
        print('📱 Native Handler: Found bottom sheet');

        // Strategy 1: Look for permission text in bottom sheet
        await _findAndTapPermissionButtons(tester);

        // Strategy 2: Look for any interactive elements in the sheet
        await _handleBottomSheetButtons(tester, bottomSheetFinder);

        _handledDialogs.add(sheetKey);
      }
    }
  }

  /// NEW: Handle bottom sheet buttons
  Future<void> _handleBottomSheetButtons(
    WidgetTester tester,
    Finder sheetFinder,
  ) async {
    // Find all button types inside the bottom sheet
    final buttonTypes = [
      TextButton,
      ElevatedButton,
      OutlinedButton,
      MaterialButton,
      CupertinoButton,
      GestureDetector,
      InkWell,
    ];

    for (final buttonType in buttonTypes) {
      try {
        final buttonFinder = find.descendant(
          of: sheetFinder,
          matching: find.byType(buttonType),
          skipOffstage: false,
        );

        if (tester.any(buttonFinder)) {
          // Look for positive action buttons first
          final positiveTexts = [
            'Allow',
            'OK',
            'Accept',
            'Continue',
            'Grant',
            'Yes',
            'Enable',
          ];

          for (final widget in buttonFinder.evaluate()) {
            final widgetText = _extractTextFromWidget(widget.widget);

            if (positiveTexts.any(
              (text) => widgetText.toLowerCase().contains(text.toLowerCase()),
            )) {
              if (await _tryTapElement(
                tester,
                find.byWidget(widget.widget),
                'Bottom sheet button: $widgetText',
              )) {
                await tester.pump(const Duration(milliseconds: 300));
                print(
                  '✅ Native Handler: Tapped bottom sheet button - "$widgetText"',
                );
                return;
              }
            }
          }

          // If no positive text found, tap the first button
          if (await _tryTapElement(
            tester,
            buttonFinder.first,
            'Bottom sheet button',
          )) {
            await tester.pump(const Duration(milliseconds: 300));
            print('✅ Native Handler: Tapped bottom sheet button');
            return;
          }
        }
      } catch (e) {
        // Continue to next button type
      }
    }
  }

  /// NEW: Extract text from any widget
  String _extractTextFromWidget(Widget widget) {
    if (widget is Text) {
      return widget.data ?? '';
    }

    // Try to find text in child widgets
    try {
      if (widget is StatelessWidget || widget is StatefulWidget) {
        final String widgetString = widget.toString();
        return widgetString;
      }
    } catch (e) {
      return '';
    }

    return '';
  }

  /// NEW: Handle icon-based permissions (visual indicators)
  Future<void> _handleIconBasedPermissions(WidgetTester tester) async {
    // Common permission-related icon types
    final permissionIconTypes = [
      Icons.location_on,
      Icons.location_pin,
      Icons.my_location,
      Icons.camera,
      Icons.camera_alt,
      Icons.photo_camera,
      Icons.notifications,
      Icons.notification_important,
      Icons.mic,
      Icons.storage,
      Icons.folder,
      Icons.bluetooth,
      Icons.settings,
    ];

    for (final iconData in permissionIconTypes) {
      try {
        final iconFinder = find.byIcon(iconData, skipOffstage: false);

        if (tester.any(iconFinder)) {
          // Found an icon - look for tappable parent
          for (final element in iconFinder.evaluate()) {
            final Widget? tappableParent = _findTappableParent(element);

            if (tappableParent != null) {
              final iconKey = 'icon-${iconData.codePoint}-${element.hashCode}';

              if (!_handledDialogs.contains(iconKey)) {
                print('🎯 Native Handler: Found permission icon');

                if (await _tryTapElement(
                  tester,
                  find.byWidget(tappableParent),
                  'Permission icon',
                )) {
                  _handledDialogs.add(iconKey);
                  await tester.pump(const Duration(milliseconds: 300));

                  // After tapping icon, handle any resulting dialog
                  await _findAndTapPermissionButtons(tester);

                  print('✅ Native Handler: Handled icon-based permission');
                  return;
                }
              }
            }
          }
        }
      } catch (e) {
        // Continue to next icon
      }
    }
  }

  /// NEW: Find tappable parent widget
  Widget? _findTappableParent(Element element) {
    Widget? tappableWidget;
    int depth = 0;

    // Use visitAncestorElements instead of parent property
    element.visitAncestorElements((ancestor) {
      if (depth >= 10) return false; // Stop after 10 levels

      final widget = ancestor.widget;

      // Check if widget is tappable
      if (widget is GestureDetector ||
          widget is InkWell ||
          widget is TextButton ||
          widget is ElevatedButton ||
          widget is OutlinedButton ||
          widget is IconButton ||
          widget is MaterialButton ||
          widget is CupertinoButton) {
        tappableWidget = widget;
        return false; // Stop traversal
      }

      depth++;
      return true; // Continue traversal
    });

    return tappableWidget;
  }

  /// ENHANCED: Handle all types of permission dialogs with multiple strategies
  Future<void> _handlePermissionDialogs(WidgetTester tester) async {
    // Expanded permission text list
    final permissionTexts = [
      // Primary actions
      'Allow',
      'ALLOW',
      'Accept',
      'Grant',
      'Continue',
      'Enable',
      'Turn on',
      'Yes',
      'OK',

      // Location specific
      'Allow once',
      'Allow only while using the app',
      'Allow all the time',
      'While using the app',
      'Only this time',
      'Precise location',
      'Allow location access',

      // Camera/Media
      'Allow camera',
      'Allow photos',
      'Allow access to photos',
      'Select photos',

      // Notifications
      'Enable notifications',
      'Turn on notifications',
      'Allow notifications',

      // Storage/Files
      'Allow files access',
      'Allow storage',
      'Manage all files',

      // Other permissions
      'Allow contacts',
      'Allow microphone',
      'Allow bluetooth',
      'Always allow',
    ];

    await _findAndTapPermissionButtons(tester, permissionTexts);
  }

  /// NEW: Unified method to find and tap permission buttons
  Future<void> _findAndTapPermissionButtons(
    WidgetTester tester, [
    List<String>? texts,
  ]) async {
    final permissionTexts =
        texts ??
        ['Allow', 'OK', 'Accept', 'Grant', 'Continue', 'Enable', 'Yes'];

    for (final text in permissionTexts) {
      // Multiple finder strategies
      final finders = [
        // Text-based
        find.text(text, findRichText: true, skipOffstage: false),
        find.textContaining(text, findRichText: true, skipOffstage: false),

        // Button widgets with text
        find.widgetWithText(TextButton, text, skipOffstage: false),
        find.widgetWithText(ElevatedButton, text, skipOffstage: false),
        find.widgetWithText(OutlinedButton, text, skipOffstage: false),
        find.widgetWithText(MaterialButton, text, skipOffstage: false),
        find.widgetWithText(CupertinoButton, text, skipOffstage: false),

        // Case-insensitive search
        find.byWidgetPredicate((widget) {
          if (widget is Text && widget.data != null) {
            return widget.data!.toLowerCase().contains(text.toLowerCase());
          }
          return false;
        }, skipOffstage: false),
      ];

      for (final finder in finders) {
        try {
          if (tester.any(finder)) {
            final dialogKey = '$text-${finder.hashCode}';

            if (!_handledDialogs.contains(dialogKey)) {
              print('🔐 Native Handler: Found permission button - "$text"');

              if (await _tryTapElement(tester, finder, text)) {
                _handledDialogs.add(dialogKey);
                await tester.pump(const Duration(milliseconds: 300));
                await tester.pump(const Duration(milliseconds: 300));
                print('✅ Native Handler: Granted permission - "$text"');
                return; // Exit after handling one
              }
            }
          }
        } catch (e) {
          // Try next finder
        }
      }
    }

    // Fallback: Find any button in dialogs
    await _handleDialogButtons(tester);
  }

  /// ENHANCED: Find and tap buttons inside dialogs
  Future<void> _handleDialogButtons(WidgetTester tester) async {
    // Look for all dialog types
    final dialogFinder = find.byWidgetPredicate(
      (widget) =>
          widget is AlertDialog ||
          widget is Dialog ||
          widget is SimpleDialog ||
          widget is CupertinoAlertDialog ||
          widget.runtimeType.toString().contains('Dialog'),
      skipOffstage: false,
    );

    if (tester.any(dialogFinder)) {
      print('📋 Native Handler: Found dialog widget');

      final buttonTypes = [
        TextButton,
        ElevatedButton,
        OutlinedButton,
        MaterialButton,
        CupertinoButton,
        CupertinoDialogAction,
      ];

      for (final buttonType in buttonTypes) {
        try {
          final buttonFinder = find.descendant(
            of: dialogFinder,
            matching: find.byType(buttonType),
            skipOffstage: false,
          );

          if (tester.any(buttonFinder)) {
            // Tap the LAST button (usually positive action in iOS/Android)
            final count = buttonFinder.evaluate().length;

            if (count > 0) {
              if (await _tryTapElement(
                tester,
                buttonFinder.last,
                'Dialog button',
              )) {
                await tester.pump(const Duration(milliseconds: 300));
                print('✅ Native Handler: Tapped dialog button');
                return;
              }
            }
          }
        } catch (e) {
          // Try next button type
        }
      }
    }
  }

  /// NEW: Handle native platform views (Android/iOS native components)
  Future<void> _handleNativePlatformViews(WidgetTester tester) async {
    try {
      // Look for PlatformView widgets
      final platformViewFinder = find.byWidgetPredicate(
        (widget) =>
            widget.runtimeType.toString().contains('PlatformView') ||
            widget.runtimeType.toString().contains('AndroidView') ||
            widget.runtimeType.toString().contains('UiKitView'),
        skipOffstage: false,
      );

      if (tester.any(platformViewFinder)) {
        print(
          '🖥️  Native Handler: Found platform view - attempting to handle',
        );

        // Try to find and tap any visible buttons near the platform view
        final buttonTypes = [TextButton, ElevatedButton, OutlinedButton];

        for (final buttonType in buttonTypes) {
          final buttonFinder = find.byType(buttonType, skipOffstage: false);

          if (tester.any(buttonFinder)) {
            if (await _tryTapElement(
              tester,
              buttonFinder.first,
              'Platform view button',
            )) {
              await tester.pump(const Duration(milliseconds: 500));
              print('✅ Native Handler: Handled platform view');
              return;
            }
          }
        }
      }
    } catch (e) {
      // Platform views might not be accessible in test environment
    }
  }

  /// ENHANCED: Try multiple tap strategies with better error handling
  Future<bool> _tryTapElement(
    WidgetTester tester,
    Finder finder,
    String description,
  ) async {
    // Strategy 1: Normal tap
    try {
      await tester.tap(finder, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
      return true;
    } catch (e1) {
      // Strategy 2: Tap at calculated center position
      try {
        final element = finder.evaluate().firstOrNull;
        if (element != null) {
          final renderBox = element.renderObject as RenderBox?;
          if (renderBox != null) {
            final position = renderBox.localToGlobal(
              renderBox.size.center(Offset.zero),
            );
            await tester.tapAt(position);
            await tester.pump(const Duration(milliseconds: 100));
            return true;
          }
        }
      } catch (e2) {
        // Strategy 3: Long press (sometimes needed for certain UI elements)
        try {
          await tester.longPress(finder, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 100));
          return true;
        } catch (e3) {
          // Strategy 4: Double tap
          try {
            await tester.tap(finder, warnIfMissed: false);
            await tester.pump(const Duration(milliseconds: 50));
            await tester.tap(finder, warnIfMissed: false);
            await tester.pump(const Duration(milliseconds: 100));
            return true;
          } catch (e4) {
            if (_checkCounter % 20 == 0) {
              print(
                '⚠️  Failed to tap "$description": All strategies exhausted',
              );
            }
            // All strategies failed
            return false;
          }
        }
      }
    }

    // Fallback return (should never reach here, but required for null safety)
    return false;
  }

  /// Handle system dialogs (ANR, crash reports, etc.)
  Future<void> _handleSystemDialogs(WidgetTester tester) async {
    final systemDialogTexts = [
      'Wait',
      'Close app',
      'OK',
      'Close',
      'Cancel',
      'Dismiss',
      'Later',
      'Not now',
      'Skip',
      'Got it',
      'Maybe later',
      'No thanks',
      'Update available',
      'Don\'t optimize',
      'Don\'t allow',
      'Deny',
    ];

    for (final text in systemDialogTexts) {
      final finder = find.text(text, findRichText: true, skipOffstage: false);

      if (tester.any(finder)) {
        final dialogKey = 'system-$text';
        if (!_handledDialogs.contains(dialogKey)) {
          print('🔔 Native Handler: Found system dialog - "$text"');
          if (await _tryTapElement(tester, finder, text)) {
            _handledDialogs.add(dialogKey);
            await tester.pump(const Duration(milliseconds: 300));
            print('✅ Native Handler: Dismissed dialog - "$text"');
            return;
          }
        }
      }
    }
  }

  /// Check for ANR (Application Not Responding)
  Future<void> _checkForANR(WidgetTester tester) async {
    final anrIndicators = [
      'isn\'t responding',
      'is not responding',
      'not responding',
    ];

    for (final indicator in anrIndicators) {
      final finder = find.textContaining(
        indicator,
        findRichText: true,
        skipOffstage: false,
      );

      if (tester.any(finder)) {
        print('🚨 ANR DETECTED! Attempting recovery...');

        final waitFinder = find.text('Wait', skipOffstage: false);
        if (tester.any(waitFinder)) {
          await _tryTapElement(tester, waitFinder, 'Wait button');
          for (int i = 0; i < 10; i++) {
            await tester.pump(const Duration(milliseconds: 200));
          }
          print('✅ ANR Handler: Tapped "Wait" button');
        }

        return;
      }
    }
  }

  /// ENHANCED: Handle location permissions with all strategies
  Future<StepResult> handleLocationPermission(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();
    print('📍 Handling location permission...');

    try {
      await tester.pump(Duration.zero);
      await tester.pump(const Duration(milliseconds: 100));
      await Future.delayed(const Duration(milliseconds: 300));
      await tester.pump(Duration.zero);

      final locationTexts = [
        'Allow',
        'Allow only while using the app',
        'While using the app',
        'Allow all the time',
        'Only this time',
        'Allow once',
        'Precise location',
      ];

      bool permissionHandled = false;

      // Try text-based first
      for (final text in locationTexts) {
        final finders = [
          find.text(text, skipOffstage: false),
          find.textContaining(text, skipOffstage: false),
          find.widgetWithText(TextButton, text, skipOffstage: false),
          find.widgetWithText(ElevatedButton, text, skipOffstage: false),
        ];

        for (final finder in finders) {
          if (tester.any(finder)) {
            if (await _tryTapElement(tester, finder, text)) {
              for (int i = 0; i < 5; i++) {
                await tester.pump(const Duration(milliseconds: 200));
              }
              permissionHandled = true;
              print('✅ Location permission granted: $text');
              break;
            }
          }
          if (permissionHandled) break;
        }
        if (permissionHandled) break;
      }

      // Try icon-based
      if (!permissionHandled) {
        final locationIcon = find.byIcon(
          Icons.location_on,
          skipOffstage: false,
        );
        if (tester.any(locationIcon)) {
          await _handleIconBasedPermissions(tester);
          permissionHandled = true;
        }
      }

      // Try bottom sheets
      if (!permissionHandled) {
        await _handleBottomSheets(tester);
      }

      // Fallback: tap any visible button
      if (!permissionHandled) {
        final buttonTypes = [ElevatedButton, TextButton, OutlinedButton];
        for (final buttonType in buttonTypes) {
          final buttonFinder = find.byType(buttonType, skipOffstage: false);
          if (tester.any(buttonFinder)) {
            if (await _tryTapElement(
              tester,
              buttonFinder.first,
              'Permission button',
            )) {
              for (int i = 0; i < 5; i++) {
                await tester.pump(const Duration(milliseconds: 200));
              }
              print('✅ Location permission granted via fallback');
              permissionHandled = true;
              break;
            }
          }
        }
      }

      stopwatch.stop();
      return StepResult.success(
        message: permissionHandled
            ? 'Location permission handled'
            : 'No location permission UI found',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Failed to handle location permission: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Handle notification permission
  Future<StepResult> handleNotificationPermission(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();
    print('🔔 Handling notification permission...');

    try {
      await tester.pump(Duration.zero);
      await Future.delayed(const Duration(milliseconds: 300));
      await tester.pump(Duration.zero);

      final notificationTexts = [
        'Allow',
        'Enable notifications',
        'Turn on notifications',
        'OK',
        'Yes',
      ];

      for (final text in notificationTexts) {
        final finder = find.text(text, skipOffstage: false);
        if (tester.any(finder)) {
          if (await _tryTapElement(tester, finder, text)) {
            for (int i = 0; i < 5; i++) {
              await tester.pump(const Duration(milliseconds: 200));
            }
            print('✅ Notification permission granted: $text');
            break;
          }
        }
      }

      stopwatch.stop();
      return StepResult.success(
        message: 'Notification permission handled',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Failed to handle notification permission: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Handle camera permission
  Future<StepResult> handleCameraPermission(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();
    print('📷 Handling camera permission...');

    try {
      await tester.pump(Duration.zero);
      await Future.delayed(const Duration(milliseconds: 300));
      await tester.pump(Duration.zero);

      final cameraTexts = [
        'Allow',
        'While using the app',
        'Only this time',
        'OK',
      ];

      for (final text in cameraTexts) {
        final finder = find.text(text, skipOffstage: false);
        if (tester.any(finder)) {
          if (await _tryTapElement(tester, finder, text)) {
            for (int i = 0; i < 5; i++) {
              await tester.pump(const Duration(milliseconds: 200));
            }
            print('✅ Camera permission granted: $text');
            break;
          }
        }
      }

      stopwatch.stop();
      return StepResult.success(
        message: 'Camera permission handled',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Failed to handle camera permission: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Handle storage permission
  Future<StepResult> handleStoragePermission(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();
    print('💾 Handling storage permission...');

    try {
      await tester.pump(Duration.zero);
      await Future.delayed(const Duration(milliseconds: 300));
      await tester.pump(Duration.zero);

      final storageTexts = [
        'Allow',
        'Allow access to photos and media',
        'Allow access to media',
        'OK',
      ];

      for (final text in storageTexts) {
        final finder = find.text(text, skipOffstage: false);
        if (tester.any(finder)) {
          if (await _tryTapElement(tester, finder, text)) {
            for (int i = 0; i < 5; i++) {
              await tester.pump(const Duration(milliseconds: 200));
            }
            print('✅ Storage permission granted: $text');
            break;
          }
        }
      }

      stopwatch.stop();
      return StepResult.success(
        message: 'Storage permission handled',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Failed to handle storage permission: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// ENHANCED: Handle all permissions at once
  Future<StepResult> handleAllStartupPermissions(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();
    print('🚀 Handling all startup permissions...');

    try {
      // Start aggressive monitoring
      startMonitoring(tester);

      // Wait for app to settle
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Actively check for all types of permission UI
      for (int attempt = 0; attempt < 8; attempt++) {
        await _handleBottomSheets(tester);
        await tester.pump(const Duration(milliseconds: 200));

        await _handlePermissionDialogs(tester);
        await tester.pump(const Duration(milliseconds: 200));

        await _handleIconBasedPermissions(tester);
        await tester.pump(const Duration(milliseconds: 200));

        await _handleSystemDialogs(tester);
        await tester.pump(const Duration(milliseconds: 200));
      }

      stopwatch.stop();
      return StepResult.success(
        message:
            'All startup permissions handled (${_handledDialogs.length} elements)',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Failed to handle startup permissions: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Recover from ANR
  Future<StepResult> recoverFromANR(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();
    print('🚨 Attempting ANR recovery...');

    try {
      await tester.pump(Duration.zero);

      final anrFinder = find.textContaining(
        'isn\'t responding',
        findRichText: true,
        skipOffstage: false,
      );

      if (tester.any(anrFinder)) {
        final waitFinder = find.text('Wait', skipOffstage: false);
        if (tester.any(waitFinder)) {
          await _tryTapElement(tester, waitFinder, 'Wait');
          for (int i = 0; i < 15; i++) {
            await tester.pump(const Duration(milliseconds: 200));
          }
          print('✅ Tapped "Wait" button');
        } else {
          final closeFinder = find.text('OK', skipOffstage: false);
          if (tester.any(closeFinder)) {
            await _tryTapElement(tester, closeFinder, 'OK');
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 200));
            }
            print('✅ Tapped "OK" button');
          }
        }

        stopwatch.stop();
        return StepResult.success(
          message: 'ANR recovered',
          duration: stopwatch.elapsed,
        );
      } else {
        stopwatch.stop();
        return StepResult.success(
          message: 'No ANR detected',
          duration: stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Failed to recover from ANR: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Handle app crash recovery
  Future<StepResult> recoverFromCrash(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();
    print('💥 Attempting crash recovery...');

    try {
      await tester.pump(Duration.zero);

      final crashIndicators = [
        'has stopped',
        'has crashed',
        'unfortunately',
        'error',
      ];

      bool crashDetected = false;
      for (final indicator in crashIndicators) {
        final finder = find.textContaining(
          indicator,
          findRichText: true,
          skipOffstage: false,
        );

        if (tester.any(finder)) {
          crashDetected = true;
          print('🚨 Crash detected: $indicator');

          final closeFinder = find.text('Close', skipOffstage: false);
          if (tester.any(closeFinder)) {
            await _tryTapElement(tester, closeFinder, 'Close');
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 200));
            }
          }

          final okFinder = find.text('OK', skipOffstage: false);
          if (tester.any(okFinder)) {
            await _tryTapElement(tester, okFinder, 'OK');
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 200));
            }
          }

          break;
        }
      }

      stopwatch.stop();

      if (crashDetected) {
        return StepResult.success(
          message: 'Crash dialog dismissed',
          duration: stopwatch.elapsed,
        );
      } else {
        return StepResult.success(
          message: 'No crash detected',
          duration: stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Failed to recover from crash: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Wait for app to become responsive
  Future<StepResult> waitForAppResponsive(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final stopwatch = Stopwatch()..start();
    print('⏳ Waiting for app to become responsive...');

    try {
      final endTime = DateTime.now().add(timeout);

      while (DateTime.now().isBefore(endTime)) {
        await tester.pump(Duration.zero);

        await _checkForANR(tester);
        for (int i = 0; i < 3; i++) {
          await tester.pump(const Duration(milliseconds: 167));
        }

        final scaffoldFinder = find.byType(Scaffold);
        if (tester.any(scaffoldFinder)) {
          stopwatch.stop();
          print('✅ App is responsive');
          return StepResult.success(
            message: 'App became responsive',
            duration: stopwatch.elapsed,
          );
        }

        await Future.delayed(const Duration(seconds: 1));
      }

      stopwatch.stop();
      return StepResult.failure(
        'App did not become responsive within ${timeout.inSeconds}s',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Failed to wait for app: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// ENHANCED: Dismiss any visible element
  Future<void> dismissAnyDialog(WidgetTester tester) async {
    print('🔄 Attempting to dismiss any visible UI elements...');

    await tester.pump(Duration.zero);

    // Try bottom sheets first
    await _handleBottomSheets(tester);

    final dismissTexts = [
      'OK',
      'Close',
      'Cancel',
      'Dismiss',
      'Later',
      'Not now',
      'Skip',
      'Got it',
      'Allow',
      'Accept',
      'Maybe later',
      'No thanks',
    ];

    for (final text in dismissTexts) {
      final finder = find.text(text, skipOffstage: false);
      if (tester.any(finder)) {
        if (await _tryTapElement(tester, finder, text)) {
          for (int i = 0; i < 5; i++) {
            await tester.pump(const Duration(milliseconds: 200));
          }
          print('✅ Dismissed UI element with: $text');
          return;
        }
      }
    }

    // Try pressing back button
    try {
      await tester.pageBack();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      print('✅ Dismissed with back button');
    } catch (e) {
      print('⚠️  Could not dismiss');
    }
  }
}

/// Extension methods for easier native action handling
extension NativeActionExtensions on WidgetTester {
  /// Handle all startup permissions
  Future<void> handleStartupPermissions() async {
    await NativeActionHandler.instance.handleAllStartupPermissions(this);
  }

  /// Handle location permission
  Future<void> grantLocationPermission() async {
    await NativeActionHandler.instance.handleLocationPermission(this);
  }

  /// Handle notification permission
  Future<void> grantNotificationPermission() async {
    await NativeActionHandler.instance.handleNotificationPermission(this);
  }

  /// Handle camera permission
  Future<void> grantCameraPermission() async {
    await NativeActionHandler.instance.handleCameraPermission(this);
  }

  /// Handle storage permission
  Future<void> grantStoragePermission() async {
    await NativeActionHandler.instance.handleStoragePermission(this);
  }

  /// Recover from ANR
  Future<void> recoverFromANR() async {
    await NativeActionHandler.instance.recoverFromANR(this);
  }

  /// Recover from crash
  Future<void> recoverFromCrash() async {
    await NativeActionHandler.instance.recoverFromCrash(this);
  }

  /// Wait for app to be responsive
  Future<void> waitUntilResponsive({Duration? timeout}) async {
    await NativeActionHandler.instance.waitForAppResponsive(
      this,
      timeout: timeout ?? const Duration(seconds: 30),
    );
  }

  /// Dismiss any visible dialog or bottom sheet
  Future<void> dismissDialogs() async {
    await NativeActionHandler.instance.dismissAnyDialog(this);
  }
}
