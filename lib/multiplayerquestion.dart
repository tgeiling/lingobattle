import 'package:flutter/material.dart';

class MultiplayerQuestion {
  final String question;
  final List<String> answers;

  MultiplayerQuestion({
    required this.question,
    required this.answers,
  });

  factory MultiplayerQuestion.fromJson(Map<String, dynamic> json) {
    return MultiplayerQuestion(
      question: json['question'],
      answers: List<String>.from(json['answers']), // Ensure list of strings
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answers': answers,
    };
  }
}
