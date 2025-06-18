import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'carousel.dart';
import 'dogs_records.dart';
import 'pickup_tracking_page.dart';
import 'abc_centre_records_page.dart';
//import 'report_analysis_page.dart';
import 'auth_service.dart';
import 'settings_page.dart';
import 'report_analysis_page.dart';
class HomePage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Authentication logic for both login and sign-up
  Future<void> authLogic(BuildContext context, bool isSignUp) async {
    try {
      final AuthService authService = AuthService();
      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      User? user;
      if (isSignUp) {
        user = await authService.signUp(context, email, password);
      } else {
        user = await authService.signIn(context, email, password);
      }

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isSignUp ? "Signed up" : "Logged in"} as ${user.email}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isSignUp ? "Sign-up" : "Login"} failed')),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    }
  }

  // Show Sign Up Dialog
  void showSignUpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _buildAuthDialog(context, true), // Pass true for sign-up
    );
  }

  // Show Login Dialog
  void showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _buildAuthDialog(context, false), // Pass false for login
    );
  }

  // Build the Auth Dialog (Login/Sign-up)
  Widget _buildAuthDialog(BuildContext context, bool isSignUp) {
    return AlertDialog(
      title: Text(isSignUp ? 'Sign Up' : 'Login'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await authLogic(context, isSignUp); // Call auth logic based on type
          },
          child: Text(isSignUp ? 'Sign Up' : 'Login'),
        ),
      ],
    );
  }

  // Logout logic
  Future<void> logoutLogic(BuildContext context) async {
    try {
      final AuthService authService = AuthService();
      await authService.signOut(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 3.0,
                color: Colors.deepPurpleAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: const BorderSide(color: Colors.white, width: 1.0),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'StrayTrack',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.account_circle_sharp),
                  onPressed: () => showLoginDialog(context),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder:(context)=> SettingsPage()),
                    );
                  }, // Show Sign Up Dialog
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => logoutLogic(context),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Carousel(),
          Expanded(child: Container()), // Spacer to push buttons to the bottom
          _buildButtonGrid(context),
        ],
      ),
    );
  }

  Widget _buildButtonGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 5.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 10.0,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          final titles = [
            'Dogs Records',
            'Pickup Tracking',
            'ABC Centre Records',
            'Report Analysis'
          ];
          final pages = [
            DogsRecordsPage(),
            const PickupTrackingPage(),
            const ABCRecordsPage(),
            ReportAnalysisPage(),

          ];
          final colors = [
            Colors.blue,
            Colors.green,
            Colors.orange,
            Colors.red
          ];

          return _buildButton(context, titles[index], pages[index], colors[index]);
        },
      ),
    );
  }

  Widget _buildButton(BuildContext context, String title, Widget page, Color color) {
    return SizedBox(
      width: double.infinity,
      height:double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(fontSize: 25, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}