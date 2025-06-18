import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'auth_dialogs.dart';// Import custom dialogs for sign-up/sign-in
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("Loading env...");
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp();

  // Load theme preference from SharedPreferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(MyApp(initialThemeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light));
}

class MyApp extends StatelessWidget {
  final ThemeMode initialThemeMode;
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  MyApp({required this.initialThemeMode}) {
    themeNotifier.value = initialThemeMode;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, ThemeMode currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: currentMode,
          home: AuthWrapper(), // AuthWrapper to handle login status
        );
      },
    );
  }

  // Method to toggle theme and save preference
  static Future<void> toggleTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (themeNotifier.value == ThemeMode.light) {
      themeNotifier.value = ThemeMode.dark;
      await prefs.setBool('isDarkMode', true);
    } else {
      themeNotifier.value = ThemeMode.light;
      await prefs.setBool('isDarkMode', false);
    }
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Listen for auth state changes
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading indicator while checking auth state
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          // User is signed in, go to HomePage
          return HomePage();
        } else {
          // User is not signed in, show SignUpSignInPage
          return const SignUpSignInPage();
        }
      },
    );
  }
}

class SignUpSignInPage extends StatelessWidget {
  const SignUpSignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login / Sign Up"),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              MyApp.toggleTheme(); // Toggle theme on button press
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Show the Sign-Up dialog
                showDialog(
                  context: context,
                  builder: (context) => const SignUpDialog(),
                );
              },
              child: const Text('Sign Up'),
            ),
            ElevatedButton(
              onPressed: () {
                // Show the Sign-In dialog
                showDialog(
                  context: context,
                  builder: (context) => const SignInDialog(),
                );
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
