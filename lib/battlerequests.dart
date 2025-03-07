import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
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
  List<String> battleRequests = [];
  bool isLoading = true;
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  void _initializeSocket() {
    socket = IO.io('http://34.159.152.1:3000', <String, dynamic>{
      'transports': ['websocket'],
    });

    if (socket.connected) return;

    socket.connect();

    socket.onConnect((_) {
      print('Connected to WebSocket server');
    });

    socket.onDisconnect((_) {
      print('Disconnected from WebSocket server');
    });
  }

  Future<void> _fetchBattleRequests() async {
    setState(() => isLoading = true);
    final Uri url = Uri.parse(
        "http://34.159.152.1:3000/battle/requests/${widget.username}");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await Future.delayed(
            const Duration(milliseconds: 300)); // Smooth UI update
        setState(() {
          battleRequests = List<String>.from(data["battleRequests"] ?? []);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (error) {
      print("Error fetching battle requests: $error");
      setState(() => isLoading = false);
    }
  }

  Future<void> _acceptBattleRequest(String opponentUsername) async {
    final Uri url = Uri.parse("http://34.159.152.1:3000/battle/accept");
    await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(
          {"username": widget.username, "opponentUsername": opponentUsername}),
    );
    _initializeSocket();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchingOpponentScreen(
          socket: socket,
          username: widget.username,
          language: "german",
          onBackToMainMenu: widget.onBackToMainMenu,
          friendUsername: opponentUsername,
        ),
      ),
    );
    await _fetchBattleRequests();
  }

  Future<void> _rejectBattleRequest(String opponentUsername) async {
    final Uri url = Uri.parse("http://34.159.152.1:3000/battle/reject");
    await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(
          {"username": widget.username, "opponentUsername": opponentUsername}),
    );
    await _fetchBattleRequests();
  }

  void _showBattleRequestsDialog() async {
    await _fetchBattleRequests(); // Ensure data is updated before showing dialog
    if (!mounted)
      return; // Prevent UI errors if the widget is no longer in context

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
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
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Battle Requests",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : battleRequests.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 20),
                                      child: Text(
                                        "No battle requests found.",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  )
                                : SizedBox(
                                    height: 250,
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: battleRequests.map((request) {
                                          return Neumorphic(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 6),
                                            padding: const EdgeInsets.all(12),
                                            style: NeumorphicStyle(
                                              depth: 4,
                                              color: Colors.white,
                                              boxShape:
                                                  NeumorphicBoxShape.roundRect(
                                                BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: ListTile(
                                              title: Text(request),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  NeumorphicButton(
                                                    style: NeumorphicStyle(
                                                      color: Colors.green,
                                                      depth: 5,
                                                      boxShape:
                                                          NeumorphicBoxShape
                                                              .circle(),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10),
                                                    onPressed: () async {
                                                      await _acceptBattleRequest(
                                                          request);
                                                      setStateDialog(() =>
                                                          battleRequests
                                                              .remove(request));
                                                    },
                                                    child: const Icon(
                                                        Icons.check,
                                                        color: Colors.white),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  NeumorphicButton(
                                                    style: NeumorphicStyle(
                                                      color: Colors.redAccent,
                                                      depth: 5,
                                                      boxShape:
                                                          NeumorphicBoxShape
                                                              .circle(),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10),
                                                    onPressed: () async {
                                                      await _rejectBattleRequest(
                                                          request);
                                                      setStateDialog(() =>
                                                          battleRequests
                                                              .remove(request));
                                                    },
                                                    child: const Icon(
                                                        Icons.close,
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

  @override
  Widget build(BuildContext context) {
    return NeumorphicButton(
      onPressed: _showBattleRequestsDialog,
      style: NeumorphicStyle(
        depth: 4,
        color: Colors.blueAccent,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: const Text(
        "Battle Requests",
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
