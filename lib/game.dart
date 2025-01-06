import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

class GameScreen extends StatefulWidget {
  final int levelId;
  final String description;

  const GameScreen({
    Key? key,
    required this.levelId,
    required this.description,
  }) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  List<bool> questionResults = List.filled(6, false);

  // Default static questions for the exercise
  final List<Map<String, dynamic>> questions = [
    {
      "question": "Translate: 'Hello' in English.",
      "correctAnswer": "Hello",
    },
    {
      "question": "Translate: 'Danke' in German.",
      "correctAnswer": "Thank you",
    },
    {
      "question": "Translate: 'Gracias' in Spanish.",
      "correctAnswer": "Thank you",
    },
    {
      "question": "Translate: 'Goedemorgen' in Dutch.",
      "correctAnswer": "Good morning",
    },
    {
      "question": "Translate: 'Merci' in Swiss.",
      "correctAnswer": "Thank you",
    },
    {
      "question": "Fill the gap: 'I am ___ to the market.'",
      "correctAnswer": "going",
    },
  ];

  TextEditingController answerController = TextEditingController();

  void submitAnswer() {
    String userAnswer = answerController.text.trim();
    if (userAnswer.isNotEmpty) {
      setState(() {
        if (userAnswer.toLowerCase() ==
            questions[currentQuestionIndex]['correctAnswer']
                .toString()
                .toLowerCase()) {
          questionResults[currentQuestionIndex] = true;
          correctAnswers++;
        } else {
          questionResults[currentQuestionIndex] = false;
        }

        if (currentQuestionIndex < 5) {
          currentQuestionIndex++;
          answerController.clear();
        } else {
          _showCompletionDialog();
        }
      });
    }
  }

  void _showCompletionDialog() {
    bool isLevelPassed = correctAnswers >= 4;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isLevelPassed ? "Level Completed!" : "Level Failed!"),
          content: Text(isLevelPassed
              ? "Congratulations! You answered $correctAnswers out of 6 questions correctly."
              : "You answered $correctAnswers out of 6 correctly. Try again!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to the level selection screen
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return NeumorphicApp(
      theme: NeumorphicThemeData(
        baseColor: const Color(0xFFE0E5EC), // Light gray background
        lightSource: LightSource.topLeft,
        depth: 8,
      ),
      home: Scaffold(
        appBar: NeumorphicAppBar(
          title: Text(
            "Level ${widget.levelId}: ${widget.description}",
            style: TextStyle(color: Colors.black),
          ),
          color: const Color(0xFFE0E5EC),
        ),
        body: Row(
          children: [
            // Main content area
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Question display
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      questions[currentQuestionIndex]['question'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Answer input integrated into the question
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text("Enter your answer"),
                            content: TextField(
                              controller: answerController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "Your Answer",
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  submitAnswer();
                                },
                                child: Text("Submit"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Neumorphic(
                      style: NeumorphicStyle(
                        depth: -4,
                        color: const Color(0xFFE0E5EC),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Center(
                        child: Text(
                          "Tap here to answer",
                          style: TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Red points on the right side
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
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
      ),
    );
  }
}
