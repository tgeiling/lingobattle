import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:provider/provider.dart';

import 'auth.dart';
import 'elements.dart';
import 'game.dart';
import 'provider.dart';
import 'matchhistory.dart';
import 'leaderboard.dart';

class StartPage extends StatefulWidget {
  final bool Function() isLoggedIn;
  final VoidCallback onBackToMainMenu;
  final Function(bool) setAuthenticated;
  final bool Function() isAuthenticated;

  const StartPage({
    Key? key,
    required this.isLoggedIn,
    required this.onBackToMainMenu,
    required this.setAuthenticated,
    required this.isAuthenticated,
  }) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final List<Map<String, String>> flags = [
    {'language': 'english', 'path': 'assets/flags/english.png'},
    {'language': 'german', 'path': 'assets/flags/german.png'},
    {'language': 'spanish', 'path': 'assets/flags/spanish.png'},
    {'language': 'dutch', 'path': 'assets/flags/dutch.png'},
    {'language': 'swiss', 'path': 'assets/flags/swiss.png'}
  ];
  late PageController _pageController;
  late IO.Socket socket;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);
    _initializeSocket();
  }

  @override
  void dispose() {
    _pageController.dispose();
    socket.dispose();
    super.dispose();
  }

  // Initialize WebSocket connection
  void _initializeSocket() {
    socket = IO.io('http://34.159.152.1:3000', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.connect();

    // Listen for WebSocket events
    socket.onConnect((_) {
      print('Connected to WebSocket server');
    });

    socket.onDisconnect((_) {
      print('Disconnected from WebSocket server');
    });
  }

  void nextFlag() {
    if (currentIndex < flags.length - 1) {
      setState(() {
        currentIndex++;
        _pageController.animateToPage(
          currentIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void previousFlag() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        _pageController.animateToPage(
          currentIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LoginScreen(setAuthenticated: widget.setAuthenticated),
      ),
    );
  }

  Future<void> _initiateBattle() async {
    final username =
        Provider.of<ProfileProvider>(context, listen: false).username;
    final selectedLanguage = flags[currentIndex]['language'];

    bool _authenticated = widget.isAuthenticated();

    if (!_authenticated) {
      _showErrorDialog("Please login in the profile first.");
      return;
    }

    // Listen for matchmaking errors
    socket.off('joinQueueError'); // Prevent multiple listeners
    socket.on('joinQueueError', (data) {
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        _showErrorDialog(data['message']);
      }
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchingOpponentScreen(
          socket: socket,
          username: username,
          language: selectedLanguage!,
          onBackToMainMenu: widget.onBackToMainMenu,
        ),
      ),
    );

    // Emit join battle event
    socket.emit('joinQueue', {
      'username': username,
      'language': selectedLanguage,
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (message != "Please login in the profile first.") {
                  Navigator.of(context).pop();
                }
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = widget.isLoggedIn();

    final profilProvider = Provider.of<ProfileProvider>(context, listen: false);
    print(profilProvider.username);

    return Scaffold(
      body: Stack(
        children: [
          // Top-right "View History" button

          Positioned(
            bottom: 16, // Adjust as needed
            right: 16, // Adjust as needed
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MatchHistoryScreen(username: profilProvider.username),
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Neumorphic(
                    style: NeumorphicStyle(
                      depth: 4,
                      intensity: 0.8,
                      shape: NeumorphicShape.concave,
                      boxShape: NeumorphicBoxShape.circle(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Icon(
                        Icons.history, // History icon
                        size: 32,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'View History',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16, // Adjust as needed
            left: 16, // Adjust as needed
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LeaderboardScreen(
                      username: profilProvider.username,
                    ),
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Neumorphic(
                    style: NeumorphicStyle(
                      depth: 4,
                      intensity: 0.8,
                      shape: NeumorphicShape.concave,
                      boxShape: NeumorphicBoxShape.circle(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Icon(
                        Icons.leaderboard_outlined, // History icon
                        size: 32,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Leaderbord',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          /* Positioned(
            top: 16, // Adjust as needed
            left: 16, // Adjust as needed
            child: GestureDetector(
              onTap: () async {
                final token = await getAuthToken();
                fetchAndPrintProfile(token!);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Neumorphic(
                    style: NeumorphicStyle(
                      depth: 4,
                      intensity: 0.8,
                      shape: NeumorphicShape.concave,
                      boxShape: NeumorphicBoxShape.circle(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Icon(
                        Icons.person, // History icon
                        size: 32,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Request Profile',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ), */
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextButton(
                      onPressed: previousFlag,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 12),
                      ),
                      child: NeumorphicIcon(
                        Icons.arrow_left,
                        size: 70,
                        style: NeumorphicStyle(
                          color: Colors.grey[400],
                          depth: 2,
                        ),
                      ),
                    ),
                    Neumorphic(
                      padding: const EdgeInsets.all(24),
                      style: NeumorphicStyle(
                        shape: NeumorphicShape.concave,
                        boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(12)),
                        depth: 8,
                        lightSource: LightSource.topLeft,
                      ),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.35,
                        height: MediaQuery.of(context).size.width * 0.3,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              currentIndex = index;
                            });
                          },
                          itemCount: flags.length,
                          itemBuilder: (context, index) {
                            return Image.asset(
                              flags[index]['path']!,
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: nextFlag,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 12),
                      ),
                      child: NeumorphicIcon(
                        Icons.arrow_right,
                        size: 70,
                        style: NeumorphicStyle(
                          color: Colors.grey[400],
                          depth: 2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 110.0),
                  child: PressableButton(
                    onPressed: _initiateBattle, // Start battle via WebSocket
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 18),
                    child: Center(
                      child: Text(
                        "Start Battle",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (!isLoggedIn)
                  PressableButton(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 18),
                    onPressed: _navigateToLogin,
                    child: Text(
                      'Login',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
