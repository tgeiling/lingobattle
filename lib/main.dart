import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:lingobattle/elements.dart';
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

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool _isModalVisible = false;
  String modalDescription = "Declaring Description";
  int level = 0;
  bool isVideoPlayer = true;

  void _toggleModal(
      [String setDescription = "Was passt für dich ?",
      int setLevel = 0,
      bool setIsVideoPlayer = true]) {
    setState(() {
      _isModalVisible = !_isModalVisible;
      if (_isModalVisible) {
        modalDescription = setDescription;
        level = setLevel;
        isVideoPlayer = setIsVideoPlayer;
      }
    });

    isModalOpen = !isModalOpen;
  }

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
        title: Consumer<ProfileProvider>(
            builder: (context, profile, child) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: <Widget>[
                        Icon(Icons.stars, color: Colors.red),
                        SizedBox(width: 8),
                        Text(profile.username),
                      ],
                    ),
                    Row(
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
                  ],
                )),
        backgroundColor: Color.fromRGBO(245, 245, 245, 0.894),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (_isModalVisible) {
                _toggleModal();
              }
            },
            behavior: HitTestBehavior.opaque,
            child: PageView(
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
                        toggleModal: _toggleModal,
                        setAuthenticated: _setAuthenticated)),
                Center(child: LevelSelectionScreen(toggleModal: _toggleModal)),
                SettingsPage(
                  setAuthenticated: _setAuthenticated,
                  isLoggedIn: isLoggedIn,
                ),
              ],
            ),
          ),
          // Modal integration from the old scaffold
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _isModalVisible ? 0 : -450,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(230, 230, 230, 0.894),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: SizedBox(
                height: modalHeight,
                width: double.maxFinite,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    print("Inner pressed");
                  },
                  child: CustomBottomModal(
                    description: modalDescription,
                    levelId: level,
                    authenticated: isAuthenticated,
                    isVideoPlayer: isVideoPlayer,
                    toggleModal: _toggleModal,
                  ),
                ),
              ),
            ),
          ),
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
              backgroundColor: Colors.grey[100],
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
                  icon: NeumorphicIcon(
                    CupertinoIcons.home,
                    size: 40,
                    style:
                        NeumorphicStyle(depth: 2, color: Colors.grey.shade400),
                  ),
                  title: const Text("Play"),
                  selectedColor: Colors.grey[600],
                ),
                SalomonBottomBarItem(
                  icon: NeumorphicIcon(
                    CupertinoIcons.wand_stars_inverse,
                    size: 40,
                    style:
                        NeumorphicStyle(depth: 2, color: Colors.grey.shade400),
                  ),
                  title: const Text("Level"),
                  selectedColor: Colors.grey[600],
                ),
                SalomonBottomBarItem(
                  icon: NeumorphicIcon(
                    CupertinoIcons.gear,
                    size: 40,
                    style:
                        NeumorphicStyle(depth: 2, color: Colors.grey.shade400),
                  ),
                  title: const Text("Settings"),
                  selectedColor: Colors.grey[600],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
