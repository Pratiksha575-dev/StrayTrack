import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false;
  String selectedLanguage = 'English'; // Default language

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load the settings (theme, language) from SharedPreferences
  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load theme preference
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false; // Default to light mode
      selectedLanguage = prefs.getString('language') ?? 'English'; // Default language
    });
  }

  // Save theme preference when toggled
  Future<void> _toggleTheme(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = value;
      prefs.setBool('isDarkMode', value);
    });
    // Apply the theme change dynamically
    MyApp.themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  // Save language preference when selected
  Future<void> _changeLanguage(String language) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedLanguage = language;
      prefs.setString('language', language);
    });
    // You can also add logic to apply the language change globally if needed
    print("Language changed to: $language");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              // Implement log out functionality if required
              // FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          // Dark Mode Toggle
          ListTile(
            title: const Text("Dark Mode"),
            trailing: Switch(
              value: isDarkMode,
              onChanged: _toggleTheme,
            ),
          ),

          // Language Selection
          ListTile(
            title: const Text("Language"),
            trailing: DropdownButton<String>(
              value: selectedLanguage,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _changeLanguage(newValue);
                }
              },
              items: <String>['English', 'Spanish', 'French', 'German']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),

          // Notifications Settings
          ListTile(
            title: const Text("Notifications"),
            trailing: Switch(
              value: true, // Replace with actual notification status
              onChanged: (value) {
                // Implement notification toggle functionality
                print("Notification toggled: $value");
              },
            ),
          ),

          // About Section
          ListTile(
            title: const Text("About"),
            onTap: () {
              // Navigate to about page or show a dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("About This App"),
                    content: const Text("This is a demo app."),
                    actions: <Widget>[
                      TextButton(
                        child: const Text("OK"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
