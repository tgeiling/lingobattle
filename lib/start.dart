import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'auth.dart';
import 'elements.dart';
import 'level.dart';

class StartPage extends StatefulWidget {
  final bool Function() isLoggedIn;
  final Function(String, int, bool) toggleModal;

  const StartPage({
    Key? key,
    required this.isLoggedIn,
    required this.toggleModal,
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
  late PageController _pageController;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);
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
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 110.0),
              child: PressableButton(
                onPressed: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    widget.toggleModal("", 0, false);
                  });
                },
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
            if (!widget.isLoggedIn())
              ElevatedButton(
                onPressed: _navigateToLogin,
                child: Text('Login'),
              ),
          ],
        ),
      ),
    ));
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
