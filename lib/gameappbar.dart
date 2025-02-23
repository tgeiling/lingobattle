import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'provider.dart';

class GameAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profile, child) => AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey.shade400, Colors.grey.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        toolbarHeight: 80,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 🔹 Username on the left
            _gamePill(
              icon: Icons.person,
              text: profile.username,
              color: Colors.blueAccent,
            ),

            // 🔹 Right side (🔥 Streak next to 👑 ELO)
            Row(
              children: [
                _gamePill(
                  iconPath: 'assets/flame.png',
                  text: '${profile.winStreak}',
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 12), // Space between streak & ELO
                _gamePill(
                  iconPath: 'assets/crown.png',
                  text: '${profile.elo}',
                  color: Colors.amber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Truncates long usernames
  String _formatUsername(String username) {
    return username.length > 10 ? '${username.substring(0, 10)}...' : username;
  }

  // 🔹 Reusable Pill Widget for Stats
  Widget _gamePill({
    IconData? icon,
    String? iconPath,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.8),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.5), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon != null
              ? Icon(icon, color: color, size: 20)
              : Image.asset(iconPath!, width: 22, height: 22),
          const SizedBox(width: 6),
          Text(
            text,
            overflow: TextOverflow.ellipsis, // Ensures text doesn’t overflow
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
