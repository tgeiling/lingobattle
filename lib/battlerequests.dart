import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'socket.dart';

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
  bool isFetching = false;

  @override
  void initState() {
    super.initState();
    _fetchBattleRequests();

    // ✅ Listen for real-time battle request events
    SocketService()
        .socket
        .on('battleRequestReceived', _onBattleRequestReceived);
    SocketService()
        .socket
        .on('battleRequestRejected', _onBattleRequestRejected);
    SocketService().socket.on('battleRequestsError', _onBattleRequestError);
  }

  @override
  void dispose() {
    SocketService()
        .socket
        .off('battleRequestReceived', _onBattleRequestReceived);
    SocketService()
        .socket
        .off('battleRequestRejected', _onBattleRequestRejected);
    SocketService().socket.off('battleRequestsError', _onBattleRequestError);
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

  /// ✅ Fetch battle requests **every 10 seconds** for real-time updates
  Future<void> _fetchBattleRequests() async {
    if (isFetching) return; // Prevent multiple calls
    setState(() => isFetching = true);

    SocketService()
        .socket
        .emit('getBattleRequests', {'username': widget.username});

    SocketService().socket.once('battleRequests', (data) {
      if (!mounted) return;
      setState(() {
        battleRequests = List<String>.from(data["battleRequests"] ?? []);
        isFetching = false;
      });

      if (isDialogOpen) {
        _showBattleRequestsDialog();
      }
    });

    SocketService().socket.once('battleRequestsError', (data) {
      if (!mounted) return;
      setState(() {
        errorMessage = data['message'];
        isFetching = false;
      });
    });

    // 🔄 Automatically refresh battle requests every 10 seconds
    Future.delayed(const Duration(seconds: 10), _fetchBattleRequests);
  }

  void _showBattleRequestsDialog() {
    setState(() => isDialogOpen = true);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Battle Requests"),
          content: isFetching
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
    SocketService().acceptBattleRequest(widget.username, opponentUsername);
    await Future.delayed(const Duration(seconds: 2));

    setState(() => battleRequests.remove(opponentUsername));
    if (!isDialogOpen) _fetchBattleRequests();
  }

  Future<void> _rejectBattleRequest(String opponentUsername) async {
    SocketService().rejectBattleRequest(widget.username, opponentUsername);
    setState(() => battleRequests.remove(opponentUsername));
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
