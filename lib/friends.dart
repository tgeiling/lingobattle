import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';

import 'elements.dart';
import 'provider.dart';

class FriendsButton extends StatefulWidget {
  final String username;

  const FriendsButton({Key? key, required this.username}) : super(key: key);

  @override
  _FriendsButtonState createState() => _FriendsButtonState();
}

class _FriendsButtonState extends State<FriendsButton> {
  List<String> friends = [];
  List<String> searchResults = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    _fetchFriends();
  }

  void _initializeSocket() {
    socket = IO.io(
      'http://34.159.152.1:3000', // Your backend server
      IO.OptionBuilder()
          .setTransports(['websocket']) // Use WebSocket
          .disableAutoConnect() // Disable auto-connect
          .build(),
    );

    // Connect manually
    socket.connect();

    // Listen for connection
    socket.onConnect((_) {
      print("Connected to WebSocket server");
    });

    socket.onDisconnect((_) {
      print("Disconnected from WebSocket server");
    });

    // Listen for friend battle requests
    socket.on('battleRequestReceived', (data) {
      _showBattleRequestDialog(data['player1']);
    });
  }

  Future<void> _fetchFriends() async {
    final Uri url = Uri.parse(
        "http://34.159.152.1:3000/friends/list?username=${widget.username}");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          friends = List<String>.from(data["friends"]);
          isLoading = false;
        });
      }
    } catch (error) {
      print("Error fetching friends: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addFriend(String friendUsername) async {
    final Uri url = Uri.parse("http://34.159.152.1:3000/friends/add");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(
          {"username": widget.username, "friendUsername": friendUsername}),
    );

    if (response.statusCode == 200) {
      _fetchFriends();
    }
  }

  Future<void> _removeFriend(String friendUsername) async {
    final Uri url = Uri.parse("http://34.159.152.1:3000/friends/remove");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(
          {"username": widget.username, "friendUsername": friendUsername}),
    );

    if (response.statusCode == 200) {
      _fetchFriends();
    }
  }

  Future<void> _searchUsers(String query, Function setStateDialog) async {
    if (query.isEmpty) return;

    final Uri url =
        Uri.parse("http://34.159.152.1:3000/friends/search?query=$query");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setStateDialog(() {
          searchResults =
              List<String>.from(data["users"].map((user) => user["username"]));
        });
      }
    } catch (error) {
      print("Error searching users: $error");
    }
  }

  void _showBattleRequestDialog(String opponentUsername) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Battle Request"),
          content: Text("$opponentUsername has invited you to a battle!"),
          actions: [
            TextButton(
              onPressed: () {
                socket.emit(
                    'acceptBattleRequest', {'opponent': opponentUsername});
                Navigator.pop(context);
              },
              child: const Text("Accept"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Decline"),
            ),
          ],
        );
      },
    );
  }

  void _showFriendsDialog() {
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
                    color: Colors.grey[200], // Light background color
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          "Your Friends",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Scrollable Friends List
                        friends.isEmpty
                            ? const Text("No friends yet. Add some!")
                            : SizedBox(
                                height: 250, // Set max height for scrolling
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: friends.map((friend) {
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
                                          title: Text(friend),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Battle Invite Button
                                              NeumorphicButton(
                                                style: NeumorphicStyle(
                                                  color: Colors.blueAccent,
                                                  depth: 5,
                                                  boxShape: NeumorphicBoxShape
                                                      .circle(),
                                                ),
                                                padding:
                                                    const EdgeInsets.all(10),
                                                onPressed: () {
                                                  _inviteFriendToBattle(friend);
                                                },
                                                child: const Icon(
                                                    Icons.sports_rounded,
                                                    color: Colors.white),
                                              ),
                                              const SizedBox(width: 10),

                                              // Remove Friend Button
                                              NeumorphicButton(
                                                style: NeumorphicStyle(
                                                  color: Colors.redAccent,
                                                  depth: 5,
                                                  boxShape: NeumorphicBoxShape
                                                      .circle(),
                                                ),
                                                padding:
                                                    const EdgeInsets.all(10),
                                                onPressed: () {
                                                  _removeFriend(friend);
                                                  setStateDialog(() =>
                                                      friends.remove(friend));
                                                },
                                                child: const Icon(
                                                    Icons.remove_circle,
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

                        // Add Friend Button
                        NeumorphicButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showSearchDialog();
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
                            "Add Friends",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Close Button
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

  void _inviteFriendToBattle(String friendUsername) {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final String username = profileProvider.username;
    final String language =
        profileProvider.nativeLanguage; // Preferred language

    /* if (username.isEmpty) {
      _showErrorDialog("You need to be logged in to start a battle.");
      return;
    }

    // Emit a battle request to the server
    socket.emit('friendBattleRequest', {
      'player1': username,
      'player2': friendUsername,
      'language': language,
    });

    _showMessageDialog("Battle request sent to $friendUsername!"); */
  }

  void _showSearchDialog() {
    _searchController.clear();
    searchResults = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return Dialog(
                  insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Colors.transparent,
                  child: FractionallySizedBox(
                    widthFactor: 0.9,
                    heightFactor: 0.7, // Adaptive height
                    child: Neumorphic(
                      style: NeumorphicStyle(
                        depth: 8, // Keeps the depth effect
                        color: Colors.grey[200], // Background color
                        lightSource: LightSource
                            .bottomRight, // Shift shadow to only bottom-right
                        shadowDarkColor: Colors.black
                            .withOpacity(0.2), // Keep subtle shadows
                        shadowLightColor:
                            Colors.transparent, // Remove top-left light shadow
                        boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(20)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Search Input Field
                            Neumorphic(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              style: NeumorphicStyle(
                                depth: -4,
                                color: Colors.white,
                                boxShape: NeumorphicBoxShape.roundRect(
                                    BorderRadius.circular(12)),
                              ),
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  labelText: "Search for users",
                                  prefixIcon: Icon(Icons.search),
                                  border: InputBorder.none,
                                ),
                                onChanged: (query) async {
                                  await _searchUsers(query, setStateDialog);
                                },
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Scrollable User List
                            Expanded(
                              child: searchResults.isNotEmpty
                                  ? SingleChildScrollView(
                                      child: Column(
                                        children: searchResults.map((user) {
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
                                              title: Text(user),
                                              trailing: NeumorphicButton(
                                                style: NeumorphicStyle(
                                                  color: Colors.green,
                                                  depth: 5,
                                                  boxShape: NeumorphicBoxShape
                                                      .circle(),
                                                ),
                                                padding:
                                                    const EdgeInsets.all(10),
                                                onPressed: () {
                                                  _addFriend(user);
                                                  setStateDialog(() =>
                                                      searchResults
                                                          .remove(user));
                                                  _fetchFriends();
                                                },
                                                child: const Icon(
                                                    Icons.person_add,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    )
                                  : const Center(child: Text("No results.")),
                            ),
                            const SizedBox(height: 10),

                            // Close Button
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PressableButton(
      onPressed: _showFriendsDialog,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: const Text("Friends"),
    );
  }
}
