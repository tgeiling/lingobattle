import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';

import 'elements.dart';
import 'game.dart';
import 'provider.dart';
import 'socket.dart';

class FriendsButton extends StatefulWidget {
  final String username;
  final VoidCallback onBackToMainMenu;

  const FriendsButton({
    Key? key,
    required this.username,
    required this.onBackToMainMenu,
  }) : super(key: key);

  @override
  _FriendsButtonState createState() => _FriendsButtonState();
}

class _FriendsButtonState extends State<FriendsButton> {
  List<String> friends = [];
  List<String> searchResults = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchFriends();
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

  void _showFriendsDialog() {
    _fetchFriends();
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
                    depth: 8, // Keeps the depth effect
                    color: Colors.grey[200], // Background color
                    lightSource: LightSource
                        .bottomRight, // Shift shadow to only bottom-right
                    shadowDarkColor:
                        Colors.black.withOpacity(0.2), // Keep subtle shadows
                    shadowLightColor:
                        Colors.transparent, // Remove top-left light shadow
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

  void _showLanguageSelectionDialog(String friendUsername) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          child: FractionallySizedBox(
            widthFactor: 0.8,
            child: Neumorphic(
              style: NeumorphicStyle(
                depth: 8,
                color: Colors.grey[200],
                boxShape:
                    NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Select a Language",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _languageButton("German", "assets/flags/german.png",
                        "german", friendUsername),
                    _languageButton("Dutch", "assets/flags/dutch.png", "dutch",
                        friendUsername),
                    _languageButton("English", "assets/flags/english.png",
                        "english", friendUsername),
                    _languageButton("Spanish", "assets/flags/spanish.png",
                        "spanish", friendUsername),
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
                        "Cancel",
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
  }

  Widget _languageButton(String language, String flagPath, String languageCode,
      String friendUsername) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: NeumorphicButton(
        onPressed: () {
          Navigator.pop(context);
          _sendBattleRequest(friendUsername, languageCode);
        },
        style: NeumorphicStyle(
          depth: 4,
          color: Colors.white,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(flagPath, width: 40, height: 30),
            const SizedBox(width: 15),
            Text(language,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _inviteFriendToBattle(String friendUsername) async {
    _showLanguageSelectionDialog(friendUsername);
  }

  Future<void> _sendBattleRequest(
      String friendUsername, String language) async {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final String username = profileProvider.username;

    if (username.isEmpty) {
      _showErrorDialog("You need to be logged in to start a battle.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://34.159.152.1:3000/sendBattleRequest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderUsername': username,
          'receiverUsername': friendUsername,
          'language': language
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showMessageDialog(
            "Battle request sent to $friendUsername in $language!");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchingOpponentScreen(
              username: username,
              language: language,
              onBackToMainMenu: widget.onBackToMainMenu,
              friendUsername: friendUsername,
            ),
          ),
        );
      } else {
        _showErrorDialog(
            responseData['message'] ?? "Failed to send battle request.");
      }
    } catch (e) {
      _showErrorDialog("Error sending battle request: $e");
    }
  }

  /* Future<void> _inviteFriendToBattle(String friendUsername) async {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final String username = profileProvider.username;

    if (username.isEmpty) {
      _showErrorDialog("You need to be logged in to start a battle.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://34.159.152.1:3000/sendBattleRequest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderUsername': username,
          'receiverUsername': friendUsername,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showMessageDialog("Battle request sent to $friendUsername!");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchingOpponentScreen(
              username: username,
              language: "german",
              onBackToMainMenu: widget.onBackToMainMenu,
              friendUsername: friendUsername,
            ),
          ),
        );
      } else {
        _showErrorDialog(
            responseData['message'] ?? "Failed to send battle request.");
      }
    } catch (e) {
      _showErrorDialog("Error sending battle request: $e");
    }
  } */

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          child: FractionallySizedBox(
            widthFactor: 0.8,
            child: Neumorphic(
              style: NeumorphicStyle(
                depth: 8,
                color: Colors.grey[200], // Light background
                boxShape:
                    NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      "Error",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    NeumorphicButton(
                      onPressed: () => Navigator.pop(context),
                      style: NeumorphicStyle(
                        depth: 4,
                        color: Colors.redAccent,
                        boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(12)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      child: const Text(
                        "OK",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
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
  }

  void _showMessageDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          child: FractionallySizedBox(
            widthFactor: 0.8,
            child: Neumorphic(
              style: NeumorphicStyle(
                depth: 8,
                color: Colors.grey[200], // Light background
                boxShape:
                    NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info, color: Colors.blueAccent, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      "Message",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    NeumorphicButton(
                      onPressed: () => Navigator.pop(context),
                      style: NeumorphicStyle(
                        depth: 4,
                        color: Colors.blueAccent,
                        boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(12)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      child: const Text(
                        "OK",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double buttonPadding = screenWidth * 0.02; // Adaptive padding
    final double fontSize = screenWidth * 0.035; // Adaptive font size

    return PressableButton(
      onPressed: _showFriendsDialog,
      padding: EdgeInsets.symmetric(
          horizontal: buttonPadding * 1.5, vertical: buttonPadding * 0.8),
      child: Text(
        "Friends",
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
