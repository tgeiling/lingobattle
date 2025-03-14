import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'provider.dart';
import 'game.dart';

bool isModalOpen = false;
String selectedLanguage = "english";

class Level {
  final int id;
  final String description;
  final int reward;
  bool isDone;
  final List<Map<String, dynamic>> questions;

  Level({
    required this.id,
    required this.description,
    required this.reward,
    this.isDone = false,
    required this.questions,
  });

  // Serialize the Level object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'reward': reward,
      'isDone': isDone,
      'questions': questions,
    };
  }

  // Deserialize a Level object from JSON
  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'],
      description: json['description'],
      reward: json['reward'],
      isDone: json['isDone'],
      questions: List<Map<String, dynamic>>.from(json['questions']),
    );
  }
}

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({
    super.key,
  });

  @override
  _LevelSelectionScreenState createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen>
    with AutomaticKeepAliveClientMixin<LevelSelectionScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final levelNotifier = Provider.of<LevelNotifier>(context);
    final levels = levelNotifier.levels;

    return Container(
      child: Column(
        children: [
          LanguageSelector(), // Language selector remains at the top
          Expanded(
            child: ListView.builder(
              reverse: false,
              controller: _scrollController,
              itemCount: levels.length,
              itemBuilder: (context, index) {
                int levelId = levels.keys.toList()[index];
                Level level = levels[levelId]!;

                // Determine if this is the next level
                bool isNext = false;
                if (!level.isDone) {
                  int? maxDoneLevelId = levels.entries
                      .where((entry) => entry.value.isDone)
                      .map((entry) => entry.key)
                      .fold<int?>(
                          null,
                          (prev, element) => prev != null
                              ? (element > prev ? element : prev)
                              : element);

                  if (maxDoneLevelId == null) {
                    isNext = levelId == levels.keys.first;
                  } else {
                    if (levelId == maxDoneLevelId + 1) {
                      isNext = true;
                    }
                  }
                }

                return LevelListItem(
                  level: level.id,
                  description: level.description,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameScreen(
                            level: level, language: selectedLanguage),
                      ),
                    );
                  },
                  isTreasureLevel: level.id % 4 == 0,
                  isDone: level.isDone,
                  isNext: isNext,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class LevelListItem extends StatelessWidget {
  final int level;
  final String description;
  final VoidCallback onTap;
  final bool isTreasureLevel;
  final bool isDone;
  final bool isNext;

  const LevelListItem({
    super.key,
    required this.level,
    required this.description,
    required this.onTap,
    this.isTreasureLevel = false,
    this.isDone = false,
    this.isNext = false,
  });

  @override
  Widget build(BuildContext context) {
    String buttonImage;

    // Determine the button image based on level status
    if (isDone) {
      buttonImage = 'assets/button_green.png';
    } else if (isNext) {
      buttonImage = 'assets/button_mint.png';
    } else {
      buttonImage = 'assets/button_locked.png';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: 8,
          color: Colors.grey[200],
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        ),
        child: InkWell(
          onTap: isNext || isDone ? onTap : null,
          splashColor: Colors.blue.withOpacity(0.2),
          highlightColor: Colors.blue.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Button Image
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Image.asset(
                    buttonImage,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Stage $level",
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDone
                                  ? Colors.green
                                  : (isNext ? Colors.blue : Colors.grey),
                            ),
                      ),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Arrow Icon
                if (isNext || isDone)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: isNext ? Colors.blue : Colors.green,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final levelNotifier = Provider.of<LevelNotifier>(context);

    // Define the languages and their corresponding flag assets
    final Map<String, String> languagesWithFlags = {
      'English': 'assets/flags_20x20/english.png',
      'German': 'assets/flags_20x20/german.png',
      'Spanish': 'assets/flags_20x20/spanish.png',
      'Dutch': 'assets/flags_20x20/dutch.png',
    };

    // Check if the selected language exists in the map
    selectedLanguage = levelNotifier.selectedLanguage;
    if (!languagesWithFlags.containsKey(selectedLanguage)) {
      selectedLanguage =
          languagesWithFlags.keys.first; // Default to the first language
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButton<String>(
        value: selectedLanguage,
        isExpanded: true, // Ensures dropdown takes full width
        items: languagesWithFlags.entries.map((entry) {
          String language = entry.key.toLowerCase();
          String translatedLanguage;

          switch (language) {
            case "german":
              translatedLanguage =
                  AppLocalizations.of(context)!.language_german;
              break;
            case "english":
              translatedLanguage =
                  AppLocalizations.of(context)!.language_english;
              break;
            case "spanish":
              translatedLanguage =
                  AppLocalizations.of(context)!.language_spanish;
              break;
            case "dutch":
              translatedLanguage = AppLocalizations.of(context)!.language_dutch;
              break;
            default:
              translatedLanguage =
                  language; // Fallback in case of unexpected value
          }

          return DropdownMenuItem<String>(
            value: entry.key,
            child: Row(
              children: [
                Image.asset(
                  entry.value, // Path to the flag image
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 8), // Spacing between flag and text
                Text(translatedLanguage), // Language name
              ],
            ),
          );
        }).toList(),
        onChanged: (String? newLanguage) {
          if (newLanguage != null) {
            levelNotifier.selectLanguage(newLanguage);
          }
        },
      ),
    );
  }
}
