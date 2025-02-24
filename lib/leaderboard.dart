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
    final Uri apiUrl = Uri.parse(
        'http://34.159.152.1:3000/leaderboard?page=$page&limit=$limit&username=${widget.username}');

    if (token == null) {
      _showErrorDialog('No authentication token found. Please log in again.');
      return;
    }

    try {
      final response = await http.get(
        apiUrl,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          leaderboard.addAll(data['leaderboard']);
          userRank = data['userRank'];
          isLoading = false;
          isFetchingMore = false;
        });
        if (loadMore) page++;
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

  void _scrollToUserRank() {
    if (userRank == null || leaderboard.isEmpty) return;

    final int index = (userRank! - 1) % limit;
    if (index >= 0 && index < leaderboard.length) {
      _scrollController.animateTo(
        index * 80.0, // Adjust height per list item
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
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
              onPressed: _scrollToUserRank,
              child: Text(
                "Go to My Rank (#$userRank)",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        ],
      ),
      body: isLoading
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
                      final elo = player['elo'];
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
