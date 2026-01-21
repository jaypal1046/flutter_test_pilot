import 'package:flutter/material.dart';
import 'package:flutter_test_pilot/src/nav/global_nav.dart';
import 'package:permission_handler/permission_handler.dart';

final aliceNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(MyApp());
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
      home: HomePage(),
      routes: {
        '/permissions': (context) => PermissionsTestPage(),
        '/location': (context) => LocationTestPage(),
        '/notifications': (context) => NotificationsTestPage(),
      },
    );
  }
}

// Home Page - Entry point for testing
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Native Watcher Test Demo'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '🎯 Test-Driven Native Watcher Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'This app demonstrates test-driven permission handling',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),

            _buildTestCard(
              context,
              'Test Permissions',
              'Request camera, location, and storage permissions',
              '/permissions',
              Colors.blue,
              Icons.security,
            ),

            _buildTestCard(
              context,
              'Test Location',
              'Test location permission with precision selection',
              '/location',
              Colors.green,
              Icons.location_on,
            ),

            _buildTestCard(
              context,
              'Test Notifications',
              'Test notification permission handling',
              '/notifications',
              Colors.orange,
              Icons.notifications,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context,
    String title,
    String description,
    String route,
    Color color,
    IconData icon,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: InkWell(
        key: Key('nav_$route'),
        onTap: () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// Permissions Test Page
class PermissionsTestPage extends StatefulWidget {
  const PermissionsTestPage({super.key});

  @override
  _PermissionsTestPageState createState() => _PermissionsTestPageState();
}

class _PermissionsTestPageState extends State<PermissionsTestPage> {
  String permissionStatus = 'Not requested';
  String lastPermissionRequested = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Permissions Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.blue),
                    SizedBox(height: 8),
                    Text(
                      'Permission Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      permissionStatus,
                      key: Key('permission_status'),
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    if (lastPermissionRequested.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        'Last requested: $lastPermissionRequested',
                        key: Key('last_permission'),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            ElevatedButton.icon(
              key: Key('request_camera_button'),
              icon: Icon(Icons.camera_alt),
              label: Text('Request Camera Permission'),
              onPressed: () {
                setState(() {
                  lastPermissionRequested = 'Camera';
                  permissionStatus = 'Requesting camera permission...';
                });
                // Simulate permission request
                Future.delayed(Duration(seconds: 1), () {
                  if (mounted) {
                    setState(() {
                      permissionStatus = 'Camera permission handled by watcher';
                    });
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            SizedBox(height: 12),

            ElevatedButton.icon(
              key: Key('request_storage_button'),
              icon: Icon(Icons.storage),
              label: Text('Request Storage Permission'),
              onPressed: () {
                setState(() {
                  lastPermissionRequested = 'Storage';
                  permissionStatus = 'Requesting storage permission...';
                });
                Future.delayed(Duration(seconds: 1), () {
                  if (mounted) {
                    setState(() {
                      permissionStatus =
                          'Storage permission handled by watcher';
                    });
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            SizedBox(height: 12),

            ElevatedButton.icon(
              key: Key('request_all_button'),
              icon: Icon(Icons.apps),
              label: Text('Request All Permissions'),
              onPressed: () {
                setState(() {
                  lastPermissionRequested = 'All';
                  permissionStatus = 'Requesting all permissions...';
                });
                Future.delayed(Duration(seconds: 1), () {
                  if (mounted) {
                    setState(() {
                      permissionStatus = 'All permissions handled by watcher';
                    });
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Location Test Page
class LocationTestPage extends StatefulWidget {
  const LocationTestPage({super.key});

  @override
  _LocationTestPageState createState() => _LocationTestPageState();
}

class _LocationTestPageState extends State<LocationTestPage> {
  String locationStatus = 'Not requested';
  String locationData = '';

  // NEW: Method to request REAL location permission
  Future<void> _requestLocationPermission() async {
    setState(() {
      locationStatus = 'Requesting location permission...';
      locationData = '';
    });

    // THIS WILL TRIGGER REAL ANDROID PERMISSION DIALOG!
    final status = await Permission.location.request();

    if (mounted) {
      setState(() {
        switch (status) {
          case PermissionStatus.granted:
            locationStatus = 'Location permission granted ✓';
            locationData = 'Location: 37.7749° N, 122.4194° W';
            break;
          case PermissionStatus.denied:
            locationStatus = 'Location permission denied ✗';
            break;
          case PermissionStatus.permanentlyDenied:
            locationStatus = 'Location permission permanently denied';
            break;
          default:
            locationStatus = 'Location permission: ${status.name}';
        }
      });
    }
  }

  // NEW: Method to request PRECISE location
  Future<void> _requestPreciseLocation() async {
    setState(() {
      locationStatus = 'Requesting precise location...';
      locationData = '';
    });

    // Request both location permissions
    final status = await Permission.locationWhenInUse.request();

    if (mounted) {
      setState(() {
        if (status.isGranted) {
          locationStatus = 'Precise location granted ✓';
          locationData = 'Precise: 37.774929° N, 122.419418° W';
        } else {
          locationStatus = 'Precise location denied ✗';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location Test'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.location_on, size: 48, color: Colors.green),
                    SizedBox(height: 8),
                    Text(
                      'Location Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      locationStatus,
                      key: Key('location_status'),
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    if (locationData.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        locationData,
                        key: Key('location_data'),
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            ElevatedButton.icon(
              key: Key('request_location_button'),
              icon: Icon(Icons.my_location),
              label: Text('Request Location Permission'),
              onPressed: _requestLocationPermission, // REAL REQUEST!
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
            ),

            SizedBox(height: 12),

            ElevatedButton.icon(
              key: Key('request_precise_location_button'),
              icon: Icon(Icons.gps_fixed),
              label: Text('Request Precise Location'),
              onPressed: _requestPreciseLocation, // REAL REQUEST!
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Notifications Test Page
class NotificationsTestPage extends StatefulWidget {
  const NotificationsTestPage({super.key});

  @override
  _NotificationsTestPageState createState() => _NotificationsTestPageState();
}

class _NotificationsTestPageState extends State<NotificationsTestPage> {
  String notificationStatus = 'Not requested';
  bool notificationsEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications Test'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.notifications, size: 48, color: Colors.orange),
                    SizedBox(height: 8),
                    Text(
                      'Notification Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      notificationStatus,
                      key: Key('notification_status'),
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    if (notificationsEnabled) ...[
                      SizedBox(height: 8),
                      Icon(Icons.check_circle, color: Colors.green, size: 32),
                      Text(
                        'Notifications Enabled',
                        key: Key('notifications_enabled'),
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            ElevatedButton.icon(
              key: Key('request_notifications_button'),
              icon: Icon(Icons.notification_add),
              label: Text('Request Notification Permission'),
              onPressed: () {
                setState(() {
                  notificationStatus = 'Requesting notification permission...';
                  notificationsEnabled = false;
                });
                Future.delayed(Duration(seconds: 1), () {
                  if (mounted) {
                    setState(() {
                      notificationStatus = 'Notification permission handled';
                      notificationsEnabled = true;
                    });
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
