import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:get_it/get_it.dart';
import 'package:lingobattle/elements.dart';
import 'package:lingobattle/localization_service.dart';
import 'package:lingobattle/services.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';

import 'provider.dart';
import 'start.dart';
import 'auth.dart';
import 'level.dart';
import 'settings.dart';
import 'gameappbar.dart';
import 'user.dart';

final GetIt getIt = GetIt.instance;

void main() {
  getIt.registerLazySingleton<LocalizationService>(() => LocalizationService());
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.grey,
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor:
                MaterialStateProperty.all(Colors.black), // Make buttons white
          ),
        ),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        // Initialize LocalizationService after MaterialApp is built
        final appLocalizations = AppLocalizations.of(context);
        if (appLocalizations != null) {
          GetIt.I<LocalizationService>().initialize(appLocalizations);
        } else {
          print("AppLocalizations is null, unable to initialize.");
        }
        return child!;
      },
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
        print("main.dart");
        print("No auth token available.");
      }
    });
    Future.microtask(() =>
        Provider.of<ProfileProvider>(context, listen: false).loadPreferences());
    Future.microtask(() => Provider.of<LevelNotifier>(context, listen: false)
        .loadLevelsAfterStart());
    WidgetsBinding.instance.addObserver(this);

    // Initialize connectivity
    _connectivity = Connectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      _updateConnectionStatus(result);
    });
    _checkInitialConnectivity();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(seconds: 3), () {
        if (profileProvider.nativeLanguage.isEmpty) {
          _showNativeLanguageDialog();
        }
      });
    });
  }

  void _showNativeLanguageDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectYourNativeLanguage),
          content: StatefulBuilder(
            builder: (context, setState) {
              String? selectedLanguage;
              Map<String, String> flagAssets = {
                "English": "assets/flags/english.png",
                "German": "assets/flags/german.png",
                "Spanish": "assets/flags/spanish.png",
                "Dutch": "assets/flags/dutch.png",
              };

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedLanguage,
                    hint: Text(AppLocalizations.of(context)!.chooseALanguage),
                    isExpanded: true,
                    items: flagAssets.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Row(
                          children: [
                            Image.asset(
                              entry.value,
                              width: 24, // Adjust flag size
                              height: 24,
                            ),
                            SizedBox(width: 10),
                            Text(entry.key),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedLanguage = value;
                        });

                        final profileProvider = Provider.of<ProfileProvider>(
                          context,
                          listen: false,
                        );
                        profileProvider.setNativeLanguage(value);
                        Navigator.pop(context); // Close dialog
                      }
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

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
      print("correct else all that counts");
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
    return Scaffold(
      appBar: GameAppBar(
        onBackToMainMenu: triggerAnimation,
        isTablet: isTablet(context),
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
              Center(
                child: UserPage(
                  onBackToMainMenu: triggerAnimation,
                ),
              ),
              SettingsPage(
                setAuthenticated: _setAuthenticated,
                isLoggedIn: isLoggedIn,
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return SalomonBottomBar(
      backgroundColor: Colors.grey[200],
      currentIndex: _currentIndex,
      onTap: (i) {
        setState(() {
          _currentIndex = i;
          _pageController.jumpToPage(i);
        });
      },
      items: [
        _buildBottomBarItem(
          icon: Icons.gamepad,
          title: AppLocalizations.of(context)!.menu1,
          isTablet: isTablet,
        ),
        _buildBottomBarItem(
          icon: Icons.menu_book,
          title: AppLocalizations.of(context)!.menu2,
          isTablet: isTablet,
        ),
        _buildBottomBarItem(
          icon: Icons.person,
          title: AppLocalizations.of(context)!.menu3,
          isTablet: isTablet,
        ),
        _buildBottomBarItem(
          icon: Icons.settings,
          title: AppLocalizations.of(context)!.menu4,
          isTablet: isTablet,
        ),
      ],
    );
  }

  SalomonBottomBarItem _buildBottomBarItem({
    required IconData icon,
    required String title,
    required bool isTablet,
  }) {
    return SalomonBottomBarItem(
      icon: NeumorphicIcon(
        icon,
        size: isTablet ? 60 : 40, // Reduce icon size on tablets
        style: NeumorphicStyle(depth: 2, color: Colors.grey.shade400),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: isTablet
              ? 17
              : MediaQuery.of(context).size.width *
                  0.030, // Reduce font size on tablets
        ),
      ),
      selectedColor: Colors.blueGrey[700],
    );
  }
}
