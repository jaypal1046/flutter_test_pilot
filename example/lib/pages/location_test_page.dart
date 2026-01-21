import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

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
