import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingobattle/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'provider.dart';

class Ranks extends StatelessWidget {
  final String currentLanguage;

  const Ranks({Key? key, required this.currentLanguage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profile, child) {
        int elo = profile.getElo(currentLanguage);
        String imagePath = _getEloImage(elo);
        String rankText = _getRank(elo, context);

        return GestureDetector(
          onTap: () => _showEloDialog(context, profile),
          child: Container(
            padding: isTablet(context)
                ? EdgeInsets.symmetric(horizontal: 36, vertical: 4)
                : EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey[500],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  rankText,
                  style: GoogleFonts.pressStart2p(
                    fontSize: isTablet(context) ? 32 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Image.asset(
                  'assets/ranks/$imagePath.png',
                  width: isTablet(context) ? 250 : 180,
                  height: isTablet(context) ? 60 : 46,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEloDialog(BuildContext context, ProfileProvider profile) {
    Map<String, int> eloMap = profile.getEloMap();
    List<MapEntry<String, int>> nonZeroEloEntries =
        eloMap.entries.where((entry) => entry.value > 0).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.elo_progression),
          content: SizedBox(
            height: 350,
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (nonZeroEloEntries.isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context)!.elo_by_language,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: nonZeroEloEntries.map((entry) {
                        return Text(
                          "${entry.key.toUpperCase()}: ${entry.value}",
                          style: const TextStyle(fontSize: 16),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ...List.generate(16, (index) {
                    int eloValue = index * 100;
                    String rank = _getRank(eloValue, context);
                    String imagePath = _getEloImage(eloValue);

                    return ListTile(
                      leading: Image.asset(
                        'assets/ranks/$imagePath.png',
                        width: 40,
                        height: 40,
                      ),
                      title: Text(AppLocalizations.of(context)!
                          .title_rank_step(rank, (index % 4) + 1)),
                      subtitle: Text(
                          AppLocalizations.of(context)!.subtitle_elo(eloValue)),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  String _getEloImage(int elo) {
    List<String> ranks = ['baby', 'beginner', 'novice', 'expert'];
    int step = (elo ~/ 100) % 4 + 1;
    int rankIndex = (elo ~/ 400).clamp(0, ranks.length - 1);
    return '${ranks[rankIndex]}0$step';
  }

  String _getRank(int elo, BuildContext context) {
    if (elo < 400) return AppLocalizations.of(context)!.ranking_baby;
    if (elo < 800) return AppLocalizations.of(context)!.ranking_beginner;
    if (elo < 1200) return AppLocalizations.of(context)!.ranking_novice;
    return AppLocalizations.of(context)!.ranking_expert;
  }
}
