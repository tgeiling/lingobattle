import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:lingobattle/elements.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stroke_text/stroke_text.dart';

import 'provider.dart';
import 'start.dart';
import 'services.dart';
import 'auth.dart';

bool isModalOpen = false;

class Level {
  final int id;
  final String description;
  final int minutes;
  final String reward;
  bool isDone;

  Level(
      {required this.id,
      required this.description,
      this.minutes = 15,
      this.reward = '',
      this.isDone = false});
}

class CustomBottomModal extends StatefulWidget {
  final String description;
  final int levelId;
  final bool Function() authenticated;
  final bool isVideoPlayer;
  final Function(String, int, bool) toggleModal;

  const CustomBottomModal({
    Key? key,
    required this.description,
    required this.levelId,
    required this.authenticated,
    required this.isVideoPlayer,
    required this.toggleModal,
  }) : super(key: key);

  @override
  _CustomBottomModalState createState() => _CustomBottomModalState();
}

class _CustomBottomModalState extends State<CustomBottomModal> {
  String selectedDifficulty = "Easy";
  String selectedType = "Speedrun";

  final List<String> difficulties = [
    "Easy",
    "Mid",
    "Hard",
    "Native",
    "Very Hard",
    "Very much Harder"
  ];

  final List<String> typeOptions = [
    "Speedrun",
    "Dictionary",
    "Wordchain",
    "Riddles"
  ];

  get http => null;

  Future<void> _initiateBattle() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchingOpponentScreen()),
    );

    final url = 'http://35.246.224.168/joinBattle';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': 'Player1', 'battleId': '12345'}),
    );

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
    var mediaQuery = MediaQuery.of(context);

    double screenWidth = mediaQuery.size.width;
    double screenHeight = mediaQuery.size.height;
    double pixelRatio = mediaQuery.devicePixelRatio;

    double widthInPixels = screenWidth * pixelRatio;
    double heightInPixels = screenHeight * pixelRatio;

    double diagonalPixels =
        sqrt(pow(widthInPixels, 2) + pow(heightInPixels, 2));

    double diagonalInches = diagonalPixels / pixelRatio / 160;

    bool isTablet =
        (diagonalInches >= 7.0 && (screenWidth / screenHeight) < 1.6);

    double modalPadding;
    double smallPressableVerticalPadding;
    double smallPressableHorizontalPadding;
    double bigPressableVerticalPadding;
    double aspectRatioItems;

    if (screenWidth < 360) {
      modalPadding = 8;
      smallPressableVerticalPadding = 0;
      smallPressableHorizontalPadding = 0;
      bigPressableVerticalPadding = 4;
      aspectRatioItems = 10;
    } else if (isTablet) {
      modalPadding = 24;
      smallPressableVerticalPadding = 0;
      smallPressableHorizontalPadding = 0;
      bigPressableVerticalPadding = 12;
      aspectRatioItems = 16;
    } else {
      modalPadding = 16;
      smallPressableVerticalPadding = 8;
      smallPressableHorizontalPadding = 12;
      bigPressableVerticalPadding = 14;
      aspectRatioItems = 8;
    }

    bool isDateSevenDaysAgo(String isoDateString) {
      DateTime parsedDate = DateTime.parse(isoDateString).toLocal();
      DateTime currentDate = DateTime.now().toLocal();
      DateTime sevenDaysAgo = currentDate.subtract(Duration(days: 7)).toLocal();

      return parsedDate.isBefore(sevenDaysAgo) ||
          parsedDate.isAtSameMomentAs(sevenDaysAgo);
    }

    final profilProvider = Provider.of<ProfileProvider>(context, listen: false);
    final bool readyForNextVideo = profilProvider.lastUpdateString == ""
        ? true
        : isDateSevenDaysAgo(profilProvider.lastUpdateString);

    //bool payedUp = profilProvider.payedSubscription == true ? true : false;

    return Padding(
      padding: EdgeInsets.all(modalPadding),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 1,
              crossAxisSpacing: 0,
              mainAxisSpacing: 10,
              childAspectRatio: aspectRatioItems / 1,
              children: <Widget>[
                PressableButton(
                  onPressed: () => showOptionDialogDifficulty(difficulties,
                      "Difficulty", (value) => selectedDifficulty = value),
                  padding: EdgeInsets.symmetric(
                      vertical: smallPressableVerticalPadding,
                      horizontal: smallPressableHorizontalPadding),
                  child: Center(
                    child: Text(
                      "Fokus: $selectedDifficulty",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
                PressableButton(
                  onPressed: () => showOptionDialogType(typeOptions,
                      "Choose Type", (value) => selectedType = value),
                  padding: EdgeInsets.symmetric(
                      vertical: smallPressableVerticalPadding,
                      horizontal: smallPressableHorizontalPadding),
                  child: Center(
                    child: Text(
                      "Ziel: $selectedType",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          /* PressableButton(
            onPressed: widget.authenticated && payedUp
                ? widget.isVideoPlayer
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoCombinerScreen(
                              levelId: widget.levelId,
                              levelNotifier: Provider.of<LevelNotifier>(context,
                                  listen: false),
                              profilProvider: Provider.of<ProfilProvider>(
                                  context,
                                  listen: false),
                              focus: selectedFocus,
                              goal: selectedGoal,
                              duration: selectedDuration,
                            ),
                          ),
                        );
                        widget.toggleModal;
                      }
                    : () {
                        downloadScreenKey.currentState!.combineAndDownloadVideo(
                            selectedFocus,
                            selectedGoal,
                            selectedDuration,
                            ProfilProvider().fitnessLevel);
                      }
                : readyForNextVideo
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoCombinerScreen(
                              levelId: widget.levelId,
                              levelNotifier: Provider.of<LevelNotifier>(context,
                                  listen: false),
                              profilProvider: Provider.of<ProfilProvider>(
                                  context,
                                  listen: false),
                              focus: selectedFocus,
                              goal: selectedGoal,
                              duration: selectedDuration,
                            ),
                          ),
                        );
                        widget.toggleModal;
                      }
                    : () async {
                        await _validateSubscriptionAndShowRestrictionDialog(profilProvider);
                      },
            padding: EdgeInsets.symmetric(
                vertical: bigPressableVerticalPadding, horizontal: 12),
            child: Center(
                child: Text(
              widget.isVideoPlayer ? "Jetzt starten" : "Video erstellen",
              style: Theme.of(context).textTheme.labelLarge,
            )),
          ), */
          PressableButton(
            onPressed: _initiateBattle,
            padding: EdgeInsets.symmetric(
                vertical: bigPressableVerticalPadding, horizontal: 12),
            child: Center(
                child: Text(
              widget.isVideoPlayer ? "Jetzt starten" : "Video erstellen",
              style: Theme.of(context).textTheme.labelLarge,
            )),
          ),
        ],
      ),
    );
  }

  /* Future<void> _validateSubscriptionAndShowRestrictionDialog(
      ProfilProvider profilProvider) async {
    bool isValid = false;

    if (Platform.isIOS && profilProvider.receiptData != null) {
      isValid = await validateAppleReceipt(profilProvider.receiptData!);
    } else if (Platform.isAndroid && profilProvider.receiptData != null) {
      isValid = await validateGoogleReceipt(profilProvider.receiptData!);
    }

    if (!isValid && profilProvider.receiptData != null) {
      profilProvider.setPayedSubscription(false);
      profilProvider.setSubType('');
      QuickAlert.show(
        backgroundColor: Colors.red.shade900,
        textColor: Colors.white,
        context: context,
        type: QuickAlertType.error,
        title: 'Abonnement ungültig',
        text: 'Ihr Abonnement wurde storniert oder ist ungültig.',
      );
    }

    showVideoRestrictionDialog(profilProvider.lastUpdateString);
  } */

  void showVideoRestrictionDialog(String lastUpdateString) {
    DateTime lastUpdateDate = DateTime.parse(lastUpdateString).toLocal();
    DateTime nextAvailableDate = lastUpdateDate.add(Duration(days: 7));

    int daysUntilNextVideo =
        nextAvailableDate.difference(DateTime.now()).inDays;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 243, 243, 243),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          title: Text(
            "Videoeinschränkung",
            style: Theme.of(context).textTheme.displayMedium,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                "Sie können nur ein Video pro Woche ansehen. Nächstes Video verfügbar in:",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$daysUntilNextVideo ',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'Tage',
                      style: TextStyle(
                        fontSize:
                            Theme.of(context).textTheme.displayLarge?.fontSize,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "OK",
                style: Theme.of(context).textTheme.displayMedium,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showOptionDialogDifficulty(List<String> options, String title,
      void Function(String) onSelected) async {
    String? selection = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 243, 243, 243),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options
                  .map((String option) => RadioListTile<String>(
                        activeColor: Colors.white,
                        title: Text(
                          option,
                          style: const TextStyle(color: Colors.white),
                        ),
                        value: option,
                        groupValue: selectedDifficulty,
                        onChanged: (String? value) {
                          if (value != null) {
                            Navigator.of(context).pop(value);
                          }
                        },
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );

    if (selection != null) {
      setState(() {
        onSelected(selection);
      });
    }
  }

  void showOptionDialogType(List<String> options, String title,
      void Function(String) onSelected) async {
    String? selection = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 243, 243, 243),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options
                  .map((String option) => RadioListTile<String>(
                        activeColor: Colors.white,
                        title: Text(
                          option,
                          style: const TextStyle(color: Colors.white),
                        ),
                        value: option,
                        groupValue: selectedType,
                        onChanged: (String? value) {
                          if (value != null) {
                            Navigator.of(context).pop(value);
                          }
                        },
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );

    if (selection != null) {
      setState(() {
        onSelected(selection);
      });
    }
  }
}

class LevelSelectionScreen extends StatefulWidget {
  final Function(String, int, bool) toggleModal;

  const LevelSelectionScreen({
    super.key,
    required this.toggleModal,
  });

  @override
  _LevelSelectionScreenState createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen>
    with AutomaticKeepAliveClientMixin<LevelSelectionScreen> {
  final ScrollController _scrollController = ScrollController();
  late Timer _timer;
  String _timeRemaining = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levelNotifier = Provider.of<LevelNotifier>(context);
    final levels = levelNotifier.levels;

    return Container(
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
        child: Stack(
          children: [
            ListView.builder(
              reverse: true,
              controller: _scrollController,
              itemCount: levels.length,
              itemBuilder: (context, index) {
                int levelId = levels.keys.toList()[index];
                Level level = levels[levelId]!;

                int group = index ~/ 5;
                int withinGroupIndex = index % 5;
                double screenWidth = MediaQuery.of(context).size.width;
                double curveIntensity = screenWidth / 2;

                double curvePadding;
                double startPadding = 0;
                double endPadding = 0;

                if (group % 2 == 0) {
                  startPadding =
                      curveIntensity * sin(withinGroupIndex * pi / 5);
                } else {
                  // Left curve (use endPadding)
                  endPadding = curveIntensity * sin(withinGroupIndex * pi / 5);
                }

                // Determine if this is the next level
                bool isNext = false;
                if (!level.isDone) {
                  int? maxDoneLevelId = levels.entries
                      .where((entry) => entry.value.isDone)
                      .map((entry) => entry.key)
                      .fold<int?>(
                          null,
                          (prev, element) => prev != null
                              ? (element > prev ? element : prev)
                              : element);

                  if (maxDoneLevelId == null) {
                    isNext = levelId == levels.keys.first;
                  } else {
                    if (levelId == maxDoneLevelId + 1) {
                      isNext = true;
                    }
                  }
                }

                return Padding(
                  padding:
                      EdgeInsets.only(left: startPadding, right: endPadding),
                  child: LevelCircle(
                    level: level.id,
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        widget.toggleModal(level.description, level.id, true);
                      });
                    },
                    isTreasureLevel: level.id % 4 == 0,
                    isDone: level.isDone,
                    isNext: isNext,
                  ),
                );
              },
            ),
            Positioned(
              top: 75,
              left: 15,
              child: GreenContainer(
                padding: const EdgeInsets.all(12.0), // Adjust padding if needed
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Level Reset: \n $_timeRemaining',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        OverlayEntry? overlayEntry;

                        overlayEntry = OverlayEntry(
                          builder: (context) => GestureDetector(
                            onTap: () {
                              overlayEntry?.remove();
                            },
                            child: Stack(
                              children: <Widget>[
                                Container(
                                  color: Colors.transparent,
                                ),
                                Positioned(
                                  top:
                                      MediaQuery.of(context).size.height * 0.08,
                                  left:
                                      MediaQuery.of(context).size.width * 0.45,
                                  child: SpeechBubble(
                                    message:
                                        ' Alle Level werden\n jeden Monat\n zurückgesetzt.\n Schau, wie weit\n du kommst!\n Du verlierst\n nicht deinen\n Gesamtfortschritt.',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        Overlay.of(context)?.insert(overlayEntry);
                      },
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 24, // Adjust size as needed
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 160,
              left: 15,
              child: Consumer<ProfileProvider>(
                builder: (context, profilProvider, child) {
                  int totalLevelsCompleted =
                      profilProvider.completedLevelsTotal;

                  return GreenContainer(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Level: $totalLevelsCompleted',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ));
  }

  @override
  bool get wantKeepAlive => true;
}

class LevelCircle extends StatelessWidget {
  final int level;
  final VoidCallback onTap;
  final bool isTreasureLevel;
  final bool isDone;
  final bool isNext;

  const LevelCircle({
    super.key,
    required this.level,
    required this.onTap,
    this.isTreasureLevel = false,
    this.isDone = false,
    this.isNext = false,
  });

  @override
  Widget build(BuildContext context) {
    String imageName;
    if (isDone) {
      imageName = 'assets/button_green.png';
    } else if (isNext) {
      imageName = 'assets/button_mint.png';
    } else {
      imageName = 'assets/button_locked.png';
    }

    double screenWidth = MediaQuery.of(context).size.width;
    bool isSmallScreen = screenWidth < 360;

    double levelNumberFontSize;
    double levelNumberFontPadding;
    double buttonDimension;
    double startFontSize;
    double startAbsoluteTopValue;

    if (isSmallScreen) {
      levelNumberFontSize = 28;
      levelNumberFontPadding = 10;
      buttonDimension = 70;
      startFontSize = 12;
      startAbsoluteTopValue = 50;
    } else {
      levelNumberFontSize = 36;
      buttonDimension = 100;
      levelNumberFontPadding = 15;
      startFontSize = 17;
      startAbsoluteTopValue = 65;
    }

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          if (isNext || isDone || isModalOpen) {
            onTap();
          }
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                width: buttonDimension,
                height: buttonDimension,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(imageName),
                    fit: BoxFit.contain,
                  ),
                ),
                child: Container(
                  padding:
                      EdgeInsets.only(right: 0, bottom: levelNumberFontPadding),
                  child: Center(
                    child: (isDone || isNext)
                        ? StrokeText(
                            text: "$level",
                            textStyle: TextStyle(
                                fontSize: levelNumberFontSize,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            strokeColor: Colors.black,
                            strokeWidth: 2,
                          )
                        : const SizedBox
                            .shrink(), // Empty widget if the conditions aren't met
                  ),
                )),
            if (isNext) ...[
              Positioned(
                top: 0,
                child: Container(
                  width: 105,
                  height: 105,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey,
                      width: 3.0,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: startAbsoluteTopValue,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    "START",
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: startFontSize,
                    ),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
