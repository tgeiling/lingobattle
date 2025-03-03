import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'elements.dart';
import 'provider.dart';

class TranslationWidget extends StatefulWidget {
  final String word;
  final Offset position; // Position of the SpeechBubble
  final VoidCallback onDismiss; // Function to remove it after delay

  const TranslationWidget({
    Key? key,
    required this.word,
    required this.position,
    required this.onDismiss,
  }) : super(key: key);

  @override
  _TranslationWidgetState createState() => _TranslationWidgetState();
}

class _TranslationWidgetState extends State<TranslationWidget> {
  Map<String, Map<String, String>> _translations = {};
  String translation = "";

  @override
  void initState() {
    super.initState();
    _loadTranslation();
    Future.delayed(
        const Duration(seconds: 2), widget.onDismiss); // Auto-dismiss
  }

  Future<void> _loadTranslation() async {
    if (_translations.isEmpty) {
      await _loadTranslationsFromJson();
    }
    String selectedLanguage = await _getSelectedLanguage();

    if (widget.word == _translations[widget.word]?[selectedLanguage]) {
      return;
    }

    setState(() {
      translation =
          _translations[widget.word]?[selectedLanguage] ?? widget.word;
    });
  }

  Future<void> _loadTranslationsFromJson() async {
    final String jsonString =
        await rootBundle.loadString('assets/translations.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    // Explicitly cast jsonData["words"] to the correct type
    final Map<String, dynamic> wordsData = jsonData["words"];

    _translations = wordsData.map((key, value) => MapEntry(
          key as String,
          Map<String, String>.from(value as Map), // ✅ Explicit casting
        ));
  }

  Future<String> _getSelectedLanguage() async {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    return profileProvider.nativeLanguage.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return translation.isEmpty
        ? SizedBox.shrink()
        : Positioned(
            left: widget.position.dx,
            top: widget.position.dy - 30, // Adjust to be above the word
            child: SpeechBubble(message: translation),
          );
  }
}
