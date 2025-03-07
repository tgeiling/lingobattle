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

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (username.isNotEmpty)
              FriendsButton(
                username: username,
                onBackToMainMenu: onBackToMainMenu,
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 50),
                  const SizedBox(height: 16), // More spacing
                  const Text(
                    "You need to set a username to add friends.",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            const SizedBox(height: 30), // Increased spacing
            const Text(
              "More coming soon",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
