import 'package:flutter/material.dart';

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
