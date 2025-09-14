import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Pilot Demo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
      navigatorKey: TestPilotNavigator.navigatorKey,
    );
  }
}

// Custom Navigation System (Similar to Patrol)
class TestPilotNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext get context => navigatorKey.currentContext!;
  static NavigatorState get navigator => navigatorKey.currentState!;

  // Navigation methods that can be controlled by tests
  static Future<void> pushTo(String routeName, {Object? arguments}) async {
    await navigator.pushNamed(routeName, arguments: arguments);
  }

  static void pop() {
    navigator.pop();
  }

  static Future<void> pushAndReplace(String routeName, {Object? arguments}) async {
    await navigator.pushReplacementNamed(routeName, arguments: arguments);
  }

  // Test-friendly navigation with delays for verification
  static Future<void> navigateAndWait(String routeName, {Duration? delay}) async {
    await pushTo(routeName);
    if (delay != null) {
      await Future.delayed(delay);
    }
  }
}

// Global variable tracker for the plugin
class GuardianGlobal {
  static Map<String, dynamic> _trackedVariables = {};
  static List<String> _navigationHistory = [];

  static void trackVariable(String name, dynamic value, {String? context}) {
    _trackedVariables[name] = {
      'value': value,
      'timestamp': DateTime.now(),
      'context': context,
    };
    print('🔍 Tracking: $name = $value ${context != null ? '($context)' : ''}');
  }

  static dynamic getVariable(String name) {
    return _trackedVariables[name]?['value'];
  }

  static Map<String, dynamic> getAllVariables() {
    return Map.from(_trackedVariables);
  }

  static void trackNavigation(String route) {
    _navigationHistory.add(route);
    print('🧭 Navigation: $route');
  }

  static void clearTracking() {
    _trackedVariables.clear();
    _navigationHistory.clear();
  }
}

// Home Page
class HomePage extends StatefulWidget {
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
    GuardianGlobal.trackVariable('current_page', 'HomePage', context: 'navigation');
    GuardianGlobal.trackVariable('policy_name', policyName, context: 'initialization');
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
                    Text('Policy Information',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Text('Policy Name: $policyName'),
                    SizedBox(height: 8),
                    Text('Policy Number: ${policyNumber.isEmpty ? "Not Set" : policyNumber}',
                        style: TextStyle(color: policyNumber.isEmpty ? Colors.red : Colors.green)),
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
                GuardianGlobal.trackVariable('policy_number', value, context: 'user_input');
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              key: Key('navigate_to_claims_button'),
              onPressed: () async {
                // This is where mistakes often happen - sending wrong variable
                GuardianGlobal.trackVariable('selected_policy_for_api', policyNumber, context: 'button_click');

                await TestPilotNavigator.navigateAndWait('/claims');
                GuardianGlobal.trackNavigation('/claims');
              },
              child: Text('Go to Claims Page'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              key: Key('navigate_to_profile_button'),
              onPressed: () async {
                GuardianGlobal.trackVariable('user_action', 'profile_navigation', context: 'button_click');

                await TestPilotNavigator.navigateAndWait('/profile');
                GuardianGlobal.trackNavigation('/profile');
              },
              child: Text('Go to Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 20),
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tracked Variables:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Policy Name: $policyName'),
                    Text('Policy Number: ${policyNumber.isEmpty ? "empty" : policyNumber}'),
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
  @override
  _ClaimsPageState createState() => _ClaimsPageState();
}

class _ClaimsPageState extends State<ClaimsPage> {
  String apiPayload = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    GuardianGlobal.trackVariable('current_page', 'ClaimsPage', context: 'navigation');

    // Get the policy number from previous page
    String policyNum = GuardianGlobal.getVariable('policy_number') ?? "";
    GuardianGlobal.trackVariable('received_policy_number', policyNum, context: 'page_init');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Claims'),
        backgroundColor: Colors.orange,
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
                    Text('API Payload Preview:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(apiPayload.isEmpty ? 'No payload generated' : apiPayload),
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
                String policyData = GuardianGlobal.getVariable('policy_number') ?? "";
                String policyName = GuardianGlobal.getVariable('policy_name') ?? "";

                // Simulate the mistake - sometimes developers send name instead of number
                String payloadContent = '''
{
  "policy_id": "$policyData",
  "policy_name": "$policyName",
  "claim_type": "medical",
  "timestamp": "${DateTime.now().toIso8601String()}"
}''';

                setState(() {
                  apiPayload = payloadContent;
                  isLoading = false;
                });

                GuardianGlobal.trackVariable('api_payload', payloadContent, context: 'payload_generation');
                GuardianGlobal.trackVariable('payload_policy_id', policyData, context: 'critical_field');
              },
              child: isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Generate API Payload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              key: Key('back_button'),
              onPressed: () {
                TestPilotNavigator.pop();
              },
              child: Text('Back to Home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Profile Page (Simple)
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    GuardianGlobal.trackVariable('current_page', 'ProfilePage', context: 'navigation');

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.green,
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
                    Text('User Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              child: Text('Back to Home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
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