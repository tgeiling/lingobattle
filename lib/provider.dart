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
  int _elo = 0;
  int _skillLevel = 0;

  int get winStreak => _winStreak;
  int get exp => _exp;
  String get username => _username;
  String get title => _title;
  int get elo => _elo;
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

  void setElo(int elo) {
    _elo = elo;
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

  Future<void> loadPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _winStreak = prefs.getInt('winStreak') ?? 0;
    _exp = prefs.getInt('exp') ?? 0;
    _username = prefs.getString('username') ?? "";
    _title = prefs.getString('title') ?? "";
    _elo = prefs.getInt('elo') ?? 0;
    _skillLevel = prefs.getInt('skillLevel') ?? 0;
    _completedLevelsJson = prefs.getString('language_levels') ?? "{}";

    notifyListeners();
  }

  Future<void> savePreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('winStreak', _winStreak);
    await prefs.setInt('exp', _exp);
    await prefs.setString('username', _username);
    await prefs.setString('title', _title);
    await prefs.setInt('elo', _elo);
    await prefs.setInt('skillLevel', _skillLevel);
    await prefs.setString('language_levels', _completedLevelsJson);
  }

  Future<void> syncProfile(String token) async {
    Map<String, dynamic>? profileData = await fetchProfile(token);
    if (profileData != null) {
      _winStreak = profileData['winStreak'] ?? _winStreak;
      _exp = profileData['exp'] ?? _exp;
      _elo = profileData['elo'] ?? _elo;
      _username = profileData['username'] ?? _username;
      _title = profileData['title'] ?? _title;
      _skillLevel = profileData['skillLevel'] ?? _skillLevel;

      // If completedLevels is in the response, update it
      if (profileData.containsKey('completedLevels')) {
        _completedLevelsJson = jsonEncode(profileData['completedLevels']);
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

        print("✅ Successfully loaded levels from SharedPreferences!");
      } catch (e) {
        print("❌ Error deserializing language levels: $e");
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
              "question": "The cat is _____ the table.",
              "answers": ["under"]
            },
            {
              "question": "I go _____ school every day.",
              "answers": ["to"]
            },
            {
              "question": "She is sitting _____ the chair.",
              "answers": ["on"]
            },
            {
              "question": "We are going _____ the park.",
              "answers": ["to"]
            },
            {
              "question": "He plays football _____ the evening.",
              "answers": ["in"]
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
              "answers": ["doing"]
            },
            {
              "question": "They are _____ to the cinema.",
              "answers": ["going"]
            },
            {
              "question": "The dog is sleeping _____ the couch.",
              "answers": ["on"]
            },
            {
              "question": "He is interested _____ music.",
              "answers": ["in"]
            },
            {
              "question": "The book is _____ the bag.",
              "answers": ["in"]
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
              "answers": ["going"]
            },
            {
              "question": "She is _____ a letter to her friend.",
              "answers": ["writing"]
            },
            {
              "question": "We are _____ dinner in the kitchen.",
              "answers": ["making"]
            },
            {
              "question": "They are _____ to the movie theater.",
              "answers": ["going"]
            },
            {
              "question": "The kids are _____ outside.",
              "answers": ["playing"]
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
              "answers": ["in"]
            },
            {
              "question": "He _____ to school by bus.",
              "answers": ["goes"]
            },
            {
              "question": "We _____ to visit our grandparents tomorrow.",
              "answers": ["plan"]
            },
            {
              "question": "She _____ a beautiful dress yesterday.",
              "answers": ["bought"]
            },
            {
              "question": "They _____ playing in the garden now.",
              "answers": ["are"]
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
              "answers": ["are"]
            },
            {
              "question": "Can you please pass _____ the salt?",
              "answers": ["me"]
            },
            {
              "question": "I would like to _____ some coffee.",
              "answers": ["have"]
            },
            {
              "question": "Do you know _____ the weather will be tomorrow?",
              "answers": ["what"]
            },
            {
              "question": "He has been working _____ the project all day.",
              "answers": ["on"]
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
              "answers": ["sit"]
            },
            {
              "question": "She wants to _____ the piano.",
              "answers": ["play"]
            },
            {
              "question": "He is going to _____ his homework later.",
              "answers": ["finish"]
            },
            {
              "question": "Can you _____ me a favor?",
              "answers": ["do"]
            },
            {
              "question": "I need to _____ some groceries.",
              "answers": ["buy"]
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
              "answers": ["are"]
            },
            {
              "question": "Could you _____ me the way to the station?",
              "answers": ["tell"]
            },
            {
              "question": "He _____ the answer to the question.",
              "answers": ["knows"]
            },
            {
              "question": "They are _____ to the park together.",
              "answers": ["going"]
            },
            {
              "question": "I _____ to see the doctor this afternoon.",
              "answers": ["need"]
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
              "answers": ["in"]
            },
            {
              "question": "She was born _____ April.",
              "answers": ["in"]
            },
            {
              "question": "We are planning to go _____ vacation soon.",
              "answers": ["on"]
            },
            {
              "question": "He is very good _____ mathematics.",
              "answers": ["at"]
            },
            {
              "question": "I need to finish this project _____ Friday.",
              "answers": ["by"]
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
              "answers": ["in"]
            },
            {
              "question": "They met _____ the coffee shop.",
              "answers": ["at"]
            },
            {
              "question": "She is looking _____ her lost keys.",
              "answers": ["for"]
            },
            {
              "question": "I will call you _____ I get home.",
              "answers": ["when"]
            },
            {
              "question": "The cat jumped _____ the fence.",
              "answers": ["over"]
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
              "answers": ["on"]
            },
            {
              "question": "They are discussing the plan _____ the meeting.",
              "answers": ["during"]
            },
            {
              "question": "She is preparing _____ her exams.",
              "answers": ["for"]
            },
            {
              "question": "The presentation is scheduled _____ next Monday.",
              "answers": ["for"]
            },
            {
              "question": "I am very proud _____ my achievements.",
              "answers": ["of"]
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
              "answers": ["unter"]
            },
            {
              "question": "Ich gehe _____ die Schule.",
              "answers": ["in"]
            },
            {
              "question": "Sie sitzt _____ dem Stuhl.",
              "answers": ["auf"]
            },
            {
              "question": "Wir fahren _____ den Park.",
              "answers": ["in"]
            },
            {
              "question": "Er spielt Fußball _____ dem Abend.",
              "answers": ["am"]
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
              "answers": ["an"]
            },
            {
              "question": "Sie gehen _____ das Kino.",
              "answers": ["in"]
            },
            {
              "question": "Der Hund schläft _____ dem Sofa.",
              "answers": ["auf"]
            },
            {
              "question": "Er interessiert sich _____ Musik.",
              "answers": ["für"]
            },
            {
              "question": "Das Buch liegt _____ der Tasche.",
              "answers": ["in"]
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
              "answers": ["in"]
            },
            {
              "question": "Er hat _____ einen Brief geschrieben.",
              "answers": ["an"]
            },
            {
              "question": "Wir haben _____ Abendessen gekocht.",
              "answers": ["das"]
            },
            {
              "question": "Sie sind _____ das Kino gegangen.",
              "answers": ["in"]
            },
            {
              "question": "Die Kinder spielen _____ draußen.",
              "answers": ["immer"]
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
              "answers": ["auf"]
            },
            {
              "question": "Er fährt _____ mit dem Bus.",
              "answers": ["immer"]
            },
            {
              "question": "Wir wollen _____ unsere Großeltern besuchen.",
              "answers": ["heute"]
            },
            {
              "question": "Sie hat _____ ein schönes Kleid gekauft.",
              "answers": ["gestern"]
            },
            {
              "question": "Sie _____ jetzt im Garten spielen.",
              "answers": ["können"]
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
              "answers": ["geht"]
            },
            {
              "question": "Können Sie mir bitte _____ den Zucker geben?",
              "answers": ["noch"]
            },
            {
              "question": "Ich möchte gerne _____ eine Tasse Kaffee bestellen.",
              "answers": ["noch"]
            },
            {
              "question": "Wissen Sie, wie _____ Wetter morgen sein wird?",
              "answers": ["das"]
            },
            {
              "question": "Er arbeitet schon den ganzen Tag _____ dem Projekt.",
              "answers": ["an"]
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
              "answers": ["bitte"]
            },
            {
              "question": "Sie möchte _____ Klavier spielen.",
              "answers": ["gerne"]
            },
            {
              "question": "Er wird später _____ seine Hausaufgaben machen.",
              "answers": ["noch"]
            },
            {
              "question": "Können Sie mir _____ einen Gefallen tun?",
              "answers": ["bitte"]
            },
            {
              "question": "Ich muss noch _____ einkaufen gehen.",
              "answers": ["etwas"]
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
              "answers": ["geht"]
            },
            {
              "question":
                  "Könntest du mir bitte _____ den Weg zum Bahnhof zeigen?",
              "answers": ["noch"]
            },
            {
              "question": "Er _____ die Antwort auf die Frage.",
              "answers": ["weiß"]
            },
            {
              "question": "Sie sind _____ gemeinsam in den Park gegangen.",
              "answers": ["oft"]
            },
            {
              "question": "Ich _____ später zum Arzt gehen.",
              "answers": ["muss"]
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
              "answers": ["viel"]
            },
            {
              "question": "Sie wurde im _____ April geboren.",
              "answers": ["Monat"]
            },
            {
              "question": "Wir planen bald in den Urlaub zu _____ gehen.",
              "answers": ["fahren"]
            },
            {
              "question": "Er ist sehr gut in _____ Mathematik.",
              "answers": ["der"]
            },
            {
              "question":
                  "Ich muss dieses Projekt bis _____ Freitag fertigstellen.",
              "answers": ["nächsten"]
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
              "answers": ["in"]
            },
            {
              "question": "Sie haben sich _____ im Café getroffen.",
              "answers": ["heute"]
            },
            {
              "question": "Sie sucht _____ ihre verlorenen Schlüssel.",
              "answers": ["nach"]
            },
            {
              "question": "Ich rufe dich an, wenn ich _____ nach Hause komme.",
              "answers": ["gleich"]
            },
            {
              "question": "Die Katze sprang _____ über den Zaun.",
              "answers": ["schnell"]
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
              "answers": ["noch"]
            },
            {
              "question": "Sie besprechen den Plan _____ im Meeting.",
              "answers": ["heute"]
            },
            {
              "question": "Sie bereitet sich _____ auf ihre Prüfungen vor.",
              "answers": ["gerade"]
            },
            {
              "question":
                  "Die Präsentation ist für nächsten Montag _____ angesetzt.",
              "answers": ["schon"]
            },
            {
              "question": "Ich bin sehr stolz _____ auf meine Leistungen.",
              "answers": ["immer"]
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
              "answers": ["debajo de"]
            },
            {
              "question": "Voy _____ la escuela todos los días.",
              "answers": ["a"]
            },
            {
              "question": "Ella está sentada _____ la silla.",
              "answers": ["en"]
            },
            {
              "question": "Vamos _____ el parque esta tarde.",
              "answers": ["a"]
            },
            {
              "question": "Él juega fútbol _____ la tarde.",
              "answers": ["por"]
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
              "answers": ["haciendo"]
            },
            {
              "question": "Ellos están yendo _____ el cine.",
              "answers": ["a"]
            },
            {
              "question": "El perro está durmiendo _____ el sofá.",
              "answers": ["en"]
            },
            {
              "question": "Ella está interesada _____ la música.",
              "answers": ["en"]
            },
            {
              "question": "El libro está _____ la mochila.",
              "answers": ["en"]
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
              "answers": ["a"]
            },
            {
              "question": "Ella está _____ una carta a su amiga.",
              "answers": ["escribiendo"]
            },
            {
              "question": "Estamos _____ la cena en la cocina.",
              "answers": ["preparando"]
            },
            {
              "question": "Ellos están _____ al cine juntos.",
              "answers": ["yendo"]
            },
            {
              "question": "Los niños están _____ afuera.",
              "answers": ["jugando"]
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
              "answers": ["en"]
            },
            {
              "question": "Él va _____ la escuela en autobús.",
              "answers": ["a"]
            },
            {
              "question": "Vamos _____ visitar a nuestros abuelos mañana.",
              "answers": ["a"]
            },
            {
              "question": "Ella _____ un vestido bonito ayer.",
              "answers": ["compró"]
            },
            {
              "question": "Ellos están _____ en el jardín ahora.",
              "answers": ["jugando"]
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
              "answers": ["te"]
            },
            {
              "question": "¿Puedes pasarme _____ la sal, por favor?",
              "answers": [""]
            },
            {
              "question": "Me gustaría _____ una taza de café.",
              "answers": ["pedir"]
            },
            {
              "question": "¿Sabes cómo estará _____ el clima mañana?",
              "answers": [""]
            },
            {
              "question":
                  "Ha estado trabajando _____ en el proyecto todo el día.",
              "answers": ["sin descanso"]
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
              "answers": ["amablemente"]
            },
            {
              "question": "Ella quiere _____ tocar el piano.",
              "answers": ["aprender a"]
            },
            {
              "question": "Él va a _____ hacer su tarea más tarde.",
              "answers": ["terminar"]
            },
            {
              "question": "¿Puedes hacerme _____ un favor?",
              "answers": [""]
            },
            {
              "question": "Necesito _____ comprar algunos comestibles.",
              "answers": ["urgentemente"]
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
              "answers": ["bien"]
            },
            {
              "question": "¿Puedes decirme _____ cómo llegar a la estación?",
              "answers": ["fácilmente"]
            },
            {
              "question": "Él sabe _____ la respuesta a la pregunta.",
              "answers": ["exactamente"]
            },
            {
              "question": "Ellos están _____ yendo al parque juntos.",
              "answers": ["felices"]
            },
            {
              "question": "Tengo que _____ visitar al médico esta tarde.",
              "answers": ["urgentemente"]
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
              "answers": ["tranquilamente"]
            },
            {
              "question": "Ella nació _____ en abril.",
              "answers": ["durante"]
            },
            {
              "question": "Estamos planeando ir _____ de vacaciones pronto.",
              "answers": ["a algún lugar tropical"]
            },
            {
              "question": "Él es muy bueno _____ en matemáticas.",
              "answers": ["practicando"]
            },
            {
              "question":
                  "Necesito terminar este proyecto _____ para el viernes.",
              "answers": ["mañana"]
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
              "answers": ["adentro"]
            },
            {
              "question": "Ellos se encontraron _____ en la cafetería.",
              "answers": ["por casualidad"]
            },
            {
              "question": "Ella está buscando _____ sus llaves perdidas.",
              "answers": ["ansiosamente"]
            },
            {
              "question": "Te llamaré _____ cuando llegue a casa.",
              "answers": ["tan pronto"]
            },
            {
              "question": "El gato saltó _____ sobre la valla.",
              "answers": ["grácilmente"]
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
              "answers": ["arduamente"]
            },
            {
              "question": "Están discutiendo el plan _____ en la reunión.",
              "answers": ["detenidamente"]
            },
            {
              "question": "Ella se está preparando _____ para sus exámenes.",
              "answers": ["diligentemente"]
            },
            {
              "question":
                  "La presentación está programada _____ para el próximo lunes.",
              "answers": ["puntualmente"]
            },
            {
              "question": "Estoy muy orgulloso _____ de mis logros.",
              "answers": ["profundamente"]
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
              "answers": ["onder"]
            },
            {
              "question": "Ik ga _____ school elke dag.",
              "answers": ["naar"]
            },
            {
              "question": "Zij zit _____ de stoel.",
              "answers": ["op"]
            },
            {
              "question": "Wij gaan _____ het park vanmiddag.",
              "answers": ["naar"]
            },
            {
              "question": "Hij speelt voetbal _____ de middag.",
              "answers": ["in"]
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
              "answers": ["bezig met"]
            },
            {
              "question": "Zij gaan _____ de bioscoop.",
              "answers": ["naar"]
            },
            {
              "question": "De hond slaapt _____ de bank.",
              "answers": ["onder"]
            },
            {
              "question": "Zij is geïnteresseerd _____ muziek.",
              "answers": ["in"]
            },
            {
              "question": "Het boek zit _____ de tas.",
              "answers": ["in"]
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
              "answers": ["naar"]
            },
            {
              "question":
                  "Zij is _____ een brief aan haar vriend aan het schrijven.",
              "answers": ["bezig met"]
            },
            {
              "question":
                  "Wij zijn _____ het avondeten in de keuken aan het bereiden.",
              "answers": ["bezig met"]
            },
            {
              "question": "Zij gaan _____ de bioscoop samen.",
              "answers": ["naar"]
            },
            {
              "question": "De kinderen zijn _____ buiten aan het spelen.",
              "answers": ["aan het"]
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
              "answers": ["in"]
            },
            {
              "question": "Hij gaat _____ school met de bus.",
              "answers": ["naar"]
            },
            {
              "question": "Wij gaan _____ onze grootouders morgen bezoeken.",
              "answers": ["om"]
            },
            {
              "question": "Zij heeft gisteren _____ een mooie jurk gekocht.",
              "answers": ["al"]
            },
            {
              "question": "Zij zijn nu _____ in de tuin aan het spelen.",
              "answers": ["bezig"]
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
              "answers": ["gaat het"]
            },
            {
              "question": "Kun je mij alsjeblieft _____ het zout aangeven?",
              "answers": ["even"]
            },
            {
              "question": "Ik zou graag _____ een kopje koffie willen.",
              "answers": ["hebben"]
            },
            {
              "question": "Weet jij hoe _____ het weer morgen zal zijn?",
              "answers": ["exact"]
            },
            {
              "question": "Hij is al de hele dag _____ met dat project bezig.",
              "answers": ["druk"]
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
              "answers": ["om"]
            },
            {
              "question": "Zij wil graag _____ piano leren spelen.",
              "answers": ["op de"]
            },
            {
              "question": "Hij gaat later _____ zijn huiswerk maken.",
              "answers": ["af"]
            },
            {
              "question": "Kun je mij alsjeblieft _____ een gunst verlenen?",
              "answers": ["eventjes"]
            },
            {
              "question": "Ik moet nog even _____ boodschappen doen.",
              "answers": ["wat"]
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
              "answers": ["voel jij"]
            },
            {
              "question": "Kun je mij _____ de weg naar het station wijzen?",
              "answers": ["precies"]
            },
            {
              "question": "Hij weet _____ het antwoord op de vraag.",
              "answers": ["altijd"]
            },
            {
              "question": "Zij gaan _____ naar het park samen.",
              "answers": ["vaak"]
            },
            {
              "question": "Ik moet vanmiddag _____ naar de dokter.",
              "answers": ["zeker"]
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
              "answers": ["rustig"]
            },
            {
              "question": "Zij werd geboren _____ in april.",
              "answers": ["ergens"]
            },
            {
              "question": "Wij zijn van plan _____ op vakantie te gaan.",
              "answers": ["binnenkort"]
            },
            {
              "question": "Hij is heel goed _____ wiskunde.",
              "answers": ["in"]
            },
            {
              "question": "Ik moet dit project _____ voor vrijdag afronden.",
              "answers": ["zeker"]
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
              "answers": ["binnen"]
            },
            {
              "question": "Zij ontmoetten elkaar _____ in het café.",
              "answers": ["voor het eerst"]
            },
            {
              "question": "Zij zoekt _____ naar haar verloren sleutels.",
              "answers": ["nog steeds"]
            },
            {
              "question": "Ik bel je zodra ik _____ thuis ben.",
              "answers": ["direct"]
            },
            {
              "question": "De kat sprong _____ over het hek.",
              "answers": ["snel"]
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
              "answers": ["geconcentreerd"]
            },
            {
              "question":
                  "Zij bespreken het plan _____ tijdens de vergadering.",
              "answers": ["uitgebreid"]
            },
            {
              "question": "Zij bereidt zich _____ op haar examens voor.",
              "answers": ["nauwgezet"]
            },
            {
              "question": "De presentatie is gepland _____ voor maandag.",
              "answers": ["volledig"]
            },
            {
              "question": "Ik ben heel trots _____ op mijn prestaties.",
              "answers": ["volledig"]
            },
          ],
        ),
      },
      'Swiss': {
        1: Level(
          id: 1,
          description: "Einführung ins Schweizerdeutsch",
          reward: 100,
          questions: [
            {
              "question": "De Hund isch _____ im Garte.",
              "answers": ["draa"]
            },
            {
              "question": "Ich gang _____ zum Coiffeur morn.",
              "answers": ["zu"]
            },
            {
              "question": "Si sind _____ use mit de Chind spaziere.",
              "answers": ["grad"]
            },
            {
              "question": "Er schlaft _____ uf em Sofa.",
              "answers": ["gerade"]
            },
            {
              "question": "Mir gönd _____ is Kino hüt Abig.",
              "answers": ["äbe"]
            },
          ],
        ),
        2: Level(
          id: 2,
          description: "Grundwortschatz Schweizerdeutsch",
          reward: 100,
          questions: [
            {
              "question": "Chasch mir bitte _____ d Tasse gä?",
              "answers": ["grad"]
            },
            {
              "question": "De Zug chunnt _____ pünktlich hüt.",
              "answers": ["sicher"]
            },
            {
              "question": "D Chatz isch _____ underem Tisch.",
              "answers": ["grad"]
            },
            {
              "question": "Ich bruuche _____ es neues Paar Schue.",
              "answers": ["unbedingt"]
            },
            {
              "question": "D Lüt warted _____ vor em Lädele.",
              "answers": ["geduldig"]
            },
          ],
        ),
        3: Level(
          id: 3,
          description: "Einfache Sätze",
          reward: 100,
          questions: [
            {
              "question": "Mir gönd _____ uf de Märt morn.",
              "answers": ["gemeinsam"]
            },
            {
              "question": "Er schribt _____ e Brief an sini Fründin.",
              "answers": ["grad"]
            },
            {
              "question": "D Kinder händ _____ im Garte gspilt.",
              "answers": ["lang"]
            },
            {
              "question": "Ich gang jetzt _____ in d Stadt.",
              "answers": ["schnell"]
            },
            {
              "question": "D Fründin chunt _____ use zum Znüni.",
              "answers": ["grad"]
            },
          ],
        ),
        4: Level(
          id: 4,
          description: "Grundlagen der Grammatik",
          reward: 100,
          questions: [
            {
              "question": "Si hät _____ es buchi Buech gläse.",
              "answers": ["letzt"]
            },
            {
              "question": "Er het _____ sine Fründ tröffe im Bistro.",
              "answers": ["grad"]
            },
            {
              "question": "D Chind gönd _____ in d Schuel morn.",
              "answers": ["zämä"]
            },
            {
              "question": "Ich ha hüt _____ z vil Arbeit gha.",
              "answers": ["mal wieder"]
            },
            {
              "question": "Si gönd _____ immer zäme laufe am See.",
              "answers": ["gern"]
            },
          ],
        ),
        5: Level(
          id: 5,
          description: "Häufig verwendete Ausdrücke",
          reward: 100,
          questions: [
            {
              "question": "Wie _____ geits dir?",
              "answers": ["guet"]
            },
            {
              "question": "Hesch _____ chli meh Salz für mi?",
              "answers": ["grad"]
            },
            {
              "question": "Ich wür gern _____ e Chafi bstelle.",
              "answers": ["sofort"]
            },
            {
              "question": "Weisch, wenn de Zug _____ chunnt?",
              "answers": ["ungefähr"]
            },
            {
              "question": "Si schaffed _____ scho e ganze Tag an dem Projekt.",
              "answers": ["intensiv"]
            },
          ],
        ),
        6: Level(
          id: 6,
          description: "Hörverständnis",
          reward: 100,
          questions: [
            {
              "question": "D Lärerin hät gseit, mir sötted _____ ruig sii.",
              "answers": ["grad"]
            },
            {
              "question": "Er wott _____ sine Vater cho hole.",
              "answers": ["sofort"]
            },
            {
              "question": "Si probiert _____ d Antwort z finde.",
              "answers": ["ganz schnell"]
            },
            {
              "question": "Chasch mir bitte _____ d Chiste bringe?",
              "answers": ["schnell"]
            },
            {
              "question": "Ich bruuche no _____ züüg vom Lädele.",
              "answers": ["chli"]
            },
          ],
        ),
        7: Level(
          id: 7,
          description: "Alltagsgespräche",
          reward: 100,
          questions: [
            {
              "question": "Wo _____ geisch hüt no?",
              "answers": ["grad"]
            },
            {
              "question": "Si gönd _____ us em Huus hüt am Nomittag.",
              "answers": ["schön"]
            },
            {
              "question": "Chasch mir _____ d Weg zeige zur Post?",
              "answers": ["bitte"]
            },
            {
              "question": "Er mues _____ sine Kolleg abhole.",
              "answers": ["grad"]
            },
            {
              "question": "Ich ha vergässe _____ d Schlüsel daheime.",
              "answers": ["leider"]
            },
          ],
        ),
        8: Level(
          id: 8,
          description: "Leseübungen",
          reward: 100,
          questions: [
            {
              "question": "D Schüler sind _____ am Lerne.",
              "answers": ["fleißig"]
            },
            {
              "question": "Mir gönd _____ am Sunntig i d Kirche.",
              "answers": ["immer"]
            },
            {
              "question": "Si bruuche meh Zit _____ zum Läse.",
              "answers": ["immer"]
            },
            {
              "question": "Er isch _____ e guete Schachspieler.",
              "answers": ["bescht"]
            },
            {
              "question": "D Lärerin hät _____ es guets Vorbild gheit.",
              "answers": ["oft"]
            },
          ],
        ),
        9: Level(
          id: 9,
          description: "Schreibübungen",
          reward: 100,
          questions: [
            {
              "question": "Ich ha _____ e E-Mail gschribe hüt.",
              "answers": ["grad"]
            },
            {
              "question": "Mir gönd _____ chli spaziere mit em Hund.",
              "answers": ["bald"]
            },
            {
              "question": "Si het _____ d Antwort gli gfunde.",
              "answers": ["schnell"]
            },
            {
              "question": "Er isch _____ ganz müed gsi nach em Schaffe.",
              "answers": ["komplett"]
            },
            {
              "question": "Chasch mir hilfe _____ d Üebig mache?",
              "answers": ["grad"]
            },
          ],
        ),
        10: Level(
          id: 10,
          description: "Fortgeschrittene Wortschatz",
          reward: 100,
          questions: [
            {
              "question": "Er het _____ e wyt Ziit im Usland glebt.",
              "answers": ["grad"]
            },
            {
              "question": "Si redet _____ über de nöie Vertrag.",
              "answers": ["oft"]
            },
            {
              "question": "Si bruuched meh Zit _____ für s Examen vorzbereite.",
              "answers": ["schnell"]
            },
            {
              "question":
                  "D Präsentation isch _____ für nächste Wuche abgmacht.",
              "answers": ["sofort"]
            },
            {
              "question": "Ich bi stolz _____ uf mini Arbeite bis jetzt.",
              "answers": ["immer"]
            },
          ],
        ),
      },
    };
  }
}
