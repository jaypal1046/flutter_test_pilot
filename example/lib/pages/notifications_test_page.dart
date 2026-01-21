import 'package:flutter/material.dart';

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
