import 'dart:convert';
import 'dart:math';

import 'package:lingobattle/provider.dart';
import 'package:lingobattle/start.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'auth.dart';
import 'package:flutter/material.dart';

class PressableButton extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onPressed;
  final Color color;
  final Color shadowColor;

  const PressableButton({
    Key? key,
    required this.child,
    required this.padding,
    this.color = const Color.fromARGB(255, 243, 243, 243),
    this.shadowColor = const Color.fromARGB(255, 216, 216, 216),
    this.onPressed,
  }) : super(key: key);

  @override
  _PressableButtonState createState() => _PressableButtonState();
}

class _PressableButtonState extends State<PressableButton> {
  bool _isPressed = false;

  void _onPointerDown(PointerDownEvent event) {
    setState(() => _isPressed = true);
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() => _isPressed = false);
    if (widget.onPressed != null) {
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: widget.shadowColor,
                    offset: const Offset(0, 5),
                    blurRadius: 0,
                  ),
                ],
        ),
        transform: _isPressed
            ? Matrix4.translationValues(0, 5, 0)
            : Matrix4.translationValues(0, 0, 0),
        child: widget.child,
      ),
    );
  }
}

class GreyContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const GreyContainer({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(8.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            offset: const Offset(0, 5),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

class GreenContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const GreenContainer({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(8.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 243, 243, 243),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: const Color.fromARGB(255, 216, 216, 216),
            offset: Offset(0, 5),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

class ProgressBarWithPill extends StatefulWidget {
  final double initialProgress;

  const ProgressBarWithPill({Key? key, required this.initialProgress})
      : super(key: key);

  @override
  _ProgressBarWithPillState createState() => _ProgressBarWithPillState();
}

class _ProgressBarWithPillState extends State<ProgressBarWithPill> {
  late double progress;

  @override
  void initState() {
    super.initState();
    progress = widget.initialProgress;
  }

  void updateProgress(double newProgress) {
    setState(() {
      progress = newProgress.clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    double progressBarWidth = MediaQuery.of(context).size.width - 40;
    double pillWidth = progressBarWidth * progress * 0.8;
    double pillLeftOffset = (progressBarWidth * progress - pillWidth) / 2;

    return Stack(
      children: [
        ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF59c977)),
              minHeight: 20,
            )),
        Positioned(
          left: pillLeftOffset,
          top: (20 - 10) / 2,
          bottom: (20 - 4) / 2,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: pillWidth,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}

class NoConnectionWidget extends StatelessWidget {
  final VoidCallback onDismiss;

  const NoConnectionWidget({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Align(
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Keine Internetverbindung',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4.0),
              Text(
                'Bitte stellen sie eine Verbindung her',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Positioned(
          top: -10,
          right: -10,
          child: GestureDetector(
            onTap: onDismiss,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.grey[800],
                size: 20.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AuthenticateWidget extends StatelessWidget {
  final VoidCallback onDismiss;
  final Function(bool) setAuthenticated;
  final VoidCallback setQuestionnairDone;

  const AuthenticateWidget({
    super.key,
    required this.onDismiss,
    required this.setAuthenticated,
    required this.setQuestionnairDone,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(
                    setAuthenticated: setAuthenticated,
                  ),
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bitte über Login anmelden',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Sie müssen sich anmelden, um fortzufahren.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -10,
          right: -10,
          child: GestureDetector(
            onTap: onDismiss,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.grey[800],
                size: 20.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DismissButton extends StatelessWidget {
  final VoidCallback onPressed;

  const DismissButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.grey[800],
                size: 20.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SpeechBubble extends StatelessWidget {
  final String message;

  const SpeechBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      // Added Material widget
      color: Colors.transparent, // Make sure the background remains transparent
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main bubble
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Triangle (pointer)
          Positioned(
            left: -10,
            top: 15,
            child: CustomPaint(
              painter: TrianglePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    var path = Path();
    // Start from the right point of the triangle
    path.moveTo(10, 0); // Start at the top-right corner
    // Draw a line to the left point
    path.lineTo(0, 5); // This is the tip of the triangle pointing left
    // Draw a line to the bottom-right corner
    path.lineTo(10, 10);
    // Close the path to form the triangle
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
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

  Future<void> _initiateBattle() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchingOpponentScreen()),
    );

    // Call the backend to join the battle
    final url =
        'http://35.246.224.168/joinBattle'; // Change with your backend IP/Port
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': 'Player1', 'battleId': '12345'}),
      );

      if (response.statusCode == 200) {
        final battleData = jsonDecode(response.body);
        // You can navigate to your battle screen here.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BattleScreen(battleData: battleData),
          ),
        );
      } else {
        // Handle failure - perhaps the battle couldn't start
        _showErrorDialog('Failed to start battle. Please try again.');
      }
    } catch (e) {
      // Handle any network or other errors
      _showErrorDialog('An error occurred: $e');
    }
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

void showCustomDialog({
  required BuildContext context,
  required String modalDescription,
  required int levelId,
}) {
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

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            title: Text(
              "Level $levelId: $modalDescription",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                // Difficulty Dropdown
                DropdownButtonFormField<String>(
                  value: selectedDifficulty,
                  decoration: InputDecoration(
                    labelText: "Select Difficulty",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: difficulties.map((difficulty) {
                    return DropdownMenuItem<String>(
                      value: difficulty,
                      child: Text(difficulty),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDifficulty = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Type Dropdown
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: "Choose Type",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: typeOptions.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Handle your "Start" logic here
                  print(
                      "Starting with Difficulty: $selectedDifficulty, Type: $selectedType, Level: $levelId");
                },
                child: Text("Start"),
              ),
            ],
          );
        },
      );
    },
  );
}
