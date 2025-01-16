import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth.dart';

class SettingsPage extends StatelessWidget {
  final Function(bool) setAuthenticated;

  const SettingsPage({
    Key? key,
    required this.setAuthenticated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          _SettingsTile(
            title: 'Login',
            icon: Icons.login,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(
                    setAuthenticated: setAuthenticated,
                  ),
                ),
              );
            },
          ),
          _SettingsTile(
            title: 'Logout',
            icon: Icons.logout,
            onTap: () {
              final authService = AuthService();
              authService.logout();
              setAuthenticated(false);
            },
          ),
          _SettingsTile(
            title: 'AGB',
            icon: Icons.article,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlaceholderPage(title: 'AGB'),
                ),
              );
            },
          ),
          _SettingsTile(
            title: 'Data Privacy',
            icon: Icons.privacy_tip,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const PlaceholderPage(title: 'Data Privacy'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsTile({
    Key? key,
    required this.title,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        title,
        style: const TextStyle(color: Colors.black),
      ),
      onTap: onTap,
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Text(title),
      ),
    );
  }
}
