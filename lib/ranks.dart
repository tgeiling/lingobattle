import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'provider.dart';

class Ranks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profile, child) {
        int elo = profile.elo;
        String imagePath = _getEloImage(elo);
        String rankText = _getRank(elo);

        return GestureDetector(
          onTap: () => _showEloDialog(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 120, bottom: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      rankText,
                      style: GoogleFonts.pressStart2p(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Image.asset(
                      'assets/ranks/$imagePath.png',
                      width: 200,
                      height: 100,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEloDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("ELO Progression"),
          content: Container(
            height: 300,
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(16, (index) {
                  int eloValue = index * 100;
                  String rank = _getRank(eloValue);
                  String imagePath = _getEloImage(eloValue);

                  return ListTile(
                    leading: Transform.scale(
                      scale: 3.0,
                      child: Image.asset(
                        'assets/ranks/$imagePath.png',
                        width: 20,
                        height: 20,
                      ),
                    ),
                    title: Text('$rank - Step ${(index % 4) + 1}'),
                    subtitle: Text('ELO: $eloValue'),
                  );
                }),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  String _getEloImage(int elo) {
    List<String> ranks = ['baby', 'beginner', 'novice', 'expert'];
    int step = (elo / 100).floor() % 4 + 1;
    int rankIndex = (elo / 400).floor().clamp(0, ranks.length - 1);
    return '${ranks[rankIndex]}0$step';
  }

  String _getRank(int elo) {
    if (elo < 400) return 'Baby';
    if (elo < 800) return 'Beginner';
    if (elo < 1200) return 'Novice';
    return 'Expert';
  }
}
