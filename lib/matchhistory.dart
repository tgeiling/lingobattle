import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MatchHistoryScreen extends StatefulWidget {
  final String username;

  const MatchHistoryScreen({Key? key, required this.username})
      : super(key: key);

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  List<dynamic> matchHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMatchHistory();
  }

  Future<void> _fetchMatchHistory() async {
    const storage = FlutterSecureStorage();
    final String? token = await storage.read(key: 'authToken');
    final Uri apiUrl =
        Uri.parse('http://34.159.152.1:3000/matchHistory/${widget.username}');

    if (token == null) {
      _showErrorDialog('No authentication token found. Please log in again.');
      return;
    }

    try {
      final response = await http.get(
        apiUrl,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          matchHistory = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorDialog(
            'Failed to fetch match history. Error: ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Error fetching match history: $e');
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
      appBar: AppBar(title: const Text('Match History')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : matchHistory.isEmpty
              ? const Center(child: Text('No match history available.'))
              : ListView.builder(
                  itemCount: matchHistory.length,
                  itemBuilder: (context, index) {
                    final match = matchHistory[index];
                    final player = match['players'].firstWhere(
                      (p) => p['username'] == widget.username,
                      orElse: () => null,
                    );
                    final opponent = match['players'].firstWhere(
                      (p) => p['username'] != widget.username,
                      orElse: () => null,
                    );

                    final isWin = (player?['correctAnswers'] ?? 0) >
                        (opponent?['correctAnswers'] ?? 0);
                    final resultText = isWin ? 'Win' : 'Loss';
                    final resultColor = isWin ? Colors.green : Colors.red;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Neumorphic(
                        style: NeumorphicStyle(
                          depth: 8,
                          intensity: 0.7,
                          shape: NeumorphicShape.flat,
                          color: Colors.grey.shade200,
                          shadowLightColor: Colors.white,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Match ID: ${match['matchId']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  Text(
                                    resultText,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: resultColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'You: ${player?['correctAnswers'] ?? 0}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Opponent: ${opponent?['username'] ?? 'Unknown'}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Opponent Score: ${opponent?['correctAnswers'] ?? 0}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Language: ${match['language']}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Created at: ${match['createdAt'] ?? 'Unknown'}',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
