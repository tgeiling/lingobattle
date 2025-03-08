import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchBattleRequests();

    // ✅ Listen only **once** per event type
    SocketService()
        .socket
        .on('battleRequestReceived', _onBattleRequestReceived);
    SocketService()
        .socket
        .on('battleRequestRejected', _onBattleRequestRejected);
    SocketService().socket.on('battleRequestError', _onBattleRequestError);
  }

  @override
  void dispose() {
    SocketService()
        .socket
        .off('battleRequestReceived', _onBattleRequestReceived);
    SocketService()
        .socket
        .off('battleRequestRejected', _onBattleRequestRejected);
    SocketService().socket.off('battleRequestError', _onBattleRequestError);
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

  void _onBattleRequestError(data) {
    setState(() => errorMessage = data['message']);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage!)),
    );
  }

  Future<void> _fetchBattleRequests() async {
    setState(() => isLoading = true);
    SocketService()
        .socket
        .emit('getBattleRequests', {'username': widget.username});

    SocketService().socket.once('battleRequests', (data) {
      if (!mounted) return;
      setState(() {
        battleRequests = List<String>.from(data["battleRequests"] ?? []);
        isLoading = false;
      });
    });

    SocketService().socket.once('battleRequestsError', (data) {
      if (!mounted) return;
      setState(() {
        errorMessage = data['message'];
        isLoading = false;
      });
    });
  }

  void _showBattleRequestsDialog() {
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
                          trailing: IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () {
                              SocketService().acceptBattleRequest(
                                  widget.username, request);
                              setState(() => battleRequests.remove(request));
                            },
                          ),
                        );
                      }).toList(),
                    ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close")),
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
