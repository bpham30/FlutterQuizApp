import 'package:flutter/material.dart';

class QuizScreen extends StatelessWidget {
  final String category;
  final int numQuestions;
  final String difficulty;
  final String type;

  const QuizScreen({
    super.key,
    required this.category,
    required this.numQuestions,
    required this.difficulty,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quiz',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Text(
          'Quiz will start with the following settings:\n'
          'Category ID: $category\n'
          'Number of Questions: $numQuestions\n'
          'Difficulty: $difficulty\n'
          'Type: $type',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}