import 'package:flutter/material.dart';
import 'package:flutter_test_pilot/src/nav/global_nav.dart';
import 'pages/home_page.dart';
import 'pages/permissions_test_page.dart';
import 'pages/location_test_page.dart';
import 'pages/notifications_test_page.dart';

final aliceNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    TestPilotNavigator.useExistingKey(aliceNavigatorKey);
    return MaterialApp(
      title: 'Native Watcher Test Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      navigatorKey: aliceNavigatorKey,
      home: const HomePage(),
      routes: {
        '/permissions': (context) => const PermissionsTestPage(),
        '/location': (context) => const LocationTestPage(),
        '/notifications': (context) => const NotificationsTestPage(),
      },
    );
  }
}
