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
  Map<int, Level> _levels = {};

  Map<int, Level> get levels => _levels;

  int get completedLevels =>
      _levels.values.where((level) => level.isDone).length;

  LevelNotifier() {
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<int, Level> tempLevels = {
      1: Level(
          id: 1,
          description: "Erste Schritte zur Rückengesundheit",
          minutes: 13),
      2: Level(id: 2, description: "Schritt 2 für deinen Rücken", minutes: 12),
      3: Level(id: 3, description: "Alle guten Dinge sind 3", minutes: 14),
      4: Level(id: 4, description: "Fokus auf Unteren Rücken", minutes: 11),
      5: Level(
          id: 5,
          description: "Zu einfach? Passe dein Fitnesslevel an",
          reward: "Gold Coin",
          minutes: 6),
      6: Level(id: 6, description: "Die meisten geben hier auf!", minutes: 6),
      7: Level(id: 7, description: "Rückenschmerzen hartnäckig?", minutes: 6),
      8: Level(id: 8, description: "Du bist auf einem gutem Weg", minutes: 6),
      9: Level(id: 9, description: "Fokus auf Hüfte", minutes: 6),
      10: Level(
          id: 10,
          description: "Schon fast 10 Level geschafft",
          reward: "Gold Coin",
          minutes: 6),
      11: Level(id: 11, description: "Fokus auf Schultern", minutes: 6),
      12: Level(
          id: 12,
          description: "Jetzt hast du bald alles ausprobiert",
          minutes: 6),
      13: Level(id: 13, description: "Lange Meditation", minutes: 6),
      14: Level(id: 14, description: "Fokus auf Unterer Rücken", minutes: 6),
      15: Level(
          id: 15,
          description: "Schau wie weit du schon bist!",
          reward: "Gold Coin",
          minutes: 6),
      16: Level(id: 16, description: "Noch 4 Level!", minutes: 6),
      17: Level(id: 17, description: "Noch 3 Level!", minutes: 6),
      18: Level(id: 18, description: "Noch 2 Level!", minutes: 6),
      19: Level(id: 19, description: "Noch 1 Level!", minutes: 6),
      20: Level(
          id: 20,
          description: "20 Übungen machen eine Gewohnheit",
          reward: "Gold Coin",
          minutes: 6),
    };

    _levels = {
      for (var entry in tempLevels.entries)
        entry.key: Level(
          id: entry.value.id,
          description: entry.value.description,
          minutes: entry.value.minutes,
          reward: entry.value.reward,
          isDone: prefs.getBool('level_${entry.value.id}_isDone') ?? false,
        ),
    };

    notifyListeners();
  }

  void updateLevelStatus(int levelId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('level_${levelId}_isDone', true);
    await prefs.setInt('completedLevels', completedLevels + 1);

    int? completedLevelsTotal = await prefs.getInt('completedLevelsTotal');

    getAuthToken().then((token) {
      if (token != null) {
        updateProfile(
          token: token,
          completedLevels: levelId,
          completedLevelsTotal: completedLevelsTotal!,
        ).then((success) {
          if (success) {
            print("Profile updated successfully.");
          } else {
            print("Failed to update profile.");
          }
        });
      } else {
        print("No auth token available.");
      }
    });

    _levels[levelId]?.isDone = true;
    notifyListeners();
  }

  void updateLevelStatusSync(int levelId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('level_${levelId}_isDone', true);

    _levels[levelId]?.isDone = true;
    _loadLevels();
    notifyListeners();
  }

  void loadLevelsAfterStart() async {
    _loadLevels();
    notifyListeners();
  }

  void earaseLevelStatusSync(int levelId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('level_${levelId}_isDone', false);

    _levels[levelId]?.isDone = true;
    _loadLevels();
    notifyListeners();
  }
}
