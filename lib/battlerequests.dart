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
  List<Map<String, String>> battleRequests = [];
  bool isLoading = false;
  String? errorMessage;
  bool isDialogOpen = false;
  bool hasFetched = false;

  final Map<String, String> languageFlags = {
    "german": "assets/flags/german.png",
    "dutch": "assets/flags/dutch.png",
    "english": "assets/flags/english.png",
    "spanish": "assets/flags/spanish.png",
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Fetch battle requests only when needed
  Future<void> _fetchBattleRequests(Function setStateDialog) async {
    if (isLoading || hasFetched) return;

    setStateDialog(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://34.159.152.1:3000/getBattleRequests/${widget.username}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setStateDialog(() {
          battleRequests = List<Map<String, String>>.from(data["battleRequests"]
                  ?.map((req) => {
                        "username": req["username"],
                        "language": req["language"]
                      }) ??
              []);
          isLoading = false;
          hasFetched = true;
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
        isLoading = false;
      });
    }
  }

  void _showBattleRequestsDialog() {
    setState(() {
      isDialogOpen = true;
      hasFetched = false;
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            _fetchBattleRequests(setStateDialog);

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
                            setStateDialog(() => hasFetched = false);
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
      setStateDialog(() => battleRequests
          .removeWhere((req) => req["username"] == opponentUsername));

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
    }
  }

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
    return NeumorphicButton(
      onPressed: _showBattleRequestsDialog,
      style: NeumorphicStyle(depth: 4, color: Colors.blueAccent),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: const Icon(Icons.mail),
    );
  }
}
