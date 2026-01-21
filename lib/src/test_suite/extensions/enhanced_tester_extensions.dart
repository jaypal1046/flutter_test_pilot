// // =============================================================================
// // ENHANCED WIDGET TESTER EXTENSIONS
// // Powerful testing utilities integrated with PilotFinder and SafePumpManager
// // =============================================================================

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import '../../finder/pilot_finder.dart';
// import '../../finder/finder_strategies.dart';
// import '../pump/safe_pump_manager.dart';
// import '../native_actions/native_action_handler.dart';

// /// Enhanced WidgetTester extension with intelligent testing capabilities
// ///
// /// Provides:
// /// - Integrated PilotFinder access
// /// - Safe pumping with conflict detection
// /// - Smart waiting utilities
// /// - Screen state detection
// /// - Navigation helpers
// /// - Gesture enhancements
// /// - Performance tracking
// /// - Error recovery
// extension EnhancedWidgetTesterExtension on WidgetTester {
//   // ═══════════════════════════════════════════════════════════════════════
//   // PILOT FINDER INTEGRATION (Already exists, documenting for completeness)
//   // ═══════════════════════════════════════════════════════════════════════

//   /// Access to PilotFinder - Intelligent multi-strategy widget finding
//   /// Example: tester.pilot.text('Login')
//   // PilotFind get pilot => PilotFind(this); // Already defined in pilot_finder.dart

//   // ═══════════════════════════════════════════════════════════════════════
//   // SAFE PUMPING UTILITIES
//   // ═══════════════════════════════════════════════════════════════════════

//   /// Safe pump with automatic conflict detection and retry
//   Future<void> pumpSafe({
//     Duration? duration,
//     String? debugLabel,
//     bool throwOnError = false,
//   }) async {
//     final result = await SafePumpManager.instance.pump(
//       this,
//       strategy: PumpStrategy.single,
//       config: duration != null
//           ? PumpConfig(frameDuration: duration, maxFrames: 1)
//           : null,
//       debugLabel: debugLabel,
//     );

//     if (throwOnError && !result.success) {
//       throw Exception('Safe pump failed: ${result.error}');
//     }
//   }

//   /// Pump and wait for animations to complete (with timeout protection)
//   Future<void> pumpUntilSettled({
//     Duration timeout = const Duration(seconds: 10),
//     String? debugLabel,
//   }) async {
//     await SafePumpManager.instance.pump(
//       this,
//       strategy: PumpStrategy.untilIdleOrTimeout,
//       config: PumpConfig.aggressive.copyWith(timeout: timeout),
//       debugLabel: debugLabel ?? 'settle',
//     );
//   }

//   /// Pump frames optimized for navigation transitions
//   Future<void> pumpForNavigation({String? debugLabel}) async {
//     await SafePumpManager.instance.pump(
//       this,
//       strategy: PumpStrategy.navigation,
//       debugLabel: debugLabel ?? 'navigation',
//     );
//   }

//   /// Smart pump that auto-detects animations
//   Future<void> pumpSmart({String? debugLabel}) async {
//     await SafePumpManager.instance.pump(
//       this,
//       strategy: PumpStrategy.smart,
//       debugLabel: debugLabel ?? 'smart',
//     );
//   }

//   /// Pump multiple frames with a specific interval
//   Future<void> pumpFrames({
//     required int count,
//     Duration interval = const Duration(milliseconds: 100),
//     String? debugLabel,
//   }) async {
//     await SafePumpManager.instance.pump(
//       this,
//       strategy: PumpStrategy.bounded,
//       config: PumpConfig.bounded.copyWith(
//         maxFrames: count,
//         frameDuration: interval,
//       ),
//       debugLabel: debugLabel ?? 'frames:$count',
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // SMART WAITING UTILITIES
//   // ═══════════════════════════════════════════════════════════════════════

//   /// Wait until a widget appears (with intelligent pumping)
//   Future<bool> waitForWidget(
//     Finder finder, {
//     Duration timeout = const Duration(seconds: 10),
//     Duration checkInterval = const Duration(milliseconds: 500),
//     String? debugLabel,
//   }) async {
//     final result = await SafePumpManager.instance.pumpUntil(
//       this,
//       condition: () => any(finder),
//       timeout: timeout,
//       checkInterval: checkInterval,
//       debugLabel: debugLabel ?? 'wait-for-widget',
//     );

//     return result.success;
//   }

//   /// Wait until a widget disappears
//   Future<bool> waitForWidgetToDisappear(
//     Finder finder, {
//     Duration timeout = const Duration(seconds: 10),
//     Duration checkInterval = const Duration(milliseconds: 500),
//     String? debugLabel,
//   }) async {
//     final result = await SafePumpManager.instance.pumpUntil(
//       this,
//       condition: () => !any(finder),
//       timeout: timeout,
//       checkInterval: checkInterval,
//       debugLabel: debugLabel ?? 'wait-for-disappear',
//     );

//     return result.success;
//   }

//   /// Wait until a condition is met
//   Future<bool> waitUntil(
//     bool Function() condition, {
//     Duration timeout = const Duration(seconds: 30),
//     Duration checkInterval = const Duration(milliseconds: 500),
//     String? debugLabel,
//   }) async {
//     final result = await SafePumpManager.instance.pumpUntil(
//       this,
//       condition: condition,
//       timeout: timeout,
//       checkInterval: checkInterval,
//       debugLabel: debugLabel ?? 'wait-until',
//     );

//     return result.success;
//   }

//   /// Wait for a specific duration with pumping
//   Future<void> waitFor(
//     Duration duration, {
//     bool pumpAfter = true,
//     String? debugLabel,
//   }) async {
//     if (pumpAfter) {
//       await SafePumpManager.instance.waitAndPump(
//         this,
//         duration: duration,
//         debugLabel: debugLabel ?? 'wait:${duration.inMilliseconds}ms',
//       );
//     } else {
//       await Future.delayed(duration);
//     }
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // SCREEN STATE DETECTION
//   // ═══════════════════════════════════════════════════════════════════════

//   /// Check if currently on a specific screen by detecting key widgets
//   bool isOnScreen({List<String>? texts, List<Key>? keys, List<Type>? types}) {
//     if (texts != null) {
//       for (final text in texts) {
//         if (any(pilot.text(text))) return true;
//       }
//     }

//     if (keys != null) {
//       for (final key in keys) {
//         if (any(find.byKey(key))) return true;
//       }
//     }

//     if (types != null) {
//       for (final type in types) {
//         if (any(find.byType(type))) return true;
//       }
//     }

//     return false;
//   }

//   /// Detect current screen by analyzing visible widgets
//   Future<ScreenInfo> detectCurrentScreen() async {
//     await pumpSafe(debugLabel: 'detect-screen');

//     final allTexts = find.byType(Text);
//     final textCount = widgetList<Text>(allTexts).length;
//     final visibleTexts = <String>[];

//     // Collect visible text widgets
//     for (final element in widgetList<Text>(allTexts).take(20)) {
//       final text = element.data ?? element.textSpan?.toPlainText() ?? '';
//       if (text.isNotEmpty && text.length < 100) {
//         visibleTexts.add(text);
//       }
//     }

//     // Detect common screen types
//     ScreenType screenType = ScreenType.unknown;

//     if (visibleTexts.any(
//       (t) =>
//           t.toLowerCase().contains('login') ||
//           t.toLowerCase().contains('sign in'),
//     )) {
//       screenType = ScreenType.login;
//     } else if (visibleTexts.any(
//       (t) =>
//           t.toLowerCase().contains('otp') ||
//           t.toLowerCase().contains('verification'),
//     )) {
//       screenType = ScreenType.otp;
//     } else if (visibleTexts.any(
//       (t) =>
//           t.toLowerCase().contains('dashboard') ||
//           t.toLowerCase().contains('home'),
//     )) {
//       screenType = ScreenType.dashboard;
//     } else if (visibleTexts.any(
//       (t) =>
//           t.toLowerCase().contains('onboarding') ||
//           t.toLowerCase().contains('get started'),
//     )) {
//       screenType = ScreenType.onboarding;
//     } else if (visibleTexts.any(
//       (t) =>
//           t.toLowerCase().contains('profile') ||
//           t.toLowerCase().contains('account'),
//     )) {
//       screenType = ScreenType.profile;
//     }

//     return ScreenInfo(
//       screenType: screenType,
//       visibleTexts: visibleTexts,
//       widgetCount: textCount,
//       hasDialog: any(find.byType(Dialog)),
//       hasBottomSheet: any(find.byType(BottomSheet)),
//       hasSnackBar: any(find.byType(SnackBar)),
//       hasLoadingIndicator: any(find.byType(CircularProgressIndicator)),
//     );
//   }

//   /// Wait for screen to change from current screen
//   Future<bool> waitForScreenChange({
//     Duration timeout = const Duration(seconds: 30),
//     String? debugLabel,
//   }) async {
//     final currentScreen = await detectCurrentScreen();

//     return await waitUntil(
//       () async {
//         final newScreen = await detectCurrentScreen();
//         return  newScreen.screenType != currentScreen.screenType;
//       },
//       timeout: timeout,
//       debugLabel: debugLabel ?? 'screen-change',
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // ENHANCED NAVIGATION HELPERS
//   // ═══════════════════════════════════════════════════════════════════════

//   /// Navigate and wait for transition to complete
//   Future<void> navigateAndWait(
//     VoidCallback navigationAction, {
//     Duration timeout = const Duration(seconds: 10),
//     String? debugLabel,
//   }) async {
//     final currentScreen = await detectCurrentScreen();

//     // Execute navigation
//     navigationAction();

//     // Wait for initial pump
//     await pumpSafe(debugLabel: 'nav-start');

//     // Pump for navigation animation
//     await pumpForNavigation(debugLabel: debugLabel ?? 'nav-transition');

//     // Wait for screen to actually change
//     await waitUntil(
//       () async {
//         final newScreen = await detectCurrentScreen();
//         return newScreen.screenType != currentScreen.screenType;
//       },
//       timeout: timeout,
//       debugLabel: 'nav-complete',
//     );
//   }

//   /// Pop and wait for navigation to complete
//   Future<void> popAndWait({
//     Duration timeout = const Duration(seconds: 5),
//     String? debugLabel,
//   }) async {
//     await pageBack();
//     await pumpForNavigation(debugLabel: debugLabel ?? 'pop');
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // ENHANCED GESTURE UTILITIES
//   // ═══════════════════════════════════════════════════════════════════════

//   /// Tap with automatic pumping and error handling
//   Future<bool> tapSafe(
//     Finder finder, {
//     bool warnOnly = false,
//     Duration? pumpDuration,
//     String? debugLabel,
//   }) async {
//     try {
//       if (!any(finder)) {
//         if (warnOnly) {
//           print('⚠️  Widget not found for tap: ${finder.description}');
//           return false;
//         }
//         throw Exception('Widget not found: ${finder.description}');
//       }

//       await ensureVisible(finder);
//       await pumpSafe(debugLabel: 'pre-tap');

//       await tap(finder);

//       await pumpSafe(
//         duration: pumpDuration ?? const Duration(milliseconds: 100),
//         debugLabel: debugLabel ?? 'post-tap',
//       );

//       return true;
//     } catch (e) {
//       if (warnOnly) {
//         print('⚠️  Tap failed: $e');
//         return false;
//       }
//       rethrow;
//     }
//   }

//   /// Enter text with automatic pumping
//   Future<bool> enterTextSafe(
//     Finder finder,
//     String text, {
//     bool warnOnly = false,
//     Duration? pumpDuration,
//     String? debugLabel,
//   }) async {
//     try {
//       if (!any(finder)) {
//         if (warnOnly) {
//           print('⚠️  Text field not found: ${finder.description}');
//           return false;
//         }
//         throw Exception('Text field not found: ${finder.description}');
//       }

//       await ensureVisible(finder);
//       await pumpSafe(debugLabel: 'pre-input');

//       await enterText(finder, text);

//       await pumpSafe(
//         duration: pumpDuration ?? const Duration(milliseconds: 300),
//         debugLabel: debugLabel ?? 'post-input',
//       );

//       return true;
//     } catch (e) {
//       if (warnOnly) {
//         print('⚠️  Text entry failed: $e');
//         return false;
//       }
//       rethrow;
//     }
//   }

//   /// Long press with pumping
//   Future<bool> longPressSafe(
//     Finder finder, {
//     Duration duration = const Duration(milliseconds: 500),
//     bool warnOnly = false,
//     String? debugLabel,
//   }) async {
//     try {
//       if (!any(finder)) {
//         if (warnOnly) {
//           print('⚠️  Widget not found for long press: ${finder.description}');
//           return false;
//         }
//         throw Exception('Widget not found: ${finder.description}');
//       }

//       await ensureVisible(finder);
//       await pumpSafe(debugLabel: 'pre-long-press');

//       await longPress(finder, duration: duration);

//       await pumpSafe(
//         duration: const Duration(milliseconds: 300),
//         debugLabel: debugLabel ?? 'post-long-press',
//       );

//       return true;
//     } catch (e) {
//       if (warnOnly) {
//         print('⚠️  Long press failed: $e');
//         return false;
//       }
//       rethrow;
//     }
//   }

//   /// Drag widget with pumping
//   Future<bool> dragSafe(
//     Finder finder,
//     Offset offset, {
//     bool warnOnly = false,
//     Duration? duration,
//     String? debugLabel,
//   }) async {
//     try {
//       if (!any(finder)) {
//         if (warnOnly) {
//           print('⚠️  Widget not found for drag: ${finder.description}');
//           return false;
//         }
//         throw Exception('Widget not found: ${finder.description}');
//       }

//       await ensureVisible(finder);
//       await pumpSafe(debugLabel: 'pre-drag');

//       await drag(finder, offset, duration: duration);

//       await pumpFrames(count: 5, debugLabel: debugLabel ?? 'post-drag');

//       return true;
//     } catch (e) {
//       if (warnOnly) {
//         print('⚠️  Drag failed: $e');
//         return false;
//       }
//       rethrow;
//     }
//   }

//   /// Scroll until widget is visible
//   Future<bool> scrollUntilVisible(
//     Finder finder,
//     Finder scrollable, {
//     double delta = 100.0,
//     int maxScrolls = 50,
//     Duration scrollDuration = const Duration(milliseconds: 50),
//     String? debugLabel,
//   }) async {
//     for (int i = 0; i < maxScrolls; i++) {
//       if (any(finder)) {
//         await ensureVisible(finder);
//         return true;
//       }

//       await drag(scrollable, Offset(0, -delta), duration: scrollDuration);
//       await pumpFrames(count: 3, debugLabel: debugLabel ?? 'scroll:$i');
//     }

//     return false;
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // DIALOG & BOTTOM SHEET HELPERS
//   // ═══════════════════════════════════════════════════════════════════════

//   /// Check if dialog is visible
//   bool get hasDialog =>
//       any(find.byType(Dialog)) || any(find.byType(AlertDialog));

//   /// Check if bottom sheet is visible
//   bool get hasBottomSheet => any(find.byType(BottomSheet));

//   /// Check if snackbar is visible
//   bool get hasSnackBar => any(find.byType(SnackBar));

//   /// Dismiss dialog by tapping outside
//   Future<bool> dismissDialog({String? debugLabel}) async {
//     if (!hasDialog) return false;

//     try {
//       // Tap outside dialog (barrier)
//       final screenSize = view.physicalSize / view.devicePixelRatio;
//       await tapAt(Offset(screenSize.width / 2, 50));
//       await pumpFrames(count: 5, debugLabel: debugLabel ?? 'dismiss-dialog');
//       return !hasDialog;
//     } catch (e) {
//       print('⚠️  Failed to dismiss dialog: $e');
//       return false;
//     }
//   }

//   /// Dismiss bottom sheet by dragging down
//   Future<bool> dismissBottomSheet({String? debugLabel}) async {
//     if (!hasBottomSheet) return false;

//     try {
//       final sheet = find.byType(BottomSheet);
//       await drag(sheet, const Offset(0, 300));
//       await pumpFrames(count: 10, debugLabel: debugLabel ?? 'dismiss-sheet');
//       return !hasBottomSheet;
//     } catch (e) {
//       print('⚠️  Failed to dismiss bottom sheet: $e');
//       return false;
//     }
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // ERROR HANDLING & DEBUGGING
//   // ═══════════════════════════════════════════════════════════════════════

//   /// Check if error widgets are visible
//   bool get hasError {
//     return any(find.textContaining('Error')) ||
//         any(find.textContaining('error')) ||
//         any(find.textContaining('Failed')) ||
//         any(find.textContaining('failed'));
//   }

//   /// Get error messages from screen
//   List<String> getErrorMessages() {
//     final errors = <String>[];

//     final errorFinder = find.textContaining('error', findRichText: true);
//     for (final element in widgetList<Text>(errorFinder)) {
//       final text = element.data ?? element.textSpan?.toPlainText() ?? '';
//       if (text.isNotEmpty) {
//         errors.add(text);
//       }
//     }

//     return errors;
//   }

//   /// Take screenshot with error context
//   Future<void> captureErrorContext(String testName) async {
//     try {
//       final screen = await detectCurrentScreen();

//       print('');
//       print('═' * 80);
//       print('🔍 ERROR CONTEXT: $testName');
//       print('═' * 80);
//       print('Screen Type: ${screen.screenType}');
//       print('Widget Count: ${screen.widgetCount}');
//       print('Has Dialog: ${screen.hasDialog}');
//       print('Has Loading: ${screen.hasLoadingIndicator}');
//       print('');
//       print('Visible Texts (first 10):');
//       for (final text in screen.visibleTexts.take(10)) {
//         print('  • $text');
//       }
//       print('═' * 80);
//       print('');

//       // TODO: Add actual screenshot capture if needed
//     } catch (e) {
//       print('⚠️  Failed to capture error context: $e');
//     }
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // PERFORMANCE & STATISTICS
//   // ═══════════════════════════════════════════════════════════════════════

//   /// Print performance statistics
//   void printPerformanceStats() {
//     print('');
//     print('═' * 80);
//     print('📊 TESTING PERFORMANCE STATISTICS');
//     print('═' * 80);

//     // SafePumpManager stats
//     SafePumpManager.instance.printStatistics();

//     // PilotFinder stats
//     PilotFinder.printPerformanceReport();
//   }

//   /// Reset all performance counters
//   void resetPerformanceStats() {
//     SafePumpManager.instance.resetStatistics();
//     PilotFinder.clearCache();
//   }

//   // ═══════════════════════════════════════════════════════════════════════
//   // NATIVE HANDLER INTEGRATION
//   // ═══════════════════════════════════════════════════════════════════════

//   /// Pause native action handler temporarily
//   void pauseNativeHandler() {
//     NativeActionHandler.instance.pause();
//   }

//   /// Resume native action handler
//   void resumeNativeHandler() {
//     NativeActionHandler.instance.resume();
//   }

//   /// Execute action with native handler paused
//   Future<T> withNativeHandlerPaused<T>(Future<T> Function() action) async {
//     pauseNativeHandler();
//     try {
//       return await action();
//     } finally {
//       resumeNativeHandler();
//     }
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════
// // SUPPORTING CLASSES
// // ═══════════════════════════════════════════════════════════════════════

// /// Information about current screen state
// class ScreenInfo {
//   final ScreenType screenType;
//   final List<String> visibleTexts;
//   final int widgetCount;
//   final bool hasDialog;
//   final bool hasBottomSheet;
//   final bool hasSnackBar;
//   final bool hasLoadingIndicator;

//   const ScreenInfo({
//     required this.screenType,
//     required this.visibleTexts,
//     required this.widgetCount,
//     required this.hasDialog,
//     required this.hasBottomSheet,
//     required this.hasSnackBar,
//     required this.hasLoadingIndicator,
//   });

//   @override
//   String toString() {
//     return 'ScreenInfo(type: $screenType, widgets: $widgetCount, '
//         'dialog: $hasDialog, loading: $hasLoadingIndicator)';
//   }
// }

// /// Common screen types
// enum ScreenType {
//   unknown,
//   splash,
//   onboarding,
//   login,
//   otp,
//   dashboard,
//   profile,
//   settings,
//   form,
//   list,
//   detail,
// }
