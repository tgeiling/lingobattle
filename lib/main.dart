import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:lingobattle/elements.dart';
import 'package:lingobattle/services.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'provider.dart';
import 'start.dart';
import 'auth.dart';
import 'level.dart';
import 'settings.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LevelNotifier()),
        ChangeNotifierProvider(create: (context) => ProfileProvider()),
      ],
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
        primarySwatch: Colors.grey,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool _isModalVisible = false;
  String modalDescription = "Declaring Description";
  int level = 0;
  bool isVideoPlayer = true;

  bool? _authenticated;
  bool? _loggedIn;
  final AuthService _authService = AuthService();
  late Connectivity _connectivity;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isConnected = true;
  bool _showConnectionMessage = true;
  bool _showAuthenticateMessage = true;
  bool _isLoading = true;

  //animation
  /* bool _showCoins = false;
  late AnimationController _controller;
  final int numCoins = 8; */

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);

    getAuthToken().then((token) {
      if (token != null) {
        profileProvider.syncProfile(token);
      } else {
        print("No auth token available.");
      }
    });
    Future.microtask(() =>
        Provider.of<ProfileProvider>(context, listen: false).loadPreferences());
    //Future.microtask(() => Provider.of<LevelNotifier>(context, listen: false).loadLevelsAfterStart());
    WidgetsBinding.instance.addObserver(this);

    // Initialize connectivity
    _connectivity = Connectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      _updateConnectionStatus(result);
    });
    _checkInitialConnectivity();

    //animation
/*     _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    ); */
  }

  //animation
  /* void triggerAnimation() {
    setState(() {
      _showCoins = true;
    });

    _controller.forward(from: 0.0).then((_) {
      setState(() {
        _showCoins = false;
      });

      Future.delayed(Duration(seconds: 1), () {
        setState(() {});
      });
    });
  } */

  void triggerAnimation() {
    print("placeholder");
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
        print("isLoggedIn");
      });
      if (tokenExpired) {
        setState(() {
          _setAuthenticated(false);
          print("tokenExpired");
        });
      }
    } else {
      await _authService.setGuestToken();
      setState(() {
        _setAuthenticated(false);
        print("guestTokenSet");
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
      print("########");
      print(loggedIn);
      _loggedIn = loggedIn;
    });
  }

  bool isLoggedIn() {
    return _loggedIn ?? false;
  }

  bool isAuthenticated() {
    return _authenticated ?? false;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isSmallScreen = screenWidth < 360;

    double modalHeight;

    if (isSmallScreen) {
      modalHeight = 200;
    } else {
      modalHeight = 240;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        toolbarHeight: 80,
        title: Consumer<ProfileProvider>(
          builder: (context, profile, child) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Username Pill
              Neumorphic(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                style: NeumorphicStyle(
                  shape: NeumorphicShape.concave,
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(6)),
                  depth: 4,
                  lightSource: LightSource.topLeft,
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.blueGrey[700], size: 18),
                    SizedBox(width: 6),
                    Text(
                      profile.username,
                      style: TextStyle(
                        color: Colors.blueGrey[800],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Streak Pill
              Neumorphic(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                style: NeumorphicStyle(
                  shape: NeumorphicShape.concave,
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(6)),
                  depth: 4,
                  lightSource: LightSource.topLeft,
                ),
                child: Row(
                  children: [
                    Image.asset('assets/flame.png', width: 25, height: 25),
                    SizedBox(width: 6),
                    Text(
                      'Streak: ${profile.winStreak}',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // EXP Pill
              Neumorphic(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                style: NeumorphicStyle(
                  shape: NeumorphicShape.concave,
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(6)),
                  depth: 4,
                  lightSource: LightSource.topLeft,
                ),
                child: Row(
                  children: [
                    Image.asset('assets/crown.png', width: 25, height: 25),
                    SizedBox(width: 6),
                    Text(
                      'ELO: ${profile.elo}',
                      style: TextStyle(
                        color: Colors.amber[800],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: [
              Center(
                  child: StartPage(
                isLoggedIn: isLoggedIn,
                //onBackToMainMenu: triggerAnimation,
                onBackToMainMenu: triggerAnimation,
                setAuthenticated: _setAuthenticated,
                isAuthenticated: isAuthenticated,
              )),
              Center(child: LevelSelectionScreen()),
              SettingsPage(
                setAuthenticated: _setAuthenticated,
                isLoggedIn: isLoggedIn,
              ),
            ],
          ),

          // Flying Coins Animation
          //if (_showCoins) CoinsOverlay(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    // Calculate the width and height in actual pixels
    double widthInPixels = screenWidth * pixelRatio;
    double heightInPixels = screenHeight * pixelRatio;

    // Calculate the diagonal in pixels
    double diagonalPixels =
        sqrt(pow(widthInPixels, 2) + pow(heightInPixels, 2));

    // Convert the diagonal from pixels to inches
    double diagonalInches = diagonalPixels /
        pixelRatio /
        160; // 160 is typically used as the DPI baseline

    // A more reliable condition for detecting tablets
    bool isTablet =
        (diagonalInches >= 7.0 && (screenWidth / screenHeight) < 1.6);

    bool isSmallScreen = screenWidth < 360;

    double navHeight;

    if (isSmallScreen) {
      navHeight = 60;
    } else if (isTablet) {
      navHeight = 140;
    } else {
      navHeight = 90;
    }

    return SizedBox(
      height: navHeight,
      child: Column(
        children: [
          Container(
            height: 1,
            color: Colors.grey,
          ),
          Expanded(
              child: SalomonBottomBar(
            backgroundColor: Colors.grey[200],
            currentIndex: _currentIndex,
            onTap: (i) {
              setState(() {
                _currentIndex = i;
                _pageController.jumpToPage(i);
              });
            },
            items: [
              SalomonBottomBarItem(
                icon: NeumorphicIcon(
                  CupertinoIcons.gamecontroller,
                  size: MediaQuery.of(context).size.width * 0.08,
                  style: NeumorphicStyle(depth: 3, color: Colors.grey.shade600),
                ),
                title: Text(
                  "Multiplayer",
                  style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.035),
                ),
                selectedColor: Colors.blueGrey[700],
              ),
              SalomonBottomBarItem(
                icon: NeumorphicIcon(
                  CupertinoIcons.book,
                  size: MediaQuery.of(context).size.width * 0.08,
                  style: NeumorphicStyle(depth: 3, color: Colors.grey.shade600),
                ),
                title: Text(
                  "Solo Learning",
                  style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.035),
                ),
                selectedColor: Colors.blueGrey[700],
              ),
              SalomonBottomBarItem(
                icon: NeumorphicIcon(
                  CupertinoIcons.person,
                  size: MediaQuery.of(context).size.width * 0.08,
                  style: NeumorphicStyle(depth: 3, color: Colors.grey.shade600),
                ),
                title: Text(
                  "Profile",
                  style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.035),
                ),
                selectedColor: Colors.blueGrey[700],
              ),
            ],
          )),
        ],
      ),
    );
  }
}
