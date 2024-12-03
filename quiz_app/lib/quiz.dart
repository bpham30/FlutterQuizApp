import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

class QuizScreen extends StatefulWidget {
  //quiz settings
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
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  //fetch questions from api and store in list
  late Future<List<Map<String, dynamic>>> _quizQuestions;

  @override
  void initState() {
    super.initState();
    _quizQuestions = _fetchQuestions();
  }

  //clean response
  String cleanRes(String html) {
    return parse(html).body?.text ?? html;
  }

  //fetch questions from api
  Future<List<Map<String, dynamic>>> _fetchQuestions() async {
    final response = await http.get(Uri.parse(
        'https://opentdb.com/api.php?amount=${widget.numQuestions}&category=${widget.category}&difficulty=${widget.difficulty}&type=${widget.type}'));
    try {
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(
          data['results'].map((question) => {
                'question': cleanRes(question['question']),
                'correct_answer': cleanRes(question['correct_answer']),
                'incorrect_answers': List<String>.from(
                    question['incorrect_answers']
                        .map((answer) => cleanRes(answer))),
              }),
        );
      }
      //error handling
      else {
        _showError('Error fetching questions. Please try again later.');
      }
      return [];
    } catch (e) {
      _showError('Error fetching questions. Please try again later.');
      return [];
    }
  }

  //popup error modal
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK')),
        ],
      ),
    );
  }

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
      //fetch questions
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _quizQuestions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                //show loading
                child: CircularProgressIndicator());
          } 
          //error handling
          else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }
          //display questions 
          else if (snapshot.hasData) {
            final questions = snapshot.data!;
            return QuizQuestionScreen(questions: questions);
          } 
          //no questions found
          else {
            return const Center(child: Text('No questions found.'));
          }
        },
      ),
    );
  }
}

//quiz questions screen
class QuizQuestionScreen extends StatefulWidget {
  //get quiz questions
  final List<Map<String, dynamic>> questions;

  const QuizQuestionScreen({super.key, required this.questions});

  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen> {
  //init steps and score
  int _currentIndex = 0;
  int _score = 0;

  //handle answering questions
  void _answerQuestion(String selectedAnswer) {
    final currentQuestion = widget.questions[_currentIndex];
    final correctAnswer = currentQuestion['correct_answer'];
    //check if correct
    if (selectedAnswer == correctAnswer) {
      //increment score
      _score++;
    }
    //check if more questions
    if (_currentIndex + 1 < widget.questions.length) {
      setState(() {
        //next question
        _currentIndex++;
      });
    } else {
      //quiz over- navigate to results
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              QuizResultsScreen(score: _score, total: widget.questions.length),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    //get current question
    final currentQuestion = widget.questions[_currentIndex];
    final questionText = Uri.decodeComponent(currentQuestion['question']);
    //get answers
    final answers = List<String>.from(currentQuestion['incorrect_answers'])
      ..add(currentQuestion['correct_answer'])
      //shuffle answers
      ..shuffle();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        //display question and answers
        children: [
          Text(
            'Question ${_currentIndex + 1} of ${widget.questions.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            questionText,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ...answers.map((answer) {
            final decodedAnswer = Uri.decodeComponent(answer);
            return Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () {
                    _answerQuestion(decodedAnswer);
                  },
                  child: Text(decodedAnswer, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),),
                ),
                const SizedBox(height: 8),
              ],
            );
          }),
        ],
      ),
    );
  }
}

//quiz results screen
class QuizResultsScreen extends StatelessWidget {
  //quiz results
  final int score;
  final int total;

  const QuizResultsScreen(
      {super.key, required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Quiz Completed!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Score: $score / $total',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Navigate back to setup screen
              },
              child: const Text('Back to Setup',style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),),
            ),
          ],
        ),
      ),
    );
  }
}
