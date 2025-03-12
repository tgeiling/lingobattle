import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LeaderboardScreen extends StatefulWidget {
  final String username;

  const LeaderboardScreen({Key? key, required this.username}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> leaderboard = [];
  bool isLoading = true;
  bool isFetching = false;
  int currentPage = 1;
  int totalPages = 1;
  final int limit = 20;
  int? userRank;
  String selectedLanguage = "english";

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    if (isFetching) return;
    setState(() => isFetching = true);

    const storage = FlutterSecureStorage();
    final String? token = await storage.read(key: 'authToken');

    if (token == null) {
      _showErrorDialog(AppLocalizations.of(context)!.no_auth_token);
      return;
    }

    final Uri apiUrl = Uri.parse(
        'http://34.159.152.1:3000/leaderboard?page=$currentPage&limit=$limit&username=${widget.username}&language=$selectedLanguage');

    try {
      final response =
          await http.get(apiUrl, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          leaderboard = data['leaderboard'];
          userRank = data['userRank'];
          totalPages = (data['totalCount'] / limit).ceil();
          isLoading = false;
        });
      } else {
        _showErrorDialog(AppLocalizations.of(context)!
            .leaderboard_fetch_failed(response.reasonPhrase!));
      }
    } catch (e) {
      _showErrorDialog(
          AppLocalizations.of(context)!.leaderboard_fetch_error(e.toString()));
    } finally {
      setState(() => isFetching = false);
    }
  }

  void _nextPage() {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
        isLoading = true;
      });
      _fetchLeaderboard();
    }
  }

  void _previousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
        isLoading = true;
      });
      _fetchLeaderboard();
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.error),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.leaderboard),
            if (userRank != null)
              TextButton(
                onPressed: () {}, // No jump-to function needed in pagination
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: Size(0, 0)),
                child: Text(AppLocalizations.of(context)!
                    .jump_to_my_rank(userRank.toString())),
              ),
          ],
        ),
        toolbarHeight: 80,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: LeaderboardLanguageSelector(
              selectedLanguage: selectedLanguage,
              onLanguageSelected: (String newLanguage) {
                setState(() {
                  selectedLanguage = newLanguage;
                  currentPage = 1;
                  isLoading = true;
                });
                _fetchLeaderboard();
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : leaderboard.isEmpty
                    ? Center(
                        child: Text(
                            AppLocalizations.of(context)!.no_leaderboard_data))
                    : ListView.builder(
                        itemCount: leaderboard.length,
                        itemBuilder: (context, index) {
                          final player = leaderboard[index];
                          final rank = index + 1 + (currentPage - 1) * limit;
                          final username = player['username'];
                          final elo = player['elo'][selectedLanguage] ?? 0;
                          final winStreak = player['winStreak'];

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.4),
                                    spreadRadius: 2,
                                    blurRadius: 6,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('#$rank',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  Text(username,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                  Row(
                                    children: [
                                      _iconLabel(Icons.emoji_events, '$elo'),
                                      const SizedBox(width: 10),
                                      _iconLabel(Icons.local_fire_department,
                                          '$winStreak', Colors.redAccent),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: currentPage > 1 ? _previousPage : null,
                  child: Text(AppLocalizations.of(context)!.previous),
                ),
                Text(
                  AppLocalizations.of(context)!
                      .page_of(currentPage, totalPages),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                ElevatedButton(
                  onPressed: currentPage < totalPages ? _nextPage : null,
                  child: Text(AppLocalizations.of(context)!.next),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconLabel(IconData icon, String text, [Color color = Colors.black]) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(text,
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class LeaderboardLanguageSelector extends StatelessWidget {
  final String selectedLanguage;
  final Function(String) onLanguageSelected;

  const LeaderboardLanguageSelector({
    Key? key,
    required this.selectedLanguage,
    required this.onLanguageSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, String> languagesWithFlags = {
      'english': 'assets/flags_20x20/english.png',
      'german': 'assets/flags_20x20/german.png',
      'spanish': 'assets/flags_20x20/spanish.png',
      'dutch': 'assets/flags_20x20/dutch.png',
    };

    // Ensure selectedLanguage is valid; default to first available language
    String currentLanguage = languagesWithFlags.containsKey(selectedLanguage)
        ? selectedLanguage
        : languagesWithFlags.keys.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButton<String>(
        value: currentLanguage,
        isExpanded: true,
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
                  entry.value, // Flag icon
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 8),
                Text(translatedLanguage), // Language name
              ],
            ),
          );
        }).toList(),
        onChanged: (String? newLanguage) {
          if (newLanguage != null) {
            onLanguageSelected(newLanguage.toLowerCase());
          }
        },
      ),
    );
  }
}
