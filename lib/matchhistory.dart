import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
          'Authorization': 'Bearer $token', // Add the token to the headers
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
        _showErrorDialog('Failed to fetch match history: ${response.body}');
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

                    return ListTile(
                      title: Text('Match ID: ${match['matchId']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Opponent: ${opponent?['username'] ?? 'N/A'}'),
                          Text('Your Score: ${player?['correctAnswers'] ?? 0}'),
                          Text(
                              'Opponent Score: ${opponent?['correctAnswers'] ?? 0}'),
                          Text('Language: ${match['language']}'),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
