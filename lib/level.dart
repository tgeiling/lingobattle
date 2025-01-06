import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:lingobattle/elements.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stroke_text/stroke_text.dart';

import 'provider.dart';
import 'start.dart';
import 'services.dart';
import 'auth.dart';
import 'game.dart';

bool isModalOpen = false;

class Level {
  final int id;
  final String description;
  final int minutes;
  final String reward;
  bool isDone;

  Level(
      {required this.id,
      required this.description,
      this.minutes = 15,
      this.reward = '',
      this.isDone = false});
}

class LevelSelectionScreen extends StatefulWidget {
  final Function(String, int, bool) toggleModal;

  const LevelSelectionScreen({
    super.key,
    required this.toggleModal,
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(245, 245, 245, 0.894),
            Color.fromRGBO(160, 160, 160, 0.886),
          ],
        ),
      ),
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
                          levelId: level.id,
                          description: level.description,
                        ),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isNext || isDone ? onTap : null,
        splashColor: Colors.blue.withOpacity(0.2),
        highlightColor: Colors.blue.withOpacity(0.1),
        child: Column(
          children: [
            // List item
            Row(
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
            // Dotted Line
            if (!isNext)
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: SizedBox(
                  height: 20,
                  child: VerticalDivider(
                    color: Colors.grey,
                    thickness: 1,
                    width: 1,
                    endIndent: 0,
                    indent: 0,
                  ),
                ),
              ),
          ],
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
      'English': 'assets/flags/english.png',
      'German': 'assets/flags/german.png',
      'Spanish': 'assets/flags/spanish.png',
      'Dutch': 'assets/flags/dutch.png',
      'Swiss': 'assets/flags/swiss.png',
    };

    // Check if the selected language exists in the map
    String? selectedLanguage = levelNotifier.selectedLanguage;
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
                Text(entry.key), // Language name
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
