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
  List<bool> questionResults = List.filled(5, false);
  final List<String> userAnswers = List.filled(5, "");

  final List<Map<String, dynamic>> questions = [
    {
      "sentence": "The plane _____ soon after takeoff, but no one was killed.",
      "correctAnswer": "crashed",
    },
    {
      "sentence": "Advertising on the Internet has helped to _____ our sales.",
      "correctAnswer": "boost",
    },
    {
      "sentence":
          "She had to _____ her car and walk to work after getting stuck in the snow.",
      "correctAnswer": "abandon",
    },
    {
      "sentence":
          "I can't afford to buy a car. I'm already in _____ from paying for university.",
      "correctAnswer": "debt",
    },
    {
      "sentence": "He _____ it would cost \$45 to fix my bicycle.",
      "correctAnswer": "estimated",
    },
  ];

  void submitAnswer() {
    setState(() {
      if (userAnswers[currentQuestionIndex].toLowerCase() ==
          questions[currentQuestionIndex]['correctAnswer'].toLowerCase()) {
        questionResults[currentQuestionIndex] = true;
        correctAnswers++;
      } else {
        questionResults[currentQuestionIndex] = false;
      }

      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
      } else {
        _showCompletionDialog();
      }
    });
  }

  void _showCompletionDialog() {
    bool isLevelPassed = correctAnswers >= 3;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isLevelPassed ? "Level Completed!" : "Level Failed!"),
          content: Text(isLevelPassed
              ? "Congratulations! You answered $correctAnswers out of ${questions.length} questions correctly."
              : "You answered $correctAnswers out of ${questions.length} correctly. Try again!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
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
            "Level ${widget.levelId}: ${widget.description}",
            style: const TextStyle(color: Colors.black),
          ),
          color: const Color(0xFFE0E5EC),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator on the right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Question ${currentQuestionIndex + 1} of ${questions.length}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: List.generate(questions.length, (index) {
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
                      questions[currentQuestionIndex]['sentence']),
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
            child: TextField(
              onChanged: (value) {
                setState(() {
                  userAnswers[currentQuestionIndex] = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Answer",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue.shade300),
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
