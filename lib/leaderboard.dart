import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LeaderboardScreen extends StatefulWidget {
  final String username;

  const LeaderboardScreen({Key? key, required this.username}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> leaderboard = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  int page = 1;
  final int limit = 20;
  int? userRank;
  final ScrollController _scrollController = ScrollController();

  String selectedLanguage = "english";

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _fetchLeaderboard({bool loadMore = false}) async {
    if (loadMore && isFetchingMore) return;
    if (loadMore) setState(() => isFetchingMore = true);

    const storage = FlutterSecureStorage();
    final String? token = await storage.read(key: 'authToken');

    if (token == null) {
      _showErrorDialog('No authentication token found. Please log in again.');
      return;
    }

    if (!loadMore) {
      setState(() {
        leaderboard.clear();
        page = 1;
        isLoading = true;
      });
    }

    final Uri apiUrl = Uri.parse(
        'http://34.159.152.1:3000/leaderboard?page=$page&limit=$limit&username=${widget.username}&language=$selectedLanguage');

    try {
      final response = await http.get(
        apiUrl,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (loadMore) {
            leaderboard.addAll(data['leaderboard']);
            page++;
          } else {
            leaderboard = data['leaderboard'];
          }
          userRank = data['userRank'];
          isLoading = false;
          isFetchingMore = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isFetchingMore = false;
        });
        _showErrorDialog(
            'Failed to fetch leaderboard. Error: ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });
      _showErrorDialog('Error fetching leaderboard: $e');
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !isFetchingMore) {
      _fetchLeaderboard(loadMore: true);
    }
  }

  void _jumpToUserRank() {
    if (userRank == null || leaderboard.isEmpty) return;

    final int index = (userRank! - 1) % limit;
    final int targetPage = ((userRank! - 1) ~/ limit) + 1;

    if (targetPage != page) {
      page = targetPage;
      _fetchLeaderboard();
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (index >= 0 && index < leaderboard.length) {
        _scrollController.animateTo(
          index * 80.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
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
        title: Text(
          'Leaderboard',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          if (userRank != null)
            TextButton(
              onPressed: _jumpToUserRank,
              child: Text(
                "Jump to My Rank (#$userRank)",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        ],
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
                  leaderboard.clear();
                  page = 1;
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
                        'No leaderboard data available.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: leaderboard.length + 1,
                        itemBuilder: (context, index) {
                          if (index < leaderboard.length) {
                            final player = leaderboard[index];
                            final rank = index + 1 + (page - 1) * limit;
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
                                    Text(
                                      '#$rank',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                            color: Colors.blueGrey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      username,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge!
                                          .copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
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
                          } else {
                            return isFetchingMore
                                ? const Center(
                                    child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(),
                                  ))
                                : const SizedBox.shrink();
                          }
                        },
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
        Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
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
      'English': 'assets/flags_20x20/english.png',
      'German': 'assets/flags_20x20/german.png',
      'Spanish': 'assets/flags_20x20/spanish.png',
      'Dutch': 'assets/flags_20x20/dutch.png',
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
                Text(entry.key), // Language name
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
