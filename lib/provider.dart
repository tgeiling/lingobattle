import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services.dart';
import 'level.dart';

class ProfileProvider with ChangeNotifier {
  int _winStreak = 0;
  int _exp = 0;
  String _completedLevelsJson = "{}"; // Stored as JSON String
  String _username = "";
  String _title = "";
  Map<String, int> _eloMap = {};
  int _skillLevel = 0;

  int get winStreak => _winStreak;
  int get exp => _exp;
  String get username => _username;
  String get title => _title;
  int getElo(String language) {
    return _eloMap[language] ?? 0; // Default to 0 if not set
  }

  Map<String, int> getEloMap() {
    return Map<String, int>.from(
        _eloMap); // Returns a copy to prevent modifications
  }

  int get skilllevel => _skillLevel;

  Map<String, int> get completedLevels {
    try {
      Map<String, dynamic> decoded = json.decode(_completedLevelsJson);
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      print("Error parsing completedLevels JSON: $e");
      return {};
    }
  }

  String get completedLevelsJson => _completedLevelsJson;

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

  void setCompletedLevels(String completedLevels) {
    _completedLevelsJson = completedLevels;
    print("Updated completedLevels: $_completedLevelsJson");
    notifyListeners();
    savePreferences();
  }

  void setUsername(String username) {
    _username = username;
    notifyListeners();
    savePreferences();
  }

  void setTitle(String title) {
    _title = title;
    notifyListeners();
    savePreferences();
  }

  void setElo(String language, int elo) {
    _eloMap[language] = elo;
    notifyListeners();
    savePreferences();
  }

  void setSkillLevel(int skillLevel) {
    _skillLevel = skillLevel;
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

  Future<void> savePreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('winStreak', _winStreak);
    await prefs.setInt('exp', _exp);
    await prefs.setString('username', _username);
    await prefs.setString('title', _title);
    await prefs.setInt('skillLevel', _skillLevel);
    await prefs.setString('language_levels', _completedLevelsJson);

    // Ensure all languages have default ELO before saving
    List<String> languages = ["english", "german", "dutch", "spanish"];
    for (String lang in languages) {
      _eloMap.putIfAbsent(lang, () => 0);
    }

    // Store elo map as JSON string
    await prefs.setString('eloMap', jsonEncode(_eloMap));
  }

  Future<void> loadPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _winStreak = prefs.getInt('winStreak') ?? 0;
    _exp = prefs.getInt('exp') ?? 0;
    _username = prefs.getString('username') ?? "";
    _title = prefs.getString('title') ?? "";
    _skillLevel = prefs.getInt('skillLevel') ?? 0;
    _completedLevelsJson = prefs.getString('language_levels') ?? "{}";

    // Load elo map
    String? eloJson = prefs.getString('eloMap');
    if (eloJson != null) {
      _eloMap = Map<String, int>.from(jsonDecode(eloJson));
    }

    // Ensure all languages have default ELO (avoid missing values)
    List<String> languages = ["english", "german", "dutch", "spanish"];
    for (String lang in languages) {
      _eloMap.putIfAbsent(lang, () => 0);
    }

    notifyListeners();
  }

  Future<void> syncProfile(String token) async {
    Map<String, dynamic>? profileData = await fetchProfile(token);
    if (profileData != null) {
      _winStreak = profileData['winStreak'] ?? _winStreak;
      _exp = profileData['exp'] ?? _exp;
      _username = profileData['username'] ?? _username;
      _title = profileData['title'] ?? _title;
      _skillLevel = profileData['skillLevel'] ?? _skillLevel;

      // Convert JSON elo data into a Map<String, int>
      if (profileData.containsKey('elo')) {
        _eloMap = Map<String, int>.from(profileData['elo']);
      }

      // Ensure all languages have default ELO (avoid missing values)
      List<String> languages = ["english", "german", "dutch", "spanish"];
      for (String lang in languages) {
        _eloMap.putIfAbsent(lang, () => 0);
      }

      notifyListeners();
      savePreferences();
      print("Profile synced successfully.");
    } else {
      print("Failed to sync profile.");
    }
  }
}

class LevelNotifier with ChangeNotifier {
  Map<String, Map<int, Level>> _languageLevels = {};
  String _selectedLanguage = 'English';

  Map<int, Level> get levels => _languageLevels[_selectedLanguage] ?? {};

  String get selectedLanguage => _selectedLanguage;

  /// Returns the completed levels count for the selected language
  int get completedLevels =>
      _languageLevels[_selectedLanguage]
          ?.values
          .where((level) => level.isDone)
          .length ??
      0;

  LevelNotifier() {
    _loadLanguages();
  }

  void loadLevelsAfterStart() async {
    _loadLanguages();
    notifyListeners();
  }

  Future<void> _loadLanguages() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load saved levels data from SharedPreferences
    String? savedData = prefs.getString('language_levels');

    if (savedData != null && savedData.isNotEmpty) {
      try {
        // Check if the JSON is double-encoded (string inside string)
        if (savedData.startsWith('"') && savedData.endsWith('"')) {
          savedData = json.decode(savedData); // Decode once if needed
        }

        // Deserialize JSON and populate _languageLevels
        Map<String, dynamic> jsonData = json.decode(savedData!);

        _languageLevels = jsonData.map((lang, levels) {
          return MapEntry(
            lang,
            (levels as Map<String, dynamic>).map((key, value) {
              if (value is Map<String, dynamic>) {
                Level level = Level.fromJson(value);

                // Ensure isDone is correctly set from the JSON data
                level.isDone = value['isDone'] ?? false;

                return MapEntry(int.parse(key), level);
              } else {
                throw Exception("Invalid value structure for level data.");
              }
            }),
          );
        });

        print("Successfully loaded levels from SharedPreferences!");
      } catch (e) {
        print("Error deserializing language levels: $e");
        _initializeDefaultLevels(); // Initialize default levels in case of error
      }
    } else {
      // Initialize default levels if no data is saved
      _initializeDefaultLevels();
      print("⚠ No saved data found. Initializing default levels.");
    }

    notifyListeners();
  }

  Future<void> saveLanguages() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Serialize _languageLevels to JSON and save it
    String jsonData = json.encode(_languageLevels.map((lang, levels) {
      return MapEntry(
        lang,
        levels.map((key, level) => MapEntry(key.toString(), level.toJson())),
      );
    }));

    getAuthToken().then((token) {
      if (token != null) {
        updateProfile(
          token: token,
          completedLevels: jsonData,
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

    await prefs.setString('language_levels', jsonData);
  }

  Future<void> saveLanguagesSync() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Serialize _languageLevels to JSON and save it
    String jsonData = json.encode(_languageLevels.map((lang, levels) {
      return MapEntry(
        lang,
        levels.map((key, level) => MapEntry(key.toString(), level.toJson())),
      );
    }));

    await prefs.setString('language_levels', jsonData);
  }

  void selectLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  void updateLevelStatus(String language, int levelId) async {
    _languageLevels[language]?[levelId]?.isDone = true;

    notifyListeners();
    await saveLanguages();
  }

  void updateLanguageLevels(String language, int maxCompletedLevel) {
    if (_languageLevels.containsKey(language)) {
      _languageLevels[language]?.forEach((levelId, level) {
        if (levelId <= maxCompletedLevel) {
          level.isDone = true;
        }
      });
      notifyListeners();
      saveLanguages(); // Save changes after updating levels
    } else {
      print("Language $language does not exist in the level data.");
    }
  }

  void updateLevelsFromMap(Map<String, int> completedLevels) {
    completedLevels.forEach((language, maxCompletedLevel) {
      updateLanguageLevels(language, maxCompletedLevel);
    });
    notifyListeners();
  }

/*   void updateLevelStatusSync(int levelId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('level_${levelId}_isDone', true);

    _levels[levelId]?.isDone = true;
    _loadLevels();
    notifyListeners();
  } */

  void loadCompletedLevels(String language, int maxCompletedLevel) {
    if (_languageLevels.containsKey(language)) {
      _languageLevels[language]?.forEach((levelId, level) {
        if (levelId <= maxCompletedLevel) {
          level.isDone = true;
        }
      });
    }
    notifyListeners();
  }

  void _initializeDefaultLevels() {
    // Populate default levels (you already have this structure)
    _languageLevels = {
      'English': {
        1: Level(
          id: 1,
          description: "Introduction to English",
          reward: 100,
          questions: [
            {
              "question": "Hello, how _____ you?",
              "answers": ["are"],
              "type": "fill"
            },
            {
              "question": "Apfel",
              "answers": ["Apple", "Mapple", "Gover", "Rover"],
              "type": "pick"
            },
            {
              "question": "She is sitting _____ the chair.",
              "answers": ["on"],
              "type": "fill"
            },
            {
              "question": "We are going _____ the park.",
              "answers": ["to"],
              "type": "fill"
            },
            {
              "question": "He plays football _____ the evening.",
              "answers": ["in"],
              "type": "fill"
            },
          ],
        ),
        2: Level(
          id: 2,
          description: "Basic Vocabulary",
          reward: 100,
          questions: [
            {
              "question": "I am _____ my homework now.",
              "answers": ["doing"],
              "type": "fill"
            },
            {
              "question": "They are _____ to the cinema.",
              "answers": ["going"],
              "type": "fill"
            },
            {
              "question": "The dog is sleeping _____ the couch.",
              "answers": ["on"],
              "type": "fill"
            },
            {
              "question": "He is interested _____ music.",
              "answers": ["in"],
              "type": "fill"
            },
            {
              "question": "The book is _____ the bag.",
              "answers": ["in"],
              "type": "fill"
            },
          ],
        ),
        3: Level(
          id: 3,
          description: "Simple Sentences",
          reward: 100,
          questions: [
            {
              "question": "I am _____ to the market.",
              "answers": ["going"],
              "type": "fill"
            },
            {
              "question": "She is _____ a letter to her friend.",
              "answers": ["writing"],
              "type": "fill"
            },
            {
              "question": "We are _____ dinner in the kitchen.",
              "answers": ["making"],
              "type": "fill"
            },
            {
              "question": "They are _____ to the movie theater.",
              "answers": ["going"],
              "type": "fill"
            },
            {
              "question": "The kids are _____ outside.",
              "answers": ["playing"],
              "type": "fill"
            },
          ],
        ),
        4: Level(
          id: 4,
          description: "Grammar Basics",
          reward: 100,
          questions: [
            {
              "question": "The bird is _____ the tree.",
              "answers": ["in"],
              "type": "fill"
            },
            {
              "question": "He _____ to school by bus.",
              "answers": ["goes"],
              "type": "fill"
            },
            {
              "question": "We _____ to visit our grandparents tomorrow.",
              "answers": ["plan"],
              "type": "fill"
            },
            {
              "question": "She _____ a beautiful dress yesterday.",
              "answers": ["bought"],
              "type": "fill"
            },
            {
              "question": "They _____ playing in the garden now.",
              "answers": ["are"],
              "type": "fill"
            },
          ],
        ),
        5: Level(
          id: 5,
          description: "Common Phrases",
          reward: 100,
          questions: [
            {
              "question": "Good morning! How _____ you?",
              "answers": ["are"],
              "type": "fill"
            },
            {
              "question": "Can you please pass _____ the salt?",
              "answers": ["me"],
              "type": "fill"
            },
            {
              "question": "I would like to _____ some coffee.",
              "answers": ["have"],
              "type": "fill"
            },
            {
              "question": "Do you know _____ the weather will be tomorrow?",
              "answers": ["what"],
              "type": "fill"
            },
            {
              "question": "He has been working _____ the project all day.",
              "answers": ["on"],
              "type": "fill"
            },
          ],
        ),
        6: Level(
          id: 6,
          description: "Listening Practice",
          reward: 100,
          questions: [
            {
              "question": "The teacher asked us to _____ quietly.",
              "answers": ["sit"],
              "type": "fill"
            },
            {
              "question": "She wants to _____ the piano.",
              "answers": ["play"],
              "type": "fill"
            },
            {
              "question": "He is going to _____ his homework later.",
              "answers": ["finish"],
              "type": "fill"
            },
            {
              "question": "Can you _____ me a favor?",
              "answers": ["do"],
              "type": "fill"
            },
            {
              "question": "I need to _____ some groceries.",
              "answers": ["buy"],
              "type": "fill"
            },
          ],
        ),
        7: Level(
          id: 7,
          description: "Daily Conversation",
          reward: 100,
          questions: [
            {
              "question": "How _____ you doing today?",
              "answers": ["are"],
              "type": "fill"
            },
            {
              "question": "Could you _____ me the way to the station?",
              "answers": ["tell"],
              "type": "fill"
            },
            {
              "question": "He _____ the answer to the question.",
              "answers": ["knows"],
              "type": "fill"
            },
            {
              "question": "They are _____ to the park together.",
              "answers": ["going"],
              "type": "fill"
            },
            {
              "question": "I _____ to see the doctor this afternoon.",
              "answers": ["need"],
              "type": "fill"
            },
          ],
        ),
        8: Level(
          id: 8,
          description: "Reading Practice",
          reward: 100,
          questions: [
            {
              "question": "The boy is reading _____ the library.",
              "answers": ["in"],
              "type": "fill"
            },
            {
              "question": "She was born _____ April.",
              "answers": ["in"],
              "type": "fill"
            },
            {
              "question": "We are planning to go _____ vacation soon.",
              "answers": ["on"],
              "type": "fill"
            },
            {
              "question": "He is very good _____ mathematics.",
              "answers": ["at"],
              "type": "fill"
            },
            {
              "question": "I need to finish this project _____ Friday.",
              "answers": ["by"],
              "type": "fill"
            },
          ],
        ),
        9: Level(
          id: 9,
          description: "Writing Basics",
          reward: 100,
          questions: [
            {
              "question": "The car is parked _____ the garage.",
              "answers": ["in"],
              "type": "fill"
            },
            {
              "question": "They met _____ the coffee shop.",
              "answers": ["at"],
              "type": "fill"
            },
            {
              "question": "She is looking _____ her lost keys.",
              "answers": ["for"],
              "type": "fill"
            },
            {
              "question": "I will call you _____ I get home.",
              "answers": ["when"],
              "type": "fill"
            },
            {
              "question": "The cat jumped _____ the fence.",
              "answers": ["over"],
              "type": "fill"
            },
          ],
        ),
        10: Level(
          id: 10,
          description: "Advanced Vocabulary",
          reward: 100,
          questions: [
            {
              "question": "He has been working _____ this problem for hours.",
              "answers": ["on"],
              "type": "fill"
            },
            {
              "question": "They are discussing the plan _____ the meeting.",
              "answers": ["during"],
              "type": "fill"
            },
            {
              "question": "She is preparing _____ her exams.",
              "answers": ["for"],
              "type": "fill"
            },
            {
              "question": "The presentation is scheduled _____ next Monday.",
              "answers": ["for"],
              "type": "fill"
            },
            {
              "question": "I am very proud _____ my achievements.",
              "answers": ["of"],
              "type": "fill"
            },
          ],
        ),
      },
      'German': {
        1: Level(
          id: 1,
          description: "Einführung in Deutsch",
          reward: 100,
          questions: [
            {
              "question": "Der Hund liegt _____ dem Tisch.",
              "answers": ["unter"],
              "type": "fill"
            },
            {
              "question": "Ich gehe _____ die Schule.",
              "answers": ["in"],
              "type": "fill"
            },
            {
              "question": "Sie sitzt _____ dem Stuhl.",
              "answers": ["auf"],
              "type": "fill"
            },
            {
              "question": "Wir fahren _____ den Park.",
              "answers": ["in"],
              "type": "fill"
            },
            {
              "question": "Er spielt Fußball _____ dem Abend.",
              "answers": ["am"],
              "type": "fill"
            },
          ],
        ),
        2: Level(
          id: 2,
          description: "Grundwortschatz",
          reward: 100,
          questions: [
            {
              "question": "Ich mache gerade _____ meine Hausaufgaben.",
              "answers": ["an"],
              "type": "fill"
            },
            {
              "question": "Sie gehen _____ das Kino.",
              "answers": ["in"],
              "type": "fill"
            },
            {
              "question": "Der Hund schläft _____ dem Sofa.",
              "answers": ["auf"],
              "type": "fill"
            },
            {
              "question": "Er interessiert sich _____ Musik.",
              "answers": ["für"],
              "type": "fill"
            },
            {
              "question": "Das Buch liegt _____ der Tasche.",
              "answers": ["in"],
              "type": "fill"
            },
          ],
        ),
        3: Level(
          id: 3,
          description: "Einfache Sätze",
          reward: 100,
          questions: [
            {
              "question": "Ich bin _____ den Supermarkt gegangen.",
              "answers": ["in"],
              "type": "fill"
            },
            {
              "question": "Er hat _____ einen Brief geschrieben.",
              "answers": ["an"],
              "type": "fill"
            },
            {
              "question": "Wir haben _____ Abendessen gekocht.",
              "answers": ["das"],
              "type": "fill"
            },
            {
              "question": "Sie sind _____ das Kino gegangen.",
              "answers": ["in"],
              "type": "fill"
            },
            {
              "question": "Die Kinder spielen _____ draußen.",
              "answers": ["immer"],
              "type": "fill"
            },
          ],
        ),
        4: Level(
          id: 4,
          description: "Grammatik Grundlagen",
          reward: 100,
          questions: [
            {
              "question": "Der Vogel ist _____ dem Baum.",
              "answers": ["auf"],
              "type": "fill"
            },
            {
              "question": "Er fährt _____ mit dem Bus.",
              "answers": ["immer"],
              "type": "fill"
            },
            {
              "question": "Wir wollen _____ unsere Großeltern besuchen.",
              "answers": ["heute"],
              "type": "fill"
            },
            {
              "question": "Sie hat _____ ein schönes Kleid gekauft.",
              "answers": ["gestern"],
              "type": "fill"
            },
            {
              "question": "Sie _____ jetzt im Garten spielen.",
              "answers": ["können"],
              "type": "fill"
            },
          ],
        ),
        5: Level(
          id: 5,
          description: "Alltägliche Ausdrücke",
          reward: 100,
          questions: [
            {
              "question": "Guten Morgen! Wie _____ es Ihnen?",
              "answers": ["geht"],
              "type": "fill"
            },
            {
              "question": "Können Sie mir bitte _____ den Zucker geben?",
              "answers": ["noch"],
              "type": "fill"
            },
            {
              "question": "Ich möchte gerne _____ eine Tasse Kaffee bestellen.",
              "answers": ["noch"],
              "type": "fill"
            },
            {
              "question": "Wissen Sie, wie _____ Wetter morgen sein wird?",
              "answers": ["das"],
              "type": "fill"
            },
            {
              "question": "Er arbeitet schon den ganzen Tag _____ dem Projekt.",
              "answers": ["an"],
              "type": "fill"
            },
          ],
        ),
        6: Level(
          id: 6,
          description: "Hörverstehen",
          reward: 100,
          questions: [
            {
              "question": "Der Lehrer bat uns, _____ leise zu bleiben.",
              "answers": ["bitte"],
              "type": "fill"
            },
            {
              "question": "Sie möchte _____ Klavier spielen.",
              "answers": ["gerne"],
              "type": "fill"
            },
            {
              "question": "Er wird später _____ seine Hausaufgaben machen.",
              "answers": ["noch"],
              "type": "fill"
            },
            {
              "question": "Können Sie mir _____ einen Gefallen tun?",
              "answers": ["bitte"],
              "type": "fill"
            },
            {
              "question": "Ich muss noch _____ einkaufen gehen.",
              "answers": ["etwas"],
              "type": "fill"
            },
          ],
        ),
        7: Level(
          id: 7,
          description: "Alltagsgespräche",
          reward: 100,
          questions: [
            {
              "question": "Wie _____ es dir heute?",
              "answers": ["geht"],
              "type": "fill"
            },
            {
              "question":
                  "Könntest du mir bitte _____ den Weg zum Bahnhof zeigen?",
              "answers": ["noch"],
              "type": "fill"
            },
            {
              "question": "Er _____ die Antwort auf die Frage.",
              "answers": ["weiß"],
              "type": "fill"
            },
            {
              "question": "Sie sind _____ gemeinsam in den Park gegangen.",
              "answers": ["oft"],
              "type": "fill"
            },
            {
              "question": "Ich _____ später zum Arzt gehen.",
              "answers": ["muss"],
              "type": "fill"
            },
          ],
        ),
        8: Level(
          id: 8,
          description: "Leseübungen",
          reward: 100,
          questions: [
            {
              "question": "Der Junge liest _____ in der Bibliothek.",
              "answers": ["viel"],
              "type": "fill"
            },
            {
              "question": "Sie wurde im _____ April geboren.",
              "answers": ["Monat"],
              "type": "fill"
            },
            {
              "question": "Wir planen bald in den Urlaub zu _____ gehen.",
              "answers": ["fahren"],
              "type": "fill"
            },
            {
              "question": "Er ist sehr gut in _____ Mathematik.",
              "answers": ["der"],
              "type": "fill"
            },
            {
              "question":
                  "Ich muss dieses Projekt bis _____ Freitag fertigstellen.",
              "answers": ["nächsten"],
              "type": "fill"
            },
          ],
        ),
        9: Level(
          id: 9,
          description: "Schreibübungen",
          reward: 100,
          questions: [
            {
              "question": "Das Auto steht _____ der Garage.",
              "answers": ["in"],
              "type": "fill"
            },
            {
              "question": "Sie haben sich _____ im Café getroffen.",
              "answers": ["heute"],
              "type": "fill"
            },
            {
              "question": "Sie sucht _____ ihre verlorenen Schlüssel.",
              "answers": ["nach"],
              "type": "fill"
            },
            {
              "question": "Ich rufe dich an, wenn ich _____ nach Hause komme.",
              "answers": ["gleich"],
              "type": "fill"
            },
            {
              "question": "Die Katze sprang _____ über den Zaun.",
              "answers": ["schnell"],
              "type": "fill"
            },
          ],
        ),
        10: Level(
          id: 10,
          description: "Fortgeschrittene Wörter",
          reward: 100,
          questions: [
            {
              "question": "Er arbeitet seit Stunden _____ an diesem Problem.",
              "answers": ["noch"],
              "type": "fill"
            },
            {
              "question": "Sie besprechen den Plan _____ im Meeting.",
              "answers": ["heute"],
              "type": "fill"
            },
            {
              "question": "Sie bereitet sich _____ auf ihre Prüfungen vor.",
              "answers": ["gerade"],
              "type": "fill"
            },
            {
              "question":
                  "Die Präsentation ist für nächsten Montag _____ angesetzt.",
              "answers": ["schon"],
              "type": "fill"
            },
            {
              "question": "Ich bin sehr stolz _____ auf meine Leistungen.",
              "answers": ["immer"],
              "type": "fill"
            },
          ],
        ),
      },
      'Spanish': {
        1: Level(
          id: 1,
          description: "Introducción al español",
          reward: 100,
          questions: [
            {
              "question": "El gato está _____ la mesa.",
              "answers": ["debajo de"],
              "type": "fill"
            },
            {
              "question": "Voy _____ la escuela todos los días.",
              "answers": ["a"],
              "type": "fill"
            },
            {
              "question": "Ella está sentada _____ la silla.",
              "answers": ["en"],
              "type": "fill"
            },
            {
              "question": "Vamos _____ el parque esta tarde.",
              "answers": ["a"],
              "type": "fill"
            },
            {
              "question": "Él juega fútbol _____ la tarde.",
              "answers": ["por"],
              "type": "fill"
            },
          ],
        ),
        2: Level(
          id: 2,
          description: "Vocabulario básico",
          reward: 100,
          questions: [
            {
              "question": "Estoy _____ mi tarea ahora.",
              "answers": ["haciendo"],
              "type": "fill"
            },
            {
              "question": "Ellos están yendo _____ el cine.",
              "answers": ["a"],
              "type": "fill"
            },
            {
              "question": "El perro está durmiendo _____ el sofá.",
              "answers": ["en"],
              "type": "fill"
            },
            {
              "question": "Ella está interesada _____ la música.",
              "answers": ["en"],
              "type": "fill"
            },
            {
              "question": "El libro está _____ la mochila.",
              "answers": ["en"],
              "type": "fill"
            },
          ],
        ),
        3: Level(
          id: 3,
          description: "Frases simples",
          reward: 100,
          questions: [
            {
              "question": "Voy _____ el mercado.",
              "answers": ["a"],
              "type": "fill"
            },
            {
              "question": "Ella está _____ una carta a su amiga.",
              "answers": ["escribiendo"],
              "type": "fill"
            },
            {
              "question": "Estamos _____ la cena en la cocina.",
              "answers": ["preparando"],
              "type": "fill"
            },
            {
              "question": "Ellos están _____ al cine juntos.",
              "answers": ["yendo"],
              "type": "fill"
            },
            {
              "question": "Los niños están _____ afuera.",
              "answers": ["jugando"],
              "type": "fill"
            },
          ],
        ),
        4: Level(
          id: 4,
          description: "Gramática básica",
          reward: 100,
          questions: [
            {
              "question": "El pájaro está _____ el árbol.",
              "answers": ["en"],
              "type": "fill"
            },
            {
              "question": "Él va _____ la escuela en autobús.",
              "answers": ["a"],
              "type": "fill"
            },
            {
              "question": "Vamos _____ visitar a nuestros abuelos mañana.",
              "answers": ["a"],
              "type": "fill"
            },
            {
              "question": "Ella _____ un vestido bonito ayer.",
              "answers": ["compró"],
              "type": "fill"
            },
            {
              "question": "Ellos están _____ en el jardín ahora.",
              "answers": ["jugando"],
              "type": "fill"
            },
          ],
        ),
        5: Level(
          id: 5,
          description: "Frases comunes",
          reward: 100,
          questions: [
            {
              "question": "¡Buenos días! ¿Cómo _____ estás?",
              "answers": ["te"],
              "type": "fill"
            },
            {
              "question": "¿Puedes pasarme _____ la sal, por favor?",
              "answers": [""],
              "type": "fill"
            },
            {
              "question": "Me gustaría _____ una taza de café.",
              "answers": ["pedir"],
              "type": "fill"
            },
            {
              "question": "¿Sabes cómo estará _____ el clima mañana?",
              "answers": [""],
              "type": "fill"
            },
            {
              "question":
                  "Ha estado trabajando _____ en el proyecto todo el día.",
              "answers": ["sin descanso"],
              "type": "fill"
            },
          ],
        ),
        6: Level(
          id: 6,
          description: "Práctica de escucha",
          reward: 100,
          questions: [
            {
              "question":
                  "El profesor nos pidió _____ que estemos en silencio.",
              "answers": ["amablemente"],
              "type": "fill"
            },
            {
              "question": "Ella quiere _____ tocar el piano.",
              "answers": ["aprender a"],
              "type": "fill"
            },
            {
              "question": "Él va a _____ hacer su tarea más tarde.",
              "answers": ["terminar"],
              "type": "fill"
            },
            {
              "question": "¿Puedes hacerme _____ un favor?",
              "answers": [""],
              "type": "fill"
            },
            {
              "question": "Necesito _____ comprar algunos comestibles.",
              "answers": ["urgentemente"],
              "type": "fill"
            },
          ],
        ),
        7: Level(
          id: 7,
          description: "Conversaciones diarias",
          reward: 100,
          questions: [
            {
              "question": "¿Cómo _____ te sientes hoy?",
              "answers": ["bien"],
              "type": "fill"
            },
            {
              "question": "¿Puedes decirme _____ cómo llegar a la estación?",
              "answers": ["fácilmente"],
              "type": "fill"
            },
            {
              "question": "Él sabe _____ la respuesta a la pregunta.",
              "answers": ["exactamente"],
              "type": "fill"
            },
            {
              "question": "Ellos están _____ yendo al parque juntos.",
              "answers": ["felices"],
              "type": "fill"
            },
            {
              "question": "Tengo que _____ visitar al médico esta tarde.",
              "answers": ["urgentemente"],
              "type": "fill"
            },
          ],
        ),
        8: Level(
          id: 8,
          description: "Práctica de lectura",
          reward: 100,
          questions: [
            {
              "question": "El niño está leyendo _____ en la biblioteca.",
              "answers": ["tranquilamente"],
              "type": "fill"
            },
            {
              "question": "Ella nació _____ en abril.",
              "answers": ["durante"],
              "type": "fill"
            },
            {
              "question": "Estamos planeando ir _____ de vacaciones pronto.",
              "answers": ["a algún lugar tropical"],
              "type": "fill"
            },
            {
              "question": "Él es muy bueno _____ en matemáticas.",
              "answers": ["practicando"],
              "type": "fill"
            },
            {
              "question":
                  "Necesito terminar este proyecto _____ para el viernes.",
              "answers": ["mañana"],
              "type": "fill"
            },
          ],
        ),
        9: Level(
          id: 9,
          description: "Escritura básica",
          reward: 100,
          questions: [
            {
              "question": "El coche está estacionado _____ en el garaje.",
              "answers": ["adentro"],
              "type": "fill"
            },
            {
              "question": "Ellos se encontraron _____ en la cafetería.",
              "answers": ["por casualidad"],
              "type": "fill"
            },
            {
              "question": "Ella está buscando _____ sus llaves perdidas.",
              "answers": ["ansiosamente"],
              "type": "fill"
            },
            {
              "question": "Te llamaré _____ cuando llegue a casa.",
              "answers": ["tan pronto"],
              "type": "fill"
            },
            {
              "question": "El gato saltó _____ sobre la valla.",
              "answers": ["grácilmente"],
              "type": "fill"
            },
          ],
        ),
        10: Level(
          id: 10,
          description: "Vocabulario avanzado",
          reward: 100,
          questions: [
            {
              "question":
                  "Él ha estado trabajando _____ en este problema por horas.",
              "answers": ["arduamente"],
              "type": "fill"
            },
            {
              "question": "Están discutiendo el plan _____ en la reunión.",
              "answers": ["detenidamente"],
              "type": "fill"
            },
            {
              "question": "Ella se está preparando _____ para sus exámenes.",
              "answers": ["diligentemente"],
              "type": "fill"
            },
            {
              "question":
                  "La presentación está programada _____ para el próximo lunes.",
              "answers": ["puntualmente"],
              "type": "fill"
            },
            {
              "question": "Estoy muy orgulloso _____ de mis logros.",
              "answers": ["profundamente"],
              "type": "fill"
            },
          ],
        ),
      },
      'Dutch': {
        1: Level(
          id: 1,
          description: "Inleiding tot Nederlands",
          reward: 100,
          questions: [
            {
              "question": "De kat zit _____ de tafel.",
              "answers": ["onder"],
              "type": "fill"
            },
            {
              "question": "Ik ga _____ school elke dag.",
              "answers": ["naar"],
              "type": "fill"
            },
            {
              "question": "Zij zit _____ de stoel.",
              "answers": ["op"],
              "type": "fill"
            },
            {
              "question": "Wij gaan _____ het park vanmiddag.",
              "answers": ["naar"],
              "type": "fill"
            },
            {
              "question": "Hij speelt voetbal _____ de middag.",
              "answers": ["in"],
              "type": "fill"
            },
          ],
        ),
        2: Level(
          id: 2,
          description: "Basiswoordenschat",
          reward: 100,
          questions: [
            {
              "question": "Ik ben _____ mijn huiswerk nu.",
              "answers": ["bezig met"],
              "type": "fill"
            },
            {
              "question": "Zij gaan _____ de bioscoop.",
              "answers": ["naar"],
              "type": "fill"
            },
            {
              "question": "De hond slaapt _____ de bank.",
              "answers": ["onder"],
              "type": "fill"
            },
            {
              "question": "Zij is geïnteresseerd _____ muziek.",
              "answers": ["in"],
              "type": "fill"
            },
            {
              "question": "Het boek zit _____ de tas.",
              "answers": ["in"],
              "type": "fill"
            },
          ],
        ),
        3: Level(
          id: 3,
          description: "Eenvoudige zinnen",
          reward: 100,
          questions: [
            {
              "question": "Ik ga _____ de markt.",
              "answers": ["naar"],
              "type": "fill"
            },
            {
              "question":
                  "Zij is _____ een brief aan haar vriend aan het schrijven.",
              "answers": ["bezig met"],
              "type": "fill"
            },
            {
              "question":
                  "Wij zijn _____ het avondeten in de keuken aan het bereiden.",
              "answers": ["bezig met"],
              "type": "fill"
            },
            {
              "question": "Zij gaan _____ de bioscoop samen.",
              "answers": ["naar"],
              "type": "fill"
            },
            {
              "question": "De kinderen zijn _____ buiten aan het spelen.",
              "answers": ["aan het"],
              "type": "fill"
            },
          ],
        ),
        4: Level(
          id: 4,
          description: "Basisgrammatica",
          reward: 100,
          questions: [
            {
              "question": "De vogel zit _____ de boom.",
              "answers": ["in"],
              "type": "fill"
            },
            {
              "question": "Hij gaat _____ school met de bus.",
              "answers": ["naar"],
              "type": "fill"
            },
            {
              "question": "Wij gaan _____ onze grootouders morgen bezoeken.",
              "answers": ["om"],
              "type": "fill"
            },
            {
              "question": "Zij heeft gisteren _____ een mooie jurk gekocht.",
              "answers": ["al"],
              "type": "fill"
            },
            {
              "question": "Zij zijn nu _____ in de tuin aan het spelen.",
              "answers": ["bezig"],
              "type": "fill"
            },
          ],
        ),
        5: Level(
          id: 5,
          description: "Veelvoorkomende zinnen",
          reward: 100,
          questions: [
            {
              "question": "Goedemorgen! Hoe _____ jij?",
              "answers": ["gaat het"],
              "type": "fill"
            },
            {
              "question": "Kun je mij alsjeblieft _____ het zout aangeven?",
              "answers": ["even"],
              "type": "fill"
            },
            {
              "question": "Ik zou graag _____ een kopje koffie willen.",
              "answers": ["hebben"],
              "type": "fill"
            },
            {
              "question": "Weet jij hoe _____ het weer morgen zal zijn?",
              "answers": ["exact"],
              "type": "fill"
            },
            {
              "question": "Hij is al de hele dag _____ met dat project bezig.",
              "answers": ["druk"],
              "type": "fill"
            },
          ],
        ),
        6: Level(
          id: 6,
          description: "Luistervaardigheid",
          reward: 100,
          questions: [
            {
              "question": "De leraar vroeg ons _____ stil te zijn.",
              "answers": ["om"],
              "type": "fill"
            },
            {
              "question": "Zij wil graag _____ piano leren spelen.",
              "answers": ["op de"],
              "type": "fill"
            },
            {
              "question": "Hij gaat later _____ zijn huiswerk maken.",
              "answers": ["af"],
              "type": "fill"
            },
            {
              "question": "Kun je mij alsjeblieft _____ een gunst verlenen?",
              "answers": ["eventjes"],
              "type": "fill"
            },
            {
              "question": "Ik moet nog even _____ boodschappen doen.",
              "answers": ["wat"],
              "type": "fill"
            },
          ],
        ),
        7: Level(
          id: 7,
          description: "Dagelijkse gesprekken",
          reward: 100,
          questions: [
            {
              "question": "Hoe _____ je vandaag?",
              "answers": ["voel jij"],
              "type": "fill"
            },
            {
              "question": "Kun je mij _____ de weg naar het station wijzen?",
              "answers": ["precies"],
              "type": "fill"
            },
            {
              "question": "Hij weet _____ het antwoord op de vraag.",
              "answers": ["altijd"],
              "type": "fill"
            },
            {
              "question": "Zij gaan _____ naar het park samen.",
              "answers": ["vaak"],
              "type": "fill"
            },
            {
              "question": "Ik moet vanmiddag _____ naar de dokter.",
              "answers": ["zeker"],
              "type": "fill"
            },
          ],
        ),
        8: Level(
          id: 8,
          description: "Leesvaardigheid",
          reward: 100,
          questions: [
            {
              "question": "De jongen leest _____ in de bibliotheek.",
              "answers": ["rustig"],
              "type": "fill"
            },
            {
              "question": "Zij werd geboren _____ in april.",
              "answers": ["ergens"],
              "type": "fill"
            },
            {
              "question": "Wij zijn van plan _____ op vakantie te gaan.",
              "answers": ["binnenkort"],
              "type": "fill"
            },
            {
              "question": "Hij is heel goed _____ wiskunde.",
              "answers": ["in"],
              "type": "fill"
            },
            {
              "question": "Ik moet dit project _____ voor vrijdag afronden.",
              "answers": ["zeker"],
              "type": "fill"
            },
          ],
        ),
        9: Level(
          id: 9,
          description: "Schrijfvaardigheid",
          reward: 100,
          questions: [
            {
              "question": "De auto staat geparkeerd _____ in de garage.",
              "answers": ["binnen"],
              "type": "fill"
            },
            {
              "question": "Zij ontmoetten elkaar _____ in het café.",
              "answers": ["voor het eerst"],
              "type": "fill"
            },
            {
              "question": "Zij zoekt _____ naar haar verloren sleutels.",
              "answers": ["nog steeds"],
              "type": "fill"
            },
            {
              "question": "Ik bel je zodra ik _____ thuis ben.",
              "answers": ["direct"],
              "type": "fill"
            },
            {
              "question": "De kat sprong _____ over het hek.",
              "answers": ["snel"],
              "type": "fill"
            },
          ],
        ),
        10: Level(
          id: 10,
          description: "Geavanceerde woordenschat",
          reward: 100,
          questions: [
            {
              "question": "Hij werkt al uren _____ aan dit probleem.",
              "answers": ["geconcentreerd"],
              "type": "fill"
            },
            {
              "question":
                  "Zij bespreken het plan _____ tijdens de vergadering.",
              "answers": ["uitgebreid"],
              "type": "fill"
            },
            {
              "question": "Zij bereidt zich _____ op haar examens voor.",
              "answers": ["nauwgezet"],
              "type": "fill"
            },
            {
              "question": "De presentatie is gepland _____ voor maandag.",
              "answers": ["volledig"],
              "type": "fill"
            },
            {
              "question": "Ik ben heel trots _____ op mijn prestaties.",
              "answers": ["volledig"],
              "type": "fill"
            },
          ],
        ),
      },
    };
  }
}
