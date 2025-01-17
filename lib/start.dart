import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'auth.dart';
import 'elements.dart';
import 'level.dart';

class StartPage extends StatefulWidget {
  final bool Function() isLoggedIn;
  final Function(String, int, bool) toggleModal;
  final Function(bool) setAuthenticated;

  const StartPage({
    Key? key,
    required this.isLoggedIn,
    required this.toggleModal,
    required this.setAuthenticated,
  }) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final List<String> flags = [
    'assets/flags/english.png',
    'assets/flags/german.png',
    'assets/flags/spanish.png',
    'assets/flags/dutch.png',
    'assets/flags/swiss.png'
  ];
  late PageController _pageController;
  late IO.Socket socket;
  int currentIndex = 0;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);
    _initializeSocket(); // Initialize WebSocket
  }

  @override
  void dispose() {
    _pageController.dispose();
    socket.dispose(); // Dispose the socket connection
    super.dispose();
  }

  // Initialize WebSocket connection
  void _initializeSocket() {
    socket = IO.io('http://35.246.224.168', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    // Listen for WebSocket events
    socket.onConnect((_) {
      print('Connected to WebSocket server');
    });

    socket.on('waitingForOpponent', (data) {
      print('Waiting for opponent: ${data['message']}');
    });

    socket.on('battleStart', (data) {
      print('Battle started: $data');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BattleScreen(battleData: data),
        ),
      );
    });

    socket.on('battleFull', (data) {
      print('Battle full: ${data['message']}');
      _showErrorDialog('Battle is already full. Try another.');
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
              LoginScreen(setAuthenticated: widget.setAuthenticated)),
    );
  }

  Future<void> _initiateBattle() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchingOpponentScreen()),
    );

    // Join the battle using WebSocket
    socket.emit('joinBattle', {
      'username': 'Player1',
      'battleId': '12345',
    });

    setState(() {
      isSearching = true;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = widget.isLoggedIn();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(245, 245, 245, 0.894),
              Color.fromRGBO(160, 160, 160, 0.886),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.arrow_left),
                    onPressed: previousFlag,
                    tooltip: 'Previous Flag',
                    iconSize: 50,
                  ),
                  Container(
                    width: 200,
                    height: 144,
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
                          flags[index],
                          fit: BoxFit.contain,
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_right),
                    onPressed: nextFlag,
                    tooltip: 'Next Flag',
                    iconSize: 50,
                  ),
                ],
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 110.0),
                child: PressableButton(
                  onPressed: _initiateBattle, // Start battle via WebSocket
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                  child: Center(
                      child: Text(
                    "Start",
                    style: Theme.of(context).textTheme.labelLarge,
                  )),
                ),
              ),
              SizedBox(height: 20),
              if (!isLoggedIn)
                ElevatedButton(
                  onPressed: _navigateToLogin,
                  child: Text('Login'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// New screen for searching opponent with SpinKit animation
class SearchingOpponentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SpinKitFadingCircle(
              color: Colors.blue,
              size: 50.0,
            ),
            SizedBox(height: 20),
            Text(
              'Searching for an opponent...',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// A sample battle screen to navigate after finding an opponent
class BattleScreen extends StatelessWidget {
  final dynamic battleData;

  const BattleScreen({Key? key, required this.battleData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Battle Screen"),
      ),
      body: Center(
        child: Text(
          'Battle started with players: ${battleData['players']}',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
