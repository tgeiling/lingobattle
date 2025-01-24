import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
        question: "The capital of France is _____",
        answers: ["Paris"],
      ),
      MultiplayerQuestion(
        question: "The largest planet in the _____ system is _____",
        answers: ["solar", "Jupiter"],
      ),
      MultiplayerQuestion(
        question: "The capital of France is _____",
        answers: ["Paris"],
      ),
      MultiplayerQuestion(
        question: "The largest planet in the solar system is _____",
        answers: ["Jupiter"],
      ),
      MultiplayerQuestion(
        question: "The capital of France is _____",
        answers: ["Paris"],
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
  late List<MultiplayerQuestion> questions;
  late List<String> questionResults;
  late List<String> opponentProgress;
  late TextEditingController _textInputController;
  late List<String> _letterBoxes; // Tracks current letters in the boxes

  @override
  void initState() {
    super.initState();
    questions = MultiplayerQuestionsPool.questionsByLanguage[widget.language]!;
    questionResults = List<String>.filled(questions.length, "unanswered");
    opponentProgress = List<String>.filled(questions.length, "unanswered");
    _textInputController = TextEditingController();

    // Initialize letter boxes for the current question
    _initializeLetterBoxes();

    widget.socket.on('progressUpdate', _onProgressUpdate);
    widget.socket.on('battleEnded', _onBattleEnded);
  }

  void _initializeLetterBoxes() {
    // Fill the letter boxes for the current question with placeholders
    final answerLength = questions[currentQuestionIndex].answers[0].length;
    _letterBoxes = List.filled(answerLength, "");
  }

  @override
  void dispose() {
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
    final String message = data['message'] ?? 'The battle has ended.';
    final String result = data['result'] ?? 'unknown';

    if (result == 'opponentDisconnected') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MultiplayerResultScreen(
            results: {
              'message': message,
              'result': 'winByDisconnect',
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
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MultiplayerResultScreen(
            results: data['result'],
            language: widget.language,
          ),
        ),
      );
    }
  }

  void _handleInput(String value) {
    setState(() {
      // Update letter boxes with the typed input
      final input = value.split('');
      for (int i = 0; i < input.length; i++) {
        if (i < _letterBoxes.length) {
          _letterBoxes[i] = input[i];
        } else {
          _letterBoxes.add(input[i]); // Add new boxes for longer words
        }
      }

      // Clear unused boxes if input is shorter than current letter boxes
      if (input.length < _letterBoxes.length) {
        _letterBoxes = _letterBoxes.sublist(0, input.length);
      }
    });
  }

  void submitAnswer() {
    setState(() {
      final correctAnswer = questions[currentQuestionIndex].answers[0];
      final typedAnswer = _textInputController.text.trim();

      bool isCorrect = typedAnswer.toLowerCase() == correctAnswer.toLowerCase();
      questionResults[currentQuestionIndex] = isCorrect ? "correct" : "wrong";
      correctAnswers =
          questionResults.where((result) => result == "correct").length;

      widget.socket.emit('submitAnswer', {
        'matchId': widget.matchId,
        'username': widget.username,
        'questionIndex': currentQuestionIndex,
        'status': questionResults[currentQuestionIndex],
      });

      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
        _textInputController.clear();
        _initializeLetterBoxes();
      } else {
        _sendResultsToServer();
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Battle in ${widget.language}"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Progress indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
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
              Row(
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
            ],
          ),
          const SizedBox(height: 20),
          // Display question with gaps
          Wrap(
            alignment: WrapAlignment.center,
            children: _buildSentenceWithGap(questions[currentQuestionIndex]),
          ),
          const SizedBox(height: 20),
          // Letter boxes with keyboard handling
          GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
              _textInputController.selection = TextSelection.collapsed(
                offset: _textInputController.text.length,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _letterBoxes.length,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Neumorphic(
                    style: NeumorphicStyle(
                      depth: -2,
                      boxShape: NeumorphicBoxShape.roundRect(
                        BorderRadius.circular(4),
                      ),
                    ),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: Text(
                          _letterBoxes[index],
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Hidden TextField for typing
          Opacity(
            opacity: 0,
            child: TextField(
              controller: _textInputController,
              onChanged: _handleInput,
              autofocus: true,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: submitAnswer,
            child: const Text("Submit Answer"),
          ),
        ],
      ),
    );
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
                  _letterBoxes.join(), // Display typed letters in the gap
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
    // Access data directly from results
    final player1 = results['player1'];
    final player2 = results['player2'];
    final winner = results['winner'];
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
              "Winner: ${winner ?? "Draw"}",
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
                      "Player 1: ${player1['username']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      children: List.generate(
                        player1['progress'].length,
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
                      "Score: ${player1['correctAnswers']}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                // Player 2 progress
                Column(
                  children: [
                    Text(
                      "Player 2: ${player2['username']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      children: List.generate(
                        player2['progress'].length,
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
                      "Score: ${player2['correctAnswers']}",
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
