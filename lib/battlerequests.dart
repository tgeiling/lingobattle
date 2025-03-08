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

    // ✅ Listen for real-time updates
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

  /// ✅ Called when a new battle request is received
  void _onBattleRequestReceived(data) {
    final String sender = data['sender'];
    setState(() {
      if (!battleRequests.contains(sender)) {
        battleRequests.add(sender);
      }
    });
  }

  /// ✅ Called when a battle request is rejected
  void _onBattleRequestRejected(data) {
    final String sender = data['sender'];
    setState(() {
      battleRequests.remove(sender);
    });
  }

  /// ✅ Handle error messages
  void _onBattleRequestError(data) {
    setState(() {
      errorMessage = data['message'];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage!)),
    );
  }

  /// ✅ Fetch the battle requests from the server
  Future<void> _fetchBattleRequests([Function? setStateDialog]) async {
    if (setStateDialog != null) {
      setStateDialog(() => isLoading = true);
    } else {
      setState(() => isLoading = true);
    }

    SocketService()
        .socket
        .emit('getBattleRequests', {'username': widget.username});

    SocketService().socket.once('battleRequests', (data) {
      if (!mounted) return;

      final List<String> requests =
          List<String>.from(data["battleRequests"] ?? []);
      print("🔍 Battle Requests Received: $requests");

      if (setStateDialog != null) {
        setStateDialog(() {
          battleRequests = requests;
          isLoading = false;
        });
      } else {
        setState(() {
          battleRequests = requests;
          isLoading = false;
        });
      }
    });

    SocketService().socket.once('battleRequestsError', (data) {
      print("Error fetching battle requests: ${data['message']}");
      if (setStateDialog != null) {
        setStateDialog(() => isLoading = false);
      } else {
        setState(() => isLoading = false);
      }
    });
  }

  /// ✅ Accept a battle request
  Future<void> _acceptBattleRequest(String opponentUsername) async {
    SocketService().acceptBattleRequest(widget.username, opponentUsername);
    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;
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
    _fetchBattleRequests();
  }

  /// ✅ Reject a battle request
  Future<void> _rejectBattleRequest(String opponentUsername) async {
    SocketService().rejectBattleRequest(widget.username, opponentUsername);
    _fetchBattleRequests();
  }

  /// ✅ Show the battle requests dialog
  void _showBattleRequestsDialog() {
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
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Battle Requests",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : battleRequests.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 20),
                                      child: Text("No battle requests found.",
                                          style: TextStyle(fontSize: 16)),
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
                          child: const Text("Close",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
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
      style: NeumorphicStyle(depth: 4, color: Colors.blueAccent),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: const Icon(Icons.mail),
    );
  }
}
