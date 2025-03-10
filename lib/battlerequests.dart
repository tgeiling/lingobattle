import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'game.dart';

class BattleRequestsButton extends StatefulWidget {
  final String username;
  final VoidCallback onBackToMainMenu;

  const BattleRequestsButton({
    Key? key,
    required this.username,
    required this.onBackToMainMenu,
  }) : super(key: key);

  @override
  _BattleRequestsButtonState createState() => _BattleRequestsButtonState();
}

class _BattleRequestsButtonState extends State<BattleRequestsButton> {
  List<Map<String, dynamic>> battleRequests = [];
  bool isLoading = false;
  String? errorMessage;
  bool isDialogOpen = false;
  bool hasFetched = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  final Map<String, String> languageFlags = {
    "german": "assets/flags/german.png",
    "dutch": "assets/flags/dutch.png",
    "english": "assets/flags/english.png",
    "spanish": "assets/flags/spanish.png",
  };

  Future<void> _fetchBattleRequests(Function setStateDialog) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://34.159.152.1:3000/getBattleRequests/${widget.username}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setStateDialog(() {
          battleRequests = List<Map<String, dynamic>>.from(
            (data["battleRequests"] ?? []).map((req) => {
                  "username": req["username"],
                  "language": req["language"],
                }),
          );
          isLoading = false;
          hasFetched = true; // Mark as fetched
        });
      } else {
        setStateDialog(() {
          errorMessage = "Failed to fetch battle requests.";
          isLoading = false;
        });
      }
    } catch (e) {
      setStateDialog(() {
        errorMessage = "Error fetching battle requests: $e";
        print("Error fetching battle requests: $e");
        isLoading = false;
      });
    }
  }

  void _showBattleRequestsDialog() {
    setState(() {
      isLoading = true;
      isDialogOpen = true;
      hasFetched = false;
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            if (!hasFetched && isLoading) {
              _fetchBattleRequests(setStateDialog);
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.transparent,
              child: FractionallySizedBox(
                widthFactor: 0.9,
                child: Neumorphic(
                  style: NeumorphicStyle(
                    depth: 8,
                    color: Colors.grey[200],
                    lightSource: LightSource.bottomRight,
                    shadowDarkColor: Colors.black.withOpacity(0.2),
                    shadowLightColor: Colors.transparent,
                    boxShape: NeumorphicBoxShape.roundRect(
                      BorderRadius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Battle Requests",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (battleRequests.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              "No battle requests found.",
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        else
                          SizedBox(
                            height: 250,
                            child: SingleChildScrollView(
                              child: Column(
                                children: battleRequests.map((request) {
                                  final String username = request["username"]!;
                                  final String language = request["language"]!;
                                  final String? flag =
                                      languageFlags[language.toLowerCase()];

                                  return Neumorphic(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.all(12),
                                    style: NeumorphicStyle(
                                      depth: 4,
                                      color: Colors.white,
                                      boxShape: NeumorphicBoxShape.roundRect(
                                        BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: flag != null
                                          ? Image.asset(flag,
                                              width: 30, height: 30)
                                          : const Icon(Icons.flag),
                                      title: Text(
                                        "$username - $language",
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          NeumorphicButton(
                                            style: NeumorphicStyle(
                                              color: Colors.green,
                                              depth: 5,
                                              boxShape:
                                                  NeumorphicBoxShape.circle(),
                                            ),
                                            padding: const EdgeInsets.all(10),
                                            onPressed: () =>
                                                _acceptBattleRequest(username,
                                                    language, setStateDialog),
                                            child: const Icon(Icons.check,
                                                color: Colors.white),
                                          ),
                                          const SizedBox(width: 10),
                                          NeumorphicButton(
                                            style: NeumorphicStyle(
                                              color: Colors.redAccent,
                                              depth: 5,
                                              boxShape:
                                                  NeumorphicBoxShape.circle(),
                                            ),
                                            padding: const EdgeInsets.all(10),
                                            onPressed: () =>
                                                _rejectBattleRequest(
                                                    username, setStateDialog),
                                            child: const Icon(Icons.close,
                                                color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        NeumorphicButton(
                          onPressed: () {
                            setStateDialog(() {
                              isLoading = true;
                              hasFetched = false; // Allow re-fetching
                            });
                            _fetchBattleRequests(setStateDialog);
                          },
                          style: NeumorphicStyle(
                            depth: 4,
                            color: Colors.blueAccent,
                            boxShape: NeumorphicBoxShape.roundRect(
                                BorderRadius.circular(12)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          child: const Text(
                            "Refresh",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 10),
                        NeumorphicButton(
                          onPressed: () => Navigator.pop(context),
                          style: NeumorphicStyle(
                            depth: 4,
                            color: Colors.grey[300],
                            boxShape: NeumorphicBoxShape.roundRect(
                                BorderRadius.circular(12)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          child: const Text(
                            "Close",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Accept a battle request and update UI
  Future<void> _acceptBattleRequest(
      String opponentUsername, String language, Function setStateDialog) async {
    final response = await http.post(
      Uri.parse('http://34.159.152.1:3000/acceptBattleRequest'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': widget.username,
        'opponentUsername': opponentUsername,
        'language': language,
      }),
    );

    if (response.statusCode == 200) {
      setStateDialog(() => battleRequests.remove(opponentUsername));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchingOpponentScreen(
            username: widget.username,
            language: language,
            onBackToMainMenu: widget.onBackToMainMenu,
            friendUsername: opponentUsername,
          ),
        ),
      );
    } else {
      final responseData = jsonDecode(response.body);
      _showErrorDialog(
          responseData['message'] ?? "Failed to accept battle request.");
    }
  }

  /// Reject a battle request and update UI
  Future<void> _rejectBattleRequest(
      String opponentUsername, Function setStateDialog) async {
    final response = await http.post(
      Uri.parse('http://34.159.152.1:3000/rejectBattleRequest'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': widget.username,
        'opponentUsername': opponentUsername,
      }),
    );

    if (response.statusCode == 200) {
      setStateDialog(() => battleRequests.remove(opponentUsername));
    } else {
      final responseData = jsonDecode(response.body);
      _showErrorDialog(
          responseData['message'] ?? "Failed to reject battle request.");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double buttonPadding = screenWidth * 0.02; // Adaptive padding
    final double iconSize = screenWidth * 0.05; // Adaptive icon size
    final double depth = screenWidth * 0.008; // Adjust depth dynamically

    return NeumorphicButton(
      onPressed: _showBattleRequestsDialog,
      padding: EdgeInsets.symmetric(
          horizontal: buttonPadding * 1.5, vertical: buttonPadding * 0.8),
      style: NeumorphicStyle(
        depth: depth, // Adjust depth based on screen size
        color: Colors.blueAccent,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(10)),
      ),
      child: Icon(
        Icons.mail,
        size: iconSize, // Responsive icon size
        color: Colors.white,
      ),
    );
  }
}
