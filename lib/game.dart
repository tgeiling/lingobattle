import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:google_fonts/google_fonts.dart';

import 'level.dart';
import 'provider.dart';
import 'multiplayerquestion.dart';
import 'elements.dart';
import 'services.dart';

bool _isInitialized = false;

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
  late Timer _timer = Timer(Duration.zero, () {});
  double _progress = 1.0;
  String? selectedAnswer;
  List<String> _shuffledAnswers = [];

  @override
  void initState() {
    super.initState();
    _textInputController = TextEditingController();
    _focusNode = FocusNode();

    questions = (widget.level.questions as List<dynamic>)
        .map((questionData) => MultiplayerQuestion(
              question: questionData['question'] as String,
              answers: List<String>.from(questionData['answers'] as List),
              type: questionData['type'] as String,
            ))
        .toList();

    // Fetch the question pool for the selected language
    questionResults = List<String>.filled(questions.length, "unanswered");
    _textInputController = TextEditingController();

    _initializeWordHandling();
    _startTimer();

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
    _timer.cancel();
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
      MultiplayerQuestion currentQuestion = questions[currentQuestionIndex];
      bool isCorrect = false;

      if (currentQuestion.type == "fill") {
        String userAnswer =
            _currentSentenceInputs.join(" ").trim().toLowerCase();
        String correctAnswer =
            currentQuestion.answers.join(" ").trim().toLowerCase();
        isCorrect = userAnswer == correctAnswer;
      } else if (currentQuestion.type == "pick") {
        isCorrect = selectedAnswer != null &&
            currentQuestion.answers.first.toLowerCase() ==
                selectedAnswer?.toLowerCase();
      }

      questionResults[currentQuestionIndex] =
          isCorrect ? "correct" : "incorrect";
      _triggerResultAnimation(isCorrect);

      if (isCorrect) correctAnswers++;

      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
        currentWordIndex = 0;
        selectedAnswer = null;
        _initializeWordHandling();
        _shuffledAnswers = List.from(questions[currentQuestionIndex].answers)
          ..shuffle();
        _startTimer();
      } else {
        Provider.of<LevelNotifier>(context, listen: false)
            .updateLevelStatus(widget.language, widget.level.id);
        _showCompletionDialog();
      }
    });
  }

  void _startTimer() {
    _timer.cancel();
    _progress = 1.0;
    const int totalSeconds = 90;
    int elapsedSeconds = 0;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        elapsedSeconds++;
        _progress = 1.0 - (elapsedSeconds / totalSeconds);

        if (elapsedSeconds >= totalSeconds) {
          _timer.cancel();
          _submitAnswer(); // Auto-submit answer after 60 seconds
        }
      });
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

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _statusText; // "Correct!" or "Wrong!"
  bool _showStatus = false; // Controls visibility of the animation

  void _triggerResultAnimation(bool isCorrect) {
    setState(() {
      _statusText = isCorrect ? "Correct!" : "Wrong!";
      _showStatus = true;
    });

    // Play sound effect
    _playSound(isCorrect);

    // Fade out after animation
    Future.delayed(Duration(milliseconds: 1300), () {
      setState(() {
        _showStatus = false;
      });
    });
  }

  void _playSound(bool isCorrect) async {
    String soundPath = isCorrect ? "correct.mp3" : "wrong.mp3";
    await _audioPlayer.play(AssetSource(soundPath));
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
        body: Stack(children: [
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey[300],
            color: Colors.red, // Change color to indicate urgency
            minHeight: 5, // Thin line
          ),
          SingleChildScrollView(
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
                if (questions[currentQuestionIndex].answers.length > 1 &&
                    questions[currentQuestionIndex].type == "fill")
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

                        List<Widget> letterBoxes = [];

                        // Generate the letter boxes
                        if (questions[currentQuestionIndex].type == "fill") {
                          letterBoxes = List.generate(
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
                        }

                        // Single row with dynamic scaling and centering
                        return Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // Center align the row
                          children: [
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: spacing,
                              children:
                                  questions[currentQuestionIndex].type == "fill"
                                      ? letterBoxes
                                      : [],
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
                SizedBox(height: 50),
              ],
            ),
          ),
          if (_showStatus)
            Align(
              alignment:
                  Alignment.topCenter, // Ensures it's centered horizontally
              child: Transform.translate(
                offset: _statusText == "Correct!"
                    ? Offset(0, 180)
                    : Offset(0,
                        180), // Moves it down from the top (adjust as needed)
                child: AnimatedOpacity(
                  opacity: _showStatus ? 1 : 0,
                  duration: const Duration(milliseconds: 800),
                  child: Lottie.asset(
                    _statusText == "Correct!"
                        ? 'assets/correct.json'
                        : 'assets/wrong.json',
                    repeat: false,
                    onLoaded: (composition) {
                      Future.delayed(Duration(milliseconds: 1300), () {
                        setState(() {
                          _showStatus = false;
                        });
                      });
                    },
                  ),
                ),
              ),
            ),
        ]));
  }

  List<Widget> _buildSentenceWithGap(MultiplayerQuestion question) {
    if (question.type == "fill") {
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
    } else {
      List<Widget> widgets = [
        Text(
          question.question,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
      ];

      widgets.addAll(_shuffledAnswers.map((answer) {
        return ElevatedButton(
          onPressed: () {
            setState(() {
              selectedAnswer = answer;
            });
            _submitAnswer();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                selectedAnswer == answer ? Colors.blue : Colors.grey[300],
          ),
          child: Text(answer),
        );
      }).toList());

      return widgets;
    }
  }
}

class MultiplayerGameScreen extends StatefulWidget {
  final IO.Socket socket;
  final String username;
  final String opponentUsername;
  final String matchId;
  final String language;
  final VoidCallback onBackToMainMenu;
  final List<MultiplayerQuestion> questions;

  const MultiplayerGameScreen({
    Key? key,
    required this.socket,
    required this.username,
    required this.opponentUsername,
    required this.matchId,
    required this.language,
    required this.onBackToMainMenu,
    required this.questions,
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
  late Timer _timer = Timer(Duration.zero, () {});
  double _progress = 1.0;
  String? selectedAnswer;
  List<String> _shuffledAnswers = [];

  @override
  void initState() {
    super.initState();
    _textInputController = TextEditingController();
    _focusNode = FocusNode();

    questions = widget.questions;
    questionResults = List<String>.filled(questions.length, "unanswered");
    opponentProgress = List<String>.filled(questions.length, "unanswered");
    _textInputController = TextEditingController();

    _shuffledAnswers = List.from(questions[currentQuestionIndex].answers);

    _initializeWordHandling();
    _startTimer();

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
    @override
    void dispose() {
      _animationFuture?.ignore(); // Ensure no pending UI update
      super.dispose();
    }

    _timer.cancel();
    _focusNode.dispose();
    widget.socket.off('connect');
    widget.socket.off('disconnect');
    widget.socket.off('battleStart');
    widget.socket.off('matchFound');
    widget.socket.off('progressUpdate');
    widget.socket.off('battleEnded');

    widget.socket.disconnect();
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
    _animationFuture?.ignore();

    try {
      final String message = data['message'] ?? 'The battle has ended.';
      final result = data['result'];
      final questions = data['questions'];

      if (result == 'opponentDisconnected' || result == 'playerLeft') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MultiplayerResultScreen(
              results: {
                'message': message,
                'questions': questions,
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MultiplayerResultScreen(
              results: {
                'message': message,
                'questions': questions,
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
      MultiplayerQuestion currentQuestion = questions[currentQuestionIndex];
      bool isCorrect = false;

      if (currentQuestion.type == "fill") {
        // Fill-in-the-blank logic
        String userAnswer =
            _currentSentenceInputs.join(" ").trim().toLowerCase();
        String correctAnswer =
            currentQuestion.answers.join(" ").trim().toLowerCase();
        isCorrect = userAnswer == correctAnswer;
      } else if (currentQuestion.type == "pick") {
        // Multiple-choice logic
        isCorrect = selectedAnswer != null &&
            currentQuestion.answers.first.toLowerCase() ==
                selectedAnswer?.toLowerCase();
      }

      // Update answer results
      questionResults[currentQuestionIndex] = isCorrect ? "correct" : "wrong";
      correctAnswers =
          questionResults.where((result) => result == "correct").length;
      _triggerResultAnimation(isCorrect);

      // Emit the answer progress to the server
      widget.socket.emit('submitAnswer', {
        'matchId': widget.matchId,
        'username': widget.username,
        'questionIndex': currentQuestionIndex,
        'status': questionResults[currentQuestionIndex],
      });

      // Reset for the next question or end the game
      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
        currentWordIndex = 0;
        selectedAnswer = null;
        _textInputController.clear();
        _initializeWordHandling();
        _shuffledAnswers = List.from(questions[currentQuestionIndex].answers)
          ..shuffle(); // Shuffle only once per question
        _startTimer();
      } else {
        _sendResultsToServer();
      }
    });
  }

  void _startTimer() {
    _timer.cancel();
    _progress = 1.0;
    const int totalSeconds = 60;
    int elapsedSeconds = 0;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        elapsedSeconds++;
        _progress = 1.0 - (elapsedSeconds / totalSeconds);

        if (elapsedSeconds >= totalSeconds) {
          _timer.cancel();
          submitAnswer();
        }
      });
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

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _statusText; // "Correct!" or "Wrong!"
  bool _showStatus = false; // Controls visibility of the animation

  Future<void>? _animationFuture;

  void _triggerResultAnimation(bool isCorrect) {
    if (!mounted) return;

    setState(() {
      _statusText = isCorrect ? "Correct!" : "Wrong!";
      _showStatus = true;
    });

    _playSound(isCorrect);
  }

  void _playSound(bool isCorrect) async {
    String soundPath = isCorrect ? "correct.mp3" : "wrong.mp3";
    await _audioPlayer.play(AssetSource(soundPath));
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
            body: Stack(children: [
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey[300],
                color: Colors.red, // Change color to indicate urgency
                minHeight: 5, // Thin line
              ),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 15),
                    Neumorphic(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 32),
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
                    if (questions[currentQuestionIndex].answers.length > 1 &&
                        questions[currentQuestionIndex].answers == "fill")
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
                            const double maxBoxHeight =
                                65; // Default box height
                            const double minBoxWidth = 25; // Minimum box width
                            const double minBoxHeight =
                                35; // Minimum box height
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
                              boxWidth =
                                  boxWidth.clamp(minBoxWidth, maxBoxWidth);
                              boxHeight = boxWidth * 1.2;
                              spacing = (maxWidth - (boxWidth * totalBoxes)) /
                                  (totalBoxes - 1);
                            } else if (totalBoxes == 6) {
                              // Special case for 6 boxes: Adjust to perfectly fit without stretching
                              double totalSpacing =
                                  defaultSpacing * 5; // 6 boxes = 5 spacings
                              boxWidth = (maxWidth - totalSpacing) / 6.5;
                              boxWidth =
                                  boxWidth.clamp(minBoxWidth, maxBoxWidth);
                              boxHeight = boxWidth * 1.2;
                              spacing = defaultSpacing;
                            } else if (totalBoxes == 5) {
                              // Special case for 5 boxes: Adjust to perfectly fit without stretching
                              double totalSpacing =
                                  defaultSpacing * 5; // 6 boxes = 5 spacings
                              boxWidth = (maxWidth - totalSpacing) / 5;
                              boxWidth =
                                  boxWidth.clamp(minBoxWidth, maxBoxWidth);
                              boxHeight = boxWidth * 1.2;
                              spacing = defaultSpacing;
                            }

                            List<Widget> letterBoxes = [];

                            // Generate the letter boxes
                            if (questions[currentQuestionIndex].type ==
                                "fill") {
                              letterBoxes = List.generate(
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
                            }

                            // Single row with dynamic scaling and centering
                            return Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .center, // Center align the row
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: spacing,
                                  children:
                                      questions[currentQuestionIndex].type ==
                                              "fill"
                                          ? letterBoxes
                                          : [],
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
              ),
              if (_showStatus)
                Align(
                    alignment: Alignment
                        .topCenter, // Ensures it's centered horizontally
                    child: Transform.translate(
                      offset: _statusText == "Correct!"
                          ? Offset(0, 180)
                          : Offset(0,
                              180), // Moves it down from the top (adjust as needed)
                      child: ResultAnimation(
                        isCorrect: _statusText == "Correct!",
                        onAnimationEnd: () {
                          setState(() {
                            _showStatus = false;
                          });
                        },
                      ),
                    ))
            ])));
  }

  List<Widget> _buildSentenceWithGap(MultiplayerQuestion question) {
    if (question.type == "fill") {
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
    } else {
      List<Widget> widgets = [
        Text(
          question.question,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
      ];

      widgets.addAll(_shuffledAnswers.map((answer) {
        return ElevatedButton(
          onPressed: () {
            setState(() {
              selectedAnswer = answer;
            });
            submitAnswer();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                selectedAnswer == answer ? Colors.blue : Colors.grey[300],
          ),
          child: Text(answer),
        );
      }).toList());

      return widgets;
    }
  }

  Future<bool> _showLeaveConfirmationDialog(BuildContext context) async {
    final List<Map<String, dynamic>> formattedQuestions = questions.map((q) {
      return {
        'question': q.question, // Extracting question as string
        'answers':
            List<String>.from(q.answers), // Ensuring answers is a List<String>
      };
    }).toList();

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
                          'questions': formattedQuestions,
                          'result': 'lossByLeave',
                          'player1': {
                            'username': widget.username,
                            'correctAnswers': correctAnswers,
                            'progress': questionResults,
                          },
                          'player2': {
                            'username': widget.opponentUsername,
                            'correctAnswers': 0,
                            'progress': List<String>.filled(
                                questionResults.length, 'unanswered'),
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
    final player1 = results['player1'] ?? {};
    final player2 = results['player2'] ?? {};
    final winner = results['winner'] ?? "Draw";
    final message = results['message'] ?? "Match concluded";
    final questions = results['questions'] ?? [];

    return Scaffold(
        backgroundColor: Colors.grey[200],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              // 🔥 This prevents the overflow
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 40), // Added space on top
                    NeumorphicText(
                      message,
                      style: NeumorphicStyle(depth: 4, color: Colors.black),
                      textStyle: NeumorphicTextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Neumorphic(
                      padding: const EdgeInsets.all(20),
                      style: NeumorphicStyle(
                        shape: NeumorphicShape.concave,
                        boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(12)),
                        depth: 10,
                        lightSource: LightSource.topLeft,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              NeumorphicText(
                                "Winner: ",
                                style: NeumorphicStyle(
                                    depth: 6, color: Colors.black),
                                textStyle: NeumorphicTextStyle(
                                  fontSize: 24, // Increased font size
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (winner != "Draw")
                                Image.asset("assets/crown.png",
                                    height: 30), // Crown Icon
                            ],
                          ),
                          NeumorphicText(
                            winner,
                            style:
                                NeumorphicStyle(depth: 6, color: Colors.black),
                            textStyle: NeumorphicTextStyle(
                              fontSize: 26, // Bigger Winner Name
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildPlayerColumn(player1, "Player 1"),
                          const SizedBox(height: 20),
                          _buildPlayerColumn(player2, "Player 2"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // View Questions Button
                    PressableButton(
                      onPressed: () =>
                          _showQuestionResultsDialog(context, questions),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      child: Text(
                        "View Questions",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Back Button
                    PressableButton(
                      onPressed: () {
                        final profileProvider = Provider.of<ProfileProvider>(
                            context,
                            listen: false);

                        getAuthToken().then((token) {
                          if (token != null) {
                            profileProvider.syncProfile(token);
                          }
                        });

                        Navigator.popUntil(context, (route) => route.isFirst);
                        onBackToMainMenu();
                      },
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      child: Text(
                        "Back to Main Menu",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildPlayerColumn(Map<String, dynamic> player, String title) {
    return Column(
      children: [
        NeumorphicText(
          title,
          style: NeumorphicStyle(depth: 4, color: Colors.black),
          textStyle:
              NeumorphicTextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (player['username'] == results['winner']) // Show crown if winner
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Image.asset("assets/crown.png", height: 20),
              ),
            Text(
              player['username'] ?? 'Unknown',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          children: List.generate(
            (player['progress'] ?? []).length,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: NeumorphicIcon(
                Icons.circle,
                style: NeumorphicStyle(
                  depth: 2,
                  color: player['progress'][index] == "correct"
                      ? Colors.green
                      : player['progress'][index] == "wrong"
                          ? Colors.red
                          : Colors.black,
                ),
                size: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        NeumorphicText(
          "Score: ${player['correctAnswers'] ?? 0}",
          style: NeumorphicStyle(depth: 4, color: Colors.black),
          textStyle: NeumorphicTextStyle(fontSize: 16),
        ),
      ],
    );
  }

  void _showQuestionResultsDialog(
      BuildContext context, List<dynamic> questions) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.grey[200],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeumorphicText(
                  "Question Review",
                  style: NeumorphicStyle(depth: 4, color: Colors.black),
                  textStyle: NeumorphicTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index]['question'];
                      final answers =
                          (questions[index]['answers'] as List).join(", ");
                      return Neumorphic(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        style: NeumorphicStyle(
                          shape: NeumorphicShape.flat,
                          depth: 4,
                          lightSource: LightSource.topLeft,
                          boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(10)),
                          color: Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Q${index + 1}: $question",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              answers.contains(",")
                                  ? "Answers: $answers"
                                  : "Answer: $answers",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                PressableButton(
                  onPressed: () => Navigator.pop(context),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    "Close",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  socket.on('battleStart', (data) {
    List<MultiplayerQuestion> questions = (data['questions'] as List)
        .map((q) => MultiplayerQuestion.fromJson(q))
        .toList();

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
                  questions: questions, // Pass the questions here
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.5,
              padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[500],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(5, 5),
                    blurRadius: 12,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    offset: const Offset(-5, -5),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SpinKitWave(
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Finding an opponent...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.socket.emit('leaveQueue');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                elevation: 8,
                shadowColor: Colors.black,
              ),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
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
    final screenWidth = MediaQuery.of(context).size.width;

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
                child: ConstrainedBox(
                  // Constrain the width so the text will wrap instead of overflow
                  constraints: BoxConstraints(maxWidth: screenWidth * 0.4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.only(right: 20),
                        child: Text(
                          widget.username,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
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
          ),

          // Opponent Name & ELO (Right Side)
          SlideTransition(
            position: _opponentAnimation,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: screenWidth * 0.4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.only(left: 20),
                        child: Text(
                          widget.opponentUsername,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
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
          ),
        ],
      ),
    );
  }
}
