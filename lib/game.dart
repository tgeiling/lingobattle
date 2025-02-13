import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lingobattle/services.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:google_fonts/google_fonts.dart';

import 'level.dart';
import 'provider.dart';
import 'questionpool.dart';

class GameScreen extends StatefulWidget {
  final Level level;
  final String language;

  const GameScreen({
    Key? key,
    required this.level,
    required this.language,
  }) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  int currentWordIndex = 0;
  late List<MultiplayerQuestion> questions;
  late List<String> questionResults;
  late TextEditingController _textInputController;
  late List<String> _letterBoxes;
  late List<String?> _currentSentenceInputs;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textInputController = TextEditingController();
    _focusNode = FocusNode();

    questions = (widget.level.questions as List<dynamic>)
        .map((questionData) => MultiplayerQuestion(
              question: questionData['question'] as String,
              answers: List<String>.from(questionData['answers'] as List),
            ))
        .toList();

    // Fetch the question pool for the selected language
    questionResults = List<String>.filled(questions.length, "unanswered");
    _textInputController = TextEditingController();

    _initializeWordHandling();

    _focusNode = FocusNode();
  }

  void _initializeWordHandling() {
    _currentSentenceInputs = List<String?>.filled(
      questions[currentQuestionIndex].answers.length,
      null,
    );
    _updateLetterBoxesForCurrentWord();
  }

  void _updateLetterBoxesForCurrentWord() {
    if (currentWordIndex >= 0 &&
        currentWordIndex < questions[currentQuestionIndex].answers.length) {
      final wordLength =
          questions[currentQuestionIndex].answers[currentWordIndex].length;
      _letterBoxes = List.filled(wordLength, "");
      _textInputController.text =
          _currentSentenceInputs[currentWordIndex] ?? "";
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textInputController.dispose();
    super.dispose();
  }

  void _handleInput(String value) {
    setState(() {
      final input = value.split('');
      for (int i = 0; i < _letterBoxes.length; i++) {
        _letterBoxes[i] = i < input.length ? input[i] : "";
      }
      _currentSentenceInputs[currentWordIndex] = value.trim();
    });
  }

  void _nextWord() {
    if (currentWordIndex < questions[currentQuestionIndex].answers.length - 1) {
      setState(() {
        _currentSentenceInputs[currentWordIndex] =
            _textInputController.text.trim();
        currentWordIndex++;
        _textInputController.clear();
        _updateLetterBoxesForCurrentWord();
      });
    } else {
      _submitAnswer();
    }
  }

  void _previousWord() {
    if (currentWordIndex > 0) {
      setState(() {
        _currentSentenceInputs[currentWordIndex] =
            _textInputController.text.trim();
        currentWordIndex--;
        _textInputController.clear();
        _updateLetterBoxesForCurrentWord();
      });
    }
  }

  void _submitAnswer() {
    setState(() {
      List<String> acceptableAnswers = questions[currentQuestionIndex].answers;
      String userAnswer = _currentSentenceInputs.join(" ").trim().toLowerCase();

      if (acceptableAnswers
          .any((answer) => answer.toLowerCase() == userAnswer)) {
        questionResults[currentQuestionIndex] = "correct";
        correctAnswers++;
      } else {
        questionResults[currentQuestionIndex] = "incorrect";
      }

      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
        currentWordIndex = 0;
        _initializeWordHandling();
      } else {
        Provider.of<LevelNotifier>(context, listen: false)
            .updateLevelStatus(widget.language, widget.level.id);
        _showCompletionDialog();
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Game Over"),
        content:
            Text("You got $correctAnswers out of ${questions.length} correct!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor:
              Colors.white, // Neutral background for neumorphic effect
          elevation: 4,
          centerTitle: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Neumorphic(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    style: NeumorphicStyle(
                      shape: NeumorphicShape.concave,
                      boxShape: NeumorphicBoxShape.roundRect(
                        BorderRadius.circular(12),
                      ),
                      depth: 8,
                      lightSource: LightSource.topLeft,
                      color: Colors.grey[200],
                    ),
                    child: Row(
                      children: List.generate(
                        questions.length,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            Icons.circle,
                            size: 8,
                            color: questionResults[index] == "unanswered"
                                ? Colors.black
                                : questionResults[index] == "correct"
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // Flag on the right
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Image.asset(
                'assets/flags/${widget.language.toLowerCase()}.png', // Flag image
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 15),
              Neumorphic(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                style: NeumorphicStyle(
                  shape: NeumorphicShape.concave, // Inward shadow effect
                  boxShape: NeumorphicBoxShape.roundRect(
                    BorderRadius.circular(16),
                  ),
                  depth: -4, // Negative depth for a concave look
                  lightSource: LightSource.topRight, // Light source direction
                  color: Colors.grey[200], // Subtle background color
                ),
                child: Container(
                  width:
                      MediaQuery.of(context).size.width * 0.75, // Dynamic width
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children:
                        _buildSentenceWithGap(questions[currentQuestionIndex]),
                  ),
                ),
              ),
              SizedBox(height: 20),
              if (questions[currentQuestionIndex].answers.length > 1)
                Text(
                    "${currentWordIndex + 1}/${questions[currentQuestionIndex].answers.length}"),
              GestureDetector(
                onTap: () {
                  if (!_focusNode.hasFocus) {
                    _focusNode.requestFocus();
                  }
                  Future.delayed(Duration.zero, () {
                    _textInputController.selection = TextSelection.collapsed(
                      offset: _textInputController.text.length,
                    );
                  });
                },
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double maxWidth = constraints.maxWidth;

                      // Define base dimensions
                      const double maxBoxWidth = 55; // Default box width
                      const double maxBoxHeight = 65; // Default box height
                      const double minBoxWidth = 25; // Minimum box width
                      const double minBoxHeight = 35; // Minimum box height
                      const double defaultSpacing =
                          12; // Normal spacing between boxes

                      // Total number of boxes
                      int totalBoxes = _letterBoxes.length;

                      // Initialize box size and spacing
                      double boxWidth = maxBoxWidth;
                      double boxHeight = maxBoxHeight;
                      double spacing = defaultSpacing;

                      // Handle dynamic resizing when boxes > 6
                      if (totalBoxes > 6) {
                        double totalSpacing = defaultSpacing * (totalBoxes - 1);
                        boxWidth = (maxWidth - totalSpacing) / totalBoxes;
                        boxWidth = boxWidth.clamp(minBoxWidth, maxBoxWidth);
                        boxHeight = boxWidth * 1.2;
                        spacing = (maxWidth - (boxWidth * totalBoxes)) /
                            (totalBoxes - 1);
                      } else if (totalBoxes == 6) {
                        // Special case for 6 boxes: Adjust to perfectly fit without stretching
                        double totalSpacing =
                            defaultSpacing * 5; // 6 boxes = 5 spacings
                        boxWidth = (maxWidth - totalSpacing) / 7;
                        boxWidth = boxWidth.clamp(minBoxWidth, maxBoxWidth);
                        boxHeight = boxWidth * 1.2;
                        spacing = defaultSpacing;
                      } else if (totalBoxes == 5) {
                        // Special case for 5 boxes: Adjust to perfectly fit without stretching
                        double totalSpacing =
                            defaultSpacing * 5; // 6 boxes = 5 spacings
                        boxWidth = (maxWidth - totalSpacing) / 8;
                        boxWidth = boxWidth.clamp(minBoxWidth, maxBoxWidth);
                        boxHeight = boxWidth * 1.2;
                        spacing = defaultSpacing;
                      }

                      // Generate the letter boxes
                      List<Widget> letterBoxes = List.generate(
                        _letterBoxes.length,
                        (index) => Neumorphic(
                          style: NeumorphicStyle(
                            depth: -2,
                            boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(4),
                            ),
                          ),
                          child: SizedBox(
                            width: boxWidth,
                            height: boxHeight,
                            child: Center(
                              child: Text(
                                _letterBoxes[index],
                                style: GoogleFonts.pressStart2p(
                                  fontSize: boxWidth * 0.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );

                      // Single row with dynamic scaling and centering
                      return Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center, // Center align the row
                        children: [
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: spacing,
                            children: letterBoxes,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Opacity(
                opacity: 0,
                child: TextField(
                  controller: _textInputController,
                  focusNode: _focusNode, // Attach the focus node here
                  onChanged: _handleInput,
                  autofocus: true,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Placeholder for Back button when it's not visible
                  if (currentWordIndex > 0)
                    NeumorphicButton(
                      onPressed: _previousWord,
                      style: NeumorphicStyle(
                        depth: 4,
                        intensity: 0.8,
                        shape: NeumorphicShape.convex,
                        boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(12),
                        ),
                        color: Colors.grey[200],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_back,
                            color: Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Back to Last Word",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width:
                          160, // Match the width of the "Back to Last Word" button
                    ),
                  const SizedBox(width: 16), // Space between buttons
                  NeumorphicButton(
                    onPressed: _nextWord,
                    style: NeumorphicStyle(
                      depth: 4,
                      intensity: 0.8,
                      shape: NeumorphicShape.convex,
                      boxShape: NeumorphicBoxShape.roundRect(
                        BorderRadius.circular(12),
                      ),
                      color: Colors.grey[200],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentWordIndex <
                                  questions[currentQuestionIndex]
                                          .answers
                                          .length -
                                      1
                              ? "Next Word"
                              : "Submit Answer",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          currentWordIndex <
                                  questions[currentQuestionIndex]
                                          .answers
                                          .length -
                                      1
                              ? Icons.arrow_forward
                              : Icons.check,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 50)
            ],
          ),
        ));
  }

  List<Widget> _buildSentenceWithGap(MultiplayerQuestion question) {
    List<String> parts = question.question.split("_____");
    List<Widget> widgets = [];
    for (int i = 0; i < parts.length; i++) {
      widgets.add(Text(
        parts[i],
        style: const TextStyle(fontSize: 18, color: Colors.black),
      ));
      if (i < parts.length - 1) {
        widgets.add(
          SizedBox(
            width: 80,
            child: Neumorphic(
              style: NeumorphicStyle(
                depth: -2,
                boxShape:
                    NeumorphicBoxShape.roundRect(BorderRadius.circular(4)),
              ),
              child: Center(
                child: Text(
                  _currentSentenceInputs[i] ?? "",
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}

class MultiplayerGameScreen extends StatefulWidget {
  final IO.Socket socket;
  final String username;
  final String opponentUsername;
  final String matchId;
  final String language;
  final VoidCallback onBackToMainMenu;

  const MultiplayerGameScreen(
      {Key? key,
      required this.socket,
      required this.username,
      required this.opponentUsername,
      required this.matchId,
      required this.language,
      required this.onBackToMainMenu})
      : super(key: key);

  @override
  _MultiplayerGameScreenState createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  int currentWordIndex = 0;
  late List<MultiplayerQuestion> questions;
  late List<String> questionResults;
  late List<String> opponentProgress;
  late TextEditingController _textInputController;
  late List<String> _letterBoxes;
  late List<String?> _currentSentenceInputs;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textInputController = TextEditingController();
    _focusNode = FocusNode();

    // Fetch the question pool for the selected language
    List<MultiplayerQuestion> questionPool =
        MultiplayerQuestionsPool.questionsByLanguage[widget.language]!;

    int seed = widget.matchId.hashCode;

    Random random = Random(seed);

    questionPool.shuffle(random);
    questions = questionPool.take(5).toList();
    questionResults = List<String>.filled(questions.length, "unanswered");
    opponentProgress = List<String>.filled(questions.length, "unanswered");
    _textInputController = TextEditingController();

    _initializeWordHandling();

    _focusNode = FocusNode();

    widget.socket.on('progressUpdate', _onProgressUpdate);
    widget.socket.on('battleEnded', _onBattleEnded);
  }

  void _initializeWordHandling() {
    _currentSentenceInputs = List<String?>.filled(
      questions[currentQuestionIndex].answers.length,
      null,
    );
    _updateLetterBoxesForCurrentWord();
  }

  void _updateLetterBoxesForCurrentWord() {
    if (currentWordIndex >= 0 &&
        currentWordIndex < questions[currentQuestionIndex].answers.length) {
      final wordLength =
          questions[currentQuestionIndex].answers[currentWordIndex].length;
      _letterBoxes = List.filled(wordLength, "");
      _textInputController.text =
          _currentSentenceInputs[currentWordIndex] ?? "";
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.socket.off('progressUpdate', _onProgressUpdate);
    widget.socket.off('battleEnded', _onBattleEnded);
    _textInputController.dispose();
    super.dispose();
  }

  void _onProgressUpdate(data) {
    setState(() {
      try {
        int questionIndex = data['questionIndex'];
        String progressStatus = data['status'];

        if (questionIndex >= 0 && questionIndex < opponentProgress.length) {
          opponentProgress[questionIndex] = progressStatus;
        }
      } catch (e) {
        print('Error in progressUpdate handler: $e');
      }
    });
  }

  void _onBattleEnded(data) {
    try {
      final String message = data['message'] ?? 'The battle has ended.';
      final result = data['result'];

      if (result == 'opponentDisconnected' || result == 'playerLeft') {
        // Handle both opponent disconnect and player leaving
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MultiplayerResultScreen(
              results: {
                'message': message,
                'result': result == 'playerLeft'
                    ? 'winByOpponentLeft'
                    : 'winByDisconnect',
                'player1': {
                  'username': widget.username,
                  'correctAnswers': correctAnswers,
                  'progress': questionResults,
                },
                'player2': {
                  'username': widget.opponentUsername,
                  'correctAnswers': 0,
                  'progress':
                      List<String>.filled(questionResults.length, 'unanswered'),
                },
                'winner': widget.username,
              },
              language: widget.language,
              onBackToMainMenu: widget.onBackToMainMenu,
            ),
          ),
        );
      } else if (result is Map<String, dynamic>) {
        // Handle normal battle results
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MultiplayerResultScreen(
              results: {
                'message': message,
                ...result,
              },
              language: widget.language,
              onBackToMainMenu: widget.onBackToMainMenu,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error handling battleEnded event: $e');
    }
  }

  void _handleInput(String value) {
    setState(() {
      final input = value.split('');
      for (int i = 0; i < _letterBoxes.length; i++) {
        _letterBoxes[i] = i < input.length ? input[i] : "";
      }
      _currentSentenceInputs[currentWordIndex] = value.trim();
    });
  }

  void _nextWord() {
    if (currentWordIndex < questions[currentQuestionIndex].answers.length - 1) {
      setState(() {
        _currentSentenceInputs[currentWordIndex] =
            _textInputController.text.trim();
        currentWordIndex++;
        _textInputController.clear();
        _updateLetterBoxesForCurrentWord();
      });
    } else {
      submitAnswer();
    }
  }

  void _previousWord() {
    if (currentWordIndex > 0) {
      setState(() {
        _currentSentenceInputs[currentWordIndex] =
            _textInputController.text.trim();
        currentWordIndex--;
        _textInputController.clear();
        _updateLetterBoxesForCurrentWord();
      });
    }
  }

  void submitAnswer() {
    setState(() {
      // Combine all entered words into a single string
      final typedAnswer = _currentSentenceInputs.join(" ").trim();
      final correctAnswer =
          questions[currentQuestionIndex].answers.join(" ").trim();

      // Check if the typed answer matches the correct answer
      bool isCorrect = typedAnswer.toLowerCase() == correctAnswer.toLowerCase();
      questionResults[currentQuestionIndex] = isCorrect ? "correct" : "wrong";
      correctAnswers =
          questionResults.where((result) => result == "correct").length;

      // Emit the answer progress to the server
      widget.socket.emit('submitAnswer', {
        'matchId': widget.matchId,
        'username': widget.username,
        'questionIndex': currentQuestionIndex,
        'status': questionResults[currentQuestionIndex],
      });

      // Reset UI for the next question or end the game
      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
        currentWordIndex = 0; // Reset to the first word
        _textInputController.clear(); // Clear input
        _initializeWordHandling(); // Reset sentence inputs and boxes
      } else {
        _sendResultsToServer(); // End the game and send results
      }
    });
  }

  void _sendResultsToServer() {
    widget.socket.emit('submitResults', {
      'matchId': widget.matchId,
      'username': widget.username,
      'correctAnswers': correctAnswers,
      'language': widget.language,
      'progress': questionResults,
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          // Show confirmation dialog
          final shouldLeave = await _showLeaveConfirmationDialog(context);
          if (shouldLeave) {
            // Emit "playerLeft" event to the server
          }

          return shouldLeave;
        },
        child: Scaffold(
            appBar: AppBar(
              backgroundColor:
                  Colors.white, // Neutral background for neumorphic effect
              elevation: 4,
              centerTitle: false,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Opponent's row: name and progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Opponent's name
                      Text(
                        widget.opponentUsername,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8), // Space between name and dots
                      // Opponent's progress
                      Neumorphic(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        style: NeumorphicStyle(
                          shape: NeumorphicShape.concave,
                          boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(12),
                          ),
                          depth: 8,
                          lightSource: LightSource.topLeft,
                          color: Colors.grey[200],
                        ),
                        child: Row(
                          children: List.generate(
                            questions.length,
                            (index) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Icon(
                                Icons.circle,
                                size: 8,
                                color: opponentProgress[index] == "unanswered"
                                    ? Colors.black
                                    : opponentProgress[index] == "correct"
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                      height: 4), // Space between opponent and player rows
                  // Player's row: name and progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Player's name
                      Text(
                        widget.username,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8), // Space between name and dots
                      // Player's progress
                      Neumorphic(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        style: NeumorphicStyle(
                          shape: NeumorphicShape.concave,
                          boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(12),
                          ),
                          depth: 8,
                          lightSource: LightSource.topLeft,
                          color: Colors.grey[200],
                        ),
                        child: Row(
                          children: List.generate(
                            questions.length,
                            (index) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Icon(
                                Icons.circle,
                                size: 8,
                                color: questionResults[index] == "unanswered"
                                    ? Colors.black
                                    : questionResults[index] == "correct"
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                // Flag on the right
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Image.asset(
                    'assets/flags/${widget.language.toLowerCase()}.png', // Flag image
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            resizeToAvoidBottomInset: true,
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 15),
                  Neumorphic(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                    style: NeumorphicStyle(
                      shape: NeumorphicShape.concave, // Inward shadow effect
                      boxShape: NeumorphicBoxShape.roundRect(
                        BorderRadius.circular(16),
                      ),
                      depth: -4, // Negative depth for a concave look
                      lightSource:
                          LightSource.topRight, // Light source direction
                      color: Colors.grey[200], // Subtle background color
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width *
                          0.75, // Dynamic width
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: _buildSentenceWithGap(
                            questions[currentQuestionIndex]),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (questions[currentQuestionIndex].answers.length > 1)
                    Text(
                        "${currentWordIndex + 1}/${questions[currentQuestionIndex].answers.length}"),
                  GestureDetector(
                    onTap: () {
                      if (!_focusNode.hasFocus) {
                        _focusNode.requestFocus();
                      }
                      Future.delayed(Duration.zero, () {
                        _textInputController.selection =
                            TextSelection.collapsed(
                          offset: _textInputController.text.length,
                        );
                      });
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double maxWidth = constraints.maxWidth;

                          // Define base dimensions
                          const double maxBoxWidth = 55; // Default box width
                          const double maxBoxHeight = 65; // Default box height
                          const double minBoxWidth = 25; // Minimum box width
                          const double minBoxHeight = 35; // Minimum box height
                          const double defaultSpacing =
                              12; // Normal spacing between boxes

                          // Total number of boxes
                          int totalBoxes = _letterBoxes.length;

                          // Initialize box size and spacing
                          double boxWidth = maxBoxWidth;
                          double boxHeight = maxBoxHeight;
                          double spacing = defaultSpacing;

                          // Handle dynamic resizing when boxes > 6
                          if (totalBoxes > 6) {
                            double totalSpacing =
                                defaultSpacing * (totalBoxes - 1);
                            boxWidth = (maxWidth - totalSpacing) / totalBoxes;
                            boxWidth = boxWidth.clamp(minBoxWidth, maxBoxWidth);
                            boxHeight = boxWidth * 1.2;
                            spacing = (maxWidth - (boxWidth * totalBoxes)) /
                                (totalBoxes - 1);
                          } else if (totalBoxes == 6) {
                            // Special case for 6 boxes: Adjust to perfectly fit without stretching
                            double totalSpacing =
                                defaultSpacing * 5; // 6 boxes = 5 spacings
                            boxWidth = (maxWidth - totalSpacing) / 6.5;
                            boxWidth = boxWidth.clamp(minBoxWidth, maxBoxWidth);
                            boxHeight = boxWidth * 1.2;
                            spacing = defaultSpacing;
                          } else if (totalBoxes == 5) {
                            // Special case for 5 boxes: Adjust to perfectly fit without stretching
                            double totalSpacing =
                                defaultSpacing * 5; // 6 boxes = 5 spacings
                            boxWidth = (maxWidth - totalSpacing) / 5;
                            boxWidth = boxWidth.clamp(minBoxWidth, maxBoxWidth);
                            boxHeight = boxWidth * 1.2;
                            spacing = defaultSpacing;
                          }

                          // Generate the letter boxes
                          List<Widget> letterBoxes = List.generate(
                            _letterBoxes.length,
                            (index) => Neumorphic(
                              style: NeumorphicStyle(
                                depth: -2,
                                boxShape: NeumorphicBoxShape.roundRect(
                                  BorderRadius.circular(4),
                                ),
                              ),
                              child: SizedBox(
                                width: boxWidth,
                                height: boxHeight,
                                child: Center(
                                  child: Text(
                                    _letterBoxes[index],
                                    style: GoogleFonts.pressStart2p(
                                      fontSize: boxWidth * 0.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );

                          // Single row with dynamic scaling and centering
                          return Row(
                            mainAxisAlignment: MainAxisAlignment
                                .center, // Center align the row
                            children: [
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: spacing,
                                children: letterBoxes,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _textInputController,
                      focusNode: _focusNode, // Attach the focus node here
                      onChanged: _handleInput,
                      autofocus: true,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Placeholder for Back button when it's not visible
                      if (currentWordIndex > 0)
                        NeumorphicButton(
                          onPressed: _previousWord,
                          style: NeumorphicStyle(
                            depth: 4,
                            intensity: 0.8,
                            shape: NeumorphicShape.convex,
                            boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(12),
                            ),
                            color: Colors.grey[200],
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.arrow_back,
                                color: Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Back to Last Word",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          width:
                              160, // Match the width of the "Back to Last Word" button
                        ),
                      const SizedBox(width: 16), // Space between buttons
                      NeumorphicButton(
                        onPressed: _nextWord,
                        style: NeumorphicStyle(
                          depth: 4,
                          intensity: 0.8,
                          shape: NeumorphicShape.convex,
                          boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(12),
                          ),
                          color: Colors.grey[200],
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentWordIndex <
                                      questions[currentQuestionIndex]
                                              .answers
                                              .length -
                                          1
                                  ? "Next Word"
                                  : "Submit Answer",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              currentWordIndex <
                                      questions[currentQuestionIndex]
                                              .answers
                                              .length -
                                          1
                                  ? Icons.arrow_forward
                                  : Icons.check,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 50)
                ],
              ),
            )));
  }

  List<Widget> _buildSentenceWithGap(MultiplayerQuestion question) {
    List<String> parts = question.question.split("_____");
    List<Widget> widgets = [];
    for (int i = 0; i < parts.length; i++) {
      widgets.add(Text(
        parts[i],
        style: const TextStyle(fontSize: 18, color: Colors.black),
      ));
      if (i < parts.length - 1) {
        widgets.add(
          SizedBox(
            width: 80,
            child: Neumorphic(
              style: NeumorphicStyle(
                depth: -2,
                boxShape:
                    NeumorphicBoxShape.roundRect(BorderRadius.circular(4)),
              ),
              child: Center(
                child: Text(
                  _currentSentenceInputs[i] ?? "",
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Future<bool> _showLeaveConfirmationDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Leave Game"),
            content: const Text(
                "Are you sure you want to leave the game? This will count as a loss."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  widget.socket.emit('playerLeft', {
                    'matchId': widget.matchId,
                    'username': widget.username,
                  });

                  // Navigate to the match result screen with a loss
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MultiplayerResultScreen(
                        results: {
                          'message': 'You left the game.',
                          'result': 'lossByLeave',
                          'player1': {
                            'username': widget.username,
                            'correctAnswers': correctAnswers,
                            'progress': questionResults,
                          },
                          'player2': {
                            'username': widget.opponentUsername,
                            'correctAnswers':
                                0, // You can adjust this if needed
                            'progress': List<String>.filled(
                                questionResults.length,
                                'unanswered'), // Placeholder
                          },
                          'winner': widget.opponentUsername,
                        },
                        language: widget.language,
                        onBackToMainMenu: widget.onBackToMainMenu,
                      ),
                    ),
                  );
                },
                child: const Text("Leave"),
              ),
            ],
          ),
        ) ??
        false; // Return false if the dialog is dismissed
  }
}

class MultiplayerResultScreen extends StatelessWidget {
  final Map<String, dynamic> results;
  final String language;
  final VoidCallback onBackToMainMenu;

  const MultiplayerResultScreen({
    Key? key,
    required this.results,
    required this.language,
    required this.onBackToMainMenu,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Safely access data
    final player1 = results['player1'] ?? {};
    final player2 = results['player2'] ?? {};
    final winner = results['winner'] ?? "Draw";
    final message = results['message'] ?? "Match concluded";

    return Scaffold(
      appBar: AppBar(title: const Text("Match Results")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display the result message
            Text(
              message,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Winner Information
            Text(
              "Winner: ${winner}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Progress Visualization for both players
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Player 1 progress
                Column(
                  children: [
                    Text(
                      "Player 1: ${player1['username'] ?? 'Unknown'}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      children: List.generate(
                        (player1['progress'] ?? []).length,
                        (index) => Icon(
                          Icons.circle,
                          color: player1['progress'][index] == "correct"
                              ? Colors.green
                              : player1['progress'][index] == "wrong"
                                  ? Colors.red
                                  : Colors.black,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Score: ${player1['correctAnswers'] ?? 0}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                // Player 2 progress
                Column(
                  children: [
                    Text(
                      "Player 2: ${player2['username'] ?? 'Unknown'}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      children: List.generate(
                        (player2['progress'] ?? []).length,
                        (index) => Icon(
                          Icons.circle,
                          color: player2['progress'][index] == "correct"
                              ? Colors.green
                              : player2['progress'][index] == "wrong"
                                  ? Colors.red
                                  : Colors.black,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Score: ${player2['correctAnswers'] ?? 0}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                final profileProvider =
                    Provider.of<ProfileProvider>(context, listen: false);

                getAuthToken().then((token) {
                  if (token != null) {
                    profileProvider.syncProfile(token);
                  } else {
                    print("No auth token available.");
                  }
                });
                Navigator.popUntil(context, (route) => route.isFirst);
                onBackToMainMenu();
              },
              child: const Text("Back to Main Menu"),
            )
          ],
        ),
      ),
    );
  }
}

void initializeSocket(BuildContext context, IO.Socket socket, String language,
    VoidCallback onBackToMainMenu) {
  socket.onConnect((_) {
    print('Connected to the server');
    socket.emit('joinQueue', {
      'username': Provider.of<ProfileProvider>(context, listen: false).username,
      'language': language,
    });
  });

  /* socket.on('matchFound', (data) {
    print('Match found: $data');
    // Navigate to searching screen if desired
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SearchingOpponentScreen(
          socket: socket,
          username: data['username'],
          language: data['language'],
          onBackToMainMenu: onBackToMainMenu,
        ),
      ),
    );
  }); */

  // Listen for battleStart event
  socket.on('battleStart', (data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BattleStartScreen(
          username: data['username'],
          opponentUsername: data['opponentUsername'],
          elo: data['elo'],
          opponentElo: data['opponentElo'],
          onBattleStart: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MultiplayerGameScreen(
                  username: data['username'],
                  opponentUsername: data['opponentUsername'],
                  matchId: data['matchId'],
                  language: data['language'],
                  socket: socket,
                  onBackToMainMenu: onBackToMainMenu,
                ),
              ),
            );
          },
        ),
      ),
    );
  });

  socket.onDisconnect((_) {
    print('Disconnected from the server');
  });

  if (!socket.connected) {
    socket.connect();
  }
}

class BattleScreen extends StatelessWidget {
  final dynamic battleData;

  const BattleScreen({Key? key, required this.battleData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Battle - ${battleData['matchId']}"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Match ID: ${battleData['matchId']}"),
            Text("Opponent: ${battleData['opponent']}"),
            Text("Language: ${battleData['language']}"),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text("Back to Home"),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchingOpponentScreen extends StatefulWidget {
  final IO.Socket socket;
  final String username;
  final String language;
  final VoidCallback onBackToMainMenu;

  const SearchingOpponentScreen({
    Key? key,
    required this.socket,
    required this.username,
    required this.language,
    required this.onBackToMainMenu,
  }) : super(key: key);

  @override
  _SearchingOpponentScreenState createState() =>
      _SearchingOpponentScreenState();
}

class _SearchingOpponentScreenState extends State<SearchingOpponentScreen> {
  @override
  void initState() {
    super.initState();

    initializeSocket(
      context,
      widget.socket,
      widget.language,
      widget.onBackToMainMenu,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Searching for Opponent...")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Searching for an opponent...',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.socket.emit('leaveQueue'); // Leave the queue
              },
              child: const Text("Cancel Search"),
            ),
          ],
        ),
      ),
    );
  }
}

class BattleStartScreen extends StatefulWidget {
  final String username;
  final String opponentUsername;
  final int elo;
  final int opponentElo;
  final VoidCallback onBattleStart;

  const BattleStartScreen({
    required this.username,
    required this.opponentUsername,
    required this.elo,
    required this.opponentElo,
    required this.onBattleStart,
    Key? key,
  }) : super(key: key);

  @override
  _BattleStartScreenState createState() => _BattleStartScreenState();
}

class _BattleStartScreenState extends State<BattleStartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _playerAnimation;
  late Animation<Offset> _opponentAnimation;
  int _countdown = 5;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _playerAnimation = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opponentAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    _startCountdown();
  }

  void _startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 1) {
        timer.cancel();
        widget.onBattleStart();
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          // Countdown Timer
          Center(
            child: Text(
              "$_countdown",
              style: const TextStyle(
                color: Colors.black,
                fontSize: 80,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Player Name & ELO (Left Side)
          SlideTransition(
            position: _playerAnimation,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.username,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5), // Space between name and ELO
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[100], // Light blue background
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Text(
                        "ELO: ${widget.elo}",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Opponent Name & ELO (Right Side)
          SlideTransition(
            position: _opponentAnimation,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.opponentUsername,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5), // Space between name and ELO
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red[100], // Light red background
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.2),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Text(
                        "ELO: ${widget.opponentElo}",
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
