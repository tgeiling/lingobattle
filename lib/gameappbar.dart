import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'friends.dart';
import 'provider.dart';
import 'battlerequests.dart';

class GameAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBackToMainMenu;

  const GameAppBar({Key? key, required this.onBackToMainMenu})
      : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(65);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double iconSize = screenWidth * 0.05; // Adaptive icon size
    final double fontSize = screenWidth * 0.035; // Adaptive font size
    final double pillPadding = screenWidth * 0.02; // Dynamic padding for pills

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
        toolbarHeight: 65,
        title: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 🔹 Left Side: Username Pill
                _gamePill(
                  icon: Icons.person,
                  text: profile.username,
                  color: Colors.blueAccent,
                  fontSize: fontSize,
                  iconSize: iconSize,
                  padding: pillPadding,
                ),

                // 🔹 Center: Battle Requests & Friends
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BattleRequestsButton(
                        username: profile.username,
                        onBackToMainMenu: onBackToMainMenu,
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      FriendsButton(
                        username: profile.username,
                        onBackToMainMenu: onBackToMainMenu,
                      ),
                    ],
                  ),
                ),

                // 🔹 Right Side: Stats (Coins & Win Streak)
                Row(
                  children: [
                    _gamePill(
                      iconPath: 'assets/button_green.png',
                      text: '${profile.coins}',
                      color: Colors.yellowAccent,
                      fontSize: fontSize,
                      iconSize: iconSize,
                      padding: pillPadding,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    _gamePill(
                      iconPath: 'assets/flame.png',
                      text: '${profile.winStreak}',
                      color: Colors.redAccent,
                      fontSize: fontSize,
                      iconSize: iconSize,
                      padding: pillPadding,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // 🔹 Optimized Game Pill Widget
  Widget _gamePill({
    IconData? icon,
    String? iconPath,
    required String text,
    required Color color,
    required double fontSize,
    required double iconSize,
    required double padding,
  }) {
    // 🔹 Trim username to 9 characters and add "..."
    String displayText = text.length > 9 ? "${text.substring(0, 9)}..." : text;

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.5), blurRadius: 3),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, color: color, size: iconSize)
          else
            Image.asset(iconPath!, width: iconSize, height: iconSize),
          SizedBox(width: padding * 0.5),
          Text(
            displayText,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
