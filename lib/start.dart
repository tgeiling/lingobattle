import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'auth.dart';
import 'elements.dart';
import 'game.dart';
import 'provider.dart';
import 'matchhistory.dart';
import 'leaderboard.dart';
import 'ranks.dart';
import 'socket.dart';
import 'services.dart';

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
  ];
  late PageController _pageController;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);
    _initializeSocket();
  }

  void _initializeSocket() {
    final socketService = SocketService(); // ✅ Ensure the socket is ready

    if (!socketService.isConnected) {
      socketService.socket.connect();
      print("Socket connected on app start.");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    SocketService().socket.off('joinQueueError'); // Prevent multiple listeners
    SocketService().socket.on('joinQueueError', (data) {
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        _showErrorDialog(data['message']);
      }
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchingOpponentScreen(
          username: username,
          language: selectedLanguage!,
          onBackToMainMenu: widget.onBackToMainMenu,
        ),
      ),
    );

    // Emit join battle event
    /* socket.emit('joinQueue', {
      'username': username,
      'language': selectedLanguage,
    }); */

    //SocketService().joinQueue(username, selectedLanguage!);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.error),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (message !=
                    AppLocalizations.of(context)!.pleaseLoginInProfileFirst) {
                  Navigator.of(context).pop();
                }
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.ok),
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
      resizeToAvoidBottomInset: true, // ✅ Ensures the keyboard does not push UI
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(), // ✅ Smooth scrolling experience
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // ✅ Prevents extra space at the bottom
            children: [
              SizedBox(height: 35),
              Ranks(currentLanguage: flags[currentIndex]['language']!),
              SizedBox(height: 50),

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
                      size: isTablet(context) ? 160 : 70,
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
                      size: isTablet(context) ? 160 : 70,
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
                padding: EdgeInsets.symmetric(
                  vertical: isTablet(context) ? 22.0 : 10.0,
                  horizontal: isTablet(context) ? 280.0 : 110.0,
                ),
                child: PressableButton(
                  onPressed: isLoggedIn ? _initiateBattle : _navigateToLogin,
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet(context) ? 8 : 12,
                    horizontal: isTablet(context) ? 12 : 18,
                  ),
                  child: Center(
                    child: Text(
                      isLoggedIn
                          ? AppLocalizations.of(context)!.startBattle
                          : AppLocalizations.of(context)!.login,
                      style: isTablet(context)
                          ? Theme.of(context).textTheme.displaySmall
                          : Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
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
                          NeumorphicIcon(
                            Icons.leaderboard,
                            size: isTablet(context)
                                ? MediaQuery.of(context).size.width * 0.1
                                : MediaQuery.of(context).size.width * 0.15,
                            style: NeumorphicStyle(
                              color: Colors.grey[400],
                              depth: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatchHistoryScreen(
                                username: profilProvider.username),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NeumorphicIcon(
                            Icons.history,
                            size: isTablet(context)
                                ? MediaQuery.of(context).size.width * 0.1
                                : MediaQuery.of(context).size.width * 0.15,
                            style: NeumorphicStyle(
                              color: Colors.blue[300],
                              depth: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                  height: 40), // ✅ Prevents layout shifting with keyboard
            ],
          ),
        ),
      ),
    );
  }
}
