import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth.dart';

class StartPage extends StatefulWidget {
  final bool Function() isLoggedIn;

  const StartPage({
    Key? key,
    required this.isLoggedIn,
  }) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final List<String> flags = [
    'assets/german.png',
    'assets/netherlands.png',
    'assets/schweiz.png'
  ];
  int currentIndex = 0;

  void nextFlag() {
    setState(() {
      if (currentIndex < flags.length - 1) {
        currentIndex++;
      } else {
        currentIndex = 0;
      }
    });
  }

  void previousFlag() {
    setState(() {
      if (currentIndex > 0) {
        currentIndex--;
      } else {
        currentIndex = flags.length - 1;
      }
    });
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => LoginScreen(setAuthenticated: (bool value) {
                print("User is authenticated: $value");
              })),
    );
  }

  Future<void> _initiateBattle() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchingOpponentScreen()),
    );

    // Call the backend to join the battle
    final url =
        'http://35.246.224.168/joinBattle'; // Change with your backend IP/Port
    final response = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': 'Player1', 'battleId': '12345'}));

    if (response.statusCode == 200) {
      // Handle battle start after opponent is found
      final battleData = jsonDecode(response.body);
      // You can navigate to your battle screen here.
    } else {
      print('Failed to start battle');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
                ),
                Image.asset(flags[currentIndex], width: 100, height: 72),
                IconButton(
                  icon: Icon(Icons.arrow_right),
                  onPressed: nextFlag,
                  tooltip: 'Next Flag',
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initiateBattle,
              child: Text('Start Battle'),
            ),
            SizedBox(height: 20),
            if (!widget.isLoggedIn())
              ElevatedButton(
                onPressed: _navigateToLogin,
                child: Text('Login'),
              ),
          ],
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
