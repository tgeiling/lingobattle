import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services.dart';
import 'level.dart';

class ProfileProvider with ChangeNotifier {
  int _winStreak = 0;
  int _exp = 0;
  int _completedLevels = 0;
  int _completedLevelsTotal = 0;
  String _lastUpdateString = "";

  int get winStreak => _winStreak;
  int get exp => _exp;
  int get completedLevels => _completedLevels;
  int get completedLevelsTotal => _completedLevelsTotal;
  String get lastUpdateString => _lastUpdateString;

  ProfileProvider() {
    loadPreferences();
  }

  void setWinStreak(int streak) {
    _winStreak = streak;
    notifyListeners();
    savePreferences();
  }

  void setExp(int experience) {
    _exp = experience;
    notifyListeners();
    savePreferences();
  }

  void setCompletedLevels(int completedLevels) {
    _completedLevels = completedLevels;
    notifyListeners();
    savePreferences();
  }

  void setCompletedLevelsTotal(int completedLevelsTotal) {
    _completedLevelsTotal = completedLevelsTotal;
    notifyListeners();
    savePreferences();
  }

  void setLastUpdateString(int completedLevels) {
    _completedLevels = completedLevels;
    notifyListeners();
    savePreferences();
  }

  void incrementWinStreak() {
    _winStreak++;
    notifyListeners();
    savePreferences();
  }

  void addExp(int points) {
    _exp += points;
    notifyListeners();
    savePreferences();
  }

  void incrementCompletedLevels() {
    _completedLevels++;
    notifyListeners();
    savePreferences();
  }

  Future<void> loadPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _winStreak = prefs.getInt('winStreak') ?? 0;
    _exp = prefs.getInt('exp') ?? 0;
    _completedLevels = prefs.getInt('completedLevels') ?? 0;
    _completedLevelsTotal = prefs.getInt('completedLevelsTotal') ?? 0;
    _lastUpdateString = prefs.getString('lastUpdateString') ?? "";
    notifyListeners();
  }

  Future<void> savePreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('winStreak', _winStreak);
    await prefs.setInt('exp', _exp);
    await prefs.setInt('completedLevels', _completedLevels);
    await prefs.setInt('completedLevelsTotal', _completedLevelsTotal);
    await prefs.setString('lastUpdateString', _lastUpdateString);
  }
}

class LevelNotifier with ChangeNotifier {
  Map<String, Map<int, Level>> _languageLevels = {};
  String _selectedLanguage = 'English';

  Map<int, Level> get levels => _languageLevels[_selectedLanguage] ?? {};

  String get selectedLanguage => _selectedLanguage;

  int get completedLevels =>
      levels.values.where((level) => level.isDone).length;

  LevelNotifier() {
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Define levels for each language
    Map<String, Map<int, Level>> tempLanguageLevels = {
      'English': {
        1: Level(id: 1, description: "Introduction to English", reward: 100),
        2: Level(id: 2, description: "Basic Vocabulary", reward: 100),
        3: Level(id: 3, description: "Simple Sentences", reward: 100),
        4: Level(id: 4, description: "Grammar Basics", reward: 100),
        5: Level(id: 5, description: "Common Phrases", reward: 100),
        6: Level(id: 6, description: "Listening Practice", reward: 100),
        7: Level(id: 7, description: "Daily Conversation", reward: 100),
        8: Level(id: 8, description: "Reading Practice", reward: 100),
        9: Level(id: 9, description: "Writing Basics", reward: 100),
        10: Level(id: 10, description: "Advanced Vocabulary", reward: 100),
      },
      'German': {
        1: Level(id: 1, description: "Einführung in Deutsch", reward: 100),
        2: Level(id: 2, description: "Grundwortschatz", reward: 100),
        3: Level(id: 3, description: "Einfache Sätze", reward: 100),
        4: Level(id: 4, description: "Grammatik Grundlagen", reward: 100),
        5: Level(id: 5, description: "Alltägliche Ausdrücke", reward: 100),
        6: Level(id: 6, description: "Hörverstehen", reward: 100),
        7: Level(id: 7, description: "Alltagsgespräche", reward: 100),
        8: Level(id: 8, description: "Leseübungen", reward: 100),
        9: Level(id: 9, description: "Schreibübungen", reward: 100),
        10: Level(id: 10, description: "Fortgeschrittene Wörter", reward: 100),
      },
      'Spanish': {
        1: Level(id: 1, description: "Introducción al español", reward: 100),
        2: Level(id: 2, description: "Vocabulario básico", reward: 100),
        3: Level(id: 3, description: "Frases simples", reward: 100),
        4: Level(id: 4, description: "Gramática básica", reward: 100),
        5: Level(id: 5, description: "Frases comunes", reward: 100),
        6: Level(id: 6, description: "Práctica de escucha", reward: 100),
        7: Level(id: 7, description: "Conversaciones diarias", reward: 100),
        8: Level(id: 8, description: "Práctica de lectura", reward: 100),
        9: Level(id: 9, description: "Escritura básica", reward: 100),
        10: Level(id: 10, description: "Vocabulario avanzado", reward: 100),
      },
      'Dutch': {
        1: Level(id: 1, description: "Introductie tot Nederlands", reward: 100),
        2: Level(id: 2, description: "Basiswoordenschat", reward: 100),
        3: Level(id: 3, description: "Eenvoudige zinnen", reward: 100),
        4: Level(id: 4, description: "Grammatica Basis", reward: 100),
        5: Level(
            id: 5, description: "Veelgebruikte uitdrukkingen", reward: 100),
        6: Level(id: 6, description: "Luistervaardigheid", reward: 100),
        7: Level(id: 7, description: "Dagelijkse gesprekken", reward: 100),
        8: Level(id: 8, description: "Leesvaardigheid", reward: 100),
        9: Level(id: 9, description: "Schrijfvaardigheid", reward: 100),
        10: Level(
            id: 10, description: "Geavanceerde woordenschat", reward: 100),
      },
      'Swiss': {
        1: Level(
            id: 1, description: "Einführung ins Schweizerdeutsch", reward: 100),
        2: Level(
            id: 2,
            description: "Grundwortschatz Schweizerdeutsch",
            reward: 100),
        3: Level(id: 3, description: "Einfache Sätze", reward: 100),
        4: Level(id: 4, description: "Grundlagen der Grammatik", reward: 100),
        5: Level(
            id: 5, description: "Häufig verwendete Ausdrücke", reward: 100),
        6: Level(id: 6, description: "Hörverständnis", reward: 100),
        7: Level(id: 7, description: "Alltagsgespräche", reward: 100),
        8: Level(id: 8, description: "Leseübungen", reward: 100),
        9: Level(id: 9, description: "Schreibübungen", reward: 100),
        10: Level(
            id: 10, description: "Fortgeschrittene Wortschatz", reward: 100),
      },
    };

    // Load levels and their completion statuses from SharedPreferences
    for (var language in tempLanguageLevels.keys) {
      _languageLevels[language] = {
        for (var entry in tempLanguageLevels[language]!.entries)
          entry.key: Level(
            id: entry.value.id,
            description: entry.value.description,
            reward: entry.value.reward,
            isDone:
                prefs.getBool('${language}_level_${entry.value.id}_isDone') ??
                    false,
          ),
      };
    }

    notifyListeners();
  }

  void selectLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  void updateLevelStatus(int levelId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_selectedLanguage}_level_${levelId}_isDone', true);

    _languageLevels[_selectedLanguage]?[levelId]?.isDone = true;
    notifyListeners();
  }
}
