import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'elements.dart';

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
          print(response.body);
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
          title: Text(AppLocalizations.of(context)!.error),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }

  void _showQuestionResultsDialog(
      BuildContext context, List<dynamic> questions) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.grey[200],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.match_questions,
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index]['question'];
                      final answers =
                          (questions[index]['answers'] as List).join(", ");
                      return Neumorphic(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        style: NeumorphicStyle(
                          shape: NeumorphicShape.flat,
                          depth: 4,
                          lightSource: LightSource.topLeft,
                          boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(10)),
                          color: Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!
                                  .question_display(index + 1, question),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!
                                  .answers_display(answers),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                PressableButton(
                  onPressed: () => Navigator.pop(context),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    AppLocalizations.of(context)!.close,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.match_history)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : matchHistory.isEmpty
              ? Center(
                  child: Text(
                      AppLocalizations.of(context)!.no_match_history_available))
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
                          horizontal: 12, vertical: 8),
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Win/Loss text
                              Text(
                                resultText,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: resultColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Scores and usernames
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        '${player?['username'] ?? 'Unknown'}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${player?['correctAnswers'] ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    ': ',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    children: [
                                      Text(
                                        '${opponent?['username'] ?? 'Unknown'}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${opponent?['correctAnswers'] ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // View Questions Button
                              PressableButton(
                                onPressed: () => _showQuestionResultsDialog(
                                    context, match['questions'] ?? []),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                child: Text(
                                  AppLocalizations.of(context)!.view_questions,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
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
