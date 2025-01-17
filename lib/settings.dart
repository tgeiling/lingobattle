import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'auth.dart';

class SettingsPage extends StatelessWidget {
  final bool Function() isLoggedIn;
  final Function(bool) setAuthenticated;

  const SettingsPage({
    Key? key,
    required this.isLoggedIn,
    required this.setAuthenticated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (!isLoggedIn())
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
          if (isLoggedIn())
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: 8,
          color: Colors.grey[200],
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.grey[600]),
          title: Text(
            title,
            style: const TextStyle(color: Colors.black),
          ),
          onTap: onTap,
        ),
      ),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          title,
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: Center(
        child: Text(title),
      ),
    );
  }
}
