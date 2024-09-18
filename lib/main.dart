import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingobattle/auth.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'provider.dart';
import 'start.dart';
import 'services.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ProfileProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salomon Bottom Bar Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  bool? _authenticated;
  bool? _loggedIn;
  final AuthService _authService = AuthService();
  late Connectivity _connectivity;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isConnected = true;
  bool _showConnectionMessage = true;
  bool _showAuthenticateMessage = true;
  bool _isLoading = true; // New state variable for loading

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    Future.microtask(() =>
        Provider.of<ProfileProvider>(context, listen: false).loadPreferences());
    WidgetsBinding.instance.addObserver(this);

    // Initialize connectivity
    _connectivity = Connectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      _updateConnectionStatus(result);
    });
    _checkInitialConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    setState(() {
      _isConnected = !results.contains(ConnectivityResult.none);
      _showConnectionMessage =
          !_isConnected || (_authenticated == false && _isConnected);
    });
  }

  Future<void> _checkInitialConnectivity() async {
    List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      Provider.of<ProfileProvider>(context, listen: false).loadPreferences();
    }
  }

  TextTheme buildTextTheme(BuildContext context) {
    var baseTextStyle = const TextStyle(
      fontFamily: 'Roboto',
      color: Colors.white,
      letterSpacing: 0.4,
    );

    // Determine screen width for responsive sizing
    double screenWidth = MediaQuery.of(context).size.width;

    // Define responsive sizes based on screen width
    double smallTextSize = screenWidth < 360 ? 11.0 : 16.0;
    double normalTextSize = screenWidth < 360 ? 12.0 : 18.0;
    double largeTextSize = screenWidth < 360 ? 16.0 : 20.0;
    double xLargeTextSize = screenWidth < 360 ? 18.0 : 22.0;
    double xxLargeTextSize = screenWidth < 360 ? 20.0 : 24.0;

    double labelLarge = screenWidth < 360 ? 14.0 : 18.0;

    return TextTheme(
      displayLarge: baseTextStyle.copyWith(fontSize: xxLargeTextSize),
      displayMedium: baseTextStyle.copyWith(fontSize: xLargeTextSize),
      displaySmall: baseTextStyle.copyWith(fontSize: largeTextSize),
      headlineLarge: baseTextStyle.copyWith(
          fontSize: largeTextSize, fontWeight: FontWeight.bold),
      headlineMedium: baseTextStyle.copyWith(
          fontSize: normalTextSize, fontWeight: FontWeight.bold),
      headlineSmall: baseTextStyle.copyWith(
          fontSize: smallTextSize, fontWeight: FontWeight.bold),
      titleLarge: baseTextStyle.copyWith(fontSize: largeTextSize),
      titleMedium: baseTextStyle.copyWith(fontSize: normalTextSize),
      titleSmall: baseTextStyle.copyWith(fontSize: smallTextSize),
      labelLarge: baseTextStyle.copyWith(fontSize: labelLarge),
      bodyLarge: baseTextStyle.copyWith(fontSize: normalTextSize),
      bodyMedium: baseTextStyle.copyWith(fontSize: smallTextSize),
      bodySmall: baseTextStyle.copyWith(fontSize: smallTextSize - 2),
    );
  }

  Future<void> _checkAuthentication() async {
    setState(() {
      _isLoading = true;
    });

    bool isGuest = await _authService.isGuestToken();
    bool tokenExpired = await _authService.isTokenExpired();

    if (!isGuest) {
      setState(() {
        _setAuthenticated(true);
      });
      if (tokenExpired) {
        setState(() {
          _setAuthenticated(false);
        });
      }
    } else {
      await _authService.setGuestToken();
      setState(() {
        _setAuthenticated(false);
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _setAuthenticated(bool authenticated) {
    setState(() => _authenticated = authenticated);
    _setLoggedIn(authenticated);
    _showAuthenticateMessage = !authenticated;
  }

  void _setLoggedIn(bool loggedIn) {
    setState(() {
      _loggedIn = loggedIn;
    });
  }

  bool isLoggedIn() {
    return _loggedIn ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ProfileProvider>(
          builder: (context, profile, child) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.stars, color: Colors.yellow),
                  SizedBox(width: 8),
                  Text(
                      'Win Streak: ${profile.winStreak}'), // Updated dynamically
                ],
              ),
              Text('EXP: ${profile.exp}'), // Updated dynamically
            ],
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          Center(child: StartPage()),
          Center(child: Text("Site2")),
        ],
      ),
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() {
            _currentIndex = i;
            _pageController.animateToPage(
              i,
              duration: Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          });
        },
        items: [
          SalomonBottomBarItem(
            icon: Icon(Icons.home),
            title: Text("Home"),
            selectedColor: Colors.purple,
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.search),
            title: Text("Search"),
            selectedColor: Colors.orange,
          ),
        ],
      ),
    );
  }
}
