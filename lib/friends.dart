import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'elements.dart';

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

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) return;

    final Uri url =
        Uri.parse("http://34.159.152.1:3000/friends/search?query=$query");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          searchResults =
              List<String>.from(data["users"].map((user) => user["username"]));
        });
      }
    } catch (error) {
      print("Error searching users: $error");
    }
  }

  void _showFriendsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Your Friends"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  friends.isEmpty
                      ? const Text("No friends yet. Add some!")
                      : Column(
                          children: friends.map((friend) {
                            return ListTile(
                              title: Text(friend),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.red),
                                onPressed: () {
                                  _removeFriend(friend);
                                  setState(() => friends.remove(friend));
                                },
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 10),
                  PressableButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showSearchDialog();
                    },
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: const Text("Add Friends"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSearchDialog() {
    _searchController.clear();
    setState(() => searchResults = []);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Search Users"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: "Search for users",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (query) {
                      _searchUsers(query);
                    },
                  ),
                  const SizedBox(height: 10),
                  searchResults != []
                      ? Column(
                          children: searchResults.map((user) {
                            return ListTile(
                              title: Text(user),
                              trailing: IconButton(
                                icon: const Icon(Icons.person_add,
                                    color: Colors.green),
                                onPressed: () {
                                  _addFriend(user);
                                  setState(() => searchResults.remove(user));
                                  _fetchFriends(); // Update list
                                },
                              ),
                            );
                          }).toList(),
                        )
                      : const Text("No results."),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
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
