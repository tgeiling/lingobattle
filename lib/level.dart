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
          LanguageSelector(),
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
                    showCustomDialog(
                      context: context,
                      modalDescription: level.description,
                      levelId: level.id,
                      isAuthenticated: true,
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

    return GestureDetector(
      onTap: isNext || isDone ? onTap : null,
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
    );
  }
}

class LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final levelNotifier = Provider.of<LevelNotifier>(context);

    // Map of language to flag assets
    final Map<String, String> languageFlags = {
      'English': 'assets/netherlands.png',
      'German': 'assets/german.png',
      'Spanish': 'assets/schweiz.png',
    };

    return Container(
      width: double.infinity, // Makes the dropdown full width
      padding: const EdgeInsets.symmetric(horizontal: 16), // Optional padding
      child: DropdownButton<String>(
        isExpanded: true, // Ensures the dropdown stretches to full width
        value: levelNotifier.selectedLanguage,
        items: languageFlags.keys.map((language) {
          return DropdownMenuItem<String>(
            value: language,
            child: Row(
              children: [
                Image.asset(
                  languageFlags[language]!,
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 8), // Spacing between flag and text
                Text(language),
              ],
            ),
          );
        }).toList(),
        onChanged: (newLanguage) {
          if (newLanguage != null) {
            levelNotifier.selectLanguage(newLanguage);
          }
        },
      ),
    );
  }
}
