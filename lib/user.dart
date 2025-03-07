import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'friends.dart';
import 'provider.dart';

class UserPage extends StatelessWidget {
  final VoidCallback onBackToMainMenu;

  const UserPage({
    Key? key,
    required this.onBackToMainMenu,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final String username = profileProvider.username;

    return Column(
      children: [
        if (username.isNotEmpty)
          FriendsButton(
            username: username,
            onBackToMainMenu: onBackToMainMenu,
          )
        else
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Prevents infinite height
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 50),
                const SizedBox(height: 10),
                const Text(
                  "You need to set a username to add friends.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        const Text("Coming soon"),
      ],
    );
  }
}
