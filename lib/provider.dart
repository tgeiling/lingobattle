import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services.dart';
import 'level.dart';

class ProfileProvider with ChangeNotifier {
  int _winStreak = 0;
  int _exp = 0;
  int _coins = 0;
  String _completedLevelsJson = "{}"; // Stored as JSON String
  String _username = "";
  String _title = "";
  Map<String, int> _eloMap = {};
  int _skillLevel = 0;
  String _nativeLanguage = "";
  bool _acceptedGdpr = false;

  int get winStreak => _winStreak;
  int get exp => _exp;
  int get coins => _coins;
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
  String get nativeLanguage => _nativeLanguage;
  bool get acceptedGdpr => _acceptedGdpr;

  Map<String, int> get completedLevels {
    try {
      Map<String, dynamic> decoded = json.decode(_completedLevelsJson);

      // Convert `{ "english": [1, 3, 7], "german": [2, 5] }` to `{ "english": 7, "german": 5 }`
      return decoded.map((language, completedList) {
        if (completedList is List && completedList.isNotEmpty) {
          return MapEntry(language,
              completedList.cast<int>().reduce((a, b) => a > b ? a : b));
        }
        return MapEntry(language, 0); // If no levels completed, return 0
      });
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

  void setCoins(int coinAmount) {
    _coins = coinAmount;
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

  void setNativeLanguage(String language) {
    _nativeLanguage = language;
    notifyListeners();
    savePreferences();
  }

  void setAcceptedGdpr(bool accepted) {
    _acceptedGdpr = accepted;
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
    await prefs.setInt('coins', _coins);
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
    await prefs.setString('nativeLanguage', _nativeLanguage);
    await prefs.setBool('acceptedGdpr', _acceptedGdpr);
  }

  Future<void> loadPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _winStreak = prefs.getInt('winStreak') ?? 0;
    _exp = prefs.getInt('exp') ?? 0;
    _coins = prefs.getInt('coins') ?? 0;
    _username = prefs.getString('username') ?? "";
    _title = prefs.getString('title') ?? "";
    _skillLevel = prefs.getInt('skillLevel') ?? 0;
    _completedLevelsJson = prefs.getString('language_levels') ?? "{}";
    _nativeLanguage = prefs.getString('nativeLanguage') ?? "";
    _acceptedGdpr = prefs.getBool('acceptedGdpr') ?? false;

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
      _coins = profileData['coins'] ?? _coins;
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
    String savedData = prefs.getString('language_levels') ?? "";

    if (savedData != null && savedData != "{}") {
      try {
        // Check if the JSON is double-encoded (string inside string)
        if (savedData.startsWith('"') && savedData.endsWith('"')) {
          savedData = json.decode(savedData); // Decode once if needed
        }

        // Deserialize JSON (expected format: { "english": [1, 3, 7], "german": [2, 5] })
        Map<String, dynamic> jsonData = json.decode(savedData);

        // Initialize the full level structure with default levels
        _initializeDefaultLevels();

        // Restore completed levels
        jsonData.forEach((language, completedLevels) {
          if (_languageLevels.containsKey(language) &&
              completedLevels is List) {
            for (int levelId in completedLevels.cast<int>()) {
              if (_languageLevels[language]!.containsKey(levelId)) {
                _languageLevels[language]![levelId]!.isDone = true;
              }
            }
          }
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

    // Extract completed levels (only IDs)
    Map<String, List<int>> optimizedData = _languageLevels.map((lang, levels) {
      return MapEntry(
        lang,
        levels.entries
            .where((entry) => entry.value.isDone) // Only save completed levels
            .map((entry) => entry.key) // Store only the level ID
            .toList(),
      );
    });

    // Convert to JSON and save to SharedPreferences
    String jsonData = json.encode(optimizedData);
    await prefs.setString('language_levels', jsonData);

    // Send to server (optional)
    getAuthToken().then((token) {
      if (token != null) {
        updateProfile(
          token: token,
          completedLevels: jsonData, // Send only optimized data
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

  Map<String, List<int>> extractCompletedLevels(
      Map<String, Map<int, Level>> levels) {
    Map<String, List<int>> completedLevels = {};

    levels.forEach((language, levelData) {
      completedLevels[language] = levelData.entries
          .where((entry) => entry.value.isDone) // Only save completed levels
          .map((entry) => entry.key) // Save only the level ID
          .toList();
    });

    return completedLevels;
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
              "question": "Apple",
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
              "question": "cash",
              "answers": ["cash", "bash", "dobla", "fiets"],
              "type": "pick"
            }
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
              "question": "Car",
              "answers": ["Car", "Bar", "Jar", "Tar"],
              "type": "pick"
            },
          ],
        ),
        3: Level(
          id: 3,
          description: "Simple Sentences",
          reward: 100,
          questions: [
            {
              "question": "I am going to _____ market.",
              "answers": ["the"],
              "type": "fill"
            },
            {
              "question": "Tree",
              "answers": ["Tree", "Free", "Bee", "See"],
              "type": "pick"
            },
            {
              "question": "We _____ making dinner in the kitchen.",
              "answers": ["are"],
              "type": "fill"
            },
            {
              "question": "Cash",
              "answers": ["Cash", "Crash", "Mash", "Dash"],
              "type": "pick"
            },
            {
              "question": "The kids _____ playing outside.",
              "answers": ["are"],
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
              "question": "Sun",
              "answers": ["Sun", "Fun", "Run", "Bun"],
              "type": "pick"
            },
            {
              "question": "The bird is sitting _____ the tree.",
              "answers": ["in"],
              "type": "fill"
            },
            {
              "question": "He goes _____ school by bus.",
              "answers": ["to"],
              "type": "fill"
            },
            {
              "question": "She bought a beautiful _____ yesterday.",
              "answers": ["dress"],
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
          description: "More Experience",
          reward: 100,
          questions: [
            {
              "question": "The teacher asked us to _____ quietly.",
              "answers": ["sit"],
              "type": "fill"
            },
            {
              "question": "We plan to visit _____ grandparents tomorrow.",
              "answers": ["our"],
              "type": "fill"
            },
            {
              "question": "Can you _____ me a favor?",
              "answers": ["do"],
              "type": "fill"
            },
            {
              "question": "Chair",
              "answers": ["Chair", "Stair", "Pair", "Fair"],
              "type": "pick"
            },
            {
              "question": "Table",
              "answers": ["Table", "Cable", "Fable", "Able"],
              "type": "pick"
            },
          ],
        ),
        7: Level(
          id: 7,
          description: "Daily Conversation",
          reward: 100,
          questions: [
            {
              "question": "How are _____ doing today?",
              "answers": ["you"],
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
              "question": "Water",
              "answers": ["Water", "Later", "Cater", "Hater"],
              "type": "pick"
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
          description: "Time based",
          reward: 100,
          questions: [
            {
              "question": "Clock",
              "answers": ["Clock", "Rock", "Stock", "Shock"],
              "type": "pick"
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
          description: "More Basics",
          reward: 100,
          questions: [
            {
              "question": "Moon",
              "answers": ["Moon", "Noon", "Soon", "Balloon"],
              "type": "pick"
            },
            {
              "question": "Star",
              "answers": ["Star", "Far", "Car", "Jar"],
              "type": "pick"
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
          description: "10th step",
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
        11: Level(
          id: 11,
          description: "Prepositions Practice",
          reward: 100,
          questions: [
            {
              "question": "She put her bag _____ the table.",
              "answers": ["on"],
              "type": "fill"
            },
            {
              "question": "They walked _____ the bridge.",
              "answers": ["over"],
              "type": "fill"
            },
            {
              "question": "Glass",
              "answers": ["Glass", "Class", "Brass", "Pass"],
              "type": "pick"
            },
            {
              "question": "We arrived _____ the airport on time.",
              "answers": ["at"],
              "type": "fill"
            },
            {
              "question": "He is afraid _____ spiders.",
              "answers": ["of"],
              "type": "fill"
            }
          ],
        ),
        12: Level(
          id: 12,
          description: "At the Airport",
          reward: 100,
          questions: [
            {
              "question": "I show my passport at the _____.",
              "answers": ["checkpoint"],
              "type": "fill"
            },
            {
              "question": "The flight departs from _____ 12.",
              "answers": ["gate"],
              "type": "fill"
            },
            {
              "question": "Luggage",
              "answers": ["Luggage", "Boarding", "Takeoff", "Landing"],
              "type": "pick"
            },
            {
              "question": "My plane is _____ due to bad weather.",
              "answers": ["delayed"],
              "type": "fill"
            },
            {
              "question": "The passengers are waiting in the _____ area.",
              "answers": ["boarding"],
              "type": "fill"
            }
          ],
        ),
        13: Level(
          id: 13,
          description: "Daily Activities",
          reward: 100,
          questions: [
            {
              "question": "I wake up _____ 7 AM every day.",
              "answers": ["at"],
              "type": "fill"
            },
            {
              "question": "Chair",
              "answers": ["Chair", "Stair", "Pair", "Fair"],
              "type": "pick"
            },
            {
              "question": "After breakfast, I _____ my teeth.",
              "answers": ["brush"],
              "type": "fill"
            },
            {
              "question": "At night, I go to _____ early.",
              "answers": ["bed"],
              "type": "fill"
            },
            {
              "question": "He _____ to work by car.",
              "answers": ["goes"],
              "type": "fill"
            }
          ],
        ),
        14: Level(
          id: 14,
          description: "Opposites",
          reward: 100,
          questions: [
            {
              "question": "The opposite of 'big' is _____",
              "answers": ["small"],
              "type": "fill"
            },
            {
              "question": "Water",
              "answers": ["Water", "Later", "Cater", "Hater"],
              "type": "pick"
            },
            {
              "question": "He was happy, but now he is _____",
              "answers": ["sad"],
              "type": "fill"
            },
            {
              "question": "The opposite of 'fast' is _____",
              "answers": ["slow"],
              "type": "fill"
            },
            {
              "question": "They built a _____ building.",
              "answers": ["tall"],
              "type": "fill"
            }
          ],
        ),
        15: Level(
          id: 15,
          description: "Verbs in Action",
          reward: 100,
          questions: [
            {
              "question": "I _____ my homework every evening.",
              "answers": ["do"],
              "type": "fill"
            },
            {
              "question": "They _____ football in the park.",
              "answers": ["play"],
              "type": "fill"
            },
            {
              "question": "Clock",
              "answers": ["Clock", "Rock", "Stock", "Shock"],
              "type": "pick"
            },
            {
              "question": "She _____ a book before sleeping.",
              "answers": ["reads"],
              "type": "fill"
            },
            {
              "question": "We _____ dinner together.",
              "answers": ["eat"],
              "type": "fill"
            }
          ],
        ),
        16: Level(
          id: 16,
          description: "Transportation",
          reward: 100,
          questions: [
            {
              "question": "He rides his _____ to school.",
              "answers": ["bike"],
              "type": "fill"
            },
            {
              "question": "They took a _____ to the airport.",
              "answers": ["taxi"],
              "type": "fill"
            },
            {
              "question": "Moon",
              "answers": ["Moon", "Noon", "Soon", "Balloon"],
              "type": "pick"
            },
            {
              "question": "She travels by _____ every day.",
              "answers": ["bus"],
              "type": "fill"
            },
            {
              "question": "They are waiting for the _____ to arrive.",
              "answers": ["train"],
              "type": "fill"
            }
          ],
        ),
        17: Level(
          id: 17,
          description: "Colors and Shapes",
          reward: 100,
          questions: [
            {
              "question": "The sky is _____ during the day.",
              "answers": ["blue"],
              "type": "fill"
            },
            {
              "question": "Her dress is _____.",
              "answers": ["pretty"],
              "type": "fill"
            },
            {
              "question": "Star",
              "answers": ["Star", "Far", "Car", "Jar"],
              "type": "pick"
            },
            {
              "question": "A ball is usually _____.",
              "answers": ["round"],
              "type": "fill"
            },
            {
              "question": "The sun looks _____ in the evening.",
              "answers": ["orange"],
              "type": "fill"
            }
          ],
        ),
        18: Level(
          id: 18,
          description: "Weather",
          reward: 100,
          questions: [
            {
              "question": "It is _____ today, so I need my umbrella.",
              "answers": ["rainy"],
              "type": "fill"
            },
            {
              "question": "The sun is shining, so it's a _____ day.",
              "answers": ["sunny"],
              "type": "fill"
            },
            {
              "question": "Cloud",
              "answers": ["Cloud", "Fog", "Smoke", "Mist"],
              "type": "pick"
            },
            {
              "question": "The weather is very _____ in winter.",
              "answers": ["cold"],
              "type": "fill"
            },
            {
              "question": "I wear a jacket because it is _____ outside.",
              "answers": ["windy"],
              "type": "fill"
            }
          ],
        ),
        19: Level(
          id: 19,
          description: "Shopping",
          reward: 100,
          questions: [
            {
              "question": "We need to buy some _____ at the supermarket.",
              "answers": ["milk"],
              "type": "fill"
            },
            {
              "question": "She paid for her groceries with _____",
              "answers": ["cash"],
              "type": "fill"
            },
            {
              "question": "Shoes",
              "answers": ["Shoes", "Socks", "Boots", "Slippers"],
              "type": "pick"
            },
            {
              "question": "I bought a new _____ for my birthday.",
              "answers": ["dress"],
              "type": "fill"
            },
            {
              "question": "We got a great _____ on the TV!",
              "answers": ["discount"],
              "type": "fill"
            }
          ],
        ),
        20: Level(
          id: 20,
          description: "Animals",
          reward: 100,
          questions: [
            {
              "question": "A _____ is known for its long neck.",
              "answers": ["giraffe"],
              "type": "fill"
            },
            {
              "question": "Cats love to chase _____.",
              "answers": ["mice"],
              "type": "fill"
            },
            {
              "question": "Fish",
              "answers": ["Fish", "Shark", "Dolphin", "Whale"],
              "type": "pick"
            },
            {
              "question": "A lion is called the king of the _____.",
              "answers": ["jungle"],
              "type": "fill"
            },
            {
              "question": "Dogs love to play with a _____.",
              "answers": ["ball"],
              "type": "fill"
            }
          ],
        ),
        21: Level(
          id: 21,
          description: "Family & Relationships",
          reward: 100,
          questions: [
            {
              "question": "My mother's brother is my _____.",
              "answers": ["uncle"],
              "type": "fill"
            },
            {
              "question": "My father's father is my _____.",
              "answers": ["grandfather"],
              "type": "fill"
            },
            {
              "question": "Car",
              "answers": ["Car", "Bar", "Jar", "Tar"],
              "type": "pick"
            },
            {
              "question": "She is my father's daughter, so she is my _____.",
              "answers": ["sister"],
              "type": "fill"
            },
            {
              "question": "My parents are _____.",
              "answers": ["married"],
              "type": "fill"
            }
          ],
        ),
        22: Level(
          id: 22,
          description: "Food & Drinks",
          reward: 100,
          questions: [
            {
              "question": "Oranges are a type of _____.",
              "answers": ["fruit"],
              "type": "fill"
            },
            {
              "question": "We drink milk from a _____.",
              "answers": ["glass"],
              "type": "fill"
            },
            {
              "question": "Apple",
              "answers": ["Apple", "Orange", "Banana", "Carrot"],
              "type": "pick"
            },
            {
              "question":
                  "A popular Italian dish made with cheese and tomato is _____.",
              "answers": ["pizza"],
              "type": "fill"
            },
            {
              "question": "We use a _____ to eat soup.",
              "answers": ["spoon"],
              "type": "fill"
            }
          ],
        ),
        23: Level(
          id: 23,
          description: "School & Learning",
          reward: 100,
          questions: [
            {
              "question": "We write on _____.",
              "answers": ["paper"],
              "type": "fill"
            },
            {
              "question": "The person who teaches a class is called a _____.",
              "answers": ["teacher"],
              "type": "fill"
            },
            {
              "question": "Pen",
              "answers": ["Pen", "Pencil", "Eraser", "Marker"],
              "type": "pick"
            },
            {
              "question": "Math, science, and history are all school _____.",
              "answers": ["subjects"],
              "type": "fill"
            },
            {
              "question": "We read books in the _____.",
              "answers": ["library"],
              "type": "fill"
            }
          ],
        ),
        24: Level(
          id: 24,
          description: "Hobbies & Leisure",
          reward: 100,
          questions: [
            {
              "question": "People play music using a _____.",
              "answers": ["guitar"],
              "type": "fill"
            },
            {
              "question": "To capture a moment, we use a _____.",
              "answers": ["camera"],
              "type": "fill"
            },
            {
              "question": "Tree",
              "answers": ["Tree", "Free", "Bee", "See"],
              "type": "pick"
            },
            {
              "question":
                  "She likes to read in her free time, so her hobby is _____.",
              "answers": ["reading"],
              "type": "fill"
            },
            {
              "question": "People go to the park to ride a _____.",
              "answers": ["bicycle"],
              "type": "fill"
            }
          ],
        ),
        25: Level(
          id: 25,
          description: "Clothes & Fashion",
          reward: 100,
          questions: [
            {
              "question": "You wear shoes on your _____.",
              "answers": ["feet"],
              "type": "fill"
            },
            {
              "question": "A jacket is used to keep you _____.",
              "answers": ["warm"],
              "type": "fill"
            },
            {
              "question": "Hat",
              "answers": ["Hat", "Scarf", "Shoe", "Glove"],
              "type": "pick"
            },
            {
              "question": "She bought a beautiful red _____.",
              "answers": ["dress"],
              "type": "fill"
            },
            {
              "question": "You wear a _____ on your wrist to tell time.",
              "answers": ["watch"],
              "type": "fill"
            }
          ],
        ),
        26: Level(
          id: 26,
          description: "Household Items",
          reward: 100,
          questions: [
            {
              "question": "We keep our clothes in a _____.",
              "answers": ["wardrobe"],
              "type": "fill"
            },
            {
              "question": "You sleep on a _____.",
              "answers": ["bed"],
              "type": "fill"
            },
            {
              "question": "Table",
              "answers": ["Table", "Cable", "Fable", "Able"],
              "type": "pick"
            },
            {
              "question": "We cook food in a _____.",
              "answers": ["kitchen"],
              "type": "fill"
            },
            {
              "question": "You can sit on a _____ in the living room.",
              "answers": ["sofa"],
              "type": "fill"
            }
          ],
        ),
        27: Level(
          id: 27,
          description: "Time & Seasons",
          reward: 100,
          questions: [
            {
              "question": "There are 12 months in a _____.",
              "answers": ["year"],
              "type": "fill"
            },
            {
              "question": "The coldest season is _____.",
              "answers": ["winter"],
              "type": "fill"
            },
            {
              "question": "Clock",
              "answers": ["Clock", "Rock", "Stock", "Shock"],
              "type": "pick"
            },
            {
              "question": "Spring, summer, fall, and winter are _____.",
              "answers": ["seasons"],
              "type": "fill"
            },
            {
              "question": "We celebrate New Year's Eve in the month of _____.",
              "answers": ["December"],
              "type": "fill"
            }
          ],
        ),
        28: Level(
          id: 28,
          description: "Emotions & Feelings",
          reward: 100,
          questions: [
            {
              "question": "I feel _____ when I get a gift.",
              "answers": ["happy"],
              "type": "fill"
            },
            {
              "question": "He was _____ because he lost his keys.",
              "answers": ["worried"],
              "type": "fill"
            },
            {
              "question": "Star",
              "answers": ["Star", "Far", "Car", "Jar"],
              "type": "pick"
            },
            {
              "question": "If I don’t sleep well, I feel _____.",
              "answers": ["tired"],
              "type": "fill"
            },
            {
              "question": "She was _____ after watching a scary movie.",
              "answers": ["afraid"],
              "type": "fill"
            }
          ],
        ),
        29: Level(
          id: 29,
          description: "Body Parts",
          reward: 100,
          questions: [
            {
              "question": "We use our _____ to see.",
              "answers": ["eyes"],
              "type": "fill"
            },
            {
              "question": "The part of the body used for walking is the _____.",
              "answers": ["legs"],
              "type": "fill"
            },
            {
              "question": "Milk",
              "answers": ["Milk", "Juice", "Tea", "Soda"],
              "type": "pick"
            },
            {
              "question": "You hear with your _____.",
              "answers": ["ears"],
              "type": "fill"
            },
            {
              "question": "We hold things with our _____.",
              "answers": ["hands"],
              "type": "fill"
            }
          ],
        ),
        30: Level(
          id: 30,
          description: "Nature & Environment",
          reward: 100,
          questions: [
            {
              "question": "The sun rises in the _____.",
              "answers": ["east"],
              "type": "fill"
            },
            {
              "question": "The ocean is full of _____.",
              "answers": ["water"],
              "type": "fill"
            },
            {
              "question": "Cloud",
              "answers": ["Cloud", "Fog", "Smoke", "Mist"],
              "type": "pick"
            },
            {
              "question": "A plant needs _____ to grow.",
              "answers": ["sunlight"],
              "type": "fill"
            },
            {
              "question": "Mount Everest is a famous _____.",
              "answers": ["mountain"],
              "type": "fill"
            }
          ],
        ),
        31: Level(
          id: 31,
          description: "Jobs & Professions",
          reward: 100,
          questions: [
            {
              "question": "A person who teaches students is a _____.",
              "answers": ["teacher"],
              "type": "fill"
            },
            {
              "question": "A doctor works in a _____.",
              "answers": ["hospital"],
              "type": "fill"
            },
            {
              "question": "Clock",
              "answers": ["Clock", "Rock", "Stock", "Shock"],
              "type": "pick"
            },
            {
              "question": "A person who cooks food in a restaurant is a _____.",
              "answers": ["chef"],
              "type": "fill"
            },
            {
              "question": "A firefighter helps to stop _____.",
              "answers": ["fires"],
              "type": "fill"
            }
          ],
        ),
        32: Level(
          id: 32,
          description: "Action Words (Verbs)",
          reward: 100,
          questions: [
            {
              "question": "He likes to _____ books before sleeping.",
              "answers": ["read"],
              "type": "fill"
            },
            {
              "question": "They _____ soccer in the evening.",
              "answers": ["play"],
              "type": "fill"
            },
            {
              "question": "Milk",
              "answers": ["Milk", "Juice", "Tea", "Soda"],
              "type": "pick"
            },
            {
              "question": "She _____ the door when she leaves.",
              "answers": ["closes"],
              "type": "fill"
            },
            {
              "question": "Birds _____ in the sky.",
              "answers": ["fly"],
              "type": "fill"
            }
          ],
        ),
        33: Level(
          id: 33,
          description: "At Home",
          reward: 100,
          questions: [
            {
              "question": "We sleep in the _____.",
              "answers": ["bedroom"],
              "type": "fill"
            },
            {
              "question": "You take a shower in the _____.",
              "answers": ["bathroom"],
              "type": "fill"
            },
            {
              "question": "candle",
              "answers": ["candle", "lantern", "torch", "lamp"],
              "type": "pick"
            },
            {
              "question": "We eat dinner in the _____.",
              "answers": ["dining room"],
              "type": "fill"
            },
            {
              "question": "The TV is in the _____.",
              "answers": ["living room"],
              "type": "fill"
            }
          ],
        ),
        34: Level(
          id: 34,
          description: "Transportation & Travel",
          reward: 100,
          questions: [
            {
              "question": "People travel long distances by _____.",
              "answers": ["plane"],
              "type": "fill"
            },
            {
              "question": "A bus carries many _____.",
              "answers": ["passengers"],
              "type": "fill"
            },
            {
              "question": "Ball",
              "answers": ["Ball", "Tall", "Wall", "Call"],
              "type": "pick"
            },
            {
              "question": "We use a _____ to ride on water.",
              "answers": ["boat"],
              "type": "fill"
            },
            {
              "question": "A bicycle has two _____.",
              "answers": ["wheels"],
              "type": "fill"
            }
          ],
        ),
        35: Level(
          id: 35,
          description: "Shapes & Sizes",
          reward: 100,
          questions: [
            {
              "question": "A ball is _____.",
              "answers": ["round"],
              "type": "fill"
            },
            {
              "question": "A square has _____ sides.",
              "answers": ["four"],
              "type": "fill"
            },
            {
              "question": "Star",
              "answers": ["Star", "Far", "Car", "Jar"],
              "type": "pick"
            },
            {
              "question": "A triangle has _____ sides.",
              "answers": ["three"],
              "type": "fill"
            },
            {
              "question": "The elephant is very _____.",
              "answers": ["big"],
              "type": "fill"
            }
          ],
        ),
        36: Level(
          id: 36,
          description: "Common Objects",
          reward: 100,
          questions: [
            {
              "question": "We write with a _____.",
              "answers": ["pen"],
              "type": "fill"
            },
            {
              "question": "A computer has a _____.",
              "answers": ["keyboard"],
              "type": "fill"
            },
            {
              "question": "Car",
              "answers": ["Car", "Bus", "Bike", "Train"],
              "type": "pick"
            },
            {
              "question": "We see our reflection in a _____.",
              "answers": ["mirror"],
              "type": "fill"
            },
            {
              "question": "A lamp gives _____.",
              "answers": ["light"],
              "type": "fill"
            }
          ],
        ),
        37: Level(
          id: 37,
          description: "Fun with Words",
          reward: 100,
          questions: [
            {
              "question": "The opposite of 'hot' is _____.",
              "answers": ["cold"],
              "type": "fill"
            },
            {
              "question": "Cash",
              "answers": ["Cash", "Crash", "Mash", "Dash"],
              "type": "pick"
            },
            {
              "question": "The opposite of 'day' is _____.",
              "answers": ["night"],
              "type": "fill"
            },
            {
              "question": "A cat says _____.",
              "answers": ["meow"],
              "type": "fill"
            },
            {
              "question": "A dog says _____.",
              "answers": ["woof"],
              "type": "fill"
            }
          ],
        ),
        38: Level(
          id: 38,
          description: "Weather & Seasons",
          reward: 100,
          questions: [
            {
              "question": "Snow falls in the season of _____.",
              "answers": ["winter"],
              "type": "fill"
            },
            {
              "question": "It is hot in _____.",
              "answers": ["summer"],
              "type": "fill"
            },
            {
              "question": "Tree",
              "answers": ["Tree", "Free", "Bee", "See"],
              "type": "pick"
            },
            {
              "question": "Leaves change color in _____.",
              "answers": ["fall"],
              "type": "fill"
            },
            {
              "question": "Flowers bloom in _____.",
              "answers": ["spring"],
              "type": "fill"
            }
          ],
        ),
        39: Level(
          id: 39,
          description: "Counting & Numbers",
          reward: 100,
          questions: [
            {
              "question": "The number after five is _____.",
              "answers": ["six"],
              "type": "fill"
            },
            {
              "question": "Ten plus ten equals _____.",
              "answers": ["twenty"],
              "type": "fill"
            },
            {
              "question": "Shoes",
              "answers": ["Shoes", "Socks", "Boots", "Slippers"],
              "type": "pick"
            },
            {
              "question": "Half of eight is _____.",
              "answers": ["four"],
              "type": "fill"
            },
            {
              "question": "Number",
              "answers": ["Number", "Open", "Web", "Tree"],
              "type": "pick"
            },
          ],
        ),
        40: Level(
          id: 40,
          description: "Basic Greetings",
          reward: 100,
          questions: [
            {
              "question": "In the morning, we say good _____.",
              "answers": ["morning"],
              "type": "fill"
            },
            {
              "question": "When we meet someone, we say _____.",
              "answers": ["hello"],
              "type": "fill"
            },
            {
              "question": "Milk",
              "answers": ["Milk", "Juice", "Tea", "Soda"],
              "type": "pick"
            },
            {
              "question": "Before bed, we say good _____.",
              "answers": ["night"],
              "type": "fill"
            },
            {
              "question": "When leaving, we say _____.",
              "answers": ["goodbye"],
              "type": "fill"
            }
          ],
        ),
        41: Level(
          id: 41,
          description: "Basic Directions",
          reward: 100,
          questions: [
            {
              "question": "Go _____ and turn left.",
              "answers": ["straight"],
              "type": "fill"
            },
            {
              "question": "The opposite of left is _____.",
              "answers": ["right"],
              "type": "fill"
            },
            {
              "question": "Clock",
              "answers": ["Clock", "Rock", "Stock", "Shock"],
              "type": "pick"
            },
            {
              "question": "North, south, east, and _____.",
              "answers": ["west"],
              "type": "fill"
            },
            {
              "question": "The sun rises in the _____.",
              "answers": ["east"],
              "type": "fill"
            }
          ],
        ),
        42: Level(
          id: 42,
          description: "Sports & Activities",
          reward: 100,
          questions: [
            {
              "question": "You kick a _____ in soccer.",
              "answers": ["ball"],
              "type": "fill"
            },
            {
              "question": "Swimming is done in a _____.",
              "answers": ["pool"],
              "type": "fill"
            },
            {
              "question": "Apple",
              "answers": ["Apple", "Orange", "Banana", "Carrot"],
              "type": "pick"
            },
            {
              "question": "In basketball, players try to hit a _____.",
              "answers": ["basket"],
              "type": "fill"
            },
            {
              "question": "A tennis player uses a _____.",
              "answers": ["racket"],
              "type": "fill"
            }
          ],
        ),
        43: Level(
          id: 43,
          description: "Shopping & Money",
          reward: 100,
          questions: [
            {
              "question": "A place where you buy groceries is a _____.",
              "answers": ["supermarket"],
              "type": "fill"
            },
            {
              "question": "Cashiers give you a _____ after payment.",
              "answers": ["receipt"],
              "type": "fill"
            },
            {
              "question": "Cash",
              "answers": ["Cash", "Crash", "Mash", "Dash"],
              "type": "pick"
            },
            {
              "question": "A credit card is used for _____.",
              "answers": ["payment"],
              "type": "fill"
            },
            {
              "question": "A special price discount is called a _____.",
              "answers": ["sale"],
              "type": "fill"
            }
          ],
        ),
        44: Level(
          id: 44,
          description: "In the Garden",
          reward: 100,
          questions: [
            {
              "question": "A plant grows from a _____.",
              "answers": ["seed"],
              "type": "fill"
            },
            {
              "question": "A tree has many _____.",
              "answers": ["leaves"],
              "type": "fill"
            },
            {
              "question": "Tree",
              "answers": ["Tree", "Free", "Bee", "See"],
              "type": "pick"
            },
            {
              "question": "Flowers bloom in the _____.",
              "answers": ["spring"],
              "type": "fill"
            },
            {
              "question": "A small flying insect that makes honey is a _____.",
              "answers": ["bee"],
              "type": "fill"
            }
          ],
        ),
        45: Level(
          id: 45,
          description: "Transportation",
          reward: 100,
          questions: [
            {
              "question": "A _____ has four wheels and is used for driving.",
              "answers": ["car"],
              "type": "fill"
            },
            {
              "question": "People travel long distances by _____.",
              "answers": ["plane"],
              "type": "fill"
            },
            {
              "question": "Ball",
              "answers": ["Ball", "Tall", "Wall", "Call"],
              "type": "pick"
            },
            {
              "question": "A two-wheeled vehicle you pedal is a _____.",
              "answers": ["bicycle"],
              "type": "fill"
            },
            {
              "question": "A _____ is used to carry goods on the road.",
              "answers": ["truck"],
              "type": "fill"
            }
          ],
        ),
        46: Level(
          id: 46,
          description: "Days & Time",
          reward: 100,
          questions: [
            {
              "question": "There are 7 _____ in a week.",
              "answers": ["days"],
              "type": "fill"
            },
            {
              "question": "The month after March is _____.",
              "answers": ["April"],
              "type": "fill"
            },
            {
              "question": "Clock",
              "answers": ["Clock", "Rock", "Stock", "Shock"],
              "type": "pick"
            },
            {
              "question": "We sleep at _____.",
              "answers": ["night"],
              "type": "fill"
            },
            {
              "question": "A new day begins at _____.",
              "answers": ["midnight"],
              "type": "fill"
            }
          ],
        ),
        47: Level(
          id: 47,
          description: "Weather Words",
          reward: 100,
          questions: [
            {
              "question": "It is _____ when the sun shines.",
              "answers": ["sunny"],
              "type": "fill"
            },
            {
              "question": "When it rains a lot, the ground gets _____.",
              "answers": ["wet"],
              "type": "fill"
            },
            {
              "question": "Star",
              "answers": ["Star", "Far", "Car", "Jar"],
              "type": "pick"
            },
            {
              "question": "A cloud filled with rain makes the sky look _____.",
              "answers": ["gray"],
              "type": "fill"
            },
            {
              "question": "A _____ is a storm with strong wind and rain.",
              "answers": ["hurricane"],
              "type": "fill"
            }
          ],
        ),
        48: Level(
          id: 48,
          description: "Rooms in a House",
          reward: 100,
          questions: [
            {
              "question": "We cook food in the _____.",
              "answers": ["kitchen"],
              "type": "fill"
            },
            {
              "question": "People sleep in the _____.",
              "answers": ["bedroom"],
              "type": "fill"
            },
            {
              "question": "Milk",
              "answers": ["Milk", "Juice", "Tea", "Soda"],
              "type": "pick"
            },
            {
              "question": "The family watches TV in the _____.",
              "answers": ["living room"],
              "type": "fill"
            },
            {
              "question": "We wash our hands in the _____.",
              "answers": ["bathroom"],
              "type": "fill"
            }
          ],
        ),
        49: Level(
          id: 49,
          description: "Past Emotions & Feelings",
          reward: 100,
          questions: [
            {
              "question": "Yesterday, she _____ because she was happy.",
              "answers": ["smiled"],
              "type": "fill"
            },
            {
              "question": "Last night, I _____ very tired.",
              "answers": ["felt"],
              "type": "fill"
            },
            {
              "question": "Shoes",
              "answers": ["Shoes", "Socks", "Boots", "Slippers"],
              "type": "pick"
            },
            {
              "question": "He _____ when he heard the bad news.",
              "answers": ["cried"],
              "type": "fill"
            },
            {
              "question": "They _____ when they heard the joke.",
              "answers": ["laughed"],
              "type": "fill"
            }
          ],
        ),
        49: Level(
          id: 49,
          description: "Past Emotions & Feelings",
          reward: 100,
          questions: [
            {
              "question": "Yesterday, she _____ because she was happy.",
              "answers": ["smiled"],
              "type": "fill"
            },
            {
              "question": "Last night, I _____ very tired.",
              "answers": ["felt"],
              "type": "fill"
            },
            {
              "question": "Shoes",
              "answers": ["Shoes", "Socks", "Boots", "Slippers"],
              "type": "pick"
            },
            {
              "question": "He _____ when he heard the bad news.",
              "answers": ["cried"],
              "type": "fill"
            },
            {
              "question": "They _____ when they heard the joke.",
              "answers": ["laughed"],
              "type": "fill"
            }
          ],
        ),
        51: Level(
          id: 51,
          description: "Past Adjectives & Descriptions",
          reward: 100,
          questions: [
            {
              "question": "Yesterday, the opposite of 'happy' was _____.",
              "answers": ["sad"],
              "type": "fill"
            },
            {
              "question": "That house was not small, it was _____.",
              "answers": ["huge"],
              "type": "fill"
            },
            {
              "question": "Apple",
              "answers": ["Apple", "Orange", "Banana", "Carrot"],
              "type": "pick"
            },
            {
              "question": "Before the accident, he was very _____.",
              "answers": ["fast"],
              "type": "fill"
            },
            {
              "question": "That building was built 200 years ago. It is _____.",
              "answers": ["ancient"],
              "type": "fill"
            }
          ],
        ),
        52: Level(
          id: 52,
          description: "Past Opposites",
          reward: 100,
          questions: [
            {
              "question": "Yesterday, the weather was not cold, it was _____.",
              "answers": ["hot"],
              "type": "fill"
            },
            {
              "question": "That pillow wasn’t soft, it was _____.",
              "answers": ["hard"],
              "type": "fill"
            },
            {
              "question": "Clock",
              "answers": ["Clock", "Rock", "Stock", "Shock"],
              "type": "pick"
            },
            {
              "question": "Before sunrise, the sky wasn’t light, it was _____.",
              "answers": ["dark"],
              "type": "fill"
            },
            {
              "question": "That chair was not strong, it was _____.",
              "answers": ["weak"],
              "type": "fill"
            }
          ],
        ),
        53: Level(
          id: 53,
          description: "Past Beach Activities",
          reward: 100,
          questions: [
            {
              "question": "Last summer, people built sandcastles with _____.",
              "answers": ["sand"],
              "type": "fill"
            },
            {
              "question": "We swam in the _____ last year.",
              "answers": ["ocean"],
              "type": "fill"
            },
            {
              "question": "Star",
              "answers": ["Star", "Far", "Car", "Jar"],
              "type": "pick"
            },
            {
              "question": "Yesterday, I wore _____ to protect my eyes.",
              "answers": ["sunglasses"],
              "type": "fill"
            },
            {
              "question": "On our last trip, we collected beautiful _____.",
              "answers": ["shells"],
              "type": "fill"
            }
          ],
        ),
        54: Level(
          id: 54,
          description: "Past Body Actions",
          reward: 100,
          questions: [
            {
              "question": "Yesterday, I used my mouth to _____.",
              "answers": ["speak"],
              "type": "fill"
            },
            {
              "question": "He _____ fast to catch the bus.",
              "answers": ["ran"],
              "type": "fill"
            },
            {
              "question": "Ball",
              "answers": ["Ball", "Tall", "Wall", "Call"],
              "type": "pick"
            },
            {
              "question":
                  "The comedian was funny, so the audience _____ a lot.",
              "answers": ["laughed"],
              "type": "fill"
            },
            {
              "question": "She was tired, so she _____ loudly.",
              "answers": ["yawned"],
              "type": "fill"
            }
          ],
        ),
        55: Level(
          id: 55,
          description: "Household Chores (Past)",
          reward: 100,
          questions: [
            {
              "question": "Yesterday, I _____ the floor with a vacuum.",
              "answers": ["cleaned"],
              "type": "fill"
            },
            {
              "question": "After dinner, we _____ the dishes.",
              "answers": ["washed"],
              "type": "fill"
            },
            {
              "question": "Shoes",
              "answers": ["Shoes", "Socks", "Boots", "Slippers"],
              "type": "pick"
            },
            {
              "question": "Before school, I _____ my bed.",
              "answers": ["made"],
              "type": "fill"
            },
            {
              "question": "To remove dust, we _____ a duster.",
              "answers": ["used"],
              "type": "fill"
            }
          ],
        ),
        56: Level(
          id: 56,
          description: "Festivals & Holidays (Past)",
          reward: 100,
          questions: [
            {
              "question": "Last year, we celebrated Christmas in _____.",
              "answers": ["December"],
              "type": "fill"
            },
            {
              "question": "On Halloween, children _____ costumes.",
              "answers": ["wore"],
              "type": "fill"
            },
            {
              "question": "Moon",
              "answers": ["Moon", "Noon", "Soon", "Balloon"],
              "type": "pick"
            },
            {
              "question": "At midnight, we _____ fireworks on New Year's Eve.",
              "answers": ["lit"],
              "type": "fill"
            },
            {
              "question": "Last year, we attended the festival called _____.",
              "answers": ["Holi"],
              "type": "fill"
            }
          ],
        ),
        57: Level(
          id: 57,
          description: "Transportation & Directions (Past)",
          reward: 100,
          questions: [
            {
              "question": "Yesterday, he _____ a car to work.",
              "answers": ["drove"],
              "type": "fill"
            },
            {
              "question": "The ship _____ on the water for a long time.",
              "answers": ["traveled"],
              "type": "fill"
            },
            {
              "question": "Car",
              "answers": ["Car", "Bus", "Bike", "Train"],
              "type": "pick"
            },
            {
              "question": "When the traffic light turned red, we _____.",
              "answers": ["stopped"],
              "type": "fill"
            },
            {
              "question": "When the light turned green, they _____ moving.",
              "answers": ["started"],
              "type": "fill"
            }
          ],
        ),
        58: Level(
          id: 58,
          description: "Fruits & Vegetables (Past)",
          reward: 100,
          questions: [
            {
              "question": "Yesterday, I ate a _____ banana.",
              "answers": ["ripe"],
              "type": "fill"
            },
            {
              "question": "We _____ orange juice from fresh oranges.",
              "answers": ["made"],
              "type": "fill"
            },
            {
              "question": "Apple",
              "answers": ["Apple", "Orange", "Banana", "Carrot"],
              "type": "pick"
            },
            {
              "question": "The rabbits _____ a big carrot in the garden.",
              "answers": ["found"],
              "type": "fill"
            },
            {
              "question": "The tomatoes _____ red last summer.",
              "answers": ["were"],
              "type": "fill"
            }
          ],
        ),
        59: Level(
          id: 59,
          description: "School Supplies (Past)",
          reward: 100,
          questions: [
            {
              "question": "I _____ on a notebook during class.",
              "answers": ["wrote"],
              "type": "fill"
            },
            {
              "question": "Yesterday, I _____ a mistake, so I used an eraser.",
              "answers": ["made"],
              "type": "fill"
            },
            {
              "question": "Pen",
              "answers": ["Pen", "Pencil", "Eraser", "Marker"],
              "type": "pick"
            },
            {
              "question": "Last week, I _____ my books in a backpack.",
              "answers": ["carried"],
              "type": "fill"
            },
            {
              "question": "The ruler _____ me measure the paper.",
              "answers": ["helped"],
              "type": "fill"
            }
          ],
        ),
        60: Level(
          id: 60,
          description: "Common Actions (Past)",
          reward: 100,
          questions: [
            {
              "question": "Before eating, I _____ my hands.",
              "answers": ["washed"],
              "type": "fill"
            },
            {
              "question": "We _____ dinner at 7 PM.",
              "answers": ["ate"],
              "type": "fill"
            },
            {
              "question": "Water",
              "answers": ["Water", "Later", "Cater", "Hater"],
              "type": "pick"
            },
            {
              "question": "Before leaving the room, I _____ off the light.",
              "answers": ["turned"],
              "type": "fill"
            },
            {
              "question": "Before bed, we _____ our teeth.",
              "answers": ["brushed"],
              "type": "fill"
            }
          ],
        ),
        61: Level(
          id: 61,
          description: "Daily Activities (Past)",
          reward: 100,
          questions: [
            {
              "question": "She _____ some coffee and grabbed a cup.",
              "answers": ["made"],
              "type": "fill"
            },
            {
              "question": "They _____ to work and arrived on time.",
              "answers": ["went"],
              "type": "fill"
            },
            {
              "question": "He _____ on his shoes before leaving the house.",
              "answers": ["put"],
              "type": "fill"
            },
            {
              "question": "She _____ an alarm and then went to bed.",
              "answers": ["set"],
              "type": "fill"
            },
            {
              "question": "Morning",
              "answers": ["Morning", "Evening", "Night", "Afternoon"],
              "type": "pick"
            }
          ],
        ),
        62: Level(
          id: 62,
          description: "At Home",
          reward: 100,
          questions: [
            {
              "question": "He placed _____ books on _____ shelf.",
              "answers": ["his", "the"],
              "type": "fill"
            },
            {
              "question": "She turned _____ the TV and went _____ sleep.",
              "answers": ["off", "to"],
              "type": "fill"
            },
            {
              "question": "They sat _____ the couch and watched _____ movie.",
              "answers": ["on", "a"],
              "type": "fill"
            },
            {
              "question":
                  "The dog ran _____ the garden and barked _____ the cat.",
              "answers": ["through", "at"],
              "type": "fill"
            },
            {
              "question": "Chair",
              "answers": ["Chair", "Table", "Couch", "Door"],
              "type": "pick"
            }
          ],
        ),
        63: Level(
          id: 63,
          description: "School & Learning",
          reward: 100,
          questions: [
            {
              "question": "He wrote _____ answers on _____ paper.",
              "answers": ["his", "the"],
              "type": "fill"
            },
            {
              "question": "She borrowed _____ book from _____ library.",
              "answers": ["a", "the"],
              "type": "fill"
            },
            {
              "question": "Notebook",
              "answers": ["Notebook", "Eraser", "Pen", "Backpack"],
              "type": "pick"
            },
            {
              "question": "The teacher gave _____ students _____ homework.",
              "answers": ["the", "some"],
              "type": "fill"
            },
            {
              "question": "Test",
              "answers": ["Test", "Game", "Song", "Picture"],
              "type": "pick"
            }
          ],
        ),
        64: Level(
          id: 64,
          description: "Shopping & Money",
          reward: 100,
          questions: [
            {
              "question": "She bought _____ jacket and paid _____ card.",
              "answers": ["a", "by"],
              "type": "fill"
            },
            {
              "question":
                  "They looked _____ the price and checked _____ budget.",
              "answers": ["at", "their"],
              "type": "fill"
            },
            {
              "question": "Shoes",
              "answers": ["Shoes", "Hat", "Gloves", "Scarf"],
              "type": "pick"
            },
            {
              "question":
                  "He saved _____ money and spent _____ little on coffee.",
              "answers": ["some", "a"],
              "type": "fill"
            },
            {
              "question": "Cash",
              "answers": ["Cash", "Credit", "Ticket", "Phone"],
              "type": "pick"
            }
          ],
        ),
        65: Level(
          id: 65,
          description: "Travel & Transportation",
          reward: 100,
          questions: [
            {
              "question":
                  "They booked _____ flight to New York and packed _____ bags.",
              "answers": ["a", "their"],
              "type": "fill"
            },
            {
              "question":
                  "She sat _____ the window seat and looked _____ the clouds.",
              "answers": ["by", "at"],
              "type": "fill"
            },
            {
              "question": "Bus",
              "answers": ["Bus", "Car", "Train", "Plane"],
              "type": "pick"
            },
            {
              "question":
                  "He arrived _____ the airport and checked _____ his tickets.",
              "answers": ["at", "in"],
              "type": "fill"
            },
            {
              "question": "Ticket",
              "answers": ["Ticket", "Suitcase", "Backpack", "Wallet"],
              "type": "pick"
            }
          ],
        ),
        66: Level(
          id: 66,
          description: "People & Emotions",
          reward: 100,
          questions: [
            {
              "question":
                  "He was feeling _____ after working _____ the whole day.",
              "answers": ["tired", "for"],
              "type": "fill"
            },
            {
              "question": "She smiled _____ her friend and said _____ hello.",
              "answers": ["at", "a"],
              "type": "fill"
            },
            {
              "question": "Happy",
              "answers": ["Happy", "Sad", "Angry", "Tired"],
              "type": "pick"
            },
            {
              "question":
                  "They were excited _____ their trip and packed _____ clothes.",
              "answers": ["for", "some"],
              "type": "fill"
            },
            {
              "question": "Nervous",
              "answers": ["Nervous", "Brave", "Relaxed", "Sleepy"],
              "type": "pick"
            }
          ],
        ),
        67: Level(
          id: 67,
          description: "Food & Drinks",
          reward: 100,
          questions: [
            {
              "question":
                  "She poured _____ juice into a glass and drank it _____ breakfast.",
              "answers": ["some", "with"],
              "type": "fill"
            },
            {
              "question":
                  "The chef placed a _____ on the plate next to _____ potatoes.",
              "answers": ["steak", "some"],
              "type": "fill"
            },
            {
              "question": "Fruit",
              "answers": ["Fruit", "Vegetable", "Meat", "Bread"],
              "type": "pick"
            },
            {
              "question":
                  "They ordered a large _____ and shared it _____ their friends.",
              "answers": ["pizza", "with"],
              "type": "fill"
            },
            {
              "question": "Drink",
              "answers": ["Drink", "Snack", "Meal", "Dessert"],
              "type": "pick"
            }
          ],
        ),
        68: Level(
          id: 68,
          description: "Shopping & Money",
          reward: 100,
          questions: [
            {
              "question": "She bought a new _____ and paid _____ cash.",
              "answers": ["dress", "in"],
              "type": "fill"
            },
            {
              "question": "They went _____ the store to buy _____ groceries.",
              "answers": ["to", "some"],
              "type": "fill"
            },
            {
              "question": "Shoes",
              "answers": ["Shoes", "Hat", "Gloves", "Scarf"],
              "type": "pick"
            },
            {
              "question":
                  "The cashier handed him _____ change after he paid _____ card.",
              "answers": ["some", "by"],
              "type": "fill"
            },
            {
              "question": "Wallet",
              "answers": ["Wallet", "Phone", "Key", "Belt"],
              "type": "pick"
            }
          ],
        ),
        69: Level(
          id: 69,
          description: "Basic Conversations",
          reward: 100,
          questions: [
            {
              "question":
                  "She said _____ and introduced herself _____ the group.",
              "answers": ["hello", "to"],
              "type": "fill"
            },
            {
              "question": "He asked _____ the time and checked _____ watch.",
              "answers": ["for", "his"],
              "type": "fill"
            },
            {
              "question": "Goodbye",
              "answers": ["Goodbye", "Hello", "Yes", "No"],
              "type": "pick"
            },
            {
              "question":
                  "They thanked their host _____ the dinner and left _____ home.",
              "answers": ["for", "for"],
              "type": "fill"
            },
            {
              "question": "Thanks",
              "answers": ["Thanks", "Sorry", "Please", "Welcome"],
              "type": "pick"
            }
          ],
        ),
        70: Level(
          id: 70,
          description: "More Everyday Actions",
          reward: 100,
          questions: [
            {
              "question": "She opened the _____ and stepped _____ the room.",
              "answers": ["door", "into"],
              "type": "fill"
            },
            {
              "question":
                  "They walked _____ the park and talked _____ their day.",
              "answers": ["through", "about"],
              "type": "fill"
            },
            {
              "question": "Run",
              "answers": ["Run", "Jump", "Sit", "Stand"],
              "type": "pick"
            },
            {
              "question": "He picked up _____ bag and left _____ work.",
              "answers": ["his", "for"],
              "type": "fill"
            },
            {
              "question": "Walk",
              "answers": ["Walk", "Talk", "Read", "Eat"],
              "type": "pick"
            }
          ],
        ),
        71: Level(
          id: 71,
          description: "Morning Routine",
          reward: 100,
          questions: [
            {
              "question": "She brushed _____ teeth before leaving _____ house.",
              "answers": ["her", "the"],
              "type": "fill"
            },
            {
              "question": "He made _____ coffee and ate _____ toast.",
              "answers": ["some", "his"],
              "type": "fill"
            },
            {
              "question": "Shower",
              "answers": ["Shower", "Sleep", "Dinner", "Walk"],
              "type": "pick"
            },
            {
              "question": "They left _____ home and went _____ school.",
              "answers": ["their", "to"],
              "type": "fill"
            },
            {
              "question": "Alarm",
              "answers": ["Alarm", "Pillow", "Spoon", "Cup"],
              "type": "pick"
            }
          ],
        ),
        72: Level(
          id: 72,
          description: "Weather & Seasons",
          reward: 100,
          questions: [
            {
              "question":
                  "It was raining, so they stayed _____ the house all _____.",
              "answers": ["inside", "day"],
              "type": "fill"
            },
            {
              "question":
                  "The sun was shining _____ the sky on a _____ afternoon.",
              "answers": ["in", "warm"],
              "type": "fill"
            },
            {
              "question": "Snow",
              "answers": ["Snow", "Rain", "Wind", "Fog"],
              "type": "pick"
            },
            {
              "question":
                  "Leaves change color _____ autumn and fall _____ the ground.",
              "answers": ["in", "to"],
              "type": "fill"
            },
            {
              "question": "Summer",
              "answers": ["Summer", "Winter", "Spring", "Fall"],
              "type": "pick"
            }
          ],
        ),
        73: Level(
          id: 73,
          description: "Transportation",
          reward: 100,
          questions: [
            {
              "question": "They took _____ train and arrived _____ time.",
              "answers": ["the", "on"],
              "type": "fill"
            },
            {
              "question":
                  "He rode _____ bike to work and parked it _____ the office.",
              "answers": ["his", "near"],
              "type": "fill"
            },
            {
              "question": "Car",
              "answers": ["Car", "Bus", "Boat", "Bike"],
              "type": "pick"
            },
            {
              "question":
                  "She waited _____ the bus stop and checked _____ phone.",
              "answers": ["at", "her"],
              "type": "fill"
            },
            {
              "question": "Plane",
              "answers": ["Plane", "Truck", "Motorcycle", "Subway"],
              "type": "pick"
            }
          ],
        ),
        74: Level(
          id: 74,
          description: "Basic Actions",
          reward: 100,
          questions: [
            {
              "question": "He picked _____ the phone and called _____ friend.",
              "answers": ["up", "his"],
              "type": "fill"
            },
            {
              "question": "She opened _____ book and started _____ read.",
              "answers": ["her", "to"],
              "type": "fill"
            },
            {
              "question": "Jump",
              "answers": ["Jump", "Sit", "Sleep", "Cook"],
              "type": "pick"
            },
            {
              "question": "They walked _____ the park and talked _____ life.",
              "answers": ["through", "about"],
              "type": "fill"
            },
            {
              "question": "Run",
              "answers": ["Run", "Talk", "Write", "Sing"],
              "type": "pick"
            }
          ],
        ),
        75: Level(
          id: 75,
          description: "Shopping & Buying",
          reward: 100,
          questions: [
            {
              "question": "She bought _____ apples and paid _____ cash.",
              "answers": ["some", "in"],
              "type": "fill"
            },
            {
              "question": "He looked _____ the price and checked _____ wallet.",
              "answers": ["at", "his"],
              "type": "fill"
            },
            {
              "question": "Shoes",
              "answers": ["Shoes", "Hat", "Shirt", "Bag"],
              "type": "pick"
            },
            {
              "question": "They waited _____ the checkout and held _____ bags.",
              "answers": ["at", "their"],
              "type": "fill"
            },
            {
              "question": "Cashier",
              "answers": ["Cashier", "Waiter", "Driver", "Cook"],
              "type": "pick"
            }
          ],
        ),
        76: Level(
          id: 76,
          description: "Describing Situations",
          reward: 100,
          questions: [
            {
              "question":
                  "She was feeling _____ after working _____ the whole night.",
              "answers": ["exhausted", "through"],
              "type": "fill"
            },
            {
              "question":
                  "The lecture was so _____ that he struggled to stay _____.",
              "answers": ["boring", "awake"],
              "type": "fill"
            },
            {
              "question": "Difficult",
              "answers": ["Difficult", "Easy", "Simple", "Slow"],
              "type": "pick"
            },
            {
              "question":
                  "He remained _____ even though the situation was _____.",
              "answers": ["calm", "stressful"],
              "type": "fill"
            },
            {
              "question": "Complex",
              "answers": ["Complex", "Basic", "Quiet", "Fast"],
              "type": "pick"
            }
          ],
        ),
        77: Level(
          id: 77,
          description: "Work & Career",
          reward: 100,
          questions: [
            {
              "question":
                  "He submitted _____ report before leaving _____ office.",
              "answers": ["his", "the"],
              "type": "fill"
            },
            {
              "question":
                  "She was promoted _____ manager because of _____ performance.",
              "answers": ["to", "her"],
              "type": "fill"
            },
            {
              "question": "Deadline",
              "answers": ["Deadline", "Holiday", "Vacation", "Break"],
              "type": "pick"
            },
            {
              "question":
                  "They had a meeting _____ their client to discuss _____ project.",
              "answers": ["with", "the"],
              "type": "fill"
            },
            {
              "question": "Presentation",
              "answers": ["Presentation", "Exercise", "Lecture", "Interview"],
              "type": "pick"
            }
          ],
        ),
        78: Level(
          id: 78,
          description: "Advanced Travel & Directions",
          reward: 100,
          questions: [
            {
              "question":
                  "She followed the map carefully and walked _____ the busy streets to reach _____ hotel.",
              "answers": ["through", "the"],
              "type": "fill"
            },
            {
              "question":
                  "After checking _____ the train schedule, they realized they were _____ late.",
              "answers": ["on", "too"],
              "type": "fill"
            },
            {
              "question": "Journey",
              "answers": ["Journey", "Event", "Lecture", "Challenge"],
              "type": "pick"
            },
            {
              "question":
                  "He asked _____ directions but still took _____ wrong turn.",
              "answers": ["for", "a"],
              "type": "fill"
            },
            {
              "question": "Navigation",
              "answers": ["Navigation", "Tradition", "Vacation", "Destination"],
              "type": "pick"
            }
          ],
        ),
        79: Level(
          id: 79,
          description: "Health & Lifestyle",
          reward: 100,
          questions: [
            {
              "question":
                  "Eating _____ food and exercising regularly contributes _____ good health.",
              "answers": ["nutritious", "to"],
              "type": "fill"
            },
            {
              "question":
                  "He was advised _____ rest and drink plenty _____ water.",
              "answers": ["to", "of"],
              "type": "fill"
            },
            {
              "question": "Hydration",
              "answers": ["Hydration", "Fasting", "Exhaustion", "Tension"],
              "type": "pick"
            },
            {
              "question":
                  "The doctor recommended reducing _____ intake of sugar and _____ more vegetables.",
              "answers": ["the", "eating"],
              "type": "fill"
            },
            {
              "question": "Wellness",
              "answers": ["Wellness", "Illness", "Weakness", "Fatigue"],
              "type": "pick"
            }
          ],
        ),
        80: Level(
          id: 80,
          description: "Technology & Communication",
          reward: 100,
          questions: [
            {
              "question": "She sent _____ email and waited _____ a response.",
              "answers": ["an", "for"],
              "type": "fill"
            },
            {
              "question":
                  "The app crashed _____ opening, so he restarted _____ phone.",
              "answers": ["upon", "his"],
              "type": "fill"
            },
            {
              "question": "Software",
              "answers": ["Software", "Hardware", "Battery", "Charger"],
              "type": "pick"
            },
            {
              "question":
                  "He forgot _____ save the file before turning _____ the computer.",
              "answers": ["to", "off"],
              "type": "fill"
            },
            {
              "question": "Update",
              "answers": ["Update", "Backup", "Download", "Storage"],
              "type": "pick"
            }
          ],
        ),
        81: Level(
          id: 81,
          description: "Advanced Conversations",
          reward: 100,
          questions: [
            {
              "question":
                  "She apologized _____ being late and explained _____ happened.",
              "answers": ["for", "what"],
              "type": "fill"
            },
            {
              "question":
                  "He hesitated _____ answering because he wasn't _____ sure.",
              "answers": ["before", "completely"],
              "type": "fill"
            },
            {
              "question": "Discussion",
              "answers": ["Discussion", "Argument", "Decision", "Debate"],
              "type": "pick"
            },
            {
              "question":
                  "They talked _____ hours but still couldn’t find _____ solution.",
              "answers": ["for", "a"],
              "type": "fill"
            },
            {
              "question": "Expression",
              "answers": ["Expression", "Question", "Response", "Statement"],
              "type": "pick"
            }
          ],
        ),
        82: Level(
          id: 82,
          description: "Science & Nature",
          reward: 100,
          questions: [
            {
              "question": "Plants need _____ and water to grow _____.",
              "answers": ["sunlight", "properly"],
              "type": "fill"
            },
            {
              "question":
                  "The experiment failed because _____ conditions were not _____.",
              "answers": ["the", "right"],
              "type": "fill"
            },
            {
              "question": "Gravity",
              "answers": ["Gravity", "Energy", "Friction", "Electricity"],
              "type": "pick"
            },
            {
              "question":
                  "The scientist explained _____ process and showed _____ results.",
              "answers": ["the", "his"],
              "type": "fill"
            },
            {
              "question": "Evolution",
              "answers": ["Evolution", "Revolution", "Mutation", "Explosion"],
              "type": "pick"
            }
          ],
        ),
        83: Level(
          id: 83,
          description: "News & Media",
          reward: 100,
          questions: [
            {
              "question":
                  "She read _____ article and shared it _____ her friends.",
              "answers": ["an", "with"],
              "type": "fill"
            },
            {
              "question":
                  "The journalist reported _____ the event as it was _____.",
              "answers": ["on", "happening"],
              "type": "fill"
            },
            {
              "question": "Headline",
              "answers": ["Headline", "Deadline", "Tagline", "Slogan"],
              "type": "pick"
            },
            {
              "question":
                  "The news spread _____ social media within _____ minutes.",
              "answers": ["on", "a few"],
              "type": "fill"
            },
            {
              "question": "Broadcast",
              "answers": ["Broadcast", "Podcast", "Newscast", "Forecast"],
              "type": "pick"
            }
          ],
        ),
        84: Level(
          id: 84,
          description: "Technology & Innovation",
          reward: 100,
          questions: [
            {
              "question":
                  "The company developed _____ new software to improve _____ security.",
              "answers": ["a", "data"],
              "type": "fill"
            },
            {
              "question":
                  "He updated _____ system and installed _____ latest features.",
              "answers": ["his", "the"],
              "type": "fill"
            },
            {
              "question": "Encryption",
              "answers": ["Encryption", "Firewall", "Processor", "Virus"],
              "type": "pick"
            },
            {
              "question":
                  "The website crashed due _____ an unexpected error in _____ code.",
              "answers": ["to", "the"],
              "type": "fill"
            },
            {
              "question": "Algorithm",
              "answers": ["Algorithm", "Application", "Database", "Interface"],
              "type": "pick"
            }
          ],
        ),
        85: Level(
          id: 85,
          description: "Economy & Business",
          reward: 100,
          questions: [
            {
              "question":
                  "The company invested _____ new markets to increase _____ revenue.",
              "answers": ["in", "its"],
              "type": "fill"
            },
            {
              "question":
                  "He managed _____ team and ensured all tasks were _____ completed.",
              "answers": ["his", "properly"],
              "type": "fill"
            },
            {
              "question": "Profit",
              "answers": ["Profit", "Loss", "Debt", "Tax"],
              "type": "pick"
            },
            {
              "question":
                  "They discussed the financial report _____ the board meeting last _____.",
              "answers": ["at", "week"],
              "type": "fill"
            },
            {
              "question": "Investment",
              "answers": ["Investment", "Expense", "Bankruptcy", "Transaction"],
              "type": "pick"
            }
          ],
        ),
        86: Level(
          id: 86,
          description: "Politics & Society",
          reward: 100,
          questions: [
            {
              "question":
                  "The government introduced _____ policy to improve _____ economy.",
              "answers": ["a", "the"],
              "type": "fill"
            },
            {
              "question":
                  "He voted _____ the election and encouraged others _____ do the same.",
              "answers": ["in", "to"],
              "type": "fill"
            },
            {
              "question": "Democracy",
              "answers": ["Democracy", "Monarchy", "Dictatorship", "Anarchy"],
              "type": "pick"
            },
            {
              "question":
                  "The law was passed _____ a majority vote in _____ parliament.",
              "answers": ["by", "the"],
              "type": "fill"
            },
            {
              "question": "Government",
              "answers": ["Government", "Organization", "Business", "Union"],
              "type": "pick"
            }
          ],
        ),
        87: Level(
          id: 87,
          description: "Legal & Crime",
          reward: 100,
          questions: [
            {
              "question":
                  "The lawyer prepared _____ case carefully before presenting it _____ court.",
              "answers": ["the", "in"],
              "type": "fill"
            },
            {
              "question":
                  "The suspect was found _____ and sentenced _____ five years in prison.",
              "answers": ["guilty", "to"],
              "type": "fill"
            },
            {
              "question": "Evidence",
              "answers": ["Evidence", "Verdict", "Trial", "Witness"],
              "type": "pick"
            },
            {
              "question":
                  "The police conducted _____ investigation and arrested _____ suspect.",
              "answers": ["an", "a"],
              "type": "fill"
            },
            {
              "question": "Justice",
              "answers": ["Justice", "Penalty", "Arrest", "Crime"],
              "type": "pick"
            }
          ],
        ),
        88: Level(
          id: 88,
          description: "Advanced Science & Technology",
          reward: 100,
          questions: [
            {
              "question":
                  "Scientists discovered _____ new element that reacts _____ oxygen.",
              "answers": ["a", "with"],
              "type": "fill"
            },
            {
              "question":
                  "The research was conducted _____ multiple universities to analyze _____ impact.",
              "answers": ["by", "its"],
              "type": "fill"
            },
            {
              "question": "Innovation",
              "answers": ["Innovation", "Discovery", "Experiment", "Theory"],
              "type": "pick"
            },
            {
              "question":
                  "Artificial intelligence is transforming _____ industries by increasing _____ efficiency.",
              "answers": ["many", "their"],
              "type": "fill"
            },
            {
              "question": "Breakthrough",
              "answers": ["Breakthrough", "Complication", "Error", "Failure"],
              "type": "pick"
            }
          ],
        ),
        89: Level(
          id: 89,
          description: "Cultural Differences & Globalization",
          reward: 100,
          questions: [
            {
              "question":
                  "Every country has _____ unique traditions that are passed _____ generations.",
              "answers": ["its", "through"],
              "type": "fill"
            },
            {
              "question":
                  "As globalization increases, people become more _____ about cultures _____ the world.",
              "answers": ["aware", "around"],
              "type": "fill"
            },
            {
              "question": "Tradition",
              "answers": ["Tradition", "Custom", "Norm", "Belief"],
              "type": "pick"
            },
            {
              "question":
                  "Cultural exchange allows societies to share _____ ideas and create _____ understanding.",
              "answers": ["new", "better"],
              "type": "fill"
            },
            {
              "question": "Diversity",
              "answers": [
                "Diversity",
                "Separation",
                "Exclusion",
                "Restriction"
              ],
              "type": "pick"
            }
          ],
        ),
        90: Level(
          id: 90,
          description: "Philosophy & Ethics",
          reward: 100,
          questions: [
            {
              "question":
                  "Ethics play _____ important role in decision-making in _____ society.",
              "answers": ["an", "every"],
              "type": "fill"
            },
            {
              "question":
                  "Philosophers have debated _____ concept of morality for _____ centuries.",
              "answers": ["the", "many"],
              "type": "fill"
            },
            {
              "question": "Wisdom",
              "answers": ["Wisdom", "Knowledge", "Experience", "Instinct"],
              "type": "pick"
            },
            {
              "question":
                  "Some argue that moral values should be _____, while others believe they are _____.",
              "answers": ["universal", "subjective"],
              "type": "fill"
            },
            {
              "question": "Ethics",
              "answers": ["Ethics", "Justice", "Principle", "Laws"],
              "type": "pick"
            }
          ],
        ),
        91: Level(
          id: 91,
          description: "Psychology & Human Behavior",
          reward: 100,
          questions: [
            {
              "question":
                  "Cognitive biases influence _____ decisions and shape _____ perceptions.",
              "answers": ["our", "our"],
              "type": "fill"
            },
            {
              "question":
                  "He struggled _____ anxiety but learned _____ manage it through therapy.",
              "answers": ["with", "to"],
              "type": "fill"
            },
            {
              "question": "Motivation",
              "answers": ["Motivation", "Depression", "Stress", "Fear"],
              "type": "pick"
            },
            {
              "question":
                  "Studies suggest that emotions play _____ crucial role in _____ reasoning.",
              "answers": ["a", "human"],
              "type": "fill"
            },
            {
              "question": "Subconscious",
              "answers": ["Subconscious", "Memory", "Awareness", "Imagination"],
              "type": "pick"
            }
          ],
        ),
        92: Level(
          id: 92,
          description: "Environmental Issues & Sustainability",
          reward: 100,
          questions: [
            {
              "question":
                  "Deforestation contributes _____ climate change and affects _____ biodiversity.",
              "answers": ["to", "global"],
              "type": "fill"
            },
            {
              "question":
                  "Many organizations promote _____ energy to reduce _____ emissions.",
              "answers": ["renewable", "carbon"],
              "type": "fill"
            },
            {
              "question": "Ecosystem",
              "answers": ["Ecosystem", "Pollution", "Industry", "Consumption"],
              "type": "pick"
            },
            {
              "question":
                  "Recycling helps decrease _____ waste and conserve _____ resources.",
              "answers": ["plastic", "natural"],
              "type": "fill"
            },
            {
              "question": "Sustainability",
              "answers": [
                "Sustainability",
                "Development",
                "Expansion",
                "Production"
              ],
              "type": "pick"
            }
          ],
        ),
        93: Level(
          id: 93,
          description: "Artificial Intelligence & Future Technologies",
          reward: 100,
          questions: [
            {
              "question":
                  "Artificial intelligence is transforming _____ industries by improving _____ efficiency.",
              "answers": ["multiple", "their"],
              "type": "fill"
            },
            {
              "question":
                  "Machine learning enables computers _____ analyze data and make _____ decisions.",
              "answers": ["to", "independent"],
              "type": "fill"
            },
            {
              "question": "Automation",
              "answers": [
                "Automation",
                "Cryptography",
                "Neuroscience",
                "Electronics"
              ],
              "type": "pick"
            },
            {
              "question":
                  "Experts debate whether AI should have _____ rights similar _____ humans.",
              "answers": ["ethical", "to"],
              "type": "fill"
            },
            {
              "question": "Singularity",
              "answers": [
                "Singularity",
                "Expansion",
                "Innovation",
                "Development"
              ],
              "type": "pick"
            }
          ],
        ),
        94: Level(
          id: 94,
          description: "Advanced Economics & Global Trade",
          reward: 100,
          questions: [
            {
              "question":
                  "Inflation occurs when the value of _____ currency decreases over _____.",
              "answers": ["a", "time"],
              "type": "fill"
            },
            {
              "question":
                  "Governments regulate _____ markets to ensure _____ competition.",
              "answers": ["financial", "fair"],
              "type": "fill"
            },
            {
              "question": "Recession",
              "answers": ["Recession", "Boom", "Surplus", "Inflation"],
              "type": "pick"
            },
            {
              "question":
                  "International trade agreements affect _____ economies and influence _____ policies.",
              "answers": ["global", "economic"],
              "type": "fill"
            },
            {
              "question": "Monetary",
              "answers": ["Monetary", "Fiscal", "Political", "Strategic"],
              "type": "pick"
            }
          ],
        ),
        95: Level(
          id: 95,
          description: "Philosophy of Science & Knowledge",
          reward: 100,
          questions: [
            {
              "question":
                  "The scientific method requires _____ observation and experimentation to test _____ hypothesis.",
              "answers": ["systematic", "a"],
              "type": "fill"
            },
            {
              "question":
                  "Philosophers debate whether knowledge is _____ constructed or _____ discovered.",
              "answers": ["socially", "objectively"],
              "type": "fill"
            },
            {
              "question": "Empiricism",
              "answers": ["Empiricism", "Dogma", "Tradition", "Speculation"],
              "type": "pick"
            },
            {
              "question":
                  "Skepticism encourages people _____ question assumptions and think _____.",
              "answers": ["to", "critically"],
              "type": "fill"
            },
            {
              "question": "Epistemology",
              "answers": ["Epistemology", "Ontology", "Logic", "Ethics"],
              "type": "pick"
            }
          ],
        ),
        96: Level(
          id: 96,
          description: "Space Exploration & Astronomy",
          reward: 100,
          questions: [
            {
              "question":
                  "Scientists study _____ objects to understand _____ formation of the universe.",
              "answers": ["celestial", "the"],
              "type": "fill"
            },
            {
              "question":
                  "Astronomers use telescopes _____ observe distant galaxies and analyze _____ composition.",
              "answers": ["to", "their"],
              "type": "fill"
            },
            {
              "question": "Gravity",
              "answers": ["Gravity", "Momentum", "Acceleration", "Friction"],
              "type": "pick"
            },
            {
              "question":
                  "The possibility of life on _____ planets remains one of the biggest _____ mysteries.",
              "answers": ["other", "scientific"],
              "type": "fill"
            },
            {
              "question": "Cosmology",
              "answers": ["Cosmology", "Geology", "Ecology", "Biology"],
              "type": "pick"
            }
          ],
        ),
        97: Level(
          id: 97,
          description: "Medical Science & Healthcare",
          reward: 100,
          questions: [
            {
              "question":
                  "Vaccines help protect _____ population from _____ diseases.",
              "answers": ["the", "infectious"],
              "type": "fill"
            },
            {
              "question":
                  "Doctors must diagnose illnesses _____ precision to prescribe _____ treatments.",
              "answers": ["with", "effective"],
              "type": "fill"
            },
            {
              "question": "Immunity",
              "answers": ["Immunity", "Contamination", "Toxicity", "Exposure"],
              "type": "pick"
            },
            {
              "question":
                  "Advances in medical technology allow _____ detection of diseases and improve _____ outcomes.",
              "answers": ["early", "patient"],
              "type": "fill"
            },
            {
              "question": "Genetics",
              "answers": ["Genetics", "Anatomy", "Radiology", "Pathology"],
              "type": "pick"
            }
          ],
        ),
        98: Level(
          id: 98,
          description: "Cybersecurity & Digital Privacy",
          reward: 100,
          questions: [
            {
              "question":
                  "Encryption is used _____ protect sensitive data from _____ access.",
              "answers": ["to", "unauthorized"],
              "type": "fill"
            },
            {
              "question":
                  "Hackers attempt _____ exploit system vulnerabilities and gain _____ information.",
              "answers": ["to", "confidential"],
              "type": "fill"
            },
            {
              "question": "Firewall",
              "answers": ["Firewall", "Antivirus", "Malware", "Trojan"],
              "type": "pick"
            },
            {
              "question":
                  "Users should create _____ passwords and update them _____ regularly.",
              "answers": ["strong", "more"],
              "type": "fill"
            },
            {
              "question": "Phishing",
              "answers": ["Phishing", "Hacking", "Spamming", "Tracking"],
              "type": "pick"
            }
          ],
        ),
        99: Level(
          id: 99,
          description: "Artificial Intelligence & Ethics",
          reward: 100,
          questions: [
            {
              "question":
                  "Ethical concerns arise when AI makes _____ decisions without _____ input.",
              "answers": ["autonomous", "human"],
              "type": "fill"
            },
            {
              "question":
                  "The development of AI requires careful _____ to avoid _____ consequences.",
              "answers": ["regulation", "unintended"],
              "type": "fill"
            },
            {
              "question": "Bias",
              "answers": [
                "Bias",
                "Innovation",
                "Automation",
                "Standardization"
              ],
              "type": "pick"
            },
            {
              "question":
                  "Companies must ensure AI systems are _____ and free from _____ discrimination.",
              "answers": ["transparent", "algorithmic"],
              "type": "fill"
            },
            {
              "question": "Autonomy",
              "answers": [
                "Autonomy",
                "Supervision",
                "Regulation",
                "Intervention"
              ],
              "type": "pick"
            }
          ],
        ),
        100: Level(
          id: 100,
          description: "Philosophy & Existential Questions",
          reward: 100,
          questions: [
            {
              "question":
                  "Philosophers question _____ meaning of life and _____ nature of existence.",
              "answers": ["the", "the"],
              "type": "fill"
            },
            {
              "question":
                  "Existentialism explores human _____ and the responsibility for _____ choices.",
              "answers": ["freedom", "individual"],
              "type": "fill"
            },
            {
              "question": "Consciousness",
              "answers": [
                "Consciousness",
                "Reality",
                "Knowledge",
                "Experience"
              ],
              "type": "pick"
            },
            {
              "question":
                  "Many argue that morality is _____ constructed, while others believe it is _____.",
              "answers": ["socially", "absolute"],
              "type": "fill"
            },
            {
              "question": "Metaphysics",
              "answers": [
                "Metaphysics",
                "Rationalism",
                "Empiricism",
                "Idealism"
              ],
              "type": "pick"
            }
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
              "question": "Der Hund liegt unter _____ Tisch.",
              "answers": ["dem"],
              "type": "fill"
            },
            {
              "question": "Ich gehe _____ die Schule.",
              "answers": ["in"],
              "type": "fill"
            },
            {
              "question": "Apfel",
              "answers": ["Apfel", "Banane", "Ball", "Maske"],
              "type": "pick"
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
              "question": "Haus",
              "answers": ["Haus", "Baum", "Auto", "Tasche"],
              "type": "pick"
            },
            {
              "question": "Sie gehen _____ das Studio .",
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
              "question": "Er _____ einen Brief geschrieben.",
              "answers": ["hat"],
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
              "question": "Wasser",
              "answers": ["Wasser", "Milch", "Saft", "Tee"],
              "type": "pick"
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
              "question": "Er fährt immer _____ dem Bus.",
              "answers": ["mit"],
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
              "question": "Brot",
              "answers": ["Brot", "Butter", "Käse", "Ei"],
              "type": "pick"
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
              "question": "Blume",
              "answers": ["Blume", "Baum", "Gras", "Ast"],
              "type": "pick"
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
              "question": "Schule",
              "answers": ["Schule", "Universität", "Kino", "Theater"],
              "type": "pick"
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
              "question": "Könntest du _____ bitte den Weg zum Bahnhof zeigen?",
              "answers": ["mir"],
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
          description: "Neue Worte",
          reward: 100,
          questions: [
            {
              "question": "Der Junge liest viel in _____ Bibliothek.",
              "answers": ["der"],
              "type": "fill"
            },
            {
              "question": "Sie wurde im _____ April geboren.",
              "answers": ["Monat"],
              "type": "fill"
            },
            {
              "question": "Er ist sehr gut _____ der Mathematik.",
              "answers": ["in"],
              "type": "fill"
            },
            {
              "question": "Fenster",
              "answers": ["Fenster", "Tür", "Dach", "Treppe"],
              "type": "pick"
            },
            {
              "question": "Buch",
              "answers": ["Buch", "Zeitung", "Heft", "Karte"],
              "type": "pick"
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
              "question": "Küche",
              "answers": ["Küche", "Badezimmer", "Schlafzimmer", "Garten"],
              "type": "pick"
            },
            {
              "question": "Sie sucht _____ ihren verlorenen Schlüssel.",
              "answers": ["nach"],
              "type": "fill"
            },
            {
              "question": "Ich _____ dich gleich an.",
              "answers": ["rufe"],
              "type": "fill"
            },
            {
              "question": "Die Katze sprang _____ den Zaun.",
              "answers": ["über"],
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
              "question": "Er arbeitet _____ Stunden an diesem Problem.",
              "answers": ["seit"],
              "type": "fill"
            },
            {
              "question": "Jacke",
              "answers": ["Jacke", "Hose", "Schuhe", "Hut"],
              "type": "pick"
            },
            {
              "question": "Sie bereitet _____ gerade auf ihre Prüfungen vor.",
              "answers": ["sich"],
              "type": "fill"
            },
            {
              "question":
                  "Die Präsentation _____ für nächsten Montag angesetzt.",
              "answers": ["ist"],
              "type": "fill"
            },
            {
              "question": "Ich bin _____ stolz auf meine Leistungen.",
              "answers": ["sehr"],
              "type": "fill"
            },
          ],
        ),
        11: Level(
          id: 11,
          description: "Reisen & Transport",
          reward: 100,
          questions: [
            {
              "question": "Sie fahren _____ den Urlaub nach Spanien.",
              "answers": ["in"],
              "type": "fill"
            },
            {
              "question": "Er wartet _____ dem Bahnhof auf den Zug.",
              "answers": ["an"],
              "type": "fill"
            },
            {
              "question": "Zug",
              "answers": ["Zug", "Bus", "Auto", "Fahrrad"],
              "type": "pick"
            },
            {
              "question": "Wir fliegen morgen _____ Deutschland.",
              "answers": ["nach"],
              "type": "fill"
            },
            {
              "question": "Das Taxi hält _____ der Ampel.",
              "answers": ["an"],
              "type": "fill"
            }
          ],
        ),
        12: Level(
          id: 12,
          description: "Berufe & Arbeit",
          reward: 100,
          questions: [
            {
              "question": "Mein Vater arbeitet _____ einer großen Firma.",
              "answers": ["bei"],
              "type": "fill"
            },
            {
              "question": "Sie ist _____ Lehrerin tätig.",
              "answers": ["als"],
              "type": "fill"
            },
            {
              "question": "Arzt",
              "answers": ["Arzt", "Ingenieur", "Koch", "Polizist"],
              "type": "pick"
            },
            {
              "question": "Sie führte den _____ im Park aus",
              "answers": ["Hund"],
              "type": "fill"
            },
            {
              "question": "Wir treffen uns morgen _____ Büro.",
              "answers": ["im"],
              "type": "fill"
            }
          ],
        ),
        13: Level(
          id: 13,
          description: "Essen & Trinken",
          reward: 100,
          questions: [
            {
              "question": "Sie bestellt eine Tasse _____ Kaffee.",
              "answers": ["mit"],
              "type": "fill"
            },
            {
              "question": "Das Kind isst _____ gerne Süßes.",
              "answers": ["sehr"],
              "type": "fill"
            },
            {
              "question": "Milch",
              "answers": ["Milch", "Saft", "Wasser", "Bier"],
              "type": "pick"
            },
            {
              "question": "Er hat sich heute ein _____ Brot gemacht.",
              "answers": ["frisches"],
              "type": "fill"
            },
            {
              "question": "Wir essen _____ dem Tisch im Wohnzimmer.",
              "answers": ["an"],
              "type": "fill"
            }
          ],
        ),
        14: Level(
          id: 14,
          description: "Einkaufen & Geld",
          reward: 100,
          questions: [
            {
              "question": "Sie bezahlt _____ Bargeld.",
              "answers": ["mit"],
              "type": "fill"
            },
            {
              "question": "Der Preis _____ das Produkt ist reduziert.",
              "answers": ["für"],
              "type": "fill"
            },
            {
              "question": "Euro",
              "answers": ["Euro", "Dollar", "Yen", "Franken"],
              "type": "pick"
            },
            {
              "question": "Das Geschäft hat täglich _____ 9 Uhr geöffnet.",
              "answers": ["ab"],
              "type": "fill"
            },
            {
              "question": "Ich habe _____ neue Jacke",
              "answers": ["eine"],
              "type": "fill"
            }
          ],
        ),
        15: Level(
          id: 15,
          description: "Familie & Freunde",
          reward: 100,
          questions: [
            {
              "question": "Mein _____ Bruder ist zwei Jahre älter als ich.",
              "answers": ["großer"],
              "type": "fill"
            },
            {
              "question": "Sie verbringt viel Zeit _____ ihrer Familie.",
              "answers": ["mit"],
              "type": "fill"
            },
            {
              "question": "Schwester",
              "answers": ["Schwester", "Cousin", "Opa", "Tante"],
              "type": "pick"
            },
            {
              "question": "Wir treffen uns _____ dem Café.",
              "answers": ["bei"],
              "type": "fill"
            },
            {
              "question": "Meine Eltern wohnen in _____ kleinen Stadt.",
              "answers": ["einer"],
              "type": "fill"
            }
          ],
        ),
        16: Level(
          id: 16,
          description: "Jahreszeiten & Wetter",
          reward: 100,
          questions: [
            {
              "question": "Im Sommer ist es oft _____ warm.",
              "answers": ["sehr"],
              "type": "fill"
            },
            {
              "question": "Es _____, also nehme ich mir einen Regenschirm mit.",
              "answers": ["regnet"],
              "type": "fill"
            },
            {
              "question": "Winter",
              "answers": ["Winter", "Sommer", "Frühling", "Herbst"],
              "type": "pick"
            },
            {
              "question": "Morgen _____ es schneien.",
              "answers": ["soll"],
              "type": "fill"
            },
            {
              "question": "Im Herbst fallen die Blätter _____ den Bäumen.",
              "answers": ["von"],
              "type": "fill"
            }
          ],
        ),
        17: Level(
          id: 17,
          description: "Freizeit & Hobbys",
          reward: 100,
          questions: [
            {
              "question": "Sie _____ Gitarre am Wochenende.",
              "answers": ["spielt"],
              "type": "fill"
            },
            {
              "question": "Er liest _____ ein Buch.",
              "answers": ["gerade"],
              "type": "fill"
            },
            {
              "question": "Sport",
              "answers": ["Sport", "Musik", "Kino", "Reisen"],
              "type": "pick"
            },
            {
              "question": "_____ gehen am Sonntag schwimmen.",
              "answers": ["Wir"],
              "type": "fill"
            },
            {
              "question": "Ich habe eine neue Serie auf Netflix _____.",
              "answers": ["gesehen"],
              "type": "fill"
            }
          ],
        ),
        18: Level(
          id: 18,
          description: "Gesundheit & Körper",
          reward: 100,
          questions: [
            {
              "question": "Ich habe _____ Kopfschmerzen.",
              "answers": ["starke"],
              "type": "fill"
            },
            {
              "question": "Er muss _____ Arzt gehen.",
              "answers": ["zum"],
              "type": "fill"
            },
            {
              "question": "Herz",
              "answers": ["Herz", "Lunge", "Leber", "Magen"],
              "type": "pick"
            },
            {
              "question": "Sie _____ Medizin gegen die Erkältung.",
              "answers": ["nimmt"],
              "type": "fill"
            },
            {
              "question": "Regelmäßige Bewegung ist gut _____ die Gesundheit.",
              "answers": ["für"],
              "type": "fill"
            }
          ],
        ),
        19: Level(
          id: 19,
          description: "Schule & Lernen",
          reward: 100,
          questions: [
            {
              "question": "Ich habe meine Hausaufgaben _____ gemacht.",
              "answers": ["schon"],
              "type": "fill"
            },
            {
              "question": "Er _____ morgen eine Matheprüfung.",
              "answers": ["schreibt"],
              "type": "fill"
            },
            {
              "question": "Tafel",
              "answers": ["Tafel", "Stuhl", "Fenster", "Heft"],
              "type": "pick"
            },
            {
              "question": "Ihr _____ mit dem Lehrer.",
              "answers": ["sprecht"],
              "type": "fill"
            },
            {
              "question": "Ihr _____ gestern mit dem Lehrer.",
              "answers": ["spracht"],
              "type": "fill"
            }
          ],
        ),
        20: Level(
          id: 20,
          description: "Emotionen & Gefühle",
          reward: 100,
          questions: [
            {
              "question": "Ich bin _____ glücklich heute.",
              "answers": ["sehr"],
              "type": "fill"
            },
            {
              "question": "Er war _____ über die Situation.",
              "answers": ["wütend"],
              "type": "fill"
            },
            {
              "question": "Freude",
              "answers": ["Freude", "Angst", "Trauer", "Wut"],
              "type": "pick"
            },
            {
              "question": "Lachen",
              "answers": ["Lachen", "Weinen", "Schreien", "Flüstern"],
              "type": "pick"
            },
            {
              "question": "Freund",
              "answers": ["Freund", "Lehrer", "Schüler", "Kollege"],
              "type": "pick"
            },
          ],
        ),
        21: Level(
          id: 21,
          description: "Grundverben (Gegenwart)",
          reward: 100,
          questions: [
            {
              "question": "Ich _____ einen Apfel.",
              "answers": ["esse"],
              "type": "fill"
            },
            {
              "question": "Du _____ Wasser.",
              "answers": ["trinkst"],
              "type": "fill"
            },
            {
              "question": "Trinken",
              "answers": ["Trinken", "Laufen", "Lesen", "Schreiben"],
              "type": "pick"
            },
            {
              "question": "Er _____ Fußball.",
              "answers": ["spielt"],
              "type": "fill"
            },
            {
              "question": "Sie _____ ein Buch.",
              "answers": ["liest"],
              "type": "fill"
            }
          ],
        ),
        22: Level(
          id: 22,
          description: "Grundverben (Vergangenheit)",
          reward: 100,
          questions: [
            {
              "question": "Ich _____ gestern einen Apfel.",
              "answers": ["aß"],
              "type": "fill"
            },
            {
              "question": "Du _____ gestern Wasser.",
              "answers": ["trankst"],
              "type": "fill"
            },
            {
              "question": "Er _____ gestern Fußball.",
              "answers": ["spielte"],
              "type": "fill"
            },
            {
              "question": "Sie _____ gestern ein Buch.",
              "answers": ["las"],
              "type": "fill"
            },
            {
              "question": "Gestern",
              "answers": ["Gestern", "Morgen", "Heute", "Bald"],
              "type": "pick"
            }
          ],
        ),
        23: Level(
          id: 23,
          description: "Haben & Sein (Gegenwart)",
          reward: 100,
          questions: [
            {
              "question": "Ich _____ einen Tisch.",
              "answers": ["habe"],
              "type": "fill"
            },
            {
              "question": "Haben",
              "answers": ["Haben", "Sein", "Laufen", "Fahren"],
              "type": "pick"
            },
            {
              "question": "Du _____ eine Katze.",
              "answers": ["hast"],
              "type": "fill"
            },
            {
              "question": "Er _____ einen Hund.",
              "answers": ["hat"],
              "type": "fill"
            },
            {
              "question": "Wir _____ viele Freunde.",
              "answers": ["haben"],
              "type": "fill"
            }
          ],
        ),
        24: Level(
          id: 24,
          description: "Haben & Sein (Vergangenheit)",
          reward: 100,
          questions: [
            {
              "question": "Ich _____ gestern einen Tisch.",
              "answers": ["hatte"],
              "type": "fill"
            },
            {
              "question": "War",
              "answers": ["War", "Hatte", "Ist", "Hat"],
              "type": "pick"
            },
            {
              "question": "Du _____ gestern eine Katze.",
              "answers": ["hattest"],
              "type": "fill"
            },
            {
              "question": "Er _____ gestern einen Hund.",
              "answers": ["hatte"],
              "type": "fill"
            },
            {
              "question": "Wir _____ gestern viele Freunde.",
              "answers": ["hatten"],
              "type": "fill"
            },
          ],
        ),
        25: Level(
          id: 25,
          description: "Orte & Richtungen",
          reward: 100,
          questions: [
            {
              "question": "Richtung",
              "answers": ["Richtung", "Stadt", "Küche", "Auto"],
              "type": "pick"
            },
            {
              "question": "Ich gehe _____ Schule.",
              "answers": ["zur"],
              "type": "fill"
            },
            {
              "question": "Du gehst _____ Markt.",
              "answers": ["zum"],
              "type": "fill"
            },
            {
              "question": "Sie fährt _____ Flughafen.",
              "answers": ["zum"],
              "type": "fill"
            },
            {
              "question": "Der Ball ist _____ dem Auto.",
              "answers": ["unter"],
              "type": "fill"
            }
          ],
        ),
        26: Level(
          id: 26,
          description: "Orte & Richtungen (Vergangenheit)",
          reward: 100,
          questions: [
            {
              "question": "Ich _____ gestern zur Schule.",
              "answers": ["ging"],
              "type": "fill"
            },
            {
              "question": "Du _____ gestern zum Markt.",
              "answers": ["gingst"],
              "type": "fill"
            },
            {
              "question": "Sie _____ gestern zum Flughafen.",
              "answers": ["fuhr"],
              "type": "fill"
            },
            {
              "question": "Das Buch _____ gestern auf dem Tisch.",
              "answers": ["lag"],
              "type": "fill"
            },
            {
              "question": "Ort",
              "answers": ["Ort", "Zeit", "Auto", "Küche"],
              "type": "pick"
            }
          ],
        ),
        27: Level(
          id: 27,
          description: "Nehmen & Sehen",
          reward: 100,
          questions: [
            {
              "question": "Sie _____ den Bus.",
              "answers": ["nehmen"],
              "type": "fill"
            },
            {
              "question": "Ich sehe _____ Hund.",
              "answers": ["einen"],
              "type": "fill"
            },
            {
              "question": "Sehen",
              "answers": ["Sehen", "Fahren", "Essen", "Schreiben"],
              "type": "pick"
            },
            {
              "question": "Du kaufst _____ Apfel.",
              "answers": ["einen"],
              "type": "fill"
            },
            {
              "question": "Er hat _____ Buch.",
              "answers": ["ein"],
              "type": "fill"
            }
          ],
        ),
        28: Level(
          id: 28,
          description: "Nehmen & Sehen (Vergangenheit)",
          reward: 100,
          questions: [
            {
              "question": "Gestern",
              "answers": ["Gestern", "Heute", "Morgen", "Später"],
              "type": "pick"
            },
            {
              "question": "Sie _____ gestern den Bus.",
              "answers": ["nahmen"],
              "type": "fill"
            },
            {
              "question": "Ich _____ gestern einen Hund.",
              "answers": ["sah"],
              "type": "fill"
            },
            {
              "question": "Du namhst gestern _____ Apfel.",
              "answers": ["einen"],
              "type": "fill"
            },
            {
              "question": "Er _____ gestern ein Buch gelesen.",
              "answers": ["hatte"],
              "type": "fill"
            }
          ],
        ),
        29: Level(
          id: 29,
          description: "Alltagshandlungen",
          reward: 100,
          questions: [
            {
              "question": "Ich höre _____ Musik.",
              "answers": ["die"],
              "type": "fill"
            },
            {
              "question": "Sie liest _____ Zeitung.",
              "answers": ["die"],
              "type": "fill"
            },
            {
              "question": "Ich esse _____ Suppe.",
              "answers": ["eine"],
              "type": "fill"
            },
            {
              "question": "Essen",
              "answers": ["Essen", "Laufen", "Schreiben", "Sehen"],
              "type": "pick"
            },
            {
              "question": "Du kaufst _____ Zeitung.",
              "answers": ["eine"],
              "type": "fill"
            }
          ],
        ),
        30: Level(
          id: 30,
          description: "Alltagshandlungen (Vergangenheit)",
          reward: 100,
          questions: [
            {
              "question": "Ich _____ gestern die Musik.",
              "answers": ["hörte"],
              "type": "fill"
            },
            {
              "question": "Las",
              "answers": ["Las", "Sah", "Ging", "Trank"],
              "type": "pick"
            },
            {
              "question": "Sie _____ gestern die Zeitung.",
              "answers": ["las"],
              "type": "fill"
            },
            {
              "question": "Ich _____ gestern eine Suppe.",
              "answers": ["aß"],
              "type": "fill"
            },
            {
              "question": "Du _____ gestern eine Zeitung.",
              "answers": ["kauftest"],
              "type": "fill"
            }
          ],
        ),
        31: Level(
          id: 31,
          description: "Modalverben (Gegenwart)",
          reward: 100,
          questions: [
            {
              "question": "Ich _____ Deutsch sprechen.",
              "answers": ["kann"],
              "type": "fill"
            },
            {
              "question": "Müssen",
              "answers": ["Müssen", "Können", "Wollen", "Dürfen"],
              "type": "pick"
            },
            {
              "question": "Du _____ früh aufstehen.",
              "answers": ["musst"],
              "type": "fill"
            },
            {
              "question": "Er _____ ein Eis essen.",
              "answers": ["möchte"],
              "type": "fill"
            },
            {
              "question": "Wir _____ heute ins Kino gehen.",
              "answers": ["wollen"],
              "type": "fill"
            }
          ],
        ),
        32: Level(
          id: 32,
          description: "Modalverben (Vergangenheit)",
          reward: 100,
          questions: [
            {
              "question": "Ich _____ gestern lange arbeiten.",
              "answers": ["musste"],
              "type": "fill"
            },
            {
              "question": "Du _____ gestern dein Zimmer aufräumen.",
              "answers": ["solltest"],
              "type": "fill"
            },
            {
              "question": "Er _____ gestern nicht kommen.",
              "answers": ["konnte"],
              "type": "fill"
            },
            {
              "question": "Wir _____ gestern ein neues Auto kaufen.",
              "answers": ["wollten"],
              "type": "fill"
            },
            {
              "question": "Konnte",
              "answers": ["Konnte", "Müsste", "Dürfte", "Sollte"],
              "type": "pick"
            }
          ],
        ),
        33: Level(
          id: 33,
          description: "Trennbare Verben (Gegenwart)",
          reward: 100,
          questions: [
            {
              "question": "Ich _____ um 7 Uhr auf.",
              "answers": ["stehe"],
              "type": "fill"
            },
            {
              "question": "Aufstehen",
              "answers": ["Aufstehen", "Zumachen", "Mitkommen", "Einkaufen"],
              "type": "pick"
            },
            {
              "question": "Du _____ das Licht aus.",
              "answers": ["machst"],
              "type": "fill"
            },
            {
              "question": "Er _____ die Tür zu.",
              "answers": ["macht"],
              "type": "fill"
            },
            {
              "question": "Wir _____ am Wochenende aus.",
              "answers": ["gehen"],
              "type": "fill"
            }
          ],
        ),
        34: Level(
          id: 34,
          description: "Trennbare Verben (Vergangenheit)",
          reward: 100,
          questions: [
            {
              "question": "Ich _____ um 7 Uhr auf.",
              "answers": ["stand"],
              "type": "fill"
            },
            {
              "question": "Du hast das Licht _____.",
              "answers": ["ausgemacht"],
              "type": "fill"
            },
            {
              "question": "Er _____ die Tür zu.",
              "answers": ["machte"],
              "type": "fill"
            },
            {
              "question": "Stand",
              "answers": ["Stand", "Ging", "Machte", "Lief"],
              "type": "pick"
            },
            {
              "question": "Wir _____ am Wochenende aus.",
              "answers": ["gingen"],
              "type": "fill"
            }
          ],
        ),
        35: Level(
          id: 35,
          description: "Fragen stellen",
          reward: 100,
          questions: [
            {
              "question": "_____ heißt du?",
              "answers": ["Wie"],
              "type": "fill"
            },
            {
              "question": "Wie alt _____ du?",
              "answers": ["bist"],
              "type": "fill"
            },
            {
              "question": "Fragewort",
              "answers": ["Fragewort", "Antwort", "Aussage", "Verb"],
              "type": "pick"
            },
            {
              "question": "_____ kommst du?",
              "answers": ["Woher"],
              "type": "fill"
            },
            {
              "question": "_____ gehst du zur Arbeit?",
              "answers": ["Wann"],
              "type": "fill"
            }
          ],
        ),
        36: Level(
          id: 36,
          description: "Vergleiche & Steigerungen",
          reward: 100,
          questions: [
            {
              "question": "Ein Elefant ist _____ als eine Maus.",
              "answers": ["größer"],
              "type": "fill"
            },
            {
              "question": "Heute ist es _____ als gestern.",
              "answers": ["wärmer"],
              "type": "fill"
            },
            {
              "question": "Ein Porsche ist _____ als ein Fahrrad.",
              "answers": ["schneller"],
              "type": "fill"
            },
            {
              "question": "Dieses Buch ist _____ als das andere.",
              "answers": ["besser"],
              "type": "fill"
            },
            {
              "question": "Schnell",
              "answers": ["Schnell", "Langsam", "Groß", "Klein"],
              "type": "pick"
            }
          ],
        ),
        37: Level(
          id: 37,
          description: "Possessivpronomen",
          reward: 100,
          questions: [
            {
              "question": "Mein",
              "answers": ["Mein", "Sein", "Unser", "Ihr"],
              "type": "pick"
            },
            {
              "question": "Das ist _____ Auto.",
              "answers": ["mein"],
              "type": "fill"
            },
            {
              "question": "Das ist _____ Buch.",
              "answers": ["dein"],
              "type": "fill"
            },
            {
              "question": "Das ist _____ Hund.",
              "answers": ["sein"],
              "type": "fill"
            },
            {
              "question": "Das ist _____ Tasche.",
              "answers": ["ihre"],
              "type": "fill"
            }
          ],
        ),
        38: Level(
          id: 38,
          description: "Relativsätze",
          reward: 100,
          questions: [
            {
              "question": "Der Mann, _____ im Park läuft, ist mein Vater.",
              "answers": ["der"],
              "type": "fill"
            },
            {
              "question": "Das Auto, _____ ich gekauft habe, ist blau.",
              "answers": ["das"],
              "type": "fill"
            },
            {
              "question": "Relativpronomen",
              "answers": ["Relativpronomen", "Verb", "Subjekt", "Präposition"],
              "type": "pick"
            },
            {
              "question": "Die Frau, _____ du kennst, ist Lehrerin.",
              "answers": ["die"],
              "type": "fill"
            },
            {
              "question": "Der Hund, _____ du magst, ist süß.",
              "answers": ["den"],
              "type": "fill"
            }
          ],
        ),
        39: Level(
          id: 39,
          description: "Trennbare & Untrennbare Verben",
          reward: 100,
          questions: [
            {
              "question": "Ich _____ einen neuen Vertrag.",
              "answers": ["unterschreibe"],
              "type": "fill"
            },
            {
              "question": "Du _____ deinen Namen.",
              "answers": ["schreibst"],
              "type": "fill"
            },
            {
              "question": "Er _____ einen Fehler.",
              "answers": ["verbessert"],
              "type": "fill"
            },
            {
              "question": "Wir _____ das Licht an.",
              "answers": ["machen"],
              "type": "fill"
            },
            {
              "question": "Aufmachen",
              "answers": [
                "Aufmachen",
                "Unterschreiben",
                "Verbessern",
                "Schreiben"
              ],
              "type": "pick"
            }
          ],
        ),
        40: Level(
          id: 40,
          description: "Wortstellung im Satz",
          reward: 100,
          questions: [
            {
              "question": "Morgen _____ ich nach Berlin.",
              "answers": ["fahre"],
              "type": "fill"
            },
            {
              "question": "Gestern _____ wir ins Kino.",
              "answers": ["gingen"],
              "type": "fill"
            },
            {
              "question": "Wortstellung",
              "answers": ["Wortstellung", "Verb", "Artikel", "Adjektiv"],
              "type": "pick"
            },
            {
              "question": "Immer _____ er seine Hausaufgaben.",
              "answers": ["macht"],
              "type": "fill"
            },
            {
              "question": "Letzte Woche _____ sie Urlaub.",
              "answers": ["hatte"],
              "type": "fill"
            },
          ],
        ),
        41: Level(
          id: 41,
          description: "Perfekt mit haben",
          reward: 100,
          questions: [
            {
              "question": "Ich _____ gestern ein Buch gelesen.",
              "answers": ["habe"],
              "type": "fill"
            },
            {
              "question": "Perfekt",
              "answers": ["Perfekt", "Präteritum", "Futur", "Plusquamperfekt"],
              "type": "pick"
            },
            {
              "question": "Du _____ einen Kuchen gebacken.",
              "answers": ["hast"],
              "type": "fill"
            },
            {
              "question": "Er _____ den Film gesehen.",
              "answers": ["hat"],
              "type": "fill"
            },
            {
              "question": "Wir _____ Musik gehört.",
              "answers": ["haben"],
              "type": "fill"
            }
          ],
        ),
        42: Level(
          id: 42,
          description: "Perfekt mit sein",
          reward: 100,
          questions: [
            {
              "question": "Ich _____ spät nach Hause gekommen.",
              "answers": ["bin"],
              "type": "fill"
            },
            {
              "question": "Du _____ nach Italien gereist.",
              "answers": ["bist"],
              "type": "fill"
            },
            {
              "question": "Er _____ gestern gelaufen.",
              "answers": ["ist"],
              "type": "fill"
            },
            {
              "question": "Gegangen",
              "answers": ["Gegangen", "Gelaufen", "Gefahren", "Gekommen"],
              "type": "pick"
            },
            {
              "question": "Wir _____ ins Kino gegangen.",
              "answers": ["sind"],
              "type": "fill"
            }
          ],
        ),
        43: Level(
          id: 43,
          description: "Plusquamperfekt",
          reward: 100,
          questions: [
            {
              "question": "Ich _____ den Film schon gesehen.",
              "answers": ["hatte"],
              "type": "fill"
            },
            {
              "question": "Du _____ das Buch gelesen.",
              "answers": ["hattest"],
              "type": "fill"
            },
            {
              "question": "Er _____ das Fenster geöffnet.",
              "answers": ["hatte"],
              "type": "fill"
            },
            {
              "question": "Wir _____ schon gegessen.",
              "answers": ["hatten"],
              "type": "fill"
            },
            {
              "question": "Zahnbürste",
              "answers": ["Zahnbürste", "Kamm", "Seife", "Handtuch"],
              "type": "pick"
            }
          ],
        ),
        44: Level(
          id: 44,
          description: "Futur I",
          reward: 100,
          questions: [
            {
              "question": "Ich _____ morgen nach Berlin fahren.",
              "answers": ["werde"],
              "type": "fill"
            },
            {
              "question": "Wird",
              "answers": ["Wird", "Hat", "War", "Ging"],
              "type": "pick"
            },
            {
              "question": "Du _____ später anrufen.",
              "answers": ["wirst"],
              "type": "fill"
            },
            {
              "question": "Er _____ das Spiel gewinnen.",
              "answers": ["wird"],
              "type": "fill"
            },
            {
              "question": "Wir _____ das Problem lösen.",
              "answers": ["werden"],
              "type": "fill"
            }
          ],
        ),
        45: Level(
          id: 45,
          description: "Picky",
          reward: 100,
          questions: [
            {
              "question": "Freund",
              "answers": ["Freund", "Lehrer", "Schüler", "Kollege"],
              "type": "pick"
            },
            {
              "question": "Apotheke",
              "answers": ["Apotheke", "Krankenhaus", "Supermarkt", "Schule"],
              "type": "pick"
            },
            {
              "question": "Tee",
              "answers": ["Tee", "Kaffee", "Milch", "Wasser"],
              "type": "pick"
            },
            {
              "question": "Geld",
              "answers": ["Geld", "Münze", "Schein", "Bank"],
              "type": "pick"
            },
            {
              "question": "Berlin",
              "answers": ["Berlin", "Hamburg", "München", "Köln"],
              "type": "pick"
            },
          ],
        ),
        46: Level(
          id: 46,
          description: "Reflexive Verben",
          reward: 100,
          questions: [
            {
              "question": "Ich _____ mich um 7 Uhr.",
              "answers": ["dusche"],
              "type": "fill"
            },
            {
              "question": "Du _____ dich auf die Prüfung vor.",
              "answers": ["bereitest"],
              "type": "fill"
            },
            {
              "question": "Er _____ sich die Haare.",
              "answers": ["wäscht"],
              "type": "fill"
            },
            {
              "question": "Wir _____ uns im Spiegel.",
              "answers": ["sehen"],
              "type": "fill"
            },
            {
              "question": "waschen",
              "answers": ["waschen", "freuen", "anziehen", "ärgern"],
              "type": "pick"
            }
          ],
        ),
        47: Level(
          id: 47,
          description: "Imperativ",
          reward: 100,
          questions: [
            {
              "question": "_____ das Buch!",
              "answers": ["Lies"],
              "type": "fill"
            },
            {
              "question": "_____ bitte leise!",
              "answers": ["Sei"],
              "type": "fill"
            },
            {
              "question": "Befehl",
              "answers": ["Befehl", "Frage", "Aussage", "Verb"],
              "type": "pick"
            },
            {
              "question": "_____ mir den Stift!",
              "answers": ["Gib"],
              "type": "fill"
            },
            {
              "question": "_____ die Tür!",
              "answers": ["Mach"],
              "type": "fill"
            }
          ],
        ),
        48: Level(
          id: 48,
          description: "Konjunktiv II (Gegenwart)",
          reward: 100,
          questions: [
            {
              "question": "Ich _____ gerne mehr Zeit.",
              "answers": ["hätte"],
              "type": "fill"
            },
            {
              "question": "Könnte",
              "answers": ["Könnte", "Hat", "War", "Ging"],
              "type": "pick"
            },
            {
              "question": "Du _____ besser Deutsch sprechen.",
              "answers": ["könntest"],
              "type": "fill"
            },
            {
              "question": "Er _____ mehr lernen.",
              "answers": ["sollte"],
              "type": "fill"
            },
            {
              "question": "Wir _____ nach Paris reisen.",
              "answers": ["würden"],
              "type": "fill"
            }
          ],
        ),
        49: Level(
          id: 49,
          description: "Konjunktiv II (Vergangenheit)",
          reward: 100,
          questions: [
            {
              "question": "Wäre",
              "answers": ["Wäre", "Hat", "Hatte", "Ging"],
              "type": "pick"
            },
            {
              "question": "Ich _____ mehr gelernt.",
              "answers": ["hätte"],
              "type": "fill"
            },
            {
              "question": "Du _____ pünktlicher gewesen.",
              "answers": ["wärst"],
              "type": "fill"
            },
            {
              "question": "Er _____ den Bus nicht verpasst.",
              "answers": ["hätte"],
              "type": "fill"
            },
            {
              "question": "Wir _____ früher angekommen.",
              "answers": ["wären"],
              "type": "fill"
            }
          ],
        ),
        50: Level(
          id: 50,
          description: "Nebensätze",
          reward: 100,
          questions: [
            {
              "question": "Ich weiß, _____ du mich magst.",
              "answers": ["dass"],
              "type": "fill"
            },
            {
              "question": "Nebensatz",
              "answers": ["Nebensatz", "Hauptsatz", "Verb", "Subjekt"],
              "type": "pick"
            },
            {
              "question": "Sie fragt, _____ er kommt.",
              "answers": ["ob"],
              "type": "fill"
            },
            {
              "question": "Er sagte, _____ er müde ist.",
              "answers": ["dass"],
              "type": "fill"
            },
            {
              "question": "Ich hoffe, _____ es dir gut geht.",
              "answers": ["dass"],
              "type": "fill"
            }
          ],
        ),
        51: Level(
          id: 51,
          description: "Adjektivdeklination (Nominativ)",
          reward: 100,
          questions: [
            {
              "question": "Das ist ein _____ Tisch.",
              "answers": ["großer"],
              "type": "fill"
            },
            {
              "question": "Er _____ eine kleine Katze.",
              "answers": ["hat"],
              "type": "fill"
            },
            {
              "question": "Adjektiv",
              "answers": ["Adjektiv", "Verb", "Artikel", "Präposition"],
              "type": "pick"
            },
            {
              "question": "Wir sehen den _____ Himmel.",
              "answers": ["blauen"],
              "type": "fill"
            },
            {
              "question": "Sie trägt  _____ Schuhe.",
              "answers": ["hohe"],
              "type": "fill"
            }
          ],
        ),
        52: Level(
          id: 52,
          description: "Beim Bäcker",
          reward: 100,
          questions: [
            {
              "question": "Ich kaufe ein _____ Brötchen.",
              "answers": ["frisches"],
              "type": "fill"
            },
            {
              "question": "Der Bäcker verkauft eine _____ Brezel.",
              "answers": ["salzige"],
              "type": "fill"
            },
            {
              "question": "Brot",
              "answers": ["Brot", "Torte", "Muffin", "Kuchen"],
              "type": "pick"
            },
            {
              "question": "Ich nehme ein Stück _____ Kuchen.",
              "answers": ["süßen"],
              "type": "fill"
            },
            {
              "question": "Die Verkäuferin gibt mir eine _____ Tüte.",
              "answers": ["kleine"],
              "type": "fill"
            }
          ],
        ),
        53: Level(
          id: 53,
          description: "Bezahlen im Geschäft",
          reward: 100,
          questions: [
            {
              "question": "Ich bezahle an der _____.",
              "answers": ["Kasse"],
              "type": "fill"
            },
            {
              "question": "Er gibt dem Verkäufer das _____.",
              "answers": ["Geld"],
              "type": "fill"
            },
            {
              "question": "Kreditkarte",
              "answers": ["Kreditkarte", "Bargeld", "Schein", "Münze"],
              "type": "pick"
            },
            {
              "question": "Ich brauche eine _____ für meine Einkäufe.",
              "answers": ["Quittung"],
              "type": "fill"
            },
            {
              "question": "Das Produkt ist sehr _____.",
              "answers": ["teuer"],
              "type": "fill"
            }
          ],
        ),
        54: Level(
          id: 54,
          description: "Im Restaurant",
          reward: 100,
          questions: [
            {
              "question": "Ich bestelle eine _____ Suppe.",
              "answers": ["warme"],
              "type": "fill"
            },
            {
              "question": "Der Kellner bringt eine _____ Rechnung.",
              "answers": ["hohe"],
              "type": "fill"
            },
            {
              "question": "Vorspeise",
              "answers": ["Vorspeise", "Hauptgericht", "Nachspeise", "Getränk"],
              "type": "pick"
            },
            {
              "question": "Das Essen schmeckt sehr _____.",
              "answers": ["lecker"],
              "type": "fill"
            },
            {
              "question": "Das Restaurant ist sehr _____ eingerichtet.",
              "answers": ["modern"],
              "type": "fill"
            }
          ],
        ),
        55: Level(
          id: 55,
          description: "Beim Arzt",
          reward: 100,
          questions: [
            {
              "question": "Ich habe starke _____ Schmerzen.",
              "answers": ["Bauch"],
              "type": "fill"
            },
            {
              "question": "Der Arzt gibt mir eine _____ Salbe.",
              "answers": ["medizinische"],
              "type": "fill"
            },
            {
              "question": "Rezept",
              "answers": ["Rezept", "Tabletten", "Spritze", "Krankenschein"],
              "type": "pick"
            },
            {
              "question": "Ich brauche ein _____ Medikament.",
              "answers": ["wirksames"],
              "type": "fill"
            },
            {
              "question": "Der Patient fühlt sich sehr _____.",
              "answers": ["müde"],
              "type": "fill"
            }
          ],
        ),
        56: Level(
          id: 56,
          description: "Reisen & Urlaub",
          reward: 100,
          questions: [
            {
              "question": "Ich buche ein _____ Hotelzimmer.",
              "answers": ["großes"],
              "type": "fill"
            },
            {
              "question": "Wir haben einen _____ Flug.",
              "answers": ["frühen"],
              "type": "fill"
            },
            {
              "question": "Koffer",
              "answers": ["Koffer", "Pass", "Ticket", "Gepäck"],
              "type": "pick"
            },
            {
              "question": "Das Wetter im Urlaub ist sehr _____.",
              "answers": ["sonnig"],
              "type": "fill"
            },
            {
              "question": "Wir besuchen eine _____ Stadt.",
              "answers": ["historische"],
              "type": "fill"
            }
          ],
        ),
        57: Level(
          id: 57,
          description: "In der Stadt",
          reward: 100,
          questions: [
            {
              "question": "Ich laufe durch eine _____ Straße.",
              "answers": ["belebte"],
              "type": "fill"
            },
            {
              "question": "Wir essen in einem _____ Café.",
              "answers": ["gemütlichen"],
              "type": "fill"
            },
            {
              "question": "Park",
              "answers": ["Park", "Bahn", "Brücke", "Denkmal"],
              "type": "pick"
            },
            {
              "question": "Das Museum zeigt eine _____ Ausstellung.",
              "answers": ["interessante"],
              "type": "fill"
            },
            {
              "question": "Die Stadt ist sehr _____.",
              "answers": ["groß"],
              "type": "fill"
            }
          ],
        ),
        58: Level(
          id: 58,
          description: "Verkehr & Transport",
          reward: 100,
          questions: [
            {
              "question": "Ich fahre mit einem _____ Bus.",
              "answers": ["modernen"],
              "type": "fill"
            },
            {
              "question": "Der Zug hat eine _____ Verspätung.",
              "answers": ["lange"],
              "type": "fill"
            },
            {
              "question": "Haltestelle",
              "answers": ["Haltestelle", "Flughafen", "Kreuzung", "Ampel"],
              "type": "pick"
            },
            {
              "question": "Wir nehmen die _____ Straßenbahn.",
              "answers": ["nächste"],
              "type": "fill"
            },
            {
              "question": "Das Taxi fährt sehr _____.",
              "answers": ["schnell"],
              "type": "fill"
            }
          ],
        ),
        59: Level(
          id: 59,
          description: "Technik & Elektronik",
          reward: 100,
          questions: [
            {
              "question": "Ich kaufe ein _____ Smartphone.",
              "answers": ["neues"],
              "type": "fill"
            },
            {
              "question": "Der Fernseher hat ein _____ Bild.",
              "answers": ["scharfes"],
              "type": "fill"
            },
            {
              "question": "Laptop",
              "answers": ["Laptop", "Tablet", "Monitor", "Maus"],
              "type": "pick"
            },
            {
              "question": "Der Akku meines Handys ist sehr _____.",
              "answers": ["schwach"],
              "type": "fill"
            },
            {
              "question": "Ich brauche eine _____ Internetverbindung.",
              "answers": ["stabile"],
              "type": "fill"
            }
          ],
        ),
        60: Level(
          id: 60,
          description: "Haus & Wohnen",
          reward: 100,
          questions: [
            {
              "question": "Ich wohne in einem _____ Haus.",
              "answers": ["kleinen"],
              "type": "fill"
            },
            {
              "question": "Mein Wohnzimmer hat eine _____ Couch.",
              "answers": ["bequeme"],
              "type": "fill"
            },
            {
              "question": "Badezimmer",
              "answers": ["Badezimmer", "Küche", "Balkon", "Keller"],
              "type": "pick"
            },
            {
              "question": "Im Garten steht ein _____ Baum.",
              "answers": ["hoher"],
              "type": "fill"
            },
            {
              "question": "Mein Schlafzimmer hat ein _____ Fenster.",
              "answers": ["großes"],
              "type": "fill"
            }
          ],
        ),
        71: Level(
          id: 71,
          description: "Haustiere",
          reward: 100,
          questions: [
            {
              "question": "Ich habe einen _____ als Haustier.",
              "answers": ["Hund"],
              "type": "fill"
            },
            {
              "question": "Die _____ miaut laut in der Nacht.",
              "answers": ["Katze"],
              "type": "fill"
            },
            {
              "question": "Vogel",
              "answers": ["Vogel", "Hund", "Fisch", "Katze"],
              "type": "pick"
            },
            {
              "question": "Ein Hamster lebt in einem _____.",
              "answers": ["Käfig"],
              "type": "fill"
            },
            {
              "question": "Mein Hund liebt es, mit dem Ball zu _____.",
              "answers": ["spielen"],
              "type": "fill"
            }
          ],
        ),
        72: Level(
          id: 72,
          description: "Krankenhaus & Arztbesuch",
          reward: 100,
          questions: [
            {
              "question": "Ich habe einen Termin beim _____.",
              "answers": ["Arzt"],
              "type": "fill"
            },
            {
              "question": "Die Krankenschwester gibt mir _____.",
              "answers": ["Medikamente"],
              "type": "fill"
            },
            {
              "question": "Krank",
              "answers": ["Krank", "Gesund", "Sportlich", "Langsam"],
              "type": "pick"
            },
            {
              "question": "Er liegt seit drei Tagen im _____.",
              "answers": ["Krankenhaus"],
              "type": "fill"
            },
            {
              "question": "Ich brauche ein Rezept für meine _____.",
              "answers": ["Tabletten"],
              "type": "fill"
            }
          ],
        ),
        73: Level(
          id: 73,
          description: "Büroalltag",
          reward: 100,
          questions: [
            {
              "question": "Ich schreibe eine E-Mail an meinen _____.",
              "answers": ["Chef"],
              "type": "fill"
            },
            {
              "question": "In meinem Büro steht ein großer _____.",
              "answers": ["Schreibtisch"],
              "type": "fill"
            },
            {
              "question": "Drucker",
              "answers": ["Drucker", "Tastatur", "Monitor", "Maus"],
              "type": "pick"
            },
            {
              "question": "Ich habe um 10 Uhr eine wichtige _____.",
              "answers": ["Besprechung"],
              "type": "fill"
            },
            {
              "question": "Meine Kollegin telefoniert mit einem _____.",
              "answers": ["Kunden"],
              "type": "fill"
            }
          ],
        ),
        74: Level(
          id: 74,
          description: "Schule & Lernen",
          reward: 100,
          questions: [
            {
              "question": "Ich schreibe meine Notizen in mein _____.",
              "answers": ["Heft"],
              "type": "fill"
            },
            {
              "question": "Der Lehrer erklärt die Aufgabe an der _____.",
              "answers": ["Tafel"],
              "type": "fill"
            },
            {
              "question": "Schüler",
              "answers": ["Schüler", "Lehrer", "Direktor", "Arzt"],
              "type": "pick"
            },
            {
              "question": "Wir haben heute eine _____.",
              "answers": ["Klassenarbeit"],
              "type": "fill"
            },
            {
              "question": "Meine Lieblingsfächer sind Mathe und _____.",
              "answers": ["Deutsch"],
              "type": "fill"
            }
          ],
        ),
        75: Level(
          id: 75,
          description: "Supermarkt & Einkaufen",
          reward: 100,
          questions: [
            {
              "question": "Ich brauche einen Einkaufswagen für meine _____.",
              "answers": ["Einkäufe"],
              "type": "fill"
            },
            {
              "question": "An der Kasse zahle ich mit _____.",
              "answers": ["Bargeld"],
              "type": "fill"
            },
            {
              "question": "Brot",
              "answers": ["Brot", "Milch", "Wasser", "Käse"],
              "type": "pick"
            },
            {
              "question": "Das Obst ist im _____.",
              "answers": ["Regal"],
              "type": "fill"
            },
            {
              "question":
                  "Ich vergleiche die Preise, um das beste _____ zu finden.",
              "answers": ["Angebot"],
              "type": "fill"
            }
          ],
        ),
        76: Level(
          id: 76,
          description: "Reisen & Transport",
          reward: 100,
          questions: [
            {
              "question": "Wir fliegen von München nach Paris mit dem _____.",
              "answers": ["Flugzeug"],
              "type": "fill"
            },
            {
              "question": "Ich kaufe ein Ticket für den _____.",
              "answers": ["Zug"],
              "type": "fill"
            },
            {
              "question": "Bahnhof",
              "answers": ["Bahnhof", "Flughafen", "Hafen", "Haltestelle"],
              "type": "pick"
            },
            {
              "question": "Ich nehme ein Taxi zum _____.",
              "answers": ["Hotel"],
              "type": "fill"
            },
            {
              "question": "Mein Koffer ist sehr _____.",
              "answers": ["schwer"],
              "type": "fill"
            }
          ],
        ),
        77: Level(
          id: 77,
          description: "Wohnen & Haushalt",
          reward: 100,
          questions: [
            {
              "question": "Ich wohne in einer kleinen _____.",
              "answers": ["Wohnung"],
              "type": "fill"
            },
            {
              "question": "Mein Bett steht im _____.",
              "answers": ["Schlafzimmer"],
              "type": "fill"
            },
            {
              "question": "Lampe",
              "answers": ["Lampe", "Tisch", "Sofa", "Teppich"],
              "type": "pick"
            },
            {
              "question": "Ich koche in der _____.",
              "answers": ["Küche"],
              "type": "fill"
            },
            {
              "question": "Ich mache die _____ in der Waschmaschine.",
              "answers": ["Wäsche"],
              "type": "fill"
            }
          ],
        ),
        78: Level(
          id: 78,
          description: "Sport & Freizeit",
          reward: 100,
          questions: [
            {
              "question": "Ich gehe gerne im Wasser _____.",
              "answers": ["schwimmen"],
              "type": "fill"
            },
            {
              "question": "Ich trete den _____.",
              "answers": ["Fußball"],
              "type": "fill"
            },
            {
              "question": "Tennis",
              "answers": ["Tennis", "Basketball", "Volleyball", "Golf"],
              "type": "pick"
            },
            {
              "question": "Ich trainiere zweimal pro Woche im _____.",
              "answers": ["Fitnessstudio"],
              "type": "fill"
            },
            {
              "question": "Er fährt gerne im Winter _____.",
              "answers": ["Ski"],
              "type": "fill"
            }
          ],
        ),
        79: Level(
          id: 79,
          description: "Post & Bank",
          reward: 100,
          questions: [
            {
              "question": "Ich schicke einen Brief per _____.",
              "answers": ["Post"],
              "type": "fill"
            },
            {
              "question": "Er hebt Geld am _____ ab.",
              "answers": ["Geldautomat"],
              "type": "fill"
            },
            {
              "question": "Kreditkarte",
              "answers": ["Kreditkarte", "Geldschein", "Münze", "Konto"],
              "type": "pick"
            },
            {
              "question": "Ich brauche eine Briefmarke für meine _____.",
              "answers": ["Postkarte"],
              "type": "fill"
            },
            {
              "question": "Ich überweise Geld auf sein _____.",
              "answers": ["Konto"],
              "type": "fill"
            }
          ],
        ),
        80: Level(
          id: 80,
          description: "Essen & Trinken",
          reward: 100,
          questions: [
            {
              "question": "Ich esse gerne _____ mit Butter.",
              "answers": ["Brot"],
              "type": "fill"
            },
            {
              "question": "Zum Frühstück trinke ich gerne _____.",
              "answers": ["Kaffee"],
              "type": "fill"
            },
            {
              "question": "Milch",
              "answers": ["Milch", "Saft", "Tee", "Limonade"],
              "type": "pick"
            },
            {
              "question": "Er kocht eine Suppe mit frischem _____.",
              "answers": ["Gemüse"],
              "type": "fill"
            },
            {
              "question": "Zum Nachtisch gibt es eine _____.",
              "answers": ["Torte"],
              "type": "fill"
            }
          ],
        ),
        81: Level(
          id: 81,
          description: "Tiere & Natur",
          reward: 100,
          questions: [
            {
              "question": "Der _____ jagt nachts Mäuse.",
              "answers": ["Fuchs"],
              "type": "fill"
            },
            {
              "question": "Im Wald gibt es viele hohe _____.",
              "answers": ["Bäume"],
              "type": "fill"
            },
            {
              "question": "Hund",
              "answers": ["Hund", "Katze", "Maus", "Vogel"],
              "type": "pick"
            },
            {
              "question": "Fische schwimmen _____ Wasser.",
              "answers": ["im"],
              "type": "fill"
            },
            {
              "question": "Der Himmel ist heute _____ blau.",
              "answers": ["sehr"],
              "type": "fill"
            }
          ],
        ),
        82: Level(
          id: 82,
          description: "Krankenhaus & Gesundheit",
          reward: 100,
          questions: [
            {
              "question": "Ich habe starke _____.",
              "answers": ["Kopfschmerzen"],
              "type": "fill"
            },
            {
              "question": "Der Arzt verschreibt mir _____.",
              "answers": ["Medikamente"],
              "type": "fill"
            },
            {
              "question": "Herz",
              "answers": ["Herz", "Lunge", "Leber", "Magen"],
              "type": "pick"
            },
            {
              "question": "Ich habe mir das Bein _____.",
              "answers": ["gebrochen"],
              "type": "fill"
            },
            {
              "question": "Er hat Fieber und eine starke _____.",
              "answers": ["Erkältung"],
              "type": "fill"
            }
          ],
        ),
        83: Level(
          id: 83,
          description: "Auf dem Bauernhof",
          reward: 100,
          questions: [
            {
              "question": "Der Bauer melkt die _____.",
              "answers": ["Kuh"],
              "type": "fill"
            },
            {
              "question": "Die Hühner legen jeden Tag _____.",
              "answers": ["Eier"],
              "type": "fill"
            },
            {
              "question": "Traktor",
              "answers": ["Traktor", "Pflug", "Scheune", "Wiese"],
              "type": "pick"
            },
            {
              "question": "Die Schafe laufen über die _____ Wiese.",
              "answers": ["grüne"],
              "type": "fill"
            },
            {
              "question": "Am Morgen _____ der Bauer die  Pferde.",
              "answers": ["füttert"],
              "type": "fill"
            }
          ],
        ),
        84: Level(
          id: 84,
          description: "Einkaufen & Supermarkt",
          reward: 100,
          questions: [
            {
              "question": "Ich kaufe Obst und Gemüse auf dem _____.",
              "answers": ["Markt"],
              "type": "fill"
            },
            {
              "question": "Er bezahlt an der _____.",
              "answers": ["Kasse"],
              "type": "fill"
            },
            {
              "question": "Milch",
              "answers": ["Milch", "Wasser", "Saft", "Tee"],
              "type": "pick"
            },
            {
              "question": "Sie sucht nach einem günstigen _____.",
              "answers": ["Angebot"],
              "type": "fill"
            },
            {
              "question": "Ich brauche eine Tüte für meine _____.",
              "answers": ["Einkäufe"],
              "type": "fill"
            }
          ],
        ),
        85: Level(
          id: 85,
          description: "Reisen & Verkehr",
          reward: 100,
          questions: [
            {
              "question": "Ich buche ein Zimmer in einem _____.",
              "answers": ["Hotel"],
              "type": "fill"
            },
            {
              "question": "Der Flug nach Berlin geht um 14:30 vom _____.",
              "answers": ["Flughafen"],
              "type": "fill"
            },
            {
              "question": "Zug",
              "answers": ["Zug", "Bus", "Auto", "Fahrrad"],
              "type": "pick"
            },
            {
              "question": "Wir fahren mit dem Taxi zum _____.",
              "answers": ["Bahnhof"],
              "type": "fill"
            },
            {
              "question": "Er hat einen Koffer für seine _____.",
              "answers": ["Reise"],
              "type": "fill"
            }
          ],
        ),
        86: Level(
          id: 86,
          description: "Haus & Möbel",
          reward: 100,
          questions: [
            {
              "question": "Das Buch liegt _____ dem Tisch.",
              "answers": ["auf"],
              "type": "fill"
            },
            {
              "question": "In der Ecke steht ein bequemer _____.",
              "answers": ["Sessel"],
              "type": "fill"
            },
            {
              "question": "Lampe",
              "answers": ["Lampe", "Stuhl", "Küche", "Teppich"],
              "type": "pick"
            },
            {
              "question": "Wir _____ gemeinsam am Esstisch.",
              "answers": ["essen"],
              "type": "fill"
            },
            {
              "question": "Mein Bett ist sehr _____.",
              "answers": ["weich"],
              "type": "fill"
            }
          ],
        ),
        87: Level(
          id: 87,
          description: "Kleidung & Mode",
          reward: 100,
          questions: [
            {
              "question": "Im Winter trage ich eine _____ Jacke.",
              "answers": ["warme"],
              "type": "fill"
            },
            {
              "question": "Die Schuhe stehen _____ der Tür.",
              "answers": ["bei"],
              "type": "fill"
            },
            {
              "question": "Hose",
              "answers": ["Hose", "Jacke", "Schuhe", "Hut"],
              "type": "pick"
            },
            {
              "question": "Er _____ immer eine rote Krawatte.",
              "answers": ["trägt"],
              "type": "fill"
            },
            {
              "question": "Der Pullover ist aus _____.",
              "answers": ["Wolle"],
              "type": "fill"
            }
          ],
        ),
        88: Level(
          id: 88,
          description: "Auf dem Campingplatz",
          reward: 100,
          questions: [
            {
              "question": "Ich schlafe in einem _____.",
              "answers": ["Zelt"],
              "type": "fill"
            },
            {
              "question": "Am Abend machen wir ein _____ Lagerfeuer.",
              "answers": ["warmes"],
              "type": "fill"
            },
            {
              "question": "Schlafsack",
              "answers": ["Schlafsack", "Taschenlampe", "Angel", "Zelt"],
              "type": "pick"
            },
            {
              "question": "Wir _____ unser Essen auf einem Gaskocher.",
              "answers": ["kochen"],
              "type": "fill"
            },
            {
              "question": "Nachts _____ wir die Geräusche des Waldes.",
              "answers": ["hören"],
              "type": "fill"
            }
          ],
        ),
        89: Level(
          id: 89,
          description: "Beim Friseur",
          reward: 100,
          questions: [
            {
              "question": "Ich bekomme heute eine _____ Frisur.",
              "answers": ["neue"],
              "type": "fill"
            },
            {
              "question": "Der Friseur benutzt eine _____ Schere.",
              "answers": ["scharfe"],
              "type": "fill"
            },
            {
              "question": "Kamm",
              "answers": ["Kamm", "Bürste", "Föhn", "Schere"],
              "type": "pick"
            },
            {
              "question": "Nach dem Haarschnitt sind meine Haare _____.",
              "answers": ["kürzer"],
              "type": "fill"
            },
            {
              "question": "Ich möchte meine Haare _____ färben.",
              "answers": ["blond"],
              "type": "fill"
            }
          ],
        ),
        90: Level(
          id: 90,
          description: "Auf dem Spielplatz",
          reward: 100,
          questions: [
            {
              "question": "Die Kinder rutschen auf der _____.",
              "answers": ["Rutsche"],
              "type": "fill"
            },
            {
              "question": "Ich _____ auf einer Schaukel.",
              "answers": ["schaukle"],
              "type": "fill"
            },
            {
              "question": "Sandkasten",
              "answers": ["Sandkasten", "Klettergerüst", "Rutsche", "Schaukel"],
              "type": "pick"
            },
            {
              "question": "Die Eltern sitzen auf einer holz _____.",
              "answers": ["Bank"],
              "type": "fill"
            },
            {
              "question": "Wir _____ einen roten Ball.",
              "answers": ["werfen"],
              "type": "fill"
            }
          ],
        ),
        91: Level(
          id: 91,
          description: "In der Bibliothek",
          reward: 100,
          questions: [
            {
              "question": "Ich lese ein _____ Buch über Geschichte.",
              "answers": ["interessantes"],
              "type": "fill"
            },
            {
              "question": "Die Bibliothek hat viele _____ Regale.",
              "answers": ["hohe"],
              "type": "fill"
            },
            {
              "question": "Roman",
              "answers": ["Roman", "Märchen", "Lehrbuch", "Lexikon"],
              "type": "pick"
            },
            {
              "question": "Die Bibliothekarin _____ mir eine Empfehlung.",
              "answers": ["gibt"],
              "type": "fill"
            },
            {
              "question": "Ich sitze an einem _____ Tisch und lese.",
              "answers": ["ruhigen"],
              "type": "fill"
            }
          ],
        ),
        92: Level(
          id: 92,
          description: "In der Autowerkstatt",
          reward: 100,
          questions: [
            {
              "question": "Mein Auto braucht eine _____ Reparatur.",
              "answers": ["dringende"],
              "type": "fill"
            },
            {
              "question": "Der Mechaniker wechselt die _____ Reifen.",
              "answers": ["kaputten"],
              "type": "fill"
            },
            {
              "question": "Ölwechsel",
              "answers": ["Ölwechsel", "Reifenwechsel", "Inspektion", "TÜV"],
              "type": "pick"
            },
            {
              "question": "Die Werkstatt hat viele _____.",
              "answers": ["Werkzeuge"],
              "type": "fill"
            },
            {
              "question": "Nach der Reparatur fährt mein Auto wieder _____.",
              "answers": ["einwandfrei"],
              "type": "fill"
            }
          ],
        ),
        93: Level(
          id: 93,
          description: "Feiertage & Traditionen",
          reward: 100,
          questions: [
            {
              "question": "An Weihnachten schmücken wir einen _____.",
              "answers": ["Weihnachtsbaum"],
              "type": "fill"
            },
            {
              "question": "Ostern feiern wir mit bunten _____.",
              "answers": ["Eiern"],
              "type": "fill"
            },
            {
              "question": "Silvester",
              "answers": ["Silvester", "Ostern", "Weihnachten", "Halloween"],
              "type": "pick"
            },
            {
              "question": "Am 31. Dezember machen wir ein großes _____.",
              "answers": ["Feuerwerk"],
              "type": "fill"
            },
            {
              "question": "Zum Geburtstag bekomme ich eine _____.",
              "answers": ["Torte"],
              "type": "fill"
            }
          ],
        ),
        94: Level(
          id: 94,
          description: "Berufe & Arbeitswelt",
          reward: 100,
          questions: [
            {
              "question": "Ein _____ arbeitet im Krankenhaus.",
              "answers": ["Arzt"],
              "type": "fill"
            },
            {
              "question": "Der _____ fährt Bus oder LKW.",
              "answers": ["Fahrer"],
              "type": "fill"
            },
            {
              "question": "Lehrer",
              "answers": ["Lehrer", "Bäcker", "Ingenieur", "Friseur"],
              "type": "pick"
            },
            {
              "question": "Ein _____ repariert Wasserleitungen.",
              "answers": ["Installateur"],
              "type": "fill"
            },
            {
              "question": "Mein Vater arbeitet als _____.",
              "answers": ["Elektriker"],
              "type": "fill"
            }
          ],
        ),
        95: Level(
          id: 95,
          description: "Verkehr & öffentliche Verkehrsmittel",
          reward: 100,
          questions: [
            {
              "question": "Ich kaufe eine Fahrkarte für den _____.",
              "answers": ["Zug"],
              "type": "fill"
            },
            {
              "question": "In der Stadt fahre ich oft mit der _____.",
              "answers": ["Straßenbahn"],
              "type": "fill"
            },
            {
              "question": "Ampel",
              "answers": ["Ampel", "Kreuzung", "Zebrastreifen", "Tunnel"],
              "type": "pick"
            },
            {
              "question": "Der Bus fährt alle 10 _____.",
              "answers": ["Minuten"],
              "type": "fill"
            },
            {
              "question": "Ich steige an der nächsten _____ aus.",
              "answers": ["Haltestelle"],
              "type": "fill"
            }
          ],
        ),
        96: Level(
          id: 96,
          description: "Elektronik & Technik",
          reward: 100,
          questions: [
            {
              "question": "Mein Computer hat einen großen _____.",
              "answers": ["Monitor"],
              "type": "fill"
            },
            {
              "question": "Ich tippe auf meiner _____.",
              "answers": ["Tastatur"],
              "type": "fill"
            },
            {
              "question": "Tablet",
              "answers": ["Tablet", "Drucker", "Maus", "Smartphone"],
              "type": "pick"
            },
            {
              "question": "Mein Smartphone muss ich jeden Tag _____.",
              "answers": ["aufladen"],
              "type": "fill"
            },
            {
              "question": "Der Fernseher hat eine _____.",
              "answers": ["Fernbedienung"],
              "type": "fill"
            }
          ],
        ),
        97: Level(
          id: 97,
          description: "Musik & Kunst",
          reward: 100,
          questions: [
            {
              "question": "Mein Lieblingsinstrument ist die _____.",
              "answers": ["Gitarre"],
              "type": "fill"
            },
            {
              "question": "In der Band spielt er _____.",
              "answers": ["Schlagzeug"],
              "type": "fill"
            },
            {
              "question": "Gemälde",
              "answers": ["Gemälde", "Skulptur", "Zeichnung", "Fotografie"],
              "type": "pick"
            },
            {
              "question": "Beethoven war ein berühmter _____.",
              "answers": ["Komponist"],
              "type": "fill"
            },
            {
              "question": "Ich male gerne mit _____.",
              "answers": ["Aquarellfarben"],
              "type": "fill"
            }
          ],
        ),
        98: Level(
          id: 98,
          description: "Zukunftsstadt & Technologie",
          reward: 100,
          questions: [
            {
              "question": "Die Stadt der Zukunft hat fliegende _____.",
              "answers": ["Autos"],
              "type": "fill"
            },
            {
              "question": "Künstliche Intelligenz steuert das _____ Haus.",
              "answers": ["intelligente"],
              "type": "fill"
            },
            {
              "question": "Roboter",
              "answers": ["Roboter", "Drohne", "Hologramm", "Laser"],
              "type": "pick"
            },
            {
              "question": "Menschen reisen in _____ Raumschiffen zum Mars.",
              "answers": ["modernen"],
              "type": "fill"
            },
            {
              "question": "Das Energiesystem basiert auf _____ Solarzellen.",
              "answers": ["effizienten"],
              "type": "fill"
            }
          ],
        ),
        99: Level(
          id: 99,
          description: "Universität & Studium",
          reward: 100,
          questions: [
            {
              "question": "Ich studiere an der _____.",
              "answers": ["Universität"],
              "type": "fill"
            },
            {
              "question": "Meine Vorlesung beginnt um _____.",
              "answers": ["8 Uhr"],
              "type": "fill"
            },
            {
              "question": "Professor",
              "answers": ["Professor", "Student", "Forscher", "Dozent"],
              "type": "pick"
            },
            {
              "question": "Ich schreibe meine Notizen in mein _____.",
              "answers": ["Skript"],
              "type": "fill"
            },
            {
              "question": "Nach dem Studium mache ich meinen _____.",
              "answers": ["Master"],
              "type": "fill"
            }
          ],
        ),
        100: Level(
          id: 100,
          description: "Geld & Finanzen",
          reward: 100,
          questions: [
            {
              "question": "Ich hebe Geld am _____ ab.",
              "answers": ["Geldautomaten"],
              "type": "fill"
            },
            {
              "question": "Meine EC-Karte ist in meiner _____.",
              "answers": ["Geldbörse"],
              "type": "fill"
            },
            {
              "question": "Münze",
              "answers": ["Münze", "Schein", "Konto", "Überweisung"],
              "type": "pick"
            },
            {
              "question": "Ich spare Geld für mein _____.",
              "answers": ["Auto"],
              "type": "fill"
            },
            {
              "question": "Ich bezahle meine Miete per _____.",
              "answers": ["Überweisung"],
              "type": "fill"
            }
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
              "question": "Hola, ¿cómo _____?",
              "answers": ["estás"],
              "type": "fill"
            },
            {
              "question": "Manzana",
              "answers": ["Manzana", "Mazana", "Mansana", "Manznana"],
              "type": "pick"
            },
            {
              "question": "Ella está sentada _____ la silla.",
              "answers": ["en"],
              "type": "fill"
            },
            {
              "question": "Vamos _____ el parque.",
              "answers": ["al"],
              "type": "fill"
            },
            {
              "question": "Dinero",
              "answers": ["Dinero", "Dunero", "Danero", "Denaro"],
              "type": "pick"
            }
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
              "question": "Ellos están _____ al cine.",
              "answers": ["yendo"],
              "type": "fill"
            },
            {
              "question": "El perro está durmiendo _____ el sofá.",
              "answers": ["en"],
              "type": "fill"
            },
            {
              "question": "Él está interesado _____ la música.",
              "answers": ["en"],
              "type": "fill"
            },
            {
              "question": "Coche",
              "answers": ["Coche", "Cocheo", "Coché", "Coch"],
              "type": "pick"
            }
          ],
        ),
        3: Level(
          id: 3,
          description: "Oraciones simples",
          reward: 100,
          questions: [
            {
              "question": "Voy _____ mercado.",
              "answers": ["al"],
              "type": "fill"
            },
            {
              "question": "Árbol",
              "answers": ["Árbol", "Árvol", "Arbol", "Árbolo"],
              "type": "pick"
            },
            {
              "question": "Nosotros _____ haciendo la cena en la cocina.",
              "answers": ["estamos"],
              "type": "fill"
            },
            {
              "question": "Dinero",
              "answers": ["Dinero", "Dunero", "Danero", "Denaro"],
              "type": "pick"
            },
            {
              "question": "Los niños _____ jugando afuera.",
              "answers": ["están"],
              "type": "fill"
            }
          ],
        ),
        4: Level(
          id: 4,
          description: "Conceptos básicos de gramática",
          reward: 100,
          questions: [
            {
              "question": "Sol",
              "answers": ["Sol", "Sal", "Sel", "Sil"],
              "type": "pick"
            },
            {
              "question": "El pájaro está _____ el árbol.",
              "answers": ["en"],
              "type": "fill"
            },
            {
              "question": "Él va _____ escuela en autobús.",
              "answers": ["a la"],
              "type": "fill"
            },
            {
              "question": "Ella compró un vestido _____ ayer.",
              "answers": ["bonito"],
              "type": "fill"
            },
            {
              "question": "Ellos _____ jugando en el jardín.",
              "answers": ["están"],
              "type": "fill"
            }
          ],
        ),
        5: Level(
          id: 5,
          description: "Frases comunes",
          reward: 100,
          questions: [
            {
              "question": "¡Buenos días! ¿Cómo _____?",
              "answers": ["estás"],
              "type": "fill"
            },
            {
              "question": "¿Puedes pasarme _____ sal, por favor?",
              "answers": ["la"],
              "type": "fill"
            },
            {
              "question": "Me gustaría _____ un café.",
              "answers": ["tomar"],
              "type": "fill"
            },
            {
              "question": "¿Sabes _____ será el clima mañana?",
              "answers": ["cómo"],
              "type": "fill"
            },
            {
              "question":
                  "Él ha estado trabajando _____ el proyecto todo el día.",
              "answers": ["en"],
              "type": "fill"
            }
          ],
        ),
        6: Level(
          id: 6,
          description: "Más práctica",
          reward: 100,
          questions: [
            {
              "question": "El profesor nos pidió que _____ en silencio.",
              "answers": ["estuviéramos"],
              "type": "fill"
            },
            {
              "question": "Planeamos visitar _____ abuelos mañana.",
              "answers": ["a nuestros"],
              "type": "fill"
            },
            {
              "question": "¿Puedes _____ un favor?",
              "answers": ["hacerme"],
              "type": "fill"
            },
            {
              "question": "Silla",
              "answers": ["Silla", "Sila", "Sillae", "Sille"],
              "type": "pick"
            },
            {
              "question": "Mesa",
              "answers": ["Mesa", "Mese", "Masa", "Misa"],
              "type": "pick"
            }
          ],
        ),
        7: Level(
          id: 7,
          description: "Conversación diaria",
          reward: 100,
          questions: [
            {
              "question": "¿Cómo _____ hoy?",
              "answers": ["estás"],
              "type": "fill"
            },
            {
              "question": "¿Podrías _____ el camino a la estación?",
              "answers": ["decirme"],
              "type": "fill"
            },
            {
              "question": "Él _____ la respuesta a la pregunta.",
              "answers": ["sabe"],
              "type": "fill"
            },
            {
              "question": "Agua",
              "answers": ["Agua", "Aguo", "Aqúa", "Aqua"],
              "type": "pick"
            },
            {
              "question": "Necesito _____ al médico esta tarde.",
              "answers": ["ir"],
              "type": "fill"
            }
          ],
        ),
        8: Level(
          id: 8,
          description: "Tiempo y fechas",
          reward: 100,
          questions: [
            {
              "question": "Reloj",
              "answers": ["Reloj", "Reloj", "Riloj", "Rolij"],
              "type": "pick"
            },
            {
              "question": "Ella nació _____ abril.",
              "answers": ["en"],
              "type": "fill"
            },
            {
              "question": "Estamos planeando ir _____ vacaciones pronto.",
              "answers": ["de"],
              "type": "fill"
            },
            {
              "question": "Él es muy bueno _____ matemáticas.",
              "answers": ["en"],
              "type": "fill"
            },
            {
              "question": "Necesito terminar este proyecto _____ el viernes.",
              "answers": ["para"],
              "type": "fill"
            }
          ],
        ),
        9: Level(
          id: 9,
          description: "Más vocabulario básico",
          reward: 100,
          questions: [
            {
              "question": "Luna",
              "answers": ["Luna", "Lina", "Lana", "Luno"],
              "type": "pick"
            },
            {
              "question": "Estrella",
              "answers": ["Estrella", "Estralla", "Estrellae", "Estrilla"],
              "type": "pick"
            },
            {
              "question": "Ella está buscando _____ sus llaves perdidas.",
              "answers": ["por"],
              "type": "fill"
            },
            {
              "question": "Te llamaré _____ llegue a casa.",
              "answers": ["cuando"],
              "type": "fill"
            },
            {
              "question": "El gato saltó _____ la cerca.",
              "answers": ["sobre"],
              "type": "fill"
            }
          ],
        ),
        10: Level(
          id: 10,
          description: "El décimo paso",
          reward: 100,
          questions: [
            {
              "question":
                  "Él ha estado trabajando _____ este problema durante horas.",
              "answers": ["en"],
              "type": "fill"
            },
            {
              "question": "Están discutiendo el plan _____ la reunión.",
              "answers": ["durante"],
              "type": "fill"
            },
            {
              "question": "Ella se está preparando _____ sus exámenes.",
              "answers": ["para"],
              "type": "fill"
            },
            {
              "question":
                  "La presentación está programada _____ el próximo lunes.",
              "answers": ["para"],
              "type": "fill"
            },
            {
              "question": "Estoy muy orgulloso _____ mis logros.",
              "answers": ["de"],
              "type": "fill"
            }
          ],
        ),
        11: Level(
          id: 11,
          description: "Artículos y Sustantivos",
          reward: 100,
          questions: [
            {
              "question": "_____ casa es muy grande.",
              "answers": ["La"],
              "type": "fill"
            },
            {
              "question": "_____ coche es azul.",
              "answers": ["El"],
              "type": "fill"
            },
            {
              "question": "Gato",
              "answers": ["Gato", "Gata", "Gatos", "Gatas"],
              "type": "pick"
            },
            {
              "question": "Necesito comprar _____ manzana.",
              "answers": ["una"],
              "type": "fill"
            },
            {
              "question": "Voy a ver _____ película esta noche.",
              "answers": ["una"],
              "type": "fill"
            }
          ],
        ),
        12: Level(
          id: 12,
          description: "Género y Número",
          reward: 100,
          questions: [
            {
              "question": "El _____ es grande.",
              "answers": ["perro"],
              "type": "fill"
            },
            {
              "question": "La _____ es bonita.",
              "answers": ["flor"],
              "type": "fill"
            },
            {
              "question": "Mesa",
              "answers": ["Mesa", "Silla", "Puerta", "Ventana"],
              "type": "pick"
            },
            {
              "question": "Las _____ están cerradas.",
              "answers": ["puertas"],
              "type": "fill"
            },
            {
              "question": "Los _____ juegan en el parque.",
              "answers": ["niños"],
              "type": "fill"
            }
          ],
        ),
        13: Level(
          id: 13,
          description: "Pronombres Personales",
          reward: 100,
          questions: [
            {
              "question": "_____ soy de España.",
              "answers": ["Yo"],
              "type": "fill"
            },
            {
              "question": "_____ tienes un coche rojo.",
              "answers": ["Tú"],
              "type": "fill"
            },
            {
              "question": "Ellos",
              "answers": ["Ellos", "Nosotros", "Tú", "Yo"],
              "type": "pick"
            },
            {
              "question": "_____ vivimos en Argentina.",
              "answers": ["Nosotros"],
              "type": "fill"
            },
            {
              "question": "_____ estudian en la universidad.",
              "answers": ["Ellos"],
              "type": "fill"
            }
          ],
        ),
        14: Level(
          id: 14,
          description: "Verbos en Presente",
          reward: 100,
          questions: [
            {
              "question": "Yo _____ español.",
              "answers": ["hablo"],
              "type": "fill"
            },
            {
              "question": "Ella _____ la televisión.",
              "answers": ["ve"],
              "type": "fill"
            },
            {
              "question": "Comer",
              "answers": ["Comer", "Beber", "Correr", "Escribir"],
              "type": "pick"
            },
            {
              "question": "Nosotros _____ en la biblioteca.",
              "answers": ["estudiamos"],
              "type": "fill"
            },
            {
              "question": "Tú _____ mucho café.",
              "answers": ["bebes"],
              "type": "fill"
            }
          ],
        ),
        15: Level(
          id: 15,
          description: "Verbos Irregulares",
          reward: 100,
          questions: [
            {
              "question": "Yo _____ temprano.",
              "answers": ["salgo"],
              "type": "fill"
            },
            {
              "question": "Él _____ la respuesta.",
              "answers": ["sabe"],
              "type": "fill"
            },
            {
              "question": "Tener",
              "answers": ["Tener", "Saber", "Ser", "Ir"],
              "type": "pick"
            },
            {
              "question": "Nosotros _____ la verdad.",
              "answers": ["decimos"],
              "type": "fill"
            },
            {
              "question": "Tú _____ muy rápido.",
              "answers": ["corres"],
              "type": "fill"
            }
          ],
        ),
        16: Level(
          id: 16,
          description: "Verbos Reflexivos",
          reward: 100,
          questions: [
            {
              "question": "Yo _____ a las siete de la mañana.",
              "answers": ["me levanto"],
              "type": "fill"
            },
            {
              "question": "Ella _____ los dientes después de comer.",
              "answers": ["se cepilla"],
              "type": "fill"
            },
            {
              "question": "Ducharse",
              "answers": ["Ducharse", "Vestirse", "Peinarse", "Cepillarse"],
              "type": "pick"
            },
            {
              "question": "Nosotros _____ temprano los sábados.",
              "answers": ["nos despertamos"],
              "type": "fill"
            },
            {
              "question": "Tú _____ en el espejo.",
              "answers": ["te miras"],
              "type": "fill"
            }
          ],
        ),
        17: Level(
          id: 17,
          description: "Tiempos Verbales",
          reward: 100,
          questions: [
            {
              "question": "Ayer yo _____ una carta.",
              "answers": ["escribí"],
              "type": "fill"
            },
            {
              "question": "Mañana nosotros _____ al cine.",
              "answers": ["iremos"],
              "type": "fill"
            },
            {
              "question": "Pasado",
              "answers": ["Pasado", "Presente", "Futuro", "Condicional"],
              "type": "pick"
            },
            {
              "question": "En este momento él _____ la televisión.",
              "answers": ["está viendo"],
              "type": "fill"
            },
            {
              "question": "Si tuviera dinero, _____ de vacaciones.",
              "answers": ["viajaría"],
              "type": "fill"
            }
          ],
        ),
        18: Level(
          id: 18,
          description: "Preposiciones Comunes",
          reward: 100,
          questions: [
            {
              "question": "El libro está _____ la mesa.",
              "answers": ["sobre"],
              "type": "fill"
            },
            {
              "question": "Voy _____ supermercado.",
              "answers": ["al"],
              "type": "fill"
            },
            {
              "question": "En",
              "answers": ["En", "A", "De", "Con"],
              "type": "pick"
            },
            {
              "question": "Él está sentado _____ la silla.",
              "answers": ["en"],
              "type": "fill"
            },
            {
              "question": "Las llaves están _____ la puerta.",
              "answers": ["cerca de"],
              "type": "fill"
            }
          ],
        ),
        19: Level(
          id: 19,
          description: "Adjetivos y Descripciones",
          reward: 100,
          questions: [
            {
              "question": "El coche es muy _____.",
              "answers": ["rápido"],
              "type": "fill"
            },
            {
              "question": "La niña tiene el cabello _____.",
              "answers": ["largo"],
              "type": "fill"
            },
            {
              "question": "Alto",
              "answers": ["Alto", "Bajo", "Gordo", "Delgado"],
              "type": "pick"
            },
            {
              "question": "La comida está _____.",
              "answers": ["deliciosa"],
              "type": "fill"
            },
            {
              "question": "El examen fue muy _____.",
              "answers": ["difícil"],
              "type": "fill"
            }
          ],
        ),
        20: Level(
          id: 20,
          description: "Frases Comunes en Conversación",
          reward: 100,
          questions: [
            {
              "question": "¿Me puede ayudar _____?",
              "answers": ["por favor"],
              "type": "fill"
            },
            {
              "question": "Muchas _____ por tu ayuda.",
              "answers": ["gracias"],
              "type": "fill"
            },
            {
              "question": "Perdón",
              "answers": ["Perdón", "Hola", "Adiós", "Gracias"],
              "type": "pick"
            },
            {
              "question": "No _____ entiendo.",
              "answers": ["te"],
              "type": "fill"
            },
            {
              "question": "¿Puedes repetirlo _____?",
              "answers": ["otra vez"],
              "type": "fill"
            }
          ],
        ),
        21: Level(
          id: 21,
          description: "Expresiones de Tiempo",
          reward: 100,
          questions: [
            {
              "question": "Ayer _____ mucho frío.",
              "answers": ["hizo"],
              "type": "fill"
            },
            {
              "question": "Voy a viajar _____ dos semanas.",
              "answers": ["en"],
              "type": "fill"
            },
            {
              "question": "Mañana",
              "answers": ["Mañana", "Ayer", "Ahora", "Nunca"],
              "type": "pick"
            },
            {
              "question": "Nos vemos _____ la tarde.",
              "answers": ["por"],
              "type": "fill"
            },
            {
              "question": "La reunión será _____ las 10 de la mañana.",
              "answers": ["a"],
              "type": "fill"
            }
          ],
        ),
        22: Level(
          id: 22,
          description: "Verbos en Infinitivo",
          reward: 100,
          questions: [
            {
              "question": "Me gusta _____ café.",
              "answers": ["tomar"],
              "type": "fill"
            },
            {
              "question": "Ella prefiere _____ temprano.",
              "answers": ["despertarse"],
              "type": "fill"
            },
            {
              "question": "Leer",
              "answers": ["Leer", "Escribir", "Dormir", "Comer"],
              "type": "pick"
            },
            {
              "question": "Voy a _____ español.",
              "answers": ["aprender"],
              "type": "fill"
            },
            {
              "question": "Nosotros queremos _____ en el parque.",
              "answers": ["correr"],
              "type": "fill"
            }
          ],
        ),
        23: Level(
          id: 23,
          description: "Preguntas Básicas",
          reward: 100,
          questions: [
            {
              "question": "¿_____ te llamas?",
              "answers": ["Cómo"],
              "type": "fill"
            },
            {
              "question": "¿_____ años tienes?",
              "answers": ["Cuántos"],
              "type": "fill"
            },
            {
              "question": "Quién",
              "answers": ["Quién", "Cómo", "Cuánto", "Dónde"],
              "type": "pick"
            },
            {
              "question": "¿_____ está la estación de tren?",
              "answers": ["Dónde"],
              "type": "fill"
            },
            {
              "question": "¿_____ es tu color favorito?",
              "answers": ["Cuál"],
              "type": "fill"
            }
          ],
        ),
        24: Level(
          id: 24,
          description: "Conjunciones Comunes",
          reward: 100,
          questions: [
            {
              "question": "Quiero un café _____ sin azúcar.",
              "answers": ["pero"],
              "type": "fill"
            },
            {
              "question": "Voy a la tienda _____ luego vuelvo.",
              "answers": ["y"],
              "type": "fill"
            },
            {
              "question": "Porque",
              "answers": ["Porque", "Pero", "Aunque", "Entonces"],
              "type": "pick"
            },
            {
              "question": "No salí _____ llovía mucho.",
              "answers": ["porque"],
              "type": "fill"
            },
            {
              "question": "Me gusta el té _____ el café.",
              "answers": ["y"],
              "type": "fill"
            }
          ],
        ),
        25: Level(
          id: 25,
          description: "Adverbios de Frecuencia",
          reward: 100,
          questions: [
            {
              "question": "_____ voy al gimnasio los lunes.",
              "answers": ["Siempre"],
              "type": "fill"
            },
            {
              "question": "Ella _____ llega tarde.",
              "answers": ["nunca"],
              "type": "fill"
            },
            {
              "question": "A veces",
              "answers": ["A veces", "Siempre", "Nunca", "Rápido"],
              "type": "pick"
            },
            {
              "question": "Nosotros _____ comemos fuera.",
              "answers": ["a veces"],
              "type": "fill"
            },
            {
              "question": "Él _____ estudia antes del examen.",
              "answers": ["siempre"],
              "type": "fill"
            }
          ],
        ),
        26: Level(
          id: 26,
          description: "Palabras de Ubicación",
          reward: 100,
          questions: [
            {
              "question": "El libro está _____ la mesa.",
              "answers": ["sobre"],
              "type": "fill"
            },
            {
              "question": "El supermercado está _____ de la farmacia.",
              "answers": ["cerca"],
              "type": "fill"
            },
            {
              "question": "Debajo",
              "answers": ["Debajo", "Encima", "Lejos", "Adentro"],
              "type": "pick"
            },
            {
              "question": "Las llaves están _____ la mochila.",
              "answers": ["dentro de"],
              "type": "fill"
            },
            {
              "question": "Nos encontramos _____ la estación.",
              "answers": ["en"],
              "type": "fill"
            }
          ],
        ),
        27: Level(
          id: 27,
          description: "Verbos Comunes en Pasado",
          reward: 100,
          questions: [
            {
              "question": "Ayer _____ una película.",
              "answers": ["vi"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ en un restaurante el domingo.",
              "answers": ["comimos"],
              "type": "fill"
            },
            {
              "question": "Hizo",
              "answers": ["Hizo", "Fue", "Vino", "Tuvo"],
              "type": "pick"
            },
            {
              "question": "Tú _____ mucho en la fiesta.",
              "answers": ["bailaste"],
              "type": "fill"
            },
            {
              "question": "Ellos _____ temprano a casa.",
              "answers": ["volvieron"],
              "type": "fill"
            }
          ],
        ),
        28: Level(
          id: 28,
          description: "Comparaciones y Superlativos",
          reward: 100,
          questions: [
            {
              "question": "Este coche es _____ que aquel.",
              "answers": ["más rápido"],
              "type": "fill"
            },
            {
              "question": "Ella es la persona _____ de la clase.",
              "answers": ["más inteligente"],
              "type": "fill"
            },
            {
              "question": "Menos",
              "answers": ["Menos", "Más", "Mayor", "Peor"],
              "type": "pick"
            },
            {
              "question": "Ese edificio es _____ que el otro.",
              "answers": ["más alto"],
              "type": "fill"
            },
            {
              "question": "Este examen fue _____ que el anterior.",
              "answers": ["más difícil"],
              "type": "fill"
            }
          ],
        ),
        29: Level(
          id: 29,
          description: "Futuro y Planes",
          reward: 100,
          questions: [
            {
              "question": "Mañana _____ a la playa.",
              "answers": ["iremos"],
              "type": "fill"
            },
            {
              "question": "Él _____ un nuevo trabajo el próximo mes.",
              "answers": ["tendrá"],
              "type": "fill"
            },
            {
              "question": "Futuro",
              "answers": ["Futuro", "Pasado", "Presente", "Condicional"],
              "type": "pick"
            },
            {
              "question": "Nosotros _____ un viaje a España el próximo año.",
              "answers": ["haremos"],
              "type": "fill"
            },
            {
              "question": "Tú _____ muy ocupado la próxima semana.",
              "answers": ["estarás"],
              "type": "fill"
            }
          ],
        ),
        30: Level(
          id: 30,
          description: "Expresiones Cotidianas",
          reward: 100,
          questions: [
            {
              "question": "Lo siento, no _____.",
              "answers": ["entiendo"],
              "type": "fill"
            },
            {
              "question": "¡Que _____ bien!",
              "answers": ["te vaya"],
              "type": "fill"
            },
            {
              "question": "Gracias",
              "answers": ["Gracias", "Hola", "Perdón", "Adiós"],
              "type": "pick"
            },
            {
              "question": "¿Me puedes ayudar _____?",
              "answers": ["por favor"],
              "type": "fill"
            },
            {
              "question": "¡_____ pronto!",
              "answers": ["Nos vemos"],
              "type": "fill"
            }
          ],
        ),
        31: Level(
          id: 31,
          description: "Números y Cantidades",
          reward: 100,
          questions: [
            {
              "question": "Tengo _____ manzanas en mi bolsa.",
              "answers": ["tres"],
              "type": "fill"
            },
            {
              "question": "Hay _____ días en una semana.",
              "answers": ["siete"],
              "type": "fill"
            },
            {
              "question": "Uno",
              "answers": ["Uno", "Cinco", "Diez", "Cien"],
              "type": "pick"
            },
            {
              "question": "Ellos compraron _____ botellas de agua.",
              "answers": ["dos"],
              "type": "fill"
            },
            {
              "question": "Él leyó _____ libros el mes pasado.",
              "answers": ["cinco"],
              "type": "fill"
            }
          ],
        ),
        32: Level(
          id: 32,
          description: "Saludos y Presentaciones",
          reward: 100,
          questions: [
            {
              "question": "Hola, ¿cómo _____?",
              "answers": ["estás"],
              "type": "fill"
            },
            {
              "question": "Me llamo Pedro y _____ de España.",
              "answers": ["soy"],
              "type": "fill"
            },
            {
              "question": "Adiós",
              "answers": ["Adiós", "Hola", "Gracias", "Perdón"],
              "type": "pick"
            },
            {
              "question": "Encantado/a de _____.",
              "answers": ["conocerte"],
              "type": "fill"
            },
            {
              "question": "Nos vemos _____ la tarde.",
              "answers": ["por"],
              "type": "fill"
            }
          ],
        ),
        33: Level(
          id: 33,
          description: "Compras y Dinero",
          reward: 100,
          questions: [
            {
              "question": "¿Cuánto _____ este libro?",
              "answers": ["cuesta"],
              "type": "fill"
            },
            {
              "question": "Quisiera comprar un café y una _____.",
              "answers": ["tarta"],
              "type": "fill"
            },
            {
              "question": "Dinero",
              "answers": ["Dinero", "Tarjeta", "Cambio", "Banco"],
              "type": "pick"
            },
            {
              "question": "Aceptan _____ de crédito aquí?",
              "answers": ["tarjetas"],
              "type": "fill"
            },
            {
              "question": "Necesito pagar con _____.",
              "answers": ["efectivo"],
              "type": "fill"
            }
          ],
        ),
        34: Level(
          id: 34,
          description: "Restaurante y Comida",
          reward: 100,
          questions: [
            {
              "question": "¿Qué _____ para comer hoy?",
              "answers": ["hay"],
              "type": "fill"
            },
            {
              "question": "¿Me puede traer la _____?",
              "answers": ["cuenta"],
              "type": "fill"
            },
            {
              "question": "Pan",
              "answers": ["Pan", "Agua", "Leche", "Carne"],
              "type": "pick"
            },
            {
              "question": "La sopa está demasiado _____.",
              "answers": ["caliente"],
              "type": "fill"
            },
            {
              "question": "Me gusta el café, pero lo prefiero _____.",
              "answers": ["sin azúcar"],
              "type": "fill"
            }
          ],
        ),
        35: Level(
          id: 35,
          description: "Viajes y Transporte",
          reward: 100,
          questions: [
            {
              "question": "¿Dónde está la _____ de tren?",
              "answers": ["estación"],
              "type": "fill"
            },
            {
              "question": "¿A qué hora _____ el autobús?",
              "answers": ["sale"],
              "type": "fill"
            },
            {
              "question": "Avión",
              "answers": ["Avión", "Barco", "Tren", "Coche"],
              "type": "pick"
            },
            {
              "question": "Necesito un billete _____ Madrid.",
              "answers": ["para"],
              "type": "fill"
            },
            {
              "question": "El avión _____ con retraso.",
              "answers": ["llega"],
              "type": "fill"
            }
          ],
        ),
        36: Level(
          id: 36,
          description: "El Clima y las Estaciones",
          reward: 100,
          questions: [
            {
              "question": "Hoy hace mucho _____.",
              "answers": ["calor"],
              "type": "fill"
            },
            {
              "question": "Ayer _____ todo el día.",
              "answers": ["llovió"],
              "type": "fill"
            },
            {
              "question": "Verano",
              "answers": ["Verano", "Invierno", "Otoño", "Primavera"],
              "type": "pick"
            },
            {
              "question": "Está nublado, pero no creo que _____.",
              "answers": ["llueva"],
              "type": "fill"
            },
            {
              "question": "Hace frío, mejor llevamos un _____.",
              "answers": ["abrigo"],
              "type": "fill"
            }
          ],
        ),
        37: Level(
          id: 37,
          description: "Casa y Vida Diaria",
          reward: 100,
          questions: [
            {
              "question": "Me levanto _____ las 7 de la mañana.",
              "answers": ["a"],
              "type": "fill"
            },
            {
              "question": "Por la mañana, me _____ los dientes.",
              "answers": ["cepillo"],
              "type": "fill"
            },
            {
              "question": "Cama",
              "answers": ["Cama", "Mesa", "Silla", "Sofá"],
              "type": "pick"
            },
            {
              "question": "Antes de dormir, me gusta _____ un libro.",
              "answers": ["leer"],
              "type": "fill"
            },
            {
              "question": "Mi casa está cerca _____ la estación.",
              "answers": ["de"],
              "type": "fill"
            }
          ],
        ),
        38: Level(
          id: 38,
          description: "Trabajo y Estudios",
          reward: 100,
          questions: [
            {
              "question": "Trabajo como _____ en una oficina.",
              "answers": ["ingeniero"],
              "type": "fill"
            },
            {
              "question": "Estoy estudiando _____ la universidad.",
              "answers": ["en"],
              "type": "fill"
            },
            {
              "question": "Profesor",
              "answers": ["Profesor", "Estudiante", "Cocinero", "Abogado"],
              "type": "pick"
            },
            {
              "question": "¿A qué hora empieza tu _____?",
              "answers": ["clase"],
              "type": "fill"
            },
            {
              "question": "Hoy tenemos una _____ de trabajo.",
              "answers": ["reunión"],
              "type": "fill"
            }
          ],
        ),
        39: Level(
          id: 39,
          description: "Salud y Bienestar",
          reward: 100,
          questions: [
            {
              "question": "Me duele la _____.",
              "answers": ["cabeza"],
              "type": "fill"
            },
            {
              "question": "Necesito ir al _____.",
              "answers": ["médico"],
              "type": "fill"
            },
            {
              "question": "Fiebre",
              "answers": ["Fiebre", "Resfriado", "Dolor", "Cansancio"],
              "type": "pick"
            },
            {
              "question": "Para el dolor de garganta, bebo _____.",
              "answers": ["té caliente"],
              "type": "fill"
            },
            {
              "question": "No me siento bien, creo que voy a _____.",
              "answers": ["descansar"],
              "type": "fill"
            }
          ],
        ),
        40: Level(
          id: 40,
          description: "Colores y Formas",
          reward: 100,
          questions: [
            {
              "question": "El cielo es de color _____.",
              "answers": ["azul"],
              "type": "fill"
            },
            {
              "question": "La manzana es _____.",
              "answers": ["roja"],
              "type": "fill"
            },
            {
              "question": "Círculo",
              "answers": ["Círculo", "Cuadrado", "Triángulo", "Rectángulo"],
              "type": "pick"
            },
            {
              "question": "El sol es de color _____.",
              "answers": ["amarillo"],
              "type": "fill"
            },
            {
              "question": "Las hojas en otoño son _____.",
              "answers": ["naranjas"],
              "type": "fill"
            }
          ],
        ),
        41: Level(
          id: 41,
          description: "Verbos en Presente",
          reward: 100,
          questions: [
            {
              "question": "Yo _____ español.",
              "answers": ["hablo"],
              "type": "fill"
            },
            {
              "question": "Ella _____ la televisión.",
              "answers": ["ve"],
              "type": "fill"
            },
            {
              "question": "Comer",
              "answers": ["Comer", "Beber", "Correr", "Escribir"],
              "type": "pick"
            },
            {
              "question": "Nosotros _____ en la biblioteca.",
              "answers": ["estudiamos"],
              "type": "fill"
            },
            {
              "question": "Tú _____ mucho café.",
              "answers": ["bebes"],
              "type": "fill"
            }
          ],
        ),
        42: Level(
          id: 42,
          description: "Verbos Irregulares",
          reward: 100,
          questions: [
            {
              "question": "Yo _____ temprano.",
              "answers": ["salgo"],
              "type": "fill"
            },
            {
              "question": "Él _____ la respuesta.",
              "answers": ["sabe"],
              "type": "fill"
            },
            {
              "question": "Tener",
              "answers": ["Tener", "Saber", "Ser", "Ir"],
              "type": "pick"
            },
            {
              "question": "Nosotros _____ la verdad.",
              "answers": ["decimos"],
              "type": "fill"
            },
            {
              "question": "Tú _____ muy rápido.",
              "answers": ["corres"],
              "type": "fill"
            }
          ],
        ),
        43: Level(
          id: 43,
          description: "Verbos Reflexivos",
          reward: 100,
          questions: [
            {
              "question": "Yo _____ a las siete de la mañana.",
              "answers": ["me levanto"],
              "type": "fill"
            },
            {
              "question": "Ella _____ los dientes después de comer.",
              "answers": ["se cepilla"],
              "type": "fill"
            },
            {
              "question": "Ducharse",
              "answers": ["Ducharse", "Vestirse", "Peinarse", "Cepillarse"],
              "type": "pick"
            },
            {
              "question": "Nosotros _____ temprano los sábados.",
              "answers": ["nos despertamos"],
              "type": "fill"
            },
            {
              "question": "Tú _____ en el espejo.",
              "answers": ["te miras"],
              "type": "fill"
            }
          ],
        ),
        44: Level(
          id: 44,
          description: "Tiempos Verbales",
          reward: 100,
          questions: [
            {
              "question": "Ayer yo _____ una carta.",
              "answers": ["escribí"],
              "type": "fill"
            },
            {
              "question": "Mañana nosotros _____ al cine.",
              "answers": ["iremos"],
              "type": "fill"
            },
            {
              "question": "Pasado",
              "answers": ["Pasado", "Presente", "Futuro", "Condicional"],
              "type": "pick"
            },
            {
              "question": "En este momento él _____ la televisión.",
              "answers": ["está viendo"],
              "type": "fill"
            },
            {
              "question": "Si tuviera dinero, _____ de vacaciones.",
              "answers": ["viajaría"],
              "type": "fill"
            }
          ],
        ),
        45: Level(
          id: 45,
          description: "Preposiciones Comunes",
          reward: 100,
          questions: [
            {
              "question": "El libro está _____ la mesa.",
              "answers": ["sobre"],
              "type": "fill"
            },
            {
              "question": "Voy _____ supermercado.",
              "answers": ["al"],
              "type": "fill"
            },
            {
              "question": "En",
              "answers": ["En", "A", "De", "Con"],
              "type": "pick"
            },
            {
              "question": "Él está sentado _____ la silla.",
              "answers": ["en"],
              "type": "fill"
            },
            {
              "question": "Las llaves están _____ la puerta.",
              "answers": ["cerca de"],
              "type": "fill"
            }
          ],
        ),
        46: Level(
          id: 46,
          description: "Adjetivos y Descripciones",
          reward: 100,
          questions: [
            {
              "question": "El coche es muy _____.",
              "answers": ["rápido"],
              "type": "fill"
            },
            {
              "question": "La niña tiene el cabello _____.",
              "answers": ["largo"],
              "type": "fill"
            },
            {
              "question": "Alto",
              "answers": ["Alto", "Bajo", "Gordo", "Delgado"],
              "type": "pick"
            },
            {
              "question": "La comida está _____.",
              "answers": ["deliciosa"],
              "type": "fill"
            },
            {
              "question": "El examen fue muy _____.",
              "answers": ["difícil"],
              "type": "fill"
            }
          ],
        ),
        47: Level(
          id: 47,
          description: "Adverbios de Frecuencia",
          reward: 100,
          questions: [
            {
              "question": "_____ voy al gimnasio los lunes.",
              "answers": ["Siempre"],
              "type": "fill"
            },
            {
              "question": "Ella _____ llega tarde.",
              "answers": ["nunca"],
              "type": "fill"
            },
            {
              "question": "A veces",
              "answers": ["A veces", "Siempre", "Nunca", "Rápido"],
              "type": "pick"
            },
            {
              "question": "Nosotros _____ comemos fuera.",
              "answers": ["a veces"],
              "type": "fill"
            },
            {
              "question": "Él _____ estudia antes del examen.",
              "answers": ["siempre"],
              "type": "fill"
            }
          ],
        ),
        48: Level(
          id: 48,
          description: "Comparaciones y Superlativos",
          reward: 100,
          questions: [
            {
              "question": "Este coche es _____ que aquel.",
              "answers": ["más rápido"],
              "type": "fill"
            },
            {
              "question": "Ella es la persona _____ de la clase.",
              "answers": ["más inteligente"],
              "type": "fill"
            },
            {
              "question": "Menos",
              "answers": ["Menos", "Más", "Mayor", "Peor"],
              "type": "pick"
            },
            {
              "question": "Ese edificio es _____ que el otro.",
              "answers": ["más alto"],
              "type": "fill"
            },
            {
              "question": "Este examen fue _____ que el anterior.",
              "answers": ["más difícil"],
              "type": "fill"
            }
          ],
        ),
        49: Level(
          id: 49,
          description: "Futuro y Planes",
          reward: 100,
          questions: [
            {
              "question": "Mañana _____ a la playa.",
              "answers": ["iremos"],
              "type": "fill"
            },
            {
              "question": "Él _____ un nuevo trabajo el próximo mes.",
              "answers": ["tendrá"],
              "type": "fill"
            },
            {
              "question": "Futuro",
              "answers": ["Futuro", "Pasado", "Presente", "Condicional"],
              "type": "pick"
            },
            {
              "question": "Nosotros _____ un viaje a España el próximo año.",
              "answers": ["haremos"],
              "type": "fill"
            },
            {
              "question": "Tú _____ muy ocupado la próxima semana.",
              "answers": ["estarás"],
              "type": "fill"
            }
          ],
        ),
        50: Level(
          id: 50,
          description: "Expresiones Cotidianas",
          reward: 100,
          questions: [
            {
              "question": "Lo siento, no _____.",
              "answers": ["entiendo"],
              "type": "fill"
            },
            {
              "question": "¡Que _____ bien!",
              "answers": ["te vaya"],
              "type": "fill"
            },
            {
              "question": "Gracias",
              "answers": ["Gracias", "Hola", "Perdón", "Adiós"],
              "type": "pick"
            },
            {
              "question": "¿Me puedes ayudar _____?",
              "answers": ["por favor"],
              "type": "fill"
            },
            {
              "question": "¡_____ pronto!",
              "answers": ["Nos vemos"],
              "type": "fill"
            }
          ],
        ),
        51: Level(
          id: 51,
          description: "Verbos en Pasado (Regulares)",
          reward: 100,
          questions: [
            {
              "question": "Ayer _____ una carta a mi amigo.",
              "answers": ["escribí"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ en un restaurante el domingo.",
              "answers": ["comimos"],
              "type": "fill"
            },
            {
              "question": "Habló",
              "answers": ["Habló", "Corrió", "Vio", "Fue"],
              "type": "pick"
            },
            {
              "question": "Tú _____ con tu madre anoche.",
              "answers": ["hablaste"],
              "type": "fill"
            },
            {
              "question": "Ellos _____ temprano a casa.",
              "answers": ["volvieron"],
              "type": "fill"
            }
          ],
        ),
        52: Level(
          id: 52,
          description: "Verbos en Pasado (Irregulares)",
          reward: 100,
          questions: [
            {
              "question": "Ayer yo _____ al cine.",
              "answers": ["fui"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ un examen difícil.",
              "answers": ["tuvimos"],
              "type": "fill"
            },
            {
              "question": "Vino",
              "answers": ["Vino", "Pudo", "Dijo", "Hizo"],
              "type": "pick"
            },
            {
              "question": "Él _____ la verdad.",
              "answers": ["dijo"],
              "type": "fill"
            },
            {
              "question": "Tú _____ muy cansado después del trabajo.",
              "answers": ["estuviste"],
              "type": "fill"
            }
          ],
        ),
        53: Level(
          id: 53,
          description: "Pasado Simple vs. Imperfecto",
          reward: 100,
          questions: [
            {
              "question": "Cuando era niño, _____ jugar fútbol.",
              "answers": ["me gustaba"],
              "type": "fill"
            },
            {
              "question": "Ayer _____ a la escuela a las 8.",
              "answers": ["llegué"],
              "type": "fill"
            },
            {
              "question": "Veía",
              "answers": ["Veía", "Vio", "Hizo", "Iba"],
              "type": "pick"
            },
            {
              "question":
                  "Cuando vivíamos en España, siempre _____ a la playa.",
              "answers": ["íbamos"],
              "type": "fill"
            },
            {
              "question": "De repente, él _____ un ruido extraño.",
              "answers": ["escuchó"],
              "type": "fill"
            }
          ],
        ),
        54: Level(
          id: 54,
          description: "Descripciones en Pasado",
          reward: 100,
          questions: [
            {
              "question": "Cuando era pequeño, mi casa _____ muy grande.",
              "answers": ["era"],
              "type": "fill"
            },
            {
              "question": "Ayer el clima _____ frío y lluvioso.",
              "answers": ["estaba"],
              "type": "fill"
            },
            {
              "question": "Bonito",
              "answers": ["Bonito", "Pequeño", "Viejo", "Moderno"],
              "type": "pick"
            },
            {
              "question": "El hotel donde nos quedamos _____ muy caro.",
              "answers": ["era"],
              "type": "fill"
            },
            {
              "question": "Cuando entré en la casa, todo _____ oscuro.",
              "answers": ["estaba"],
              "type": "fill"
            }
          ],
        ),
        55: Level(
          id: 55,
          description: "Acciones en Pasado",
          reward: 100,
          questions: [
            {
              "question": "Ayer _____ mucho café.",
              "answers": ["bebí"],
              "type": "fill"
            },
            {
              "question":
                  "Nosotros _____ una película el fin de semana pasado.",
              "answers": ["vimos"],
              "type": "fill"
            },
            {
              "question": "Salió",
              "answers": ["Salió", "Entró", "Corrió", "Comió"],
              "type": "pick"
            },
            {
              "question": "Tú _____ en la fiesta toda la noche.",
              "answers": ["bailaste"],
              "type": "fill"
            },
            {
              "question": "Ellos _____ una decisión importante.",
              "answers": ["tomaron"],
              "type": "fill"
            }
          ],
        ),
        56: Level(
          id: 56,
          description: "Planes que Cambiaron en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Quería salir, pero _____ mucho frío.",
              "answers": ["hacía"],
              "type": "fill"
            },
            {
              "question": "Pensábamos ir a la playa, pero _____ lluvia.",
              "answers": ["hubo"],
              "type": "fill"
            },
            {
              "question": "Iba",
              "answers": ["Iba", "Pensó", "Decidió", "Vino"],
              "type": "pick"
            },
            {
              "question": "Nosotros _____ estudiar, pero vimos una película.",
              "answers": ["íbamos"],
              "type": "fill"
            },
            {
              "question": "Ella _____ cocinar, pero no tenía tiempo.",
              "answers": ["quería"],
              "type": "fill"
            }
          ],
        ),
        57: Level(
          id: 57,
          description: "Relatos y Cuentos en Pasado",
          reward: 100,
          questions: [
            {
              "question": "Había una vez un rey que _____ en un castillo.",
              "answers": ["vivía"],
              "type": "fill"
            },
            {
              "question": "Un día, él _____ un gran tesoro.",
              "answers": ["encontró"],
              "type": "fill"
            },
            {
              "question": "Corría",
              "answers": ["Corría", "Anduvo", "Saltó", "Gritó"],
              "type": "pick"
            },
            {
              "question": "La princesa _____ al bosque encantado.",
              "answers": ["fue"],
              "type": "fill"
            },
            {
              "question": "Cuando llegó al castillo, todo _____ en silencio.",
              "answers": ["estaba"],
              "type": "fill"
            }
          ],
        ),
        58: Level(
          id: 58,
          description: "Conversaciones en Pasado",
          reward: 100,
          questions: [
            {
              "question": "Ayer _____ con mi madre por teléfono.",
              "answers": ["hablé"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ sobre nuestros planes de vacaciones.",
              "answers": ["discutimos"],
              "type": "fill"
            },
            {
              "question": "Dijo",
              "answers": ["Dijo", "Preguntó", "Respondió", "Comentó"],
              "type": "pick"
            },
            {
              "question": "Él me _____ que iba a llegar tarde.",
              "answers": ["dijo"],
              "type": "fill"
            },
            {
              "question": "Ella _____ que no podía asistir a la reunión.",
              "answers": ["explicó"],
              "type": "fill"
            }
          ],
        ),
        59: Level(
          id: 59,
          description: "Sueños y Deseos en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Cuando era niño, _____ ser astronauta.",
              "answers": ["quería"],
              "type": "fill"
            },
            {
              "question": "Siempre _____ viajar por el mundo.",
              "answers": ["soñaba"],
              "type": "fill"
            },
            {
              "question": "Esperaba",
              "answers": ["Esperaba", "Pensaba", "Deseaba", "Soñaba"],
              "type": "pick"
            },
            {
              "question": "Mi abuela siempre _____ vivir en el campo.",
              "answers": ["quería"],
              "type": "fill"
            },
            {
              "question": "Ellos _____ con tener una casa grande.",
              "answers": ["soñaban"],
              "type": "fill"
            }
          ],
        ),
        60: Level(
          id: 60,
          description: "Expresiones con Pasado",
          reward: 100,
          questions: [
            {
              "question": "Lo siento, no _____ lo que dijiste.",
              "answers": ["escuché"],
              "type": "fill"
            },
            {
              "question": "Ayer _____ un error en mi examen.",
              "answers": ["cometí"],
              "type": "fill"
            },
            {
              "question": "Recordé",
              "answers": ["Recordé", "Olvidé", "Pensé", "Aprendí"],
              "type": "pick"
            },
            {
              "question": "Cuando llegué, ya _____ empezado la película.",
              "answers": ["había"],
              "type": "fill"
            },
            {
              "question": "No _____ lo que pasó anoche.",
              "answers": ["recuerdo"],
              "type": "fill"
            }
          ],
        ),
        61: Level(
          id: 61,
          description: "Acciones Cotidianas en Pasado",
          reward: 100,
          questions: [
            {
              "question": "Ayer _____ a las 7 de la mañana.",
              "answers": ["me desperté"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ el desayuno juntos.",
              "answers": ["preparamos"],
              "type": "fill"
            },
            {
              "question": "Lavé",
              "answers": ["Lavé", "Comí", "Dormí", "Fui"],
              "type": "pick"
            },
            {
              "question": "Ella _____ la casa antes de salir.",
              "answers": ["limpió"],
              "type": "fill"
            },
            {
              "question": "Tú _____ tarde a la reunión.",
              "answers": ["llegaste"],
              "type": "fill"
            }
          ],
        ),
        62: Level(
          id: 62,
          description: "Salud y Bienestar en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Ayer me _____ la cabeza todo el día.",
              "answers": ["dolió"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ al médico porque estábamos enfermos.",
              "answers": ["fuimos"],
              "type": "fill"
            },
            {
              "question": "Tomé",
              "answers": ["Tomé", "Dormí", "Corrí", "Bebí"],
              "type": "pick"
            },
            {
              "question": "Él _____ mucha agua para sentirse mejor.",
              "answers": ["bebió"],
              "type": "fill"
            },
            {
              "question": "Tú _____ una pastilla para el dolor de cabeza.",
              "answers": ["tomaste"],
              "type": "fill"
            }
          ],
        ),
        63: Level(
          id: 63,
          description: "Compras en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Ayer _____ una camisa nueva.",
              "answers": ["compré"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ frutas en el mercado.",
              "answers": ["compramos"],
              "type": "fill"
            },
            {
              "question": "Costó",
              "answers": ["Costó", "Vendió", "Dio", "Llevó"],
              "type": "pick"
            },
            {
              "question": "Ella _____ un regalo para su amiga.",
              "answers": ["compró"],
              "type": "fill"
            },
            {
              "question": "Tú _____ en la tienda por más de una hora.",
              "answers": ["estuviste"],
              "type": "fill"
            }
          ],
        ),
        64: Level(
          id: 64,
          description: "Comida y Bebida en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Anoche _____ una pizza grande.",
              "answers": ["comimos"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ café después de la cena.",
              "answers": ["tomamos"],
              "type": "fill"
            },
            {
              "question": "Bebió",
              "answers": ["Bebió", "Comió", "Cocinó", "Preparó"],
              "type": "pick"
            },
            {
              "question": "Ella _____ un pastel delicioso.",
              "answers": ["horneó"],
              "type": "fill"
            },
            {
              "question": "Tú _____ el almuerzo con tus amigos.",
              "answers": ["compartiste"],
              "type": "fill"
            }
          ],
        ),
        65: Level(
          id: 65,
          description: "Viajes en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "El verano pasado _____ a España.",
              "answers": ["viajé"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ en un hotel muy bonito.",
              "answers": ["nos quedamos"],
              "type": "fill"
            },
            {
              "question": "Visitó",
              "answers": ["Visitó", "Compró", "Salió", "Fue"],
              "type": "pick"
            },
            {
              "question": "Ella _____ muchos museos en París.",
              "answers": ["visitó"],
              "type": "fill"
            },
            {
              "question": "Tú _____ muchas fotos del paisaje.",
              "answers": ["sacaste"],
              "type": "fill"
            }
          ],
        ),
        66: Level(
          id: 66,
          description: "Transporte en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Ayer _____ el autobús para ir al trabajo.",
              "answers": ["tomé"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ un taxi para llegar a tiempo.",
              "answers": ["tomamos"],
              "type": "fill"
            },
            {
              "question": "Manejé",
              "answers": ["Manejé", "Corrí", "Paré", "Caminé"],
              "type": "pick"
            },
            {
              "question": "Ella _____ su bicicleta por el parque.",
              "answers": ["montó"],
              "type": "fill"
            },
            {
              "question": "Tú _____ en coche a la casa de tus padres.",
              "answers": ["fuiste"],
              "type": "fill"
            }
          ],
        ),
        67: Level(
          id: 67,
          description: "Trabajo y Estudios en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "El año pasado _____ en una empresa grande.",
              "answers": ["trabajé"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ para el examen toda la semana.",
              "answers": ["estudiamos"],
              "type": "fill"
            },
            {
              "question": "Aprendí",
              "answers": ["Aprendí", "Escuché", "Leí", "Pregunté"],
              "type": "pick"
            },
            {
              "question": "Ella _____ un curso de español en la universidad.",
              "answers": ["tomó"],
              "type": "fill"
            },
            {
              "question": "Tú _____ tu tesis el año pasado.",
              "answers": ["escribiste"],
              "type": "fill"
            }
          ],
        ),
        68: Level(
          id: 68,
          description: "Eventos Sociales en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Anoche _____ a una fiesta con mis amigos.",
              "answers": ["fui"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ en la boda de Juan.",
              "answers": ["bailamos"],
              "type": "fill"
            },
            {
              "question": "Celebró",
              "answers": ["Celebró", "Comió", "Jugó", "Cantó"],
              "type": "pick"
            },
            {
              "question": "Ella _____ con sus amigas en el concierto.",
              "answers": ["cantó"],
              "type": "fill"
            },
            {
              "question": "Tú _____ muchas personas nuevas.",
              "answers": ["conociste"],
              "type": "fill"
            }
          ],
        ),
        69: Level(
          id: 69,
          description: "Relatos en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Ayer _____ una historia interesante.",
              "answers": ["leí"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ un cuento a los niños.",
              "answers": ["contamos"],
              "type": "fill"
            },
            {
              "question": "Escuchó",
              "answers": ["Escuchó", "Dibujó", "Cantó", "Jugó"],
              "type": "pick"
            },
            {
              "question": "Ella _____ un cuento de hadas.",
              "answers": ["narró"],
              "type": "fill"
            },
            {
              "question": "Tú _____ una historia de terror.",
              "answers": ["escribiste"],
              "type": "fill"
            }
          ],
        ),
        70: Level(
          id: 70,
          description: "Sueños y Metas en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Cuando era niño, _____ ser astronauta.",
              "answers": ["quería"],
              "type": "fill"
            },
            {
              "question": "Nosotros siempre _____ viajar por el mundo.",
              "answers": ["soñábamos"],
              "type": "fill"
            },
            {
              "question": "Esperaba",
              "answers": ["Esperaba", "Pensaba", "Deseaba", "Soñaba"],
              "type": "pick"
            },
            {
              "question": "Ella _____ con ser actriz.",
              "answers": ["soñaba"],
              "type": "fill"
            },
            {
              "question": "Tú _____ aprender a tocar la guitarra.",
              "answers": ["quisiste"],
              "type": "fill"
            }
          ],
        ),
        71: Level(
          id: 71,
          description: "Actividades de la Mañana en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Ayer _____ a las 6 de la mañana.",
              "answers": ["me desperté"],
              "type": "fill"
            },
            {
              "question": "Después, _____ un café.",
              "answers": ["tomé"],
              "type": "fill"
            },
            {
              "question": "Duché",
              "answers": ["Duché", "Lavé", "Corrí", "Dormí"],
              "type": "pick"
            },
            {
              "question": "Él _____ los dientes después de desayunar.",
              "answers": ["se cepilló"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ la casa antes de salir.",
              "answers": ["limpiamos"],
              "type": "fill"
            }
          ],
        ),
        72: Level(
          id: 72,
          description: "Recuerdos de la Infancia",
          reward: 100,
          questions: [
            {
              "question": "Cuando era niño, _____ con mis amigos en el parque.",
              "answers": ["jugaba"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ dibujos animados todas las mañanas.",
              "answers": ["veíamos"],
              "type": "fill"
            },
            {
              "question": "Corríamos",
              "answers": ["Corríamos", "Gritamos", "Saltamos", "Hablamos"],
              "type": "pick"
            },
            {
              "question":
                  "Mi abuela siempre me _____ historias antes de dormir.",
              "answers": ["contaba"],
              "type": "fill"
            },
            {
              "question":
                  "De pequeños, mis hermanos y yo _____ juntos todo el tiempo.",
              "answers": ["estábamos"],
              "type": "fill"
            }
          ],
        ),
        73: Level(
          id: 73,
          description: "Experiencias de Viaje en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "El verano pasado _____ a Italia.",
              "answers": ["viajé"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ en un hotel cerca del mar.",
              "answers": ["nos quedamos"],
              "type": "fill"
            },
            {
              "question": "Visitamos",
              "answers": ["Visitamos", "Comimos", "Leímos", "Nadamos"],
              "type": "pick"
            },
            {
              "question": "Ellos _____ muchos lugares históricos.",
              "answers": ["visitaron"],
              "type": "fill"
            },
            {
              "question": "Tú _____ muchas fotos del paisaje.",
              "answers": ["sacaste"],
              "type": "fill"
            }
          ],
        ),
        74: Level(
          id: 74,
          description: "Fiestas y Celebraciones Pasadas",
          reward: 100,
          questions: [
            {
              "question": "El año pasado _____ mi cumpleaños con mis amigos.",
              "answers": ["celebré"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ toda la noche en la boda de Ana.",
              "answers": ["bailamos"],
              "type": "fill"
            },
            {
              "question": "Cantamos",
              "answers": ["Cantamos", "Saltamos", "Bebimos", "Comimos"],
              "type": "pick"
            },
            {
              "question": "Ella _____ un vestido hermoso en la fiesta.",
              "answers": ["llevó"],
              "type": "fill"
            },
            {
              "question": "Tú _____ un brindis con champán.",
              "answers": ["hiciste"],
              "type": "fill"
            }
          ],
        ),
        75: Level(
          id: 75,
          description: "Enfermedades y Visitas al Médico",
          reward: 100,
          questions: [
            {
              "question": "La semana pasada _____ fiebre.",
              "answers": ["tuve"],
              "type": "fill"
            },
            {
              "question":
                  "Nosotros _____ al hospital porque Juan estaba enfermo.",
              "answers": ["fuimos"],
              "type": "fill"
            },
            {
              "question": "Tomaste",
              "answers": ["Tomaste", "Llamaste", "Caminaste", "Dormiste"],
              "type": "pick"
            },
            {
              "question": "Él _____ medicina para el resfriado.",
              "answers": ["tomó"],
              "type": "fill"
            },
            {
              "question": "Tú _____ en cama todo el día.",
              "answers": ["descansaste"],
              "type": "fill"
            }
          ],
        ),
        76: Level(
          id: 76,
          description: "Cosas que Aprendimos",
          reward: 100,
          questions: [
            {
              "question": "El año pasado _____ a cocinar.",
              "answers": ["aprendí"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ un nuevo idioma.",
              "answers": ["aprendimos"],
              "type": "fill"
            },
            {
              "question": "Estudiaste",
              "answers": ["Estudiaste", "Dibujaste", "Bailaste", "Cantaste"],
              "type": "pick"
            },
            {
              "question": "Ella _____ a tocar la guitarra.",
              "answers": ["aprendió"],
              "type": "fill"
            },
            {
              "question": "Tú _____ matemáticas con un profesor privado.",
              "answers": ["estudiaste"],
              "type": "fill"
            }
          ],
        ),
        77: Level(
          id: 77,
          description: "El Tiempo y el Clima en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Ayer _____ mucho calor.",
              "answers": ["hizo"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ lluvia todo el día.",
              "answers": ["tuvimos"],
              "type": "fill"
            },
            {
              "question": "Nevó",
              "answers": ["Nevó", "Llovió", "Hizo sol", "Granizó"],
              "type": "pick"
            },
            {
              "question": "Él _____ un viento muy fuerte en la montaña.",
              "answers": ["sintió"],
              "type": "fill"
            },
            {
              "question": "Tú _____ que hacía demasiado frío para salir.",
              "answers": ["pensaste"],
              "type": "fill"
            }
          ],
        ),
        78: Level(
          id: 78,
          description: "Decisiones Importantes en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "El año pasado _____ cambiar de trabajo.",
              "answers": ["decidí"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ mudarnos a una nueva ciudad.",
              "answers": ["decidimos"],
              "type": "fill"
            },
            {
              "question": "Pensó",
              "answers": ["Pensó", "Soñó", "Deseó", "Intentó"],
              "type": "pick"
            },
            {
              "question": "Él _____ estudiar medicina en la universidad.",
              "answers": ["eligió"],
              "type": "fill"
            },
            {
              "question": "Tú _____ que era mejor esperar.",
              "answers": ["decidiste"],
              "type": "fill"
            }
          ],
        ),
        79: Level(
          id: 79,
          description: "Descripciones de Lugares en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Cuando visité Roma, la ciudad _____ increíble.",
              "answers": ["era"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ en un hotel muy bonito.",
              "answers": ["nos quedamos"],
              "type": "fill"
            },
            {
              "question": "Había",
              "answers": ["Había", "Existía", "Parecía", "Veía"],
              "type": "pick"
            },
            {
              "question": "Él _____ que el paisaje era impresionante.",
              "answers": ["dijo"],
              "type": "fill"
            },
            {
              "question": "Tú _____ que el lugar era muy tranquilo.",
              "answers": ["pensaste"],
              "type": "fill"
            }
          ],
        ),
        80: Level(
          id: 80,
          description: "Planes que Cambiaron",
          reward: 100,
          questions: [
            {
              "question": "Ayer íbamos a salir, pero _____ a llover.",
              "answers": ["empezó"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ quedarnos en casa porque hacía frío.",
              "answers": ["decidimos"],
              "type": "fill"
            },
            {
              "question": "Quería",
              "answers": ["Quería", "Pensaba", "Intentaba", "Soñaba"],
              "type": "pick"
            },
            {
              "question": "Él _____ ir al cine, pero estaba cerrado.",
              "answers": ["quería"],
              "type": "fill"
            },
            {
              "question":
                  "Tú _____ ir a la playa, pero hacía demasiado viento.",
              "answers": ["pensabas"],
              "type": "fill"
            }
          ],
        ),
        81: Level(
          id: 81,
          description: "Narraciones en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Cuando _____ a casa, ya era de noche.",
              "answers": ["llegué"],
              "type": "fill"
            },
            {
              "question": "Mientras ella _____, el teléfono sonó.",
              "answers": ["dormía"],
              "type": "fill"
            },
            {
              "question": "Estaban",
              "answers": ["Estaban", "Fueron", "Iban", "Hicieron"],
              "type": "pick"
            },
            {
              "question": "Él _____ la noticia mientras desayunaba.",
              "answers": ["leyó"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ en el parque cuando empezó a llover.",
              "answers": ["caminábamos"],
              "type": "fill"
            }
          ],
        ),
        82: Level(
          id: 82,
          description: "Pasado con Conectores Temporales",
          reward: 100,
          questions: [
            {
              "question": "Después de que _____ la cena, vi una película.",
              "answers": ["terminé"],
              "type": "fill"
            },
            {
              "question": "Tan pronto como _____, empezó la clase.",
              "answers": ["llegué"],
              "type": "fill"
            },
            {
              "question": "Antes de",
              "answers": ["Antes de", "Después de", "Mientras", "Hasta que"],
              "type": "pick"
            },
            {
              "question": "Cuando _____ pequeño, solía jugar en el jardín.",
              "answers": ["era"],
              "type": "fill"
            },
            {
              "question": "Hasta que no _____ el problema, no descansó.",
              "answers": ["resolvió"],
              "type": "fill"
            }
          ],
        ),
        83: Level(
          id: 83,
          description: "Pluscuamperfecto del Indicativo",
          reward: 100,
          questions: [
            {
              "question": "Cuando llegué, ellos ya _____ cenado.",
              "answers": ["habían"],
              "type": "fill"
            },
            {
              "question": "Nosotros ya _____ estudiado antes del examen.",
              "answers": ["habíamos"],
              "type": "fill"
            },
            {
              "question": "Habías",
              "answers": ["Habías", "Habían", "Había", "Hubiste"],
              "type": "pick"
            },
            {
              "question": "Ella dijo que nunca _____ estado en París.",
              "answers": ["había"],
              "type": "fill"
            },
            {
              "question": "Tú _____ llamado antes de salir.",
              "answers": ["habías"],
              "type": "fill"
            }
          ],
        ),
        84: Level(
          id: 84,
          description: "Condicional en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Si hubiera estudiado más, _____ aprobado el examen.",
              "answers": ["habría"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ ido al cine si no hubiera llovido.",
              "answers": ["habríamos"],
              "type": "fill"
            },
            {
              "question": "Habría",
              "answers": ["Habría", "Hubiera", "Hubo", "Hizo"],
              "type": "pick"
            },
            {
              "question": "Si me hubieras avisado, _____ preparado algo.",
              "answers": ["habría"],
              "type": "fill"
            },
            {
              "question": "Tú _____ viajado más si hubieras tenido dinero.",
              "answers": ["habrías"],
              "type": "fill"
            }
          ],
        ),
        85: Level(
          id: 85,
          description: "Subjuntivo en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Esperaba que él _____ a la reunión.",
              "answers": ["viniera"],
              "type": "fill"
            },
            {
              "question": "Nos pidieron que _____ en silencio.",
              "answers": ["estuviéramos"],
              "type": "fill"
            },
            {
              "question": "Dijera",
              "answers": ["Dijera", "Dijo", "Diría", "Decía"],
              "type": "pick"
            },
            {
              "question":
                  "Si ella _____ más tiempo, habría terminado el proyecto.",
              "answers": ["tuviera"],
              "type": "fill"
            },
            {
              "question": "Era necesario que tú _____ temprano.",
              "answers": ["llegaras"],
              "type": "fill"
            }
          ],
        ),
        86: Level(
          id: 86,
          description: "Expresiones con el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Hace un año _____ un viaje increíble.",
              "answers": ["hice"],
              "type": "fill"
            },
            {
              "question": "No _____ nada interesante ayer.",
              "answers": ["hice"],
              "type": "fill"
            },
            {
              "question": "Hace",
              "answers": ["Hace", "Desde", "Por", "Hasta"],
              "type": "pick"
            },
            {
              "question": "Él no _____ visto la película hasta ayer.",
              "answers": ["había"],
              "type": "fill"
            },
            {
              "question": "Nosotros _____ mucho cuando éramos niños.",
              "answers": ["jugábamos"],
              "type": "fill"
            }
          ],
        ),
        87: Level(
          id: 87,
          description: "Narraciones y Relatos en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Había una vez un príncipe que _____ en un castillo.",
              "answers": ["vivía"],
              "type": "fill"
            },
            {
              "question": "Un día, él _____ un objeto mágico.",
              "answers": ["encontró"],
              "type": "fill"
            },
            {
              "question": "Corría",
              "answers": ["Corría", "Anduvo", "Saltó", "Gritó"],
              "type": "pick"
            },
            {
              "question": "Cuando entró en la cueva, todo _____ oscuro.",
              "answers": ["estaba"],
              "type": "fill"
            },
            {
              "question": "El villano _____ un plan para robar el tesoro.",
              "answers": ["ideó"],
              "type": "fill"
            }
          ],
        ),
        88: Level(
          id: 88,
          description: "Acciones Interrumpidas en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Mientras yo _____, el teléfono sonó.",
              "answers": ["dormía"],
              "type": "fill"
            },
            {
              "question": "Cuando ellos _____ la cena, la luz se apagó.",
              "answers": ["preparaban"],
              "type": "fill"
            },
            {
              "question": "Leía",
              "answers": ["Leía", "Leyó", "Leerá", "Leería"],
              "type": "pick"
            },
            {
              "question": "Nosotros _____ en el parque cuando empezó a llover.",
              "answers": ["paseábamos"],
              "type": "fill"
            },
            {
              "question": "Ella _____ la tele cuando su amigo llamó.",
              "answers": ["veía"],
              "type": "fill"
            }
          ],
        ),
        89: Level(
          id: 89,
          description: "Planes y Expectativas en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Pensábamos que el vuelo _____ más tarde.",
              "answers": ["saldría"],
              "type": "fill"
            },
            {
              "question": "Nos dijeron que la clase _____ a las 10.",
              "answers": ["empezaría"],
              "type": "fill"
            },
            {
              "question": "Iría",
              "answers": ["Iría", "Fue", "Irá", "Iba"],
              "type": "pick"
            },
            {
              "question": "Él creía que el tren _____ a tiempo.",
              "answers": ["llegaría"],
              "type": "fill"
            },
            {
              "question": "Yo esperaba que tú _____ la carta.",
              "answers": ["leyeras"],
              "type": "fill"
            }
          ],
        ),
        90: Level(
          id: 90,
          description: "Errores y Malentendidos en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Pensé que el examen _____ más fácil.",
              "answers": ["sería"],
              "type": "fill"
            },
            {
              "question": "Nosotros creímos que la tienda _____ abierta.",
              "answers": ["estaba"],
              "type": "fill"
            },
            {
              "question": "Confundí",
              "answers": ["Confundí", "Olvidé", "Recordé", "Escuché"],
              "type": "pick"
            },
            {
              "question": "Ella supuso que él _____ la dirección correcta.",
              "answers": ["sabía"],
              "type": "fill"
            },
            {
              "question": "Tú pensaste que el autobús _____ más rápido.",
              "answers": ["vendría"],
              "type": "fill"
            }
          ],
        ),
        91: Level(
          id: 91,
          description: "Pluscuamperfecto y Conectores Temporales",
          reward: 100,
          questions: [
            {
              "question": "Cuando llegué, ellos ya _____.",
              "answers": ["habían salido"],
              "type": "fill"
            },
            {
              "question": "Después de que _____ la carta, la envié.",
              "answers": ["hube escrito"],
              "type": "fill"
            },
            {
              "question": "Había",
              "answers": ["Había", "Hubo", "Habría", "Fue"],
              "type": "pick"
            },
            {
              "question": "No entendí porque no _____ bien.",
              "answers": ["habían explicado"],
              "type": "fill"
            },
            {
              "question": "Cuando entramos, la película ya _____.",
              "answers": ["había comenzado"],
              "type": "fill"
            }
          ],
        ),
        92: Level(
          id: 92,
          description: "Condicional Compuesto en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Si hubiera estudiado más, _____ mejor en el examen.",
              "answers": ["habría sacado"],
              "type": "fill"
            },
            {
              "question":
                  "Nosotros _____ el tren si no hubiéramos llegado tarde.",
              "answers": ["habríamos tomado"],
              "type": "fill"
            },
            {
              "question": "Habría",
              "answers": ["Habría", "Hubiera", "Había", "Hubo"],
              "type": "pick"
            },
            {
              "question":
                  "Si tú me lo hubieras dicho antes, _____ preparado algo.",
              "answers": ["habría"],
              "type": "fill"
            },
            {
              "question": "Si no hubiera llovido, ellos _____ al parque.",
              "answers": ["habrían ido"],
              "type": "fill"
            }
          ],
        ),
        93: Level(
          id: 93,
          description: "Subjuntivo Pasado en Expresiones Complejas",
          reward: 100,
          questions: [
            {
              "question": "Esperaba que él _____ la verdad.",
              "answers": ["dijera"],
              "type": "fill"
            },
            {
              "question": "Me sorprendió que tú _____ tan tarde.",
              "answers": ["llegaras"],
              "type": "fill"
            },
            {
              "question": "Tuviera",
              "answers": ["Tuviera", "Tenía", "Tuvo", "Tendría"],
              "type": "pick"
            },
            {
              "question": "Si yo _____ más dinero, habría viajado más.",
              "answers": ["tuviera"],
              "type": "fill"
            },
            {
              "question": "Era importante que ella _____ la decisión correcta.",
              "answers": ["tomara"],
              "type": "fill"
            }
          ],
        ),
        94: Level(
          id: 94,
          description: "Estilo Indirecto en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Él me dijo que _____ a la reunión.",
              "answers": ["vendría"],
              "type": "fill"
            },
            {
              "question": "Nos informaron que el vuelo _____ retrasado.",
              "answers": ["había sido"],
              "type": "fill"
            },
            {
              "question": "Dijo",
              "answers": ["Dijo", "Respondió", "Comentó", "Explicó"],
              "type": "pick"
            },
            {
              "question": "Ella contó que su hermano _____ a España.",
              "answers": ["había viajado"],
              "type": "fill"
            },
            {
              "question": "Me aseguraron que todo _____ según lo planeado.",
              "answers": ["había salido"],
              "type": "fill"
            }
          ],
        ),
        95: Level(
          id: 95,
          description: "Acciones Hipotéticas en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Si lo _____ antes, te habría ayudado.",
              "answers": ["hubiera sabido"],
              "type": "fill"
            },
            {
              "question": "Si él _____ mejor, no habría cometido ese error.",
              "answers": ["hubiera pensado"],
              "type": "fill"
            },
            {
              "question": "Hubiera",
              "answers": ["Hubiera", "Hubo", "Habría", "Había"],
              "type": "pick"
            },
            {
              "question":
                  "Si nosotros _____ más temprano, habríamos evitado el tráfico.",
              "answers": ["hubiéramos salido"],
              "type": "fill"
            },
            {
              "question": "Si tú _____ más cuidado, no te habrías caído.",
              "answers": ["hubieras tenido"],
              "type": "fill"
            }
          ],
        ),
        96: Level(
          id: 96,
          description: "Comparaciones y Opiniones en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Pensé que la película _____ más interesante.",
              "answers": ["sería"],
              "type": "fill"
            },
            {
              "question": "Nos dijeron que el hotel _____ mejor.",
              "answers": ["parecía"],
              "type": "fill"
            },
            {
              "question": "Creí",
              "answers": ["Creí", "Pensé", "Supuse", "Entendí"],
              "type": "pick"
            },
            {
              "question": "Él afirmó que el examen _____ difícil.",
              "answers": ["había sido"],
              "type": "fill"
            },
            {
              "question": "Yo imaginaba que el viaje _____ más corto.",
              "answers": ["sería"],
              "type": "fill"
            }
          ],
        ),
        97: Level(
          id: 97,
          description: "Eventos Inesperados en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "De repente, _____ la luz.",
              "answers": ["se apagó"],
              "type": "fill"
            },
            {
              "question": "Cuando llegué, ya _____ el autobús.",
              "answers": ["había salido"],
              "type": "fill"
            },
            {
              "question": "Apareció",
              "answers": ["Apareció", "Desapareció", "Volvió", "Corrió"],
              "type": "pick"
            },
            {
              "question":
                  "Ellos no esperaban que la reunión _____ tan temprano.",
              "answers": ["terminara"],
              "type": "fill"
            },
            {
              "question": "Mientras caminábamos, de repente _____ a llover.",
              "answers": ["empezó"],
              "type": "fill"
            }
          ],
        ),
        98: Level(
          id: 98,
          description: "Errores y Malentendidos en el Pasado",
          reward: 100,
          questions: [
            {
              "question": "Pensé que el examen _____ más fácil.",
              "answers": ["sería"],
              "type": "fill"
            },
            {
              "question": "Nosotros creímos que la tienda _____ abierta.",
              "answers": ["estaba"],
              "type": "fill"
            },
            {
              "question": "Confundí",
              "answers": ["Confundí", "Olvidé", "Recordé", "Escuché"],
              "type": "pick"
            },
            {
              "question": "Ella supuso que él _____ la dirección correcta.",
              "answers": ["sabía"],
              "type": "fill"
            },
            {
              "question": "Tú pensaste que el autobús _____ más rápido.",
              "answers": ["vendría"],
              "type": "fill"
            }
          ],
        ),
        99: Level(
          id: 99,
          description: "Expresiones y Frases Complejas",
          reward: 100,
          questions: [
            {
              "question": "A pesar de que _____, salimos a la calle.",
              "answers": ["llovía"],
              "type": "fill"
            },
            {
              "question": "Él se fue sin que yo lo _____.",
              "answers": ["notara"],
              "type": "fill"
            },
            {
              "question": "Aunque",
              "answers": ["Aunque", "Si", "Porque", "Hasta"],
              "type": "pick"
            },
            {
              "question": "Nos encontramos con alguien que no _____ en años.",
              "answers": ["veíamos"],
              "type": "fill"
            },
            {
              "question": "Antes de que _____ la tormenta, llegamos a casa.",
              "answers": ["empezara"],
              "type": "fill"
            }
          ],
        ),
        100: Level(
          id: 100,
          description: "Finalizando con Complejidad",
          reward: 100,
          questions: [
            {
              "question": "Me habría gustado que tú _____ antes.",
              "answers": ["llegaras"],
              "type": "fill"
            },
            {
              "question": "Dudo que él _____ entendido la pregunta.",
              "answers": ["haya"],
              "type": "fill"
            },
            {
              "question": "Hubiera",
              "answers": ["Hubiera", "Había", "Habría", "Hubo"],
              "type": "pick"
            },
            {
              "question": "Si él _____ más paciencia, habría sido mejor.",
              "answers": ["hubiera tenido"],
              "type": "fill"
            },
            {
              "question": "No esperaba que ellos _____ tan temprano.",
              "answers": ["se fueran"],
              "type": "fill"
            }
          ],
        ),
      },
      'Dutch': {
        1: Level(
          id: 1,
          description: "Introductie in het Nederlands",
          reward: 100,
          questions: [
            {
              "question": "Hallo, hoe _____ je?",
              "answers": ["heet"],
              "type": "fill"
            },
            {
              "question": "Ik kom _____ Duitsland.",
              "answers": ["uit"],
              "type": "fill"
            },
            {
              "question": "Man",
              "answers": ["Man", "Vrouw", "Kind", "Hond"],
              "type": "pick"
            },
            {
              "question": "Dit is mijn vriend. Hij _____ uit Nederland.",
              "answers": ["komt"],
              "type": "fill"
            },
            {
              "question": "Wij wonen _____ een klein dorp.",
              "answers": ["in"],
              "type": "fill"
            }
          ],
        ),
        2: Level(
          id: 2,
          description: "Basiswoordenschat",
          reward: 100,
          questions: [
            {
              "question": "Ik spreek een beetje _____.",
              "answers": ["Nederlands"],
              "type": "fill"
            },
            {
              "question": "Zij wonen _____ een groot huis.",
              "answers": ["in"],
              "type": "fill"
            },
            {
              "question": "Hond",
              "answers": ["Hond", "Kat", "Muis", "Paard"],
              "type": "pick"
            },
            {
              "question": "Wij gaan morgen _____ de bioscoop.",
              "answers": ["naar"],
              "type": "fill"
            },
            {
              "question": "Hij werkt al vijf jaar bij dezelfde _____.",
              "answers": ["firma"],
              "type": "fill"
            }
          ],
        ),
        3: Level(
          id: 3,
          description: "Eenvoudige zinnen",
          reward: 100,
          questions: [
            {
              "question": "Ik ben _____ de supermarkt geweest.",
              "answers": ["naar"],
              "type": "fill"
            },
            {
              "question": "De auto staat geparkeerd _____ het huis.",
              "answers": ["voor"],
              "type": "fill"
            },
            {
              "question": "Boek",
              "answers": ["Boek", "Pen", "Tafel", "Stoel"],
              "type": "pick"
            },
            {
              "question": "Wij hebben _____ avondeten gekookt.",
              "answers": ["het"],
              "type": "fill"
            },
            {
              "question": "De kinderen _____ buiten aan het spelen.",
              "answers": ["zijn"],
              "type": "fill"
            }
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
              "question": "Zon",
              "answers": ["Zon", "Maan", "Ster", "Wolk"],
              "type": "pick"
            },
            {
              "question": "Zij heeft een mooie _____ gekocht.",
              "answers": ["jurk"],
              "type": "fill"
            },
            {
              "question": "Wij _____ in de tuin aan het werken.",
              "answers": ["waren"],
              "type": "fill"
            }
          ],
        ),
        5: Level(
          id: 5,
          description: "Veelgebruikte uitdrukkingen",
          reward: 100,
          questions: [
            {
              "question": "Goedemorgen! Hoe _____ het met jou?",
              "answers": ["gaat"],
              "type": "fill"
            },
            {
              "question": "Kunt u mij _____ het zout geven?",
              "answers": ["alstublieft"],
              "type": "fill"
            },
            {
              "question": "Dankjewel",
              "answers": ["Dankjewel", "Hallo", "Tot ziens", "Alsjeblieft"],
              "type": "pick"
            },
            {
              "question": "Weet jij _____ het morgen mooi weer wordt?",
              "answers": ["of"],
              "type": "fill"
            },
            {
              "question": "Hij werkt al de hele dag _____ dit project.",
              "answers": ["aan"],
              "type": "fill"
            }
          ],
        ),
        6: Level(
          id: 6,
          description: "Meer oefenen",
          reward: 100,
          questions: [
            {
              "question": "De leraar vroeg ons om _____ stil te zijn.",
              "answers": ["even"],
              "type": "fill"
            },
            {
              "question": "Wij willen graag _____ onze grootouders bezoeken.",
              "answers": ["vandaag"],
              "type": "fill"
            },
            {
              "question": "Tafel",
              "answers": ["Tafel", "Deur", "Ramen", "Boek"],
              "type": "pick"
            },
            {
              "question": "Ik moet nog even _____ boodschappen doen.",
              "answers": ["snel"],
              "type": "fill"
            },
            {
              "question": "Wij hebben een nieuwe _____ gekocht.",
              "answers": ["bank"],
              "type": "fill"
            }
          ],
        ),
        7: Level(
          id: 7,
          description: "Dagelijkse gesprekken",
          reward: 100,
          questions: [
            {
              "question": "Hoe laat _____ het nu?",
              "answers": ["is"],
              "type": "fill"
            },
            {
              "question": "Kun je mij de weg naar het station _____?",
              "answers": ["uitleggen"],
              "type": "fill"
            },
            {
              "question": "Water",
              "answers": ["Water", "Melk", "Koffie", "Sap"],
              "type": "pick"
            },
            {
              "question": "Ik _____ om 15:00 een afspraak bij de dokter.",
              "answers": ["heb"],
              "type": "fill"
            },
            {
              "question": "Wij _____ vaak samen naar muziek.",
              "answers": ["luisteren"],
              "type": "fill"
            }
          ],
        ),
        8: Level(
          id: 8,
          description: "Tijd en data",
          reward: 100,
          questions: [
            {
              "question": "De klok hangt _____ de muur.",
              "answers": ["aan"],
              "type": "fill"
            },
            {
              "question": "Wij zijn geboren _____ april.",
              "answers": ["in"],
              "type": "fill"
            },
            {
              "question": "Week",
              "answers": ["Week", "Maand", "Jaar", "Dag"],
              "type": "pick"
            },
            {
              "question": "Wij vertrekken _____ 14:00 uur.",
              "answers": ["om"],
              "type": "fill"
            },
            {
              "question": "De vergadering is gepland _____ vrijdag.",
              "answers": ["op"],
              "type": "fill"
            }
          ],
        ),
        9: Level(
          id: 9,
          description: "Meer basiswoorden",
          reward: 100,
          questions: [
            {
              "question": "De maan schijnt _____ de nacht.",
              "answers": ["tijdens"],
              "type": "fill"
            },
            {
              "question":
                  "Ik zoek mijn sleutels, maar ik weet niet _____ ze zijn.",
              "answers": ["waar"],
              "type": "fill"
            },
            {
              "question": "Ster",
              "answers": ["Ster", "Zon", "Planeet", "Wolk"],
              "type": "pick"
            },
            {
              "question": "De kat sprong _____ de tafel.",
              "answers": ["op"],
              "type": "fill"
            },
            {
              "question": "Ik bel je zodra ik _____ thuis ben.",
              "answers": ["weer"],
              "type": "fill"
            }
          ],
        ),
        10: Level(
          id: 10,
          description: "Eenvoudige grammatica",
          reward: 100,
          questions: [
            {
              "question":
                  "Hij is al de hele dag _____ dit probleem aan het werken.",
              "answers": ["aan"],
              "type": "fill"
            },
            {
              "question": "De presentatie is gepland _____ volgende maandag.",
              "answers": ["voor"],
              "type": "fill"
            },
            {
              "question": "Auto",
              "answers": ["Auto", "Fiets", "Bus", "Trein"],
              "type": "pick"
            },
            {
              "question": "Ik ben erg trots _____ mijn prestaties.",
              "answers": ["op"],
              "type": "fill"
            },
            {
              "question": "Wij hebben de hele dag _____ de stad gewandeld.",
              "answers": ["door"],
              "type": "fill"
            }
          ],
        ),
        11: Level(
          id: 11,
          description: "Getallen en Hoeveelheden",
          reward: 100,
          questions: [
            {
              "question": "Ik heb _____ appels in mijn tas.",
              "answers": ["drie"],
              "type": "fill"
            },
            {
              "question": "Er zijn _____ dagen in een week.",
              "answers": ["zeven"],
              "type": "fill"
            },
            {
              "question": "Eén",
              "answers": ["Eén", "Vijf", "Tien", "Honderd"],
              "type": "pick"
            },
            {
              "question": "Zij kochten _____ flessen water.",
              "answers": ["twee"],
              "type": "fill"
            },
            {
              "question": "Hij las _____ boeken vorige maand.",
              "answers": ["vijf"],
              "type": "fill"
            }
          ],
        ),
        12: Level(
          id: 12,
          description: "Groeten en Kennismaken",
          reward: 100,
          questions: [
            {
              "question": "Hallo, hoe _____ het?",
              "answers": ["gaat"],
              "type": "fill"
            },
            {
              "question": "Ik heet Thomas en ik _____ uit Nederland.",
              "answers": ["kom"],
              "type": "fill"
            },
            {
              "question": "Tot ziens",
              "answers": ["Tot ziens", "Hallo", "Dank je", "Sorry"],
              "type": "pick"
            },
            {
              "question": "Aangenaam! Ik ben blij je te _____.",
              "answers": ["ontmoeten"],
              "type": "fill"
            },
            {
              "question": "Wij zien elkaar _____ vanavond.",
              "answers": ["vanavond"],
              "type": "fill"
            }
          ],
        ),
        13: Level(
          id: 13,
          description: "Boodschappen en Geld",
          reward: 100,
          questions: [
            {
              "question": "Hoeveel _____ deze kaas?",
              "answers": ["kost"],
              "type": "fill"
            },
            {
              "question": "Ik wil graag een kop koffie en een _____.",
              "answers": ["koekje"],
              "type": "fill"
            },
            {
              "question": "Geld",
              "answers": ["Geld", "Bankpas", "Portemonnee", "Winkel"],
              "type": "pick"
            },
            {
              "question": "Kan ik hier met _____ betalen?",
              "answers": ["pinpas"],
              "type": "fill"
            },
            {
              "question": "De supermarkt is open van 8 uur _____ 18 uur.",
              "answers": ["tot"],
              "type": "fill"
            }
          ],
        ),
        14: Level(
          id: 14,
          description: "Eten en Drinken",
          reward: 100,
          questions: [
            {
              "question": "Wat _____ u graag eten?",
              "answers": ["wilt"],
              "type": "fill"
            },
            {
              "question": "Kunt u mij de _____ geven?",
              "answers": ["menukaart"],
              "type": "fill"
            },
            {
              "question": "Kaas",
              "answers": ["Kaas", "Melk", "Vlees", "Brood"],
              "type": "pick"
            },
            {
              "question": "De soep is te _____.",
              "answers": ["heet"],
              "type": "fill"
            },
            {
              "question": "Ik drink mijn koffie altijd _____.",
              "answers": ["zwart"],
              "type": "fill"
            }
          ],
        ),
        15: Level(
          id: 15,
          description: "Reizen en Vervoer",
          reward: 100,
          questions: [
            {
              "question": "Waar is het _____ station?",
              "answers": ["dichtstbijzijnde"],
              "type": "fill"
            },
            {
              "question": "Hoe laat _____ de trein?",
              "answers": ["vertrekt"],
              "type": "fill"
            },
            {
              "question": "Bus",
              "answers": ["Bus", "Boot", "Fiets", "Trein"],
              "type": "pick"
            },
            {
              "question": "Ik wil een ticket kopen _____ Amsterdam.",
              "answers": ["naar"],
              "type": "fill"
            },
            {
              "question": "Mijn vlucht heeft twee uur _____.",
              "answers": ["vertraging"],
              "type": "fill"
            }
          ],
        ),
        16: Level(
          id: 16,
          description: "Weer en Seizoenen",
          reward: 100,
          questions: [
            {
              "question": "Vandaag is het erg _____.",
              "answers": ["warm"],
              "type": "fill"
            },
            {
              "question": "Gisteren _____ het de hele dag.",
              "answers": ["regende"],
              "type": "fill"
            },
            {
              "question": "Zomer",
              "answers": ["Zomer", "Herfst", "Winter", "Lente"],
              "type": "pick"
            },
            {
              "question": "Het is bewolkt, maar ik denk niet dat het _____.",
              "answers": ["gaat regenen"],
              "type": "fill"
            },
            {
              "question": "In de winter draag ik altijd een _____.",
              "answers": ["jas"],
              "type": "fill"
            }
          ],
        ),
        17: Level(
          id: 17,
          description: "Wonen en Dagelijks Leven",
          reward: 100,
          questions: [
            {
              "question": "Ik sta elke dag om 7 uur _____.",
              "answers": ["op"],
              "type": "fill"
            },
            {
              "question": "Na het eten _____ ik altijd de afwas.",
              "answers": ["doe"],
              "type": "fill"
            },
            {
              "question": "Slaapkamer",
              "answers": ["Slaapkamer", "Keuken", "Badkamer", "Woonkamer"],
              "type": "pick"
            },
            {
              "question": "Mijn huis heeft drie _____.",
              "answers": ["kamers"],
              "type": "fill"
            },
            {
              "question": "Wil jij de tafel _____?",
              "answers": ["dekken"],
              "type": "fill"
            }
          ],
        ),
        18: Level(
          id: 18,
          description: "Werk en Studie",
          reward: 100,
          questions: [
            {
              "question": "Ik werk als _____ in een kantoor.",
              "answers": ["ingenieur"],
              "type": "fill"
            },
            {
              "question": "Ik studeer _____ de universiteit.",
              "answers": ["aan"],
              "type": "fill"
            },
            {
              "question": "Leraar",
              "answers": ["Leraar", "Student", "Verkoper", "Advocaat"],
              "type": "pick"
            },
            {
              "question": "Hoe laat begint jouw _____?",
              "answers": ["les"],
              "type": "fill"
            },
            {
              "question": "Vandaag hebben we een lange _____.",
              "answers": ["vergadering"],
              "type": "fill"
            }
          ],
        ),
        19: Level(
          id: 19,
          description: "Gezondheid en Welzijn",
          reward: 100,
          questions: [
            {
              "question": "Ik heb pijn aan mijn _____.",
              "answers": ["hoofd"],
              "type": "fill"
            },
            {
              "question": "Ik moet naar de _____.",
              "answers": ["dokter"],
              "type": "fill"
            },
            {
              "question": "Koorts",
              "answers": ["Koorts", "Verkoudheid", "Pijn", "Hoest"],
              "type": "pick"
            },
            {
              "question": "Voor keelpijn drink ik altijd _____.",
              "answers": ["thee"],
              "type": "fill"
            },
            {
              "question": "Ik voel me niet goed, ik ga _____.",
              "answers": ["rusten"],
              "type": "fill"
            }
          ],
        ),
        20: Level(
          id: 20,
          description: "Kleuren en Vormen",
          reward: 100,
          questions: [
            {
              "question": "De lucht is _____.",
              "answers": ["blauw"],
              "type": "fill"
            },
            {
              "question": "Een banaan is _____.",
              "answers": ["geel"],
              "type": "fill"
            },
            {
              "question": "Cirkel",
              "answers": ["Cirkel", "Vierkant", "Driehoek", "Rechthoek"],
              "type": "pick"
            },
            {
              "question": "Het stoplicht is nu _____.",
              "answers": ["rood"],
              "type": "fill"
            },
            {
              "question": "De blaadjes in de herfst zijn _____.",
              "answers": ["oranje"],
              "type": "fill"
            }
          ],
        ),
        21: Level(
          id: 21,
          description: "Dagelijkse Activiteiten in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Gisteren _____ ik om 7 uur op.",
              "answers": ["stond"],
              "type": "fill"
            },
            {
              "question": "Wij _____ ontbijt met koffie en brood.",
              "answers": ["aten"],
              "type": "fill"
            },
            {
              "question": "Poetste",
              "answers": ["Poetste", "Dronk", "Kocht", "Keek"],
              "type": "pick"
            },
            {
              "question": "Hij _____ zijn tanden en ging naar school.",
              "answers": ["poetste"],
              "type": "fill"
            },
            {
              "question": "Na het werk _____ we samen een film.",
              "answers": ["keken"],
              "type": "fill"
            }
          ],
        ),
        22: Level(
          id: 22,
          description: "Reizen en Vakanties in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Vorige zomer _____ we naar Spanje.",
              "answers": ["reisden"],
              "type": "fill"
            },
            {
              "question": "Wij _____ in een klein hotel aan zee.",
              "answers": ["bleven"],
              "type": "fill"
            },
            {
              "question": "Vlogen",
              "answers": ["Vlogen", "Renden", "Zwommen", "Stapten"],
              "type": "pick"
            },
            {
              "question": "Hij _____ veel foto's van de bergen.",
              "answers": ["maakte"],
              "type": "fill"
            },
            {
              "question": "Twee jaar geleden _____ ik naar Japan.",
              "answers": ["vloog"],
              "type": "fill"
            }
          ],
        ),
        23: Level(
          id: 23,
          description: "Gezondheid en Ziekte in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Vorige week _____ ik griep.",
              "answers": ["had"],
              "type": "fill"
            },
            {
              "question": "Wij _____ de dokter om advies.",
              "answers": ["belden"],
              "type": "fill"
            },
            {
              "question": "Nam",
              "answers": ["Nam", "Liep", "Dronk", "Kreeg"],
              "type": "pick"
            },
            {
              "question": "Hij _____ veel water om beter te worden.",
              "answers": ["dronk"],
              "type": "fill"
            },
            {
              "question": "Zij _____ medicijnen tegen de pijn.",
              "answers": ["nam"],
              "type": "fill"
            }
          ],
        ),
        24: Level(
          id: 24,
          description: "Weer en Seizoenen in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Gisteren _____ het de hele dag.",
              "answers": ["regende"],
              "type": "fill"
            },
            {
              "question": "Vorige winter _____ het veel in Nederland.",
              "answers": ["sneeuwde"],
              "type": "fill"
            },
            {
              "question": "Stormde",
              "answers": ["Stormde", "Sneeuwde", "Regende", "Donderde"],
              "type": "pick"
            },
            {
              "question": "Het weer _____ slecht, dus we bleven binnen.",
              "answers": ["was"],
              "type": "fill"
            },
            {
              "question": "Vorig jaar _____ we een heel warme zomer.",
              "answers": ["hadden"],
              "type": "fill"
            }
          ],
        ),
        25: Level(
          id: 25,
          description: "Eten en Drinken in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Gisteren _____ we pizza voor het avondeten.",
              "answers": ["aten"],
              "type": "fill"
            },
            {
              "question": "Wij _____ koffie na het eten.",
              "answers": ["dronken"],
              "type": "fill"
            },
            {
              "question": "Bestelde",
              "answers": ["Bestelde", "Kocht", "Smaakte", "Kookte"],
              "type": "pick"
            },
            {
              "question": "Hij _____ een groot bord pasta in het restaurant.",
              "answers": ["bestelde"],
              "type": "fill"
            },
            {
              "question": "Zij _____ een heerlijke taart voor haar verjaardag.",
              "answers": ["bakte"],
              "type": "fill"
            }
          ],
        ),
        26: Level(
          id: 26,
          description: "Werk en Studie in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Vorig jaar _____ ik bij een groot bedrijf.",
              "answers": ["werkte"],
              "type": "fill"
            },
            {
              "question": "Wij _____ een cursus Nederlands.",
              "answers": ["volgden"],
              "type": "fill"
            },
            {
              "question": "Schreef",
              "answers": ["Schreef", "Las", "Luisterde", "Vertelde"],
              "type": "pick"
            },
            {
              "question": "Hij _____ een lange e-mail naar zijn baas.",
              "answers": ["schreef"],
              "type": "fill"
            },
            {
              "question": "Zij _____ haar studie in 2020 af.",
              "answers": ["ronde"],
              "type": "fill"
            }
          ],
        ),
        27: Level(
          id: 27,
          description: "Wonen en Verhuizen in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Tien jaar geleden _____ wij in Utrecht.",
              "answers": ["woonden"],
              "type": "fill"
            },
            {
              "question": "Zij _____ naar een nieuw appartement in Amsterdam.",
              "answers": ["verhuisde"],
              "type": "fill"
            },
            {
              "question": "Kocht",
              "answers": ["Kocht", "Huurde", "Verkocht", "Verhuisde"],
              "type": "pick"
            },
            {
              "question": "Wij _____ vorig jaar een nieuw huis.",
              "answers": ["kochten"],
              "type": "fill"
            },
            {
              "question": "Hij _____ zijn oude huis voor een goede prijs.",
              "answers": ["verkocht"],
              "type": "fill"
            }
          ],
        ),
        28: Level(
          id: 28,
          description: "Evenementen en Feesten in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Vorige week _____ we een groot feest.",
              "answers": ["vierden"],
              "type": "fill"
            },
            {
              "question": "Wij _____ met vrienden op oudejaarsavond.",
              "answers": ["dansten"],
              "type": "fill"
            },
            {
              "question": "Zong",
              "answers": ["Zong", "Sprak", "Kocht", "Wandelde"],
              "type": "pick"
            },
            {
              "question": "Zij _____ op het podium tijdens het concert.",
              "answers": ["zong"],
              "type": "fill"
            },
            {
              "question": "Hij _____ zijn verjaardag met een groot feest.",
              "answers": ["vierde"],
              "type": "fill"
            }
          ],
        ),
        29: Level(
          id: 29,
          description: "Emoties en Gevoelens in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Gisteren _____ ik erg blij.",
              "answers": ["was"],
              "type": "fill"
            },
            {
              "question": "Wij _____ moe na een lange dag werken.",
              "answers": ["waren"],
              "type": "fill"
            },
            {
              "question": "Voelde",
              "answers": ["Voelde", "Lachte", "Dacht", "Hoorde"],
              "type": "pick"
            },
            {
              "question": "Hij _____ zich verdrietig na het slechte nieuws.",
              "answers": ["voelde"],
              "type": "fill"
            },
            {
              "question": "Tegen het einde van de dag _____ ik erg moe.",
              "answers": ["voelde"],
              "type": "fill"
            }
          ],
        ),
        30: Level(
          id: 30,
          description: "Dagelijkse Gewoonten in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Toen ik jong was, _____ ik altijd vroeg op.",
              "answers": ["stond"],
              "type": "fill"
            },
            {
              "question": "Wij _____ elke dag naar school met de fiets.",
              "answers": ["reden"],
              "type": "fill"
            },
            {
              "question": "Eten",
              "answers": ["Eten", "Drinken", "Slapen", "Werken"],
              "type": "pick"
            },
            {
              "question": "Hij _____ altijd thee in de ochtend.",
              "answers": ["dronk"],
              "type": "fill"
            },
            {
              "question": "Zij _____ elke avond een boek.",
              "answers": ["las"],
              "type": "fill"
            }
          ],
        ),
        31: Level(
          id: 31,
          description: "Dagelijkse Gewoonten in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Toen ik jong was, _____ ik altijd vroeg op.",
              "answers": ["stond"],
              "type": "fill"
            },
            {
              "question": "Wij _____ elke dag naar school met de fiets.",
              "answers": ["reden"],
              "type": "fill"
            },
            {
              "question": "Eten",
              "answers": ["Eten", "Drinken", "Slapen", "Werken"],
              "type": "pick"
            },
            {
              "question": "Hij _____ altijd thee in de ochtend.",
              "answers": ["dronk"],
              "type": "fill"
            },
            {
              "question": "Zij _____ elke avond een boek.",
              "answers": ["las"],
              "type": "fill"
            }
          ],
        ),
        32: Level(
          id: 32,
          description: "Werk en Carrière in het Verleden",
          reward: 100,
          questions: [
            {
              "question":
                  "Vorig jaar _____ ik als ingenieur bij een groot bedrijf.",
              "answers": ["werkte"],
              "type": "fill"
            },
            {
              "question":
                  "Wij _____ een belangrijke vergadering in de ochtend.",
              "answers": ["hadden"],
              "type": "fill"
            },
            {
              "question": "Besloot",
              "answers": ["Besloot", "Koos", "Verhuisde", "Reisde"],
              "type": "pick"
            },
            {
              "question": "Hij _____ om een nieuwe baan te zoeken.",
              "answers": ["besloot"],
              "type": "fill"
            },
            {
              "question": "Zij _____ haar baan en startte een eigen bedrijf.",
              "answers": ["verliet"],
              "type": "fill"
            }
          ],
        ),
        33: Level(
          id: 33,
          description: "Studie en Onderwijs in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Toen ik studeerde, _____ ik veel in de bibliotheek.",
              "answers": ["las"],
              "type": "fill"
            },
            {
              "question": "Wij _____ voor ons examen tot laat in de nacht.",
              "answers": ["studeerden"],
              "type": "fill"
            },
            {
              "question": "Leerde",
              "answers": ["Leerde", "Sprak", "Zong", "Dacht"],
              "type": "pick"
            },
            {
              "question": "Hij _____ een nieuwe taal tijdens zijn studie.",
              "answers": ["leerde"],
              "type": "fill"
            },
            {
              "question": "Zij _____ haar diploma in 2020.",
              "answers": ["haalde"],
              "type": "fill"
            }
          ],
        ),
        34: Level(
          id: 34,
          description: "Familie en Vrienden in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Vroeger _____ wij vaak met onze familie.",
              "answers": ["gingen"],
              "type": "fill"
            },
            {
              "question": "Wij _____ elke zondag bij onze grootouders.",
              "answers": ["bezochten"],
              "type": "fill"
            },
            {
              "question": "Speelde",
              "answers": ["Speelde", "Keek", "Dronk", "Werkte"],
              "type": "pick"
            },
            {
              "question": "Hij _____ vroeger veel met zijn neven en nichten.",
              "answers": ["speelde"],
              "type": "fill"
            },
            {
              "question": "Zij _____ haar ouders elk weekend.",
              "answers": ["belde"],
              "type": "fill"
            }
          ],
        ),
        35: Level(
          id: 35,
          description: "Sport en Vrije Tijd in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Toen ik jonger was, _____ ik drie keer per week.",
              "answers": ["zwom"],
              "type": "fill"
            },
            {
              "question": "Wij _____ vaak voetbal in het park.",
              "answers": ["speelden"],
              "type": "fill"
            },
            {
              "question": "Rende",
              "answers": ["Rende", "Dacht", "Zong", "Werkte"],
              "type": "pick"
            },
            {
              "question": "Hij _____ de marathon in 2019.",
              "answers": ["rende"],
              "type": "fill"
            },
            {
              "question": "Zij _____ elke avond muziek.",
              "answers": ["luisterde"],
              "type": "fill"
            }
          ],
        ),
        36: Level(
          id: 36,
          description: "Vakanties en Reizen in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Vorig jaar _____ we naar Frankrijk op vakantie.",
              "answers": ["gingen"],
              "type": "fill"
            },
            {
              "question": "Wij _____ een hotel aan het strand.",
              "answers": ["hadden"],
              "type": "fill"
            },
            {
              "question": "Vlogen",
              "answers": ["Vlogen", "Zwommen", "Kozen", "Huurden"],
              "type": "pick"
            },
            {
              "question": "Hij _____ een auto om door Italië te reizen.",
              "answers": ["huurde"],
              "type": "fill"
            },
            {
              "question": "Zij _____ prachtige landschappen tijdens de reis.",
              "answers": ["fotografeerde"],
              "type": "fill"
            }
          ],
        ),
        37: Level(
          id: 37,
          description: "Boodschappen en Winkelen in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Gisteren _____ we naar de markt.",
              "answers": ["gingen"],
              "type": "fill"
            },
            {
              "question": "Wij _____ groente en fruit.",
              "answers": ["kochten"],
              "type": "fill"
            },
            {
              "question": "Betaalde",
              "answers": ["Betaalde", "Sprak", "Kookte", "Werkte"],
              "type": "pick"
            },
            {
              "question": "Hij _____ met zijn pinpas.",
              "answers": ["betaalde"],
              "type": "fill"
            },
            {
              "question": "Zij _____ naar een nieuwe jas.",
              "answers": ["zocht"],
              "type": "fill"
            }
          ],
        ),
        38: Level(
          id: 38,
          description: "Gezondheid en Medisch Verleden",
          reward: 100,
          questions: [
            {
              "question": "Vorig jaar _____ ik een operatie.",
              "answers": ["had"],
              "type": "fill"
            },
            {
              "question": "Wij _____ medicijnen van de apotheek.",
              "answers": ["haalden"],
              "type": "fill"
            },
            {
              "question": "Voelde",
              "answers": ["Voelde", "Dronk", "Smaakte", "Werkte"],
              "type": "pick"
            },
            {
              "question": "Hij _____ zich erg ziek na het eten.",
              "answers": ["voelde"],
              "type": "fill"
            },
            {
              "question": "Zij _____ een allergie voor noten.",
              "answers": ["had"],
              "type": "fill"
            }
          ],
        ),
        39: Level(
          id: 39,
          description: "Liefde en Relaties in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Wij _____ elkaar op de universiteit.",
              "answers": ["ontmoetten"],
              "type": "fill"
            },
            {
              "question": "Zij _____ drie jaar voordat ze trouwden.",
              "answers": ["verkeerden"],
              "type": "fill"
            },
            {
              "question": "Gaf",
              "answers": ["Gaf", "Nam", "Kocht", "Spreidde"],
              "type": "pick"
            },
            {
              "question": "Hij _____ haar een mooie ring.",
              "answers": ["gaf"],
              "type": "fill"
            },
            {
              "question": "Ze _____ samen een huis in Amsterdam.",
              "answers": ["kochten"],
              "type": "fill"
            }
          ],
        ),
        40: Level(
          id: 40,
          description: "Ongelukken en Pech in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Gisteren _____ hij met de fiets.",
              "answers": ["viel"],
              "type": "fill"
            },
            {
              "question": "Wij _____ in de file op de snelweg.",
              "answers": ["stonden"],
              "type": "fill"
            },
            {
              "question": "Verloor",
              "answers": ["Verloor", "Vond", "Dacht", "Keek"],
              "type": "pick"
            },
            {
              "question": "Hij _____ zijn sleutels op straat.",
              "answers": ["verloor"],
              "type": "fill"
            },
            {
              "question": "Zij _____ haar mobiel in de trein.",
              "answers": ["vergat"],
              "type": "fill"
            }
          ],
        ),
        41: Level(
          id: 41,
          description: "Verleden Tijd met Oorzaken en Gevolgen",
          reward: 100,
          questions: [
            {
              "question": "Omdat het regende, _____ wij niet naar buiten.",
              "answers": ["gingen"],
              "type": "fill"
            },
            {
              "question": "Hij was te laat omdat hij zijn wekker niet _____.",
              "answers": ["hoorde"],
              "type": "fill"
            },
            {
              "question": "Vergeten",
              "answers": ["Vergeten", "Verloren", "Gevallen", "Gestopt"],
              "type": "pick"
            },
            {
              "question": "Zij _____ haar paraplu, dus ze werd nat.",
              "answers": ["vergat"],
              "type": "fill"
            },
            {
              "question": "Omdat hij ziek was, _____ hij niet naar zijn werk.",
              "answers": ["ging"],
              "type": "fill"
            }
          ],
        ),
        42: Level(
          id: 42,
          description: "Plusquamperfectum in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Toen ik aankwam, _____ zij al gegeten.",
              "answers": ["hadden"],
              "type": "fill"
            },
            {
              "question":
                  "Wij konden de film niet zien omdat we de tickets niet _____.",
              "answers": ["hadden gekocht"],
              "type": "fill"
            },
            {
              "question": "Gebeld",
              "answers": ["Gebeld", "Gezegd", "Gegeven", "Gemaakt"],
              "type": "pick"
            },
            {
              "question": "Hij _____ me al eerder gebeld, maar ik nam niet op.",
              "answers": ["had"],
              "type": "fill"
            },
            {
              "question":
                  "Voordat ze trouwden, _____ ze tien jaar samen gewoond.",
              "answers": ["hadden"],
              "type": "fill"
            }
          ],
        ),
        43: Level(
          id: 43,
          description: "Voorwaardelijke Zinnen in het Verleden",
          reward: 100,
          questions: [
            {
              "question":
                  "Als ik harder had gestudeerd, _____ ik het examen gehaald.",
              "answers": ["zou hebben"],
              "type": "fill"
            },
            {
              "question":
                  "Als we op tijd waren vertrokken, _____ we de trein niet gemist.",
              "answers": ["hadden"],
              "type": "fill"
            },
            {
              "question": "Hadden",
              "answers": ["Hadden", "Zouden", "Deden", "Waren"],
              "type": "pick"
            },
            {
              "question": "Als zij meer had geoefend, _____ ze beter gespeeld.",
              "answers": ["zou hebben"],
              "type": "fill"
            },
            {
              "question": "Als jij me had gebeld, _____ ik je geholpen.",
              "answers": ["zou hebben"],
              "type": "fill"
            }
          ],
        ),
        44: Level(
          id: 44,
          description: "Indirecte Rede in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Hij zei dat hij gisteren te laat _____.",
              "answers": ["was gekomen"],
              "type": "fill"
            },
            {
              "question": "Zij vertelde dat ze haar sleutels _____.",
              "answers": ["was verloren"],
              "type": "fill"
            },
            {
              "question": "Gezegd",
              "answers": ["Gezegd", "Gesproken", "Verteld", "Geantwoord"],
              "type": "pick"
            },
            {
              "question": "Mijn moeder zei dat ze al boodschappen _____.",
              "answers": ["had gedaan"],
              "type": "fill"
            },
            {
              "question":
                  "De leraar vertelde dat we de toets vorige week _____.",
              "answers": ["hadden gemaakt"],
              "type": "fill"
            }
          ],
        ),
        45: Level(
          id: 45,
          description: "Hypothetische Situaties in het Verleden",
          reward: 100,
          questions: [
            {
              "question":
                  "Als ik meer tijd had gehad, _____ ik het rapport afgemaakt.",
              "answers": ["zou hebben"],
              "type": "fill"
            },
            {
              "question":
                  "Als zij de kans had gehad, _____ ze in het buitenland gestudeerd.",
              "answers": ["zou hebben"],
              "type": "fill"
            },
            {
              "question": "Had",
              "answers": ["Had", "Zou", "Wilde", "Kon"],
              "type": "pick"
            },
            {
              "question":
                  "Als jij beter had opgelet, _____ je het antwoord geweten.",
              "answers": ["zou hebben"],
              "type": "fill"
            },
            {
              "question": "Wij zouden gekomen zijn als we het eerder _____.",
              "answers": ["hadden geweten"],
              "type": "fill"
            }
          ],
        ),
        46: Level(
          id: 46,
          description: "Emoties en Reacties in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Ik was erg blij toen ik het goede nieuws _____.",
              "answers": ["hoorde"],
              "type": "fill"
            },
            {
              "question": "Hij was verbaasd omdat hij het niet _____ verwacht.",
              "answers": ["had"],
              "type": "fill"
            },
            {
              "question": "Voelde",
              "answers": ["Voelde", "Dacht", "Wist", "Verbaasde"],
              "type": "pick"
            },
            {
              "question": "Zij _____ erg teleurgesteld na het slechte nieuws.",
              "answers": ["voelde zich"],
              "type": "fill"
            },
            {
              "question": "Wij _____ opgelucht toen alles goed ging.",
              "answers": ["waren"],
              "type": "fill"
            }
          ],
        ),
        47: Level(
          id: 47,
          description: "Verrassingen en Onverwachte Gebeurtenissen",
          reward: 100,
          questions: [
            {
              "question": "Opeens _____ de lichten uit.",
              "answers": ["gingen"],
              "type": "fill"
            },
            {
              "question":
                  "Toen we op vakantie waren, _____ we een beroemdheid.",
              "answers": ["zagen"],
              "type": "fill"
            },
            {
              "question": "Gebeurde",
              "answers": ["Gebeurde", "Werd", "Kreeg", "Ging"],
              "type": "pick"
            },
            {
              "question": "Hij _____ zijn oude vriend onverwachts in de stad.",
              "answers": ["ontmoette"],
              "type": "fill"
            },
            {
              "question": "Ik _____ geschrokken toen ik het hoorde.",
              "answers": ["was"],
              "type": "fill"
            }
          ],
        ),
        48: Level(
          id: 48,
          description: "Misverstanden en Vergissingen",
          reward: 100,
          questions: [
            {
              "question":
                  "Ik dacht dat de les om 10 uur begon, maar ik _____ me.",
              "answers": ["vergiste"],
              "type": "fill"
            },
            {
              "question":
                  "Wij _____ de verkeerde bus en kwamen op een andere plek aan.",
              "answers": ["namen"],
              "type": "fill"
            },
            {
              "question": "Verkeerd",
              "answers": ["Verkeerd", "Juist", "Duidelijk", "Goed"],
              "type": "pick"
            },
            {
              "question":
                  "Hij _____ zijn sleutelbos thuis en kon niet naar binnen.",
              "answers": ["vergat"],
              "type": "fill"
            },
            {
              "question": "Ze _____ zich in de datum van de afspraak.",
              "answers": ["vergiste"],
              "type": "fill"
            }
          ],
        ),
        49: Level(
          id: 49,
          description: "Redeneringen en Gedachten in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Ik dacht dat het museum op zondag _____.",
              "answers": ["open was"],
              "type": "fill"
            },
            {
              "question": "Zij _____ dat ze het goed had gedaan op de toets.",
              "answers": ["vermoedde"],
              "type": "fill"
            },
            {
              "question": "Meende",
              "answers": ["Meende", "Wist", "Hield", "Vergeet"],
              "type": "pick"
            },
            {
              "question": "Hij _____ dat het beter was om te wachten.",
              "answers": ["besloot"],
              "type": "fill"
            },
            {
              "question": "Wij _____ dat hij al vertrokken was.",
              "answers": ["dachten"],
              "type": "fill"
            }
          ],
        ),
        50: Level(
          id: 50,
          description: "Reflectie en Ervaringen in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Terugkijkend _____ ik alles anders gedaan.",
              "answers": ["zou hebben"],
              "type": "fill"
            },
            {
              "question": "Wij _____ nooit zoiets spannends meegemaakt.",
              "answers": ["hadden"],
              "type": "fill"
            },
            {
              "question": "Ervaren",
              "answers": ["Ervaren", "Vergeten", "Weten", "Leren"],
              "type": "pick"
            },
            {
              "question": "Hij _____ zich de details niet meer.",
              "answers": ["herinnerde"],
              "type": "fill"
            },
            {
              "question": "Zij _____ dat dit een van de mooiste dagen was.",
              "answers": ["besefte"],
              "type": "fill"
            }
          ],
        ),
        51: Level(
          id: 51,
          description: "Gesprekken en Communicatie in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Gisteren _____ ik met mijn moeder over de vakantie.",
              "answers": ["sprak"],
              "type": "fill"
            },
            {
              "question": "Wij _____ met de buren over het feest.",
              "answers": ["praatten"],
              "type": "fill"
            },
            {
              "question": "Zei",
              "answers": ["Zei", "Vroeg", "Gaf", "Vertelde"],
              "type": "pick"
            },
            {
              "question": "Hij _____ me dat hij morgen zou komen.",
              "answers": ["zei"],
              "type": "fill"
            },
            {
              "question":
                  "Tegen het einde van de vergadering _____ iedereen hun mening.",
              "answers": ["gaf"],
              "type": "fill"
            }
          ],
        ),
        52: Level(
          id: 52,
          description: "Verklaringen en Uitleg in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "De leraar _____ de grammatica in detail.",
              "answers": ["legde uit"],
              "type": "fill"
            },
            {
              "question": "Wij _____ waarom we te laat waren.",
              "answers": ["verklaarden"],
              "type": "fill"
            },
            {
              "question": "Legde uit",
              "answers": ["Legde uit", "Vroeg", "Besloot", "Dacht"],
              "type": "pick"
            },
            {
              "question": "Hij _____ het probleem zodat iedereen het begreep.",
              "answers": ["verklaarde"],
              "type": "fill"
            },
            {
              "question": "De politie _____ hoe het ongeluk gebeurde.",
              "answers": ["beschreef"],
              "type": "fill"
            }
          ],
        ),
        53: Level(
          id: 53,
          description: "Telefoneren en Berichten in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Gisteren _____ ik met mijn vriend in Duitsland.",
              "answers": ["belde"],
              "type": "fill"
            },
            {
              "question": "Wij _____ een bericht naar de klantenservice.",
              "answers": ["stuurden"],
              "type": "fill"
            },
            {
              "question": "Schreef",
              "answers": ["Schreef", "Verstuurde", "Las", "Sprak"],
              "type": "pick"
            },
            {
              "question": "Hij _____ een lange e-mail over zijn klacht.",
              "answers": ["schreef"],
              "type": "fill"
            },
            {
              "question": "Zij _____ haar moeder om te vragen hoe het ging.",
              "answers": ["belde"],
              "type": "fill"
            }
          ],
        ),
        54: Level(
          id: 54,
          description: "Vragen en Antwoorden in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Hij _____ of ik morgen kon komen.",
              "answers": ["vroeg"],
              "type": "fill"
            },
            {
              "question": "Wij _____ de gids veel vragen over de stad.",
              "answers": ["stelden"],
              "type": "fill"
            },
            {
              "question": "Antwoordde",
              "answers": ["Antwoordde", "Vroeg", "Schreef", "Hoorde"],
              "type": "pick"
            },
            {
              "question": "Zij _____ heel duidelijk op alle vragen.",
              "answers": ["antwoordde"],
              "type": "fill"
            },
            {
              "question": "Hij _____ mij waarom ik te laat was.",
              "answers": ["vroeg"],
              "type": "fill"
            }
          ],
        ),
        55: Level(
          id: 55,
          description: "Misverstanden en Fouten in het Verleden",
          reward: 100,
          questions: [
            {
              "question":
                  "Ik _____ de instructies verkeerd en maakte een fout.",
              "answers": ["begreep"],
              "type": "fill"
            },
            {
              "question":
                  "Wij _____ het verkeerd en dachten dat het om 10 uur begon.",
              "answers": ["dachten"],
              "type": "fill"
            },
            {
              "question": "Vergiste",
              "answers": ["Vergiste", "Vergeet", "Dacht", "Weet"],
              "type": "pick"
            },
            {
              "question": "Hij _____ zich in de datum van de afspraak.",
              "answers": ["vergiste"],
              "type": "fill"
            },
            {
              "question":
                  "Zij _____ dat hij het al wist, maar dat was niet zo.",
              "answers": ["vermoedde"],
              "type": "fill"
            }
          ],
        ),
        56: Level(
          id: 56,
          description: "Boeken en Lezen in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Gisteren _____ ik een interessant boek.",
              "answers": ["las"],
              "type": "fill"
            },
            {
              "question": "Wij _____ een tijdschrift terwijl we wachtten.",
              "answers": ["lazen"],
              "type": "fill"
            },
            {
              "question": "Leerde",
              "answers": ["Leerde", "Las", "Schreef", "Sprak"],
              "type": "pick"
            },
            {
              "question": "Hij _____ een artikel over geschiedenis.",
              "answers": ["las"],
              "type": "fill"
            },
            {
              "question":
                  "Zij _____ een nieuw boek van haar favoriete schrijver.",
              "answers": ["kocht"],
              "type": "fill"
            }
          ],
        ),
        57: Level(
          id: 57,
          description: "Talen Leren en Spreken in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Vroeger _____ ik vaak Frans met mijn leraar.",
              "answers": ["sprak"],
              "type": "fill"
            },
            {
              "question":
                  "Wij _____ Nederlands toen we naar Nederland verhuisden.",
              "answers": ["leerden"],
              "type": "fill"
            },
            {
              "question": "Oefende",
              "answers": ["Oefende", "Luisterde", "Zei", "Schreef"],
              "type": "pick"
            },
            {
              "question": "Hij _____ elke dag zijn uitspraak.",
              "answers": ["oefende"],
              "type": "fill"
            },
            {
              "question": "Zij _____ veel nieuwe woorden in haar taalcursus.",
              "answers": ["onthield"],
              "type": "fill"
            }
          ],
        ),
        58: Level(
          id: 58,
          description: "Discussies en Debatten in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Gisteren _____ wij over politiek in de les.",
              "answers": ["discussieerden"],
              "type": "fill"
            },
            {
              "question": "Hij _____ waarom hij het daar niet mee eens was.",
              "answers": ["legde uit"],
              "type": "fill"
            },
            {
              "question": "Betwistte",
              "answers": ["Betwistte", "Accepteerde", "Geloofde", "Begreep"],
              "type": "pick"
            },
            {
              "question": "Zij _____ de mening van haar collega.",
              "answers": ["betwistte"],
              "type": "fill"
            },
            {
              "question": "Wij _____ over wie gelijk had.",
              "answers": ["ruzie maakten"],
              "type": "fill"
            }
          ],
        ),
        59: Level(
          id: 59,
          description: "Verhalen en Herinneringen in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Mijn opa _____ vroeger verhalen over zijn jeugd.",
              "answers": ["vertelde"],
              "type": "fill"
            },
            {
              "question": "Wij _____ over onze vakantie in Italië.",
              "answers": ["herinnerden ons"],
              "type": "fill"
            },
            {
              "question": "Droomde",
              "answers": ["Droomde", "Sprak", "Las", "Schreef"],
              "type": "pick"
            },
            {
              "question": "Hij _____ over een spannend avontuur.",
              "answers": ["droomde"],
              "type": "fill"
            },
            {
              "question": "Zij _____ haar eerste schooldag nog goed.",
              "answers": ["herinnerde zich"],
              "type": "fill"
            }
          ],
        ),
        60: Level(
          id: 60,
          description: "Uitdrukkingen en Gezegden in het Verleden",
          reward: 100,
          questions: [
            {
              "question":
                  "Mijn oma _____ altijd: 'Haastige spoed is zelden goed.'",
              "answers": ["zei"],
              "type": "fill"
            },
            {
              "question": "Wij _____ een bekend gezegde over geduld.",
              "answers": ["gebruikten"],
              "type": "fill"
            },
            {
              "question": "Verklaarde",
              "answers": ["Verklaarde", "Begreep", "Voelde", "Kocht"],
              "type": "pick"
            },
            {
              "question": "Hij _____ waarom het gezegde zo belangrijk was.",
              "answers": ["verklaarde"],
              "type": "fill"
            },
            {
              "question":
                  "Zij _____ dat dit spreekwoord goed bij de situatie paste.",
              "answers": ["begreep"],
              "type": "fill"
            }
          ],
        ),
        61: Level(
          id: 61,
          description: "Gesprekken en Vergissingen in het Verleden",
          reward: 100,
          questions: [
            {
              "question":
                  "Gisteren _____ ik mijn collega per ongeluk met een verkeerde naam.",
              "answers": ["noemde"],
              "type": "fill"
            },
            {
              "question":
                  "Wij _____ dat de afspraak om 15:00 was, maar het was om 14:00.",
              "answers": ["dachten"],
              "type": "fill"
            },
            {
              "question": "Vergiste",
              "answers": ["Vergiste", "Herinnerde", "Vroeg", "Antwoordde"],
              "type": "pick"
            },
            {
              "question":
                  "Hij _____ zich in het adres en kwam op de verkeerde plek.",
              "answers": ["vergiste"],
              "type": "fill"
            },
            {
              "question":
                  "Zij _____ niet dat de winkel op zondag gesloten was.",
              "answers": ["wist"],
              "type": "fill"
            }
          ],
        ),
        62: Level(
          id: 62,
          description: "Verwarring en Misverstanden in het Verleden",
          reward: 100,
          questions: [
            {
              "question":
                  "Ik _____ zijn bericht verkeerd en dacht dat hij morgen kwam.",
              "answers": ["begreep"],
              "type": "fill"
            },
            {
              "question":
                  "Wij _____ de instructies niet goed, dus we maakten fouten.",
              "answers": ["volgden"],
              "type": "fill"
            },
            {
              "question": "Dacht",
              "answers": ["Dacht", "Schreef", "Sprak", "Las"],
              "type": "pick"
            },
            {
              "question": "Hij _____ dat de vergadering een uur later begon.",
              "answers": ["dacht"],
              "type": "fill"
            },
            {
              "question":
                  "Zij _____ dat hij boos was, maar hij was gewoon moe.",
              "answers": ["veronderstelde"],
              "type": "fill"
            }
          ],
        ),
        63: Level(
          id: 63,
          description: "Discussies en Meningen in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Wij _____ een discussie over politiek.",
              "answers": ["hadden"],
              "type": "fill"
            },
            {
              "question": "Hij _____ dat zijn idee het beste was.",
              "answers": ["vond"],
              "type": "fill"
            },
            {
              "question": "Betwistte",
              "answers": ["Betwistte", "Accepteerde", "Geloofde", "Hoorde"],
              "type": "pick"
            },
            {
              "question": "Zij _____ het standpunt van haar collega.",
              "answers": ["betwistte"],
              "type": "fill"
            },
            {
              "question":
                  "Hij _____ haar mening, maar was het er niet mee eens.",
              "answers": ["respekteerde"],
              "type": "fill"
            }
          ],
        ),
        64: Level(
          id: 64,
          description: "Gebeurtenissen en Reacties in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Toen hij het nieuws hoorde, _____ hij geschrokken.",
              "answers": ["was"],
              "type": "fill"
            },
            {
              "question": "Wij _____ verbaasd over de plotselinge verandering.",
              "answers": ["waren"],
              "type": "fill"
            },
            {
              "question": "Reageerde",
              "answers": ["Reageerde", "Dacht", "Voelde", "Schreef"],
              "type": "pick"
            },
            {
              "question": "Hij _____ kalm ondanks het slechte nieuws.",
              "answers": ["bleef"],
              "type": "fill"
            },
            {
              "question": "Zij _____ erg enthousiast toen ze de prijs won.",
              "answers": ["was"],
              "type": "fill"
            }
          ],
        ),
        65: Level(
          id: 65,
          description: "Reizen en Ervaringen in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Vorige zomer _____ we naar Frankrijk.",
              "answers": ["gingen"],
              "type": "fill"
            },
            {
              "question": "Wij _____ in een klein dorp aan de kust.",
              "answers": ["bleven"],
              "type": "fill"
            },
            {
              "question": "Ontdekte",
              "answers": ["Ontdekte", "Reisde", "Vertrok", "Wandelde"],
              "type": "pick"
            },
            {
              "question": "Hij _____ een prachtige plek tijdens zijn reis.",
              "answers": ["ontdekte"],
              "type": "fill"
            },
            {
              "question": "Zij _____ een nieuwe cultuur en tradities.",
              "answers": ["leerde kennen"],
              "type": "fill"
            }
          ],
        ),
        66: Level(
          id: 66,
          description: "Talen en Communicatie in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Op school _____ we Frans en Duits.",
              "answers": ["leerden"],
              "type": "fill"
            },
            {
              "question": "Hij _____ een presentatie in het Engels.",
              "answers": ["gaf"],
              "type": "fill"
            },
            {
              "question": "Vertaalde",
              "answers": ["Vertaalde", "Besprak", "Las", "Schreef"],
              "type": "pick"
            },
            {
              "question": "Zij _____ een moeilijke tekst naar het Nederlands.",
              "answers": ["vertaalde"],
              "type": "fill"
            },
            {
              "question": "Wij _____ in verschillende talen tijdens onze reis.",
              "answers": ["communiceerden"],
              "type": "fill"
            }
          ],
        ),
        67: Level(
          id: 67,
          description: "Verleden Tijd en Toekomstverwachtingen",
          reward: 100,
          questions: [
            {
              "question": "Hij _____ dat hij volgend jaar zou verhuizen.",
              "answers": ["verwachtte"],
              "type": "fill"
            },
            {
              "question": "Wij _____ dat de situatie beter zou worden.",
              "answers": ["hoopten"],
              "type": "fill"
            },
            {
              "question": "Dacht",
              "answers": ["Dacht", "Voelde", "Las", "Hield"],
              "type": "pick"
            },
            {
              "question": "Zij _____ dat het weer goed zou blijven.",
              "answers": ["verwachtte"],
              "type": "fill"
            },
            {
              "question": "Hij _____ dat hij zou slagen voor zijn examen.",
              "answers": ["hoopte"],
              "type": "fill"
            }
          ],
        ),
        68: Level(
          id: 68,
          description: "Emoties en Ervaringen in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Ik _____ me erg gelukkig op mijn trouwdag.",
              "answers": ["voelde"],
              "type": "fill"
            },
            {
              "question": "Wij _____ heel veel plezier tijdens onze vakantie.",
              "answers": ["hadden"],
              "type": "fill"
            },
            {
              "question": "Genoot",
              "answers": ["Genoot", "Leefde", "Werkte", "Hield"],
              "type": "pick"
            },
            {
              "question": "Hij _____ echt van het concert.",
              "answers": ["genoot"],
              "type": "fill"
            },
            {
              "question": "Zij _____ zich verdrietig na het afscheid.",
              "answers": ["voelde"],
              "type": "fill"
            }
          ],
        ),
        69: Level(
          id: 69,
          description: "Problemen en Oplossingen in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Wij _____ een probleem met de software.",
              "answers": ["hadden"],
              "type": "fill"
            },
            {
              "question": "Hij _____ een manier om het probleem op te lossen.",
              "answers": ["vond"],
              "type": "fill"
            },
            {
              "question": "Oploste",
              "answers": ["Oploste", "Gaf", "Zei", "Dacht"],
              "type": "pick"
            },
            {
              "question": "Zij _____ het probleem in een paar minuten op.",
              "answers": ["oplosde"],
              "type": "fill"
            },
            {
              "question": "Hij _____ een slimme oplossing voor de situatie.",
              "answers": ["bedacht"],
              "type": "fill"
            }
          ],
        ),
        70: Level(
          id: 70,
          description: "Lessen en Inzichten uit het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Ik _____ veel van die ervaring.",
              "answers": ["leerde"],
              "type": "fill"
            },
            {
              "question": "Wij _____ een belangrijke les over geduld.",
              "answers": ["leerden"],
              "type": "fill"
            },
            {
              "question": "Besefte",
              "answers": ["Besefte", "Dacht", "Begreep", "Vond"],
              "type": "pick"
            },
            {
              "question": "Hij _____ hoe belangrijk discipline was.",
              "answers": ["besefte"],
              "type": "fill"
            },
            {
              "question": "Zij _____ zich dat ze een fout had gemaakt.",
              "answers": ["begreep"],
              "type": "fill"
            }
          ],
        ),
        71: Level(
          id: 71,
          description: "Herinneringen aan het Verleden",
          reward: 100,
          questions: [
            {
              "question":
                  "Toen ik een kind was, _____ ik altijd buiten te spelen.",
              "answers": ["hield"],
              "type": "fill"
            },
            {
              "question": "Wij _____ vroeger elke zomer naar de zee.",
              "answers": ["gingen"],
              "type": "fill"
            },
            {
              "question": "Speelde",
              "answers": ["Speelde", "Dacht", "Werkte", "Leerde"],
              "type": "pick"
            },
            {
              "question": "Hij _____ als kind altijd met lego.",
              "answers": ["speelde"],
              "type": "fill"
            },
            {
              "question": "Zij _____ zich de vakanties met haar familie.",
              "answers": ["herinnerde"],
              "type": "fill"
            }
          ],
        ),
        72: Level(
          id: 72,
          description: "Reflexie en Lessen uit het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Achteraf gezien _____ ik de verkeerde beslissing.",
              "answers": ["nam"],
              "type": "fill"
            },
            {
              "question": "Wij _____ dat we meer geduld moesten hebben.",
              "answers": ["beseften"],
              "type": "fill"
            },
            {
              "question": "Leerde",
              "answers": ["Leerde", "Besefte", "Begreep", "Onthield"],
              "type": "pick"
            },
            {
              "question": "Hij _____ veel van zijn fouten in het verleden.",
              "answers": ["leerde"],
              "type": "fill"
            },
            {
              "question": "Zij _____ dat ze dingen anders had moeten doen.",
              "answers": ["begreep"],
              "type": "fill"
            }
          ],
        ),
        73: Level(
          id: 73,
          description: "Onverwachte Gebeurtenissen in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Gisteren _____ er een stroomstoring in onze straat.",
              "answers": ["was"],
              "type": "fill"
            },
            {
              "question":
                  "Wij _____ per ongeluk een beroemde acteur in het restaurant.",
              "answers": ["ontmoetten"],
              "type": "fill"
            },
            {
              "question": "Gebeurde",
              "answers": ["Gebeurde", "Leerde", "Dacht", "Zei"],
              "type": "pick"
            },
            {
              "question": "Hij _____ plotseling op een oude vriend in de stad.",
              "answers": ["botste"],
              "type": "fill"
            },
            {
              "question":
                  "Toen ik de deur opendeed, _____ ik een pakket dat ik niet had besteld.",
              "answers": ["vond"],
              "type": "fill"
            }
          ],
        ),
        74: Level(
          id: 74,
          description: "Hypothetische Situaties in het Verleden",
          reward: 100,
          questions: [
            {
              "question":
                  "Als ik meer tijd had gehad, _____ ik langer gebleven.",
              "answers": ["zou hebben"],
              "type": "fill"
            },
            {
              "question":
                  "Wij _____ een auto gehuurd als we het geweten hadden.",
              "answers": ["zouden hebben"],
              "type": "fill"
            },
            {
              "question": "Had",
              "answers": ["Had", "Zou", "Wilde", "Moest"],
              "type": "pick"
            },
            {
              "question":
                  "Hij _____ de trein genomen als hij op tijd was opgestaan.",
              "answers": ["zou hebben"],
              "type": "fill"
            },
            {
              "question":
                  "Als zij had geweten dat het regende, _____ ze een paraplu meegenomen.",
              "answers": ["zou hebben"],
              "type": "fill"
            }
          ],
        ),
        75: Level(
          id: 75,
          description: "Uitdagingen en Overwinningen in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Hij _____ veel moeite om de cursus af te maken.",
              "answers": ["deed"],
              "type": "fill"
            },
            {
              "question": "Wij _____ trots op onze prestatie.",
              "answers": ["waren"],
              "type": "fill"
            },
            {
              "question": "Overwon",
              "answers": ["Overwon", "Leerde", "Dacht", "Sprak"],
              "type": "pick"
            },
            {
              "question": "Hij _____ zijn angst voor spreken in het openbaar.",
              "answers": ["overwon"],
              "type": "fill"
            },
            {
              "question": "Zij _____ eindelijk haar rijbewijs na veel oefenen.",
              "answers": ["haalde"],
              "type": "fill"
            }
          ],
        ),
        76: Level(
          id: 76,
          description: "Misverstanden en Communicatieproblemen",
          reward: 100,
          questions: [
            {
              "question": "Wij _____ de afspraak verkeerd en kwamen te laat.",
              "answers": ["begrepen"],
              "type": "fill"
            },
            {
              "question": "Hij _____ een grapje, maar zij nam het serieus.",
              "answers": ["maakte"],
              "type": "fill"
            },
            {
              "question": "Vergiste",
              "answers": ["Vergiste", "Dacht", "Las", "Vertelde"],
              "type": "pick"
            },
            {
              "question": "Zij _____ zich in de naam van de persoon.",
              "answers": ["vergiste"],
              "type": "fill"
            },
            {
              "question": "Toen hij haar bericht las, _____ hij het verkeerd.",
              "answers": ["interpreteerde"],
              "type": "fill"
            }
          ],
        ),
        77: Level(
          id: 77,
          description: "Beroemde Momenten en Geschiedenis",
          reward: 100,
          questions: [
            {
              "question": "De eerste mens _____ op de maan in 1969.",
              "answers": ["landde"],
              "type": "fill"
            },
            {
              "question":
                  "Wij _____ over belangrijke historische gebeurtenissen op school.",
              "answers": ["leerden"],
              "type": "fill"
            },
            {
              "question": "Ontdekte",
              "answers": ["Ontdekte", "Dacht", "Besloot", "Bouwde"],
              "type": "pick"
            },
            {
              "question": "Columbus _____ Amerika in 1492.",
              "answers": ["ontdekte"],
              "type": "fill"
            },
            {
              "question":
                  "Zij _____ over de Tweede Wereldoorlog in de geschiedenisles.",
              "answers": ["leerde"],
              "type": "fill"
            }
          ],
        ),
        78: Level(
          id: 78,
          description: "Dromen en Aspiraties uit het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Als kind _____ ik altijd astronaut te worden.",
              "answers": ["wilde"],
              "type": "fill"
            },
            {
              "question": "Wij _____ ervan om de wereld rond te reizen.",
              "answers": ["droomden"],
              "type": "fill"
            },
            {
              "question": "Hoopte",
              "answers": ["Hoopte", "Sprak", "Werkte", "Luisterde"],
              "type": "pick"
            },
            {
              "question": "Hij _____ ooit een eigen bedrijf te starten.",
              "answers": ["hoopte"],
              "type": "fill"
            },
            {
              "question": "Zij _____ altijd om actrice te worden.",
              "answers": ["droomde"],
              "type": "fill"
            }
          ],
        ),
        79: Level(
          id: 79,
          description: "Verrassingen en Cadeaus in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Op mijn verjaardag _____ ik een mooie fiets.",
              "answers": ["kreeg"],
              "type": "fill"
            },
            {
              "question": "Wij _____ onze ouders een speciaal cadeau.",
              "answers": ["gaven"],
              "type": "fill"
            },
            {
              "question": "Vond",
              "answers": ["Vond", "Kocht", "Dacht", "Liep"],
              "type": "pick"
            },
            {
              "question": "Hij _____ een oude foto in een boek.",
              "answers": ["vond"],
              "type": "fill"
            },
            {
              "question": "Zij _____ verrast toen ze het cadeau opende.",
              "answers": ["was"],
              "type": "fill"
            }
          ],
        ),
        80: Level(
          id: 80,
          description: "Moeilijke Keuzes en Beslissingen",
          reward: 100,
          questions: [
            {
              "question": "Wij _____ lang over deze beslissing.",
              "answers": ["nadenken"],
              "type": "fill"
            },
            {
              "question": "Hij _____ uiteindelijk om van baan te veranderen.",
              "answers": ["besloot"],
              "type": "fill"
            },
            {
              "question": "Koos",
              "answers": ["Koos", "Dacht", "Las", "Begreep"],
              "type": "pick"
            },
            {
              "question": "Zij _____ een moeilijke keuze tussen twee opties.",
              "answers": ["maakte"],
              "type": "fill"
            },
            {
              "question": "Ik _____ niet wat de beste optie was.",
              "answers": ["wist"],
              "type": "fill"
            }
          ],
        ),
        81: Level(
          id: 81,
          description: "Onwaarschijnlijke Scenario’s in het Verleden",
          reward: 100,
          questions: [
            {
              "question":
                  "Als ik harder had gewerkt, _____ ik promotie gekregen.",
              "answers": ["zou hebben"],
              "type": "fill"
            },
            {
              "question":
                  "Wij _____ de trein gehaald als we vijf minuten eerder waren vertrokken.",
              "answers": ["zouden hebben"],
              "type": "fill"
            },
            {
              "question": "Had",
              "answers": ["Had", "Zou", "Moest", "Wist"],
              "type": "pick"
            },
            {
              "question":
                  "Als hij beter had opgelet, _____ hij het ongeluk vermeden.",
              "answers": ["zou hebben"],
              "type": "fill"
            },
            {
              "question":
                  "Als het weer beter was geweest, _____ we buiten geluncht.",
              "answers": ["hadden"],
              "type": "fill"
            }
          ],
        ),
        82: Level(
          id: 82,
          description: "Complexe Gedachten en Twijfels in het Verleden",
          reward: 100,
          questions: [
            {
              "question":
                  "Ik _____ niet zeker of ik de juiste beslissing had genomen.",
              "answers": ["was"],
              "type": "fill"
            },
            {
              "question": "Wij _____ of we de juiste weg hadden gekozen.",
              "answers": ["twijfelden"],
              "type": "fill"
            },
            {
              "question": "Begreep",
              "answers": ["Begreep", "Verwachtte", "Hoopte", "Vroeg"],
              "type": "pick"
            },
            {
              "question":
                  "Hij _____ dat er iets niet klopte, maar wist niet wat.",
              "answers": ["begreep"],
              "type": "fill"
            },
            {
              "question": "Zij _____ dat ze misschien een fout had gemaakt.",
              "answers": ["besefte"],
              "type": "fill"
            }
          ],
        ),
        83: Level(
          id: 83,
          description: "Verkeerde Conclusies en Misvattingen",
          reward: 100,
          questions: [
            {
              "question": "Ik _____ dat hij boos was, maar hij was gewoon moe.",
              "answers": ["dacht"],
              "type": "fill"
            },
            {
              "question":
                  "Wij _____ dat het museum open zou zijn, maar het was gesloten.",
              "answers": ["veronderstelden"],
              "type": "fill"
            },
            {
              "question": "Verkeek",
              "answers": ["Verkeek", "Geloofde", "Las", "Sprak"],
              "type": "pick"
            },
            {
              "question": "Hij _____ zich in de tijd en kwam een uur te laat.",
              "answers": ["verkeek"],
              "type": "fill"
            },
            {
              "question":
                  "Zij _____ ten onrechte dat haar collega de taak had gedaan.",
              "answers": ["vermoedde"],
              "type": "fill"
            }
          ],
        ),
        84: Level(
          id: 84,
          description: "Verlies en Spijt in het Verleden",
          reward: 100,
          questions: [
            {
              "question":
                  "Ik _____ mijn telefoon op de trein en kon hem niet terugvinden.",
              "answers": ["verloor"],
              "type": "fill"
            },
            {
              "question": "Wij _____ het document voordat we het opsloegen.",
              "answers": ["verwijderden"],
              "type": "fill"
            },
            {
              "question": "Begreep",
              "answers": ["Begreep", "Vergat", "Dacht", "Keek"],
              "type": "pick"
            },
            {
              "question":
                  "Hij _____ niet hoe belangrijk dit was totdat het te laat was.",
              "answers": ["begreep"],
              "type": "fill"
            },
            {
              "question": "Zij _____ dat ze een betere keuze had moeten maken.",
              "answers": ["beseft"],
              "type": "fill"
            }
          ],
        ),
        85: Level(
          id: 85,
          description: "Verleden Tijd en Oorzaak-Gevolg Relaties",
          reward: 100,
          questions: [
            {
              "question": "Omdat we te laat vertrokken, _____ we de bus.",
              "answers": ["misten"],
              "type": "fill"
            },
            {
              "question":
                  "Hij _____ het examen niet omdat hij niet had geleerd.",
              "answers": ["haalde"],
              "type": "fill"
            },
            {
              "question": "Ging",
              "answers": ["Ging", "Keek", "Sprak", "Liep"],
              "type": "pick"
            },
            {
              "question": "Omdat hij ziek was, _____ hij niet naar school.",
              "answers": ["ging"],
              "type": "fill"
            },
            {
              "question": "Omdat zij haar paraplu vergat, _____ ze nat.",
              "answers": ["werd"],
              "type": "fill"
            }
          ],
        ),
        86: Level(
          id: 86,
          description: "Moeilijke Beslissingen en Gevolgen",
          reward: 100,
          questions: [
            {
              "question": "Hij _____ lang na over wat hij moest doen.",
              "answers": ["dacht"],
              "type": "fill"
            },
            {
              "question":
                  "Wij _____ uiteindelijk om de baan niet te accepteren.",
              "answers": ["besloten"],
              "type": "fill"
            },
            {
              "question": "Kies",
              "answers": ["Kies", "Verlies", "Bouw", "Wacht"],
              "type": "pick"
            },
            {
              "question":
                  "Hij _____ voor een moeilijke keuze tussen twee opties.",
              "answers": ["stond"],
              "type": "fill"
            },
            {
              "question":
                  "Zij _____ haar baan op om een nieuw bedrijf te starten.",
              "answers": ["gaf"],
              "type": "fill"
            }
          ],
        ),
        87: Level(
          id: 87,
          description: "Geheugen en Herinneringen in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Ik _____ me niet meer hoe hij heette.",
              "answers": ["herinnerde"],
              "type": "fill"
            },
            {
              "question": "Wij _____ ons oude huis nog goed.",
              "answers": ["onthielden"],
              "type": "fill"
            },
            {
              "question": "Vergeten",
              "answers": ["Vergeten", "Denk", "Schrijf", "Roep"],
              "type": "pick"
            },
            {
              "question": "Hij _____ zijn sleutels elke dag ergens anders.",
              "answers": ["vergat"],
              "type": "fill"
            },
            {
              "question": "Zij _____ nog steeds haar eerste schooldag.",
              "answers": ["herinnerde"],
              "type": "fill"
            }
          ],
        ),
        88: Level(
          id: 88,
          description: "Onzekerheden en Twijfels in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Ik _____ niet zeker of ik het goed had gedaan.",
              "answers": ["was"],
              "type": "fill"
            },
            {
              "question":
                  "Wij _____ of we wel de juiste beslissing hadden genomen.",
              "answers": ["twijfelden"],
              "type": "fill"
            },
            {
              "question": "Vertrouwde",
              "answers": ["Vertrouwde", "Begreep", "Dacht", "Leerde"],
              "type": "pick"
            },
            {
              "question": "Hij _____ niet of hij het juiste had gezegd.",
              "answers": ["wist"],
              "type": "fill"
            },
            {
              "question": "Zij _____ of de test echt eerlijk was.",
              "answers": ["twijfelde"],
              "type": "fill"
            }
          ],
        ),
        89: Level(
          id: 89,
          description: "Overwinning en Groei in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Hij _____ zijn angst voor spreken in het openbaar.",
              "answers": ["overwon"],
              "type": "fill"
            },
            {
              "question": "Wij _____ veel door onze fouten te maken.",
              "answers": ["leerden"],
              "type": "fill"
            },
            {
              "question": "Groeide",
              "answers": ["Groeide", "Bleef", "Werd", "Was"],
              "type": "pick"
            },
            {
              "question": "Hij _____ in zijn rol als leider.",
              "answers": ["groeide"],
              "type": "fill"
            },
            {
              "question": "Zij _____ sterker na de moeilijke periode.",
              "answers": ["werd"],
              "type": "fill"
            }
          ],
        ),
        90: Level(
          id: 90,
          description: "Fouten en Verbeteringen in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Hij _____ een fout in de berekening.",
              "answers": ["maakte"],
              "type": "fill"
            },
            {
              "question": "Wij _____ het probleem nadat we het hadden ontdekt.",
              "answers": ["corrigeerden"],
              "type": "fill"
            },
            {
              "question": "Herstelde",
              "answers": ["Herstelde", "Vergat", "Dacht", "Wist"],
              "type": "pick"
            },
            {
              "question": "Hij _____ de schade aan zijn fiets.",
              "answers": ["herstelde"],
              "type": "fill"
            },
            {
              "question": "Zij _____ haar uitspraak na feedback.",
              "answers": ["verbeterde"],
              "type": "fill"
            }
          ],
        ),
        91: Level(
          id: 91,
          description: "Onverwachte Situaties en Reacties",
          reward: 100,
          questions: [
            {
              "question":
                  "Hij _____ plotseling ziek en moest naar het ziekenhuis.",
              "answers": ["werd"],
              "type": "fill"
            },
            {
              "question": "Wij _____ geschrokken toen we het nieuws hoorden.",
              "answers": ["waren"],
              "type": "fill"
            },
            {
              "question": "Gebeurt",
              "answers": ["Gebeurt", "Dacht", "Leerde", "Begreep"],
              "type": "pick"
            },
            {
              "question": "Zij _____ haar telefoon toen ze haast had.",
              "answers": ["verloor"],
              "type": "fill"
            },
            {
              "question": "Toen hij binnenkwam, _____ iedereen stil.",
              "answers": ["viel"],
              "type": "fill"
            }
          ],
        ),
        92: Level(
          id: 92,
          description: "Logische Fouten en Misverstanden",
          reward: 100,
          questions: [
            {
              "question":
                  "Wij _____ dat we de afspraak om 10:00 hadden, maar het was om 9:00.",
              "answers": ["dachten"],
              "type": "fill"
            },
            {
              "question": "Hij _____ de verkeerde straat in en verdwaalde.",
              "answers": ["liep"],
              "type": "fill"
            },
            {
              "question": "Vergiste",
              "answers": ["Vergiste", "Vergeten", "Begrijpen", "Kocht"],
              "type": "pick"
            },
            {
              "question":
                  "Zij _____ zich in het adres en ging naar het verkeerde huis.",
              "answers": ["vergiste"],
              "type": "fill"
            },
            {
              "question": "Hij _____ een fout bij het rekenen.",
              "answers": ["maakte"],
              "type": "fill"
            }
          ],
        ),
        93: Level(
          id: 93,
          description: "Geheugen en Vergeten in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Ik _____ niet meer hoe de leraar heette.",
              "answers": ["herinnerde"],
              "type": "fill"
            },
            {
              "question": "Wij _____ ons niet meer de naam van dat restaurant.",
              "answers": ["wisten"],
              "type": "fill"
            },
            {
              "question": "Vergeten",
              "answers": ["Vergeten", "Vonden", "Leerden", "Benoemden"],
              "type": "pick"
            },
            {
              "question": "Hij _____ zijn sleutels elke dag ergens anders.",
              "answers": ["vergat"],
              "type": "fill"
            },
            {
              "question": "Zij _____ zich haar eerste schooldag nog goed.",
              "answers": ["herinnerde"],
              "type": "fill"
            }
          ],
        ),
        94: Level(
          id: 94,
          description: "Verrassingen en Emoties in het Verleden",
          reward: 100,
          questions: [
            {
              "question":
                  "Hij _____ heel blij toen hij het goede nieuws hoorde.",
              "answers": ["werd"],
              "type": "fill"
            },
            {
              "question": "Wij _____ niet dat hij al vertrokken was.",
              "answers": ["wisten"],
              "type": "fill"
            },
            {
              "question": "Voelde",
              "answers": ["Voelde", "Besloot", "Begreep", "Dacht"],
              "type": "pick"
            },
            {
              "question": "Zij _____ zich verdrietig na het afscheid.",
              "answers": ["voelde"],
              "type": "fill"
            },
            {
              "question": "Hij _____ verbaasd dat het zo snel was gegaan.",
              "answers": ["was"],
              "type": "fill"
            }
          ],
        ),
        95: Level(
          id: 95,
          description: "Hypothetische Situaties en Spijt",
          reward: 100,
          questions: [
            {
              "question":
                  "Als ik beter had opgelet, _____ ik de fout vermeden.",
              "answers": ["zou hebben"],
              "type": "fill"
            },
            {
              "question":
                  "Wij _____ een andere route genomen als we de files hadden geweten.",
              "answers": ["zouden hebben"],
              "type": "fill"
            },
            {
              "question": "Had",
              "answers": ["Had", "Zou", "Moest", "Wist"],
              "type": "pick"
            },
            {
              "question":
                  "Hij _____ het examen gehaald als hij harder had gestudeerd.",
              "answers": ["zou hebben"],
              "type": "fill"
            },
            {
              "question":
                  "Als het weer beter was geweest, _____ we buiten gegeten.",
              "answers": ["hadden"],
              "type": "fill"
            }
          ],
        ),
        96: Level(
          id: 96,
          description: "Discussies en Meningen uit het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Wij _____ dat onze oplossing de beste was.",
              "answers": ["dachten"],
              "type": "fill"
            },
            {
              "question": "Hij _____ dat zijn plan beter was dan het andere.",
              "answers": ["vond"],
              "type": "fill"
            },
            {
              "question": "Betwistte",
              "answers": ["Betwistte", "Accepteerde", "Geloofde", "Hoorde"],
              "type": "pick"
            },
            {
              "question": "Zij _____ het standpunt van haar collega.",
              "answers": ["betwistte"],
              "type": "fill"
            },
            {
              "question":
                  "Hij _____ dat hij gelijk had, maar niemand was het met hem eens.",
              "answers": ["meende"],
              "type": "fill"
            }
          ],
        ),
        97: Level(
          id: 97,
          description: "Onrealistische Verwachtingen in het Verleden",
          reward: 100,
          questions: [
            {
              "question":
                  "Hij _____ dat het examen makkelijk zou zijn, maar dat was het niet.",
              "answers": ["verwachtte"],
              "type": "fill"
            },
            {
              "question":
                  "Wij _____ dat de trein op tijd zou zijn, maar hij was vertraagd.",
              "answers": ["dachten"],
              "type": "fill"
            },
            {
              "question": "Hoopte",
              "answers": ["Hoopte", "Leerde", "Dacht", "Kocht"],
              "type": "pick"
            },
            {
              "question":
                  "Hij _____ dat het eten lekker zou zijn, maar het viel tegen.",
              "answers": ["hoopte"],
              "type": "fill"
            },
            {
              "question":
                  "Zij _____ dat de film spannend zou zijn, maar hij was saai.",
              "answers": ["verwachtte"],
              "type": "fill"
            }
          ],
        ),
        98: Level(
          id: 98,
          description: "Problemen en Oplossingen in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Wij _____ een oplossing voor het probleem.",
              "answers": ["vonden"],
              "type": "fill"
            },
            {
              "question":
                  "Hij _____ het probleem nadat hij er lang over had nagedacht.",
              "answers": ["begreep"],
              "type": "fill"
            },
            {
              "question": "Corrigeerde",
              "answers": ["Corrigeerde", "Las", "Dacht", "Bouwde"],
              "type": "pick"
            },
            {
              "question":
                  "Zij _____ haar fout direct nadat ze het had opgemerkt.",
              "answers": ["corrigeerde"],
              "type": "fill"
            },
            {
              "question":
                  "Hij _____ een slimme manier om het systeem te verbeteren.",
              "answers": ["bedacht"],
              "type": "fill"
            }
          ],
        ),
        99: Level(
          id: 99,
          description: "Moeilijke Beslissingen in het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Wij _____ lang na voordat we een beslissing namen.",
              "answers": ["nadenken"],
              "type": "fill"
            },
            {
              "question":
                  "Hij _____ uiteindelijk om een andere baan te zoeken.",
              "answers": ["besloot"],
              "type": "fill"
            },
            {
              "question": "Koos",
              "answers": ["Koos", "Dacht", "Las", "Begreep"],
              "type": "pick"
            },
            {
              "question": "Zij _____ tussen twee moeilijke opties.",
              "answers": ["koos"],
              "type": "fill"
            },
            {
              "question":
                  "Ik _____ niet zeker of ik de juiste keuze had gemaakt.",
              "answers": ["was"],
              "type": "fill"
            }
          ],
        ),
        100: Level(
          id: 100,
          description: "Reflectie en Levenslessen uit het Verleden",
          reward: 100,
          questions: [
            {
              "question": "Achteraf gezien zou _____ ik het anders aangepakt.",
              "answers": ["hebben"],
              "type": "fill"
            },
            {
              "question":
                  "Wij _____ niet dat deze beslissing zo belangrijk was.",
              "answers": ["beseften"],
              "type": "fill"
            },
            {
              "question": "Leer",
              "answers": ["Leer", "Begreep", "Onthield", "Dacht"],
              "type": "pick"
            },
            {
              "question": "Hij _____ van zijn fouten en groeide als persoon.",
              "answers": ["leerde"],
              "type": "fill"
            },
            {
              "question":
                  "Zij _____ dat ze in de toekomst beter moest nadenken.",
              "answers": ["begreep"],
              "type": "fill"
            }
          ],
        ),
      },
    };
  }
}
