import 'package:flutter/material.dart';
import 'package:flutter_test_pilot/src/nav/global_nav.dart';

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
      title: 'Test Pilot Demo App',
      theme: ThemeData(primarySwatch: Colors.blue),

      navigatorKey: aliceNavigatorKey,
      routes: AppRoutes.routes,
    );
  }
}

// Home Page
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String policyNumber = "";
  String policyName = "Health Plus Premium";

  @override
  void initState() {
    super.initState();
    // Track initial variables
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Pilot Demo'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Policy Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text('Policy Name: $policyName'),
                    SizedBox(height: 8),
                    Text(
                      'Policy Number: ${policyNumber.isEmpty ? "Not Set" : policyNumber}',
                      style: TextStyle(
                        color: policyNumber.isEmpty ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              key: Key('policy_number_input'),
              decoration: InputDecoration(
                labelText: 'Enter Policy Number',
                border: OutlineInputBorder(),
                hintText: 'POL123456',
              ),
              onChanged: (value) {
                setState(() {
                  policyNumber = value;
                });
                // Track the variable change
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              key: Key('navigate_to_claims_button'),
              onPressed: () async {
                // This is where mistakes often happen - sending wrong variable

                await TestPilotNavigator.navigateAndWait('/claims');
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Go to Claims Page'),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              key: Key('navigate_to_profile_button'),
              onPressed: () async {
                await TestPilotNavigator.navigateAndWait('/profile');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Go to Profile'),
            ),
            SizedBox(height: 20),
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tracked Variables:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Policy Name: $policyName'),
                    Text(
                      'Policy Number: ${policyNumber.isEmpty ? "empty" : policyNumber}',
                    ),
                    Text('Current Page: HomePage'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Claims Page
class ClaimsPage extends StatefulWidget {
  const ClaimsPage({super.key});

  @override
  _ClaimsPageState createState() => _ClaimsPageState();
}

class _ClaimsPageState extends State<ClaimsPage> {
  String apiPayload = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    // Get the policy number from previous page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Claims'), backgroundColor: Colors.orange),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API Payload Preview:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        apiPayload.isEmpty
                            ? 'No payload generated'
                            : apiPayload,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              key: Key('generate_payload_button'),
              onPressed: () {
                setState(() {
                  isLoading = true;
                });

                // This is where the mistake often happens

                // Simulate the mistake - sometimes developers send name instead of number
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Generate API Payload'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              key: Key('back_button'),
              onPressed: () {
                TestPilotNavigator.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// Profile Page (Simple)
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile'), backgroundColor: Colors.green),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text('Name: John Doe'),
                    Text('Email: john@example.com'),
                    Text('Policy Count: 3'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                TestPilotNavigator.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// Route Configuration
class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => HomePage(),
    '/claims': (context) => ClaimsPage(),
    '/profile': (context) => ProfilePage(),
  };
}
