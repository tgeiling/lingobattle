import 'package:flutter/material.dart';

class StartPage extends StatefulWidget {
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
              onPressed: () {
                // Insert event for start button here
              },
              child: Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}
