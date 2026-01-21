import 'package:flutter/material.dart';

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
