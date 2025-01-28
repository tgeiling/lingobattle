import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:google_fonts/google_fonts.dart';

import 'level.dart';
import 'provider.dart';

class GameScreen extends StatefulWidget {
  final Level level;

  const GameScreen({
    Key? key,
    required this.level,
  }) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  late List<bool> questionResults;
  late List<TextEditingController> controllers;

  @override
  void initState() {
    super.initState();
    questionResults = List.filled(widget.level.questions.length, false);
    controllers = List.generate(
      widget.level.questions.length,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void submitAnswer() {
    setState(() {
      List<String> acceptableAnswers =
          widget.level.questions[currentQuestionIndex]['answers'];
      if (acceptableAnswers.any((answer) =>
          controllers[currentQuestionIndex].text.toLowerCase() ==
          answer.toLowerCase())) {
        questionResults[currentQuestionIndex] = true;
        correctAnswers++;
      } else {
        questionResults[currentQuestionIndex] = false;
      }

      if (currentQuestionIndex < widget.level.questions.length - 1) {
        currentQuestionIndex++;
        controllers[currentQuestionIndex]
            .clear(); // Clear input box for next question
      } else {
        // Mark the level as completed and save progress
        Provider.of<LevelNotifier>(context, listen: false)
            .updateLevelStatus(widget.level.id);

        // Show completion dialog
        _showCompletionDialog();
      }
    });
  }

  void _showCompletionDialog() {
    bool isLevelPassed = correctAnswers >= widget.level.questions.length ~/ 2;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Neumorphic(
          style: NeumorphicStyle(
            depth: 10,
            color: Colors.white,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
          ),
          child: AlertDialog(
            title: Text(isLevelPassed ? "Level Completed!" : "Level Failed!"),
            content: Text(isLevelPassed
                ? "Congratulations! You answered $correctAnswers out of ${widget.level.questions.length} questions correctly."
                : "You answered $correctAnswers out of ${widget.level.questions.length} correctly. Try again!"),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return NeumorphicTheme(
      theme: NeumorphicThemeData(
        baseColor: const Color(0xFFE0E5EC),
        lightSource: LightSource.topLeft,
        depth: 8,
      ),
      child: Scaffold(
        appBar: NeumorphicAppBar(
          title: Text(
            "Level ${widget.level.id}: ${widget.level.description}",
            style: const TextStyle(color: Colors.black),
          ),
          color: const Color(0xFFE0E5EC),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Question ${currentQuestionIndex + 1} of ${widget.level.questions.length}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children:
                        List.generate(widget.level.questions.length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: questionResults[index]
                              ? Colors.green
                              : index < currentQuestionIndex
                                  ? Colors.red
                                  : Colors.grey,
                        ),
                      );
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Sentence with gap
              Neumorphic(
                padding: const EdgeInsets.all(16),
                style: NeumorphicStyle(
                  depth: -4,
                  color: const Color(0xFFFFFFFF),
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: _buildSentenceWithGap(
                      widget.level.questions[currentQuestionIndex]['question']),
                ),
              ),

              const SizedBox(height: 20),

              // Submit button
              Center(
                child: NeumorphicButton(
                  onPressed: submitAnswer,
                  style: NeumorphicStyle(
                    color: Colors.blue.shade100,
                    depth: 6,
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text(
                      "Submit Answer",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSentenceWithGap(String sentence) {
    List<String> parts = sentence.split("_____");
    List<Widget> widgets = [];
    for (int i = 0; i < parts.length; i++) {
      widgets.add(Text(parts[i],
          style: const TextStyle(fontSize: 18, color: Colors.black87)));
      if (i < parts.length - 1) {
        widgets.add(
          SizedBox(
            width: 100,
            child: Neumorphic(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              style: NeumorphicStyle(
                depth: -2,
                boxShape:
                    NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                color: Colors.white,
              ),
              child: TextField(
                controller: controllers[currentQuestionIndex],
                onChanged: (value) {
                  setState(() {});
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Answer",
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}

class MultiplayerQuestion {
  final String question;
  final List<String> answers;

  MultiplayerQuestion({
    required this.question,
    required this.answers,
  });
}

class MultiplayerQuestionsPool {
  static final Map<String, List<MultiplayerQuestion>> questionsByLanguage = {
    'english': [
      MultiplayerQuestion(
        question: "The capital of Italy is _____",
        answers: ["Rome"],
      ),
      MultiplayerQuestion(
        question: "The chemical symbol for water is _____",
        answers: ["H2O"],
      ),
      MultiplayerQuestion(
        question: "The fastest animal in the sky is the _____ falcon",
        answers: ["peregrine"],
      ),
      MultiplayerQuestion(
        question: "The Great Wall of China was built to protect against _____",
        answers: ["invasions"],
      ),
      MultiplayerQuestion(
        question: "The largest ocean on Earth is the _____ Ocean",
        answers: ["Pacific"],
      ),
    ],
    'spanish': [
      MultiplayerQuestion(
        question: "La capital de España es _____",
        answers: ["Madrid"],
      ),
      MultiplayerQuestion(
        question: "El océano más grande del mundo es el _____",
        answers: ["Pacífico"],
      ),
    ],
    'dutch': [
      MultiplayerQuestion(
        question: "De hoofdstad van Nederland is _____",
        answers: ["Amsterdam"],
      ),
      MultiplayerQuestion(
        question: "Het grootste land in Europa is _____",
        answers: ["Rusland"],
      ),
    ],
    'german': [
      MultiplayerQuestion(
        question: "Die Hauptstadt von Deutschland ist _____",
        answers: ["Berlin"],
      ),
      MultiplayerQuestion(
        question: "Der höchste Berg in Europa ist der _____",
        answers: ["Mont Blanc"],
      ),
    ],
    'swiss': [
      MultiplayerQuestion(
        question: "Die Hauptstadt der Schweiz ist _____",
        answers: ["Bern"],
      ),
      MultiplayerQuestion(
        question: "Der größte See der Schweiz ist der _____",
        answers: ["Genfersee"],
      ),
    ],
  };
}

class MultiplayerGameScreen extends StatefulWidget {
  final IO.Socket socket;
  final String username;
  final String opponentUsername;
  final String matchId;
  final String language;

  const MultiplayerGameScreen({
    Key? key,
    required this.socket,
    required this.username,
    required this.opponentUsername,
    required this.matchId,
    required this.language,
  }) : super(key: key);

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
    questions = MultiplayerQuestionsPool.questionsByLanguage[widget.language]!;
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
              centerTitle: true,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Display the flag
                  Image.asset(
                    'assets/flags/${widget.language.toLowerCase()}.png', // Match flag file
                    width: 32, // Adjust flag size
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(
                      width: 8), // Add spacing between the flag and text
                  // Neumorphic container around the text
                  Neumorphic(
                    style: NeumorphicStyle(
                      depth: -2,
                      color: Colors.white,
                      boxShape: NeumorphicBoxShape.roundRect(
                        BorderRadius.circular(16),
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "BATTLE IN ${widget.language.toUpperCase()}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            resizeToAvoidBottomInset: true,
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 40),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Opponent's name
                          Text(
                            widget.opponentUsername,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          // Player's name
                          Text(
                            widget.username,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                          height:
                              8), // Add spacing between names and progress rows
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Opponent's progress indicators inside the specified Neumorphic container
                          Neumorphic(
                            padding: const EdgeInsets.all(8),
                            style: NeumorphicStyle(
                              shape: NeumorphicShape.concave,
                              boxShape: NeumorphicBoxShape.roundRect(
                                BorderRadius.circular(12),
                              ),
                              depth: 8,
                              lightSource: LightSource.topLeft,
                            ),
                            child: Row(
                              children: List.generate(
                                questions.length,
                                (index) => Icon(
                                  Icons.circle,
                                  color: opponentProgress[index] == "unanswered"
                                      ? Colors.black
                                      : opponentProgress[index] == "correct"
                                          ? Colors.green
                                          : Colors.red,
                                ),
                              ),
                            ),
                          ),
                          // Player's progress indicators inside the specified Neumorphic container
                          Neumorphic(
                            padding: const EdgeInsets.all(8),
                            style: NeumorphicStyle(
                              shape: NeumorphicShape.concave,
                              boxShape: NeumorphicBoxShape.roundRect(
                                BorderRadius.circular(12),
                              ),
                              depth: 8,
                              lightSource: LightSource.topLeft,
                            ),
                            child: Row(
                              children: List.generate(
                                questions.length,
                                (index) => Icon(
                                  Icons.circle,
                                  color: questionResults[index] == "unanswered"
                                      ? Colors.black
                                      : questionResults[index] == "correct"
                                          ? Colors.green
                                          : Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
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
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                  SizedBox(height: 20),
                  if (questions[currentQuestionIndex].answers.length > 1)
                    Text(
                        "${currentWordIndex + 1}/${questions[currentQuestionIndex].answers.length}"),
                  GestureDetector(
                    onTap: () {
                      // Request focus for the TextField
                      if (!_focusNode.hasFocus) {
                        _focusNode
                            .requestFocus(); // Request focus directly for the existing FocusNode
                      }
                      // Place the cursor at the end of the text
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

                          // Define thresholds and base dimensions
                          const int minBoxesBeforeReduction =
                              5; // Start reducing after 5 boxes
                          const double minBoxWidth =
                              40; // Slightly larger minimum width
                          const double maxBoxWidth = 55;
                          const double minBoxHeight =
                              50; // Slightly larger minimum height
                          const double maxBoxHeight = 65;
                          const double minSpacing =
                              6; // Larger minimum spacing for better aesthetics
                          const double maxSpacing = 16;
                          const double minRunSpacing = 4;
                          const double maxRunSpacing = 12;

                          // Calculate reduction factor
                          int totalBoxes = _letterBoxes.length;
                          double reductionFactor =
                              ((totalBoxes - minBoxesBeforeReduction) / 10)
                                  .clamp(0.0, 0.8);

                          // Interpolate values based on reduction factor
                          double boxWidth = maxBoxWidth -
                              (maxBoxWidth - minBoxWidth) * reductionFactor;
                          double boxHeight = maxBoxHeight -
                              (maxBoxHeight - minBoxHeight) * reductionFactor;
                          double spacing = maxSpacing -
                              (maxSpacing - minSpacing) * reductionFactor;
                          double runSpacing = maxRunSpacing -
                              (maxRunSpacing - minRunSpacing) * reductionFactor;

                          // Calculate maximum boxes per row
                          int maxBoxesPerRow =
                              (maxWidth / (boxWidth + spacing)).floor();
                          maxBoxesPerRow = maxBoxesPerRow.clamp(
                              1, totalBoxes); // Ensure at least one box per row

                          // Adjust box dimensions if more than one row
                          if (totalBoxes > maxBoxesPerRow) {
                            double scalingFactor = totalBoxes / maxBoxesPerRow;
                            boxWidth /= scalingFactor.clamp(
                                1.0, 1.2); // Gentler scaling
                            boxHeight /= scalingFactor.clamp(1.0, 1.2);
                          }

                          return Wrap(
                            alignment: WrapAlignment.center,
                            spacing: spacing, // Dynamic horizontal spacing
                            runSpacing: runSpacing, // Dynamic vertical spacing
                            children: List.generate(
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
                                        fontSize:
                                            boxWidth * 0.5, // Dynamic font size
                                        fontWeight:
                                            FontWeight.bold, // Bold font
                                        color:
                                            Colors.grey[800], // Dark gray color
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
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

  const MultiplayerResultScreen({
    Key? key,
    required this.results,
    required this.language,
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

            // Back to Main Menu button
            ElevatedButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text("Back to Main Menu"),
            ),
          ],
        ),
      ),
    );
  }
}

void initializeSocket(BuildContext context, IO.Socket socket, String language) {
  socket.onConnect((_) {
    print('Connected to the server');
    socket.emit('joinQueue', {
      'username': Provider.of<ProfileProvider>(context, listen: false).username,
      'language': language,
    });
  });

  socket.on('matchFound', (data) {
    print('Match found: $data');
    // Navigate to searching screen if desired
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SearchingOpponentScreen(
          socket: socket,
          username: data['username'],
          language: data['language'],
        ),
      ),
    );
  });

  // Listen for battleStart event
  socket.on('battleStart', (data) {
    print('Battle started with data: $data');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MultiplayerGameScreen(
          username: data['username'],
          opponentUsername: data['opponentUsername'],
          matchId: data['matchId'],
          language: data['language'],
          socket: socket,
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

  const SearchingOpponentScreen({
    Key? key,
    required this.socket,
    required this.username,
    required this.language,
  }) : super(key: key);

  @override
  _SearchingOpponentScreenState createState() =>
      _SearchingOpponentScreenState();
}

class _SearchingOpponentScreenState extends State<SearchingOpponentScreen> {
  @override
  void initState() {
    super.initState();

    // Listen for battleStart event
    widget.socket.on('battleStart', (data) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BattleScreen(battleData: data),
        ),
      );
    });

    // Optionally handle battleFull or other error events
    widget.socket.on('battleFull', (data) {
      _showErrorDialog('Battle is already full. Try another.');
    });

    initializeSocket(context, widget.socket, widget.language);
  }

  @override
  void dispose() {
    // Remove listeners when the screen is disposed
    widget.socket.off('battleStart');
    widget.socket.off('battleFull');
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
