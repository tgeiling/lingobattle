import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'socket.dart';
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
  bool isLoading = false;
  String? errorMessage;
  bool isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _fetchBattleRequests(); // Fetch requests via HTTP

    // ✅ Listen for real-time WebSocket updates
    SocketService()
        .socket
        .on('battleRequestReceived', _onBattleRequestReceived);
    SocketService()
        .socket
        .on('battleRequestRejected', _onBattleRequestRejected);
  }

  @override
  void dispose() {
    SocketService()
        .socket
        .off('battleRequestReceived', _onBattleRequestReceived);
    SocketService()
        .socket
        .off('battleRequestRejected', _onBattleRequestRejected);
    super.dispose();
  }

  void _onBattleRequestReceived(data) {
    final String sender = data['sender'];
    if (!battleRequests.contains(sender)) {
      setState(() => battleRequests.add(sender));
    }
  }

  void _onBattleRequestRejected(data) {
    final String sender = data['sender'];
    setState(() => battleRequests.remove(sender));
  }

  /// ✅ Fetch battle requests using HTTP
  Future<void> _fetchBattleRequests() async {
    setState(() => isLoading = true);

    final response = await http.get(
      Uri.parse(
          'http://34.159.152.1:3000/getBattleRequests/${widget.username}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        battleRequests = List<String>.from(data["battleRequests"] ?? []);
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = "Failed to fetch battle requests.";
        isLoading = false;
      });
    }
  }

  void _showBattleRequestsDialog() {
    setState(() => isDialogOpen = true);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Battle Requests"),
          content: isLoading
              ? const Center(child: CircularProgressIndicator())
              : battleRequests.isEmpty
                  ? const Text("No battle requests found.")
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: battleRequests.map((request) {
                        return ListTile(
                          title: Text(request),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () => _acceptBattleRequest(request),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _rejectBattleRequest(request),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => isDialogOpen = false);
                Navigator.pop(context);
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _acceptBattleRequest(String opponentUsername) async {
    final response = await http.post(
      Uri.parse('http://34.159.152.1:3000/acceptBattleRequest'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': widget.username,
        'opponentUsername': opponentUsername,
      }),
    );

    if (response.statusCode == 200) {
      setState(() => battleRequests.remove(opponentUsername));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchingOpponentScreen(
            username: widget.username,
            language: "german",
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

  Future<void> _rejectBattleRequest(String opponentUsername) async {
    final response = await http.post(
      Uri.parse('http://34.159.152.1:3000/rejectBattleRequest'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': widget.username,
        'opponentUsername': opponentUsername,
      }),
    );

    if (response.statusCode == 200) {
      setState(() => battleRequests.remove(opponentUsername));
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
