import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) toggleDarkMode;
  final MaterialColor currentColor;
  final Function(MaterialColor) changeThemeColor;

  const SettingsPage({
    super.key,
    required this.isDarkMode,
    required this.toggleDarkMode,
    required this.currentColor,
    required this.changeThemeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: currentColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Dark mode toggle
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: isDarkMode,
            onChanged: toggleDarkMode,
            secondary: const Icon(Icons.dark_mode),
          ),

          const Divider(height: 32),

          const Text(
            'Theme Color',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            children: Colors.primaries.map((color) {
              return GestureDetector(
                onTap: () => changeThemeColor(color),
                child: CircleAvatar(
                  backgroundColor: color,
                  child: currentColor == color
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 40),
          const Divider(height: 32),

          // 🔴 Logout button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
