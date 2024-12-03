import 'dart:async';

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
    try {
      return parse(html).body?.text ?? html;
    } catch (e) {
      return html;
    }
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
            //clean responses and store in map
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
  //init variables
  int _currentIndex = 0;
  int _score = 0;
  int _timeLeft = 15;
  late Timer _timer;

  //init lists
  List<String> _shuffledAnswers = [];
  final Map<int, String> _userAnswers = {};

  //init feedback
  String? _feedback; 
  bool _showFeedback = false;

  @override
  void initState() {
    super.initState();
    //shuffle answers and start timer
    _shuffleAnswers();
    _startTimer();
  }

  @override
  void dispose() {
    //cancel timer
    _timer.cancel();
    super.dispose();
  }

  //start timer function
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      //countdown to 0
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer.cancel();
        //no answer when time runs out
        _answerQuestion(null); 
      }
    });
  }

  //reset timer function
  void _resetTimer() {
    _timer.cancel();
    setState(() {
      //reset timer
      _timeLeft = 15;
      //reset feedback
      _showFeedback = false; 
    });
    _startTimer();
  }

  //shuffle answers function
  void _shuffleAnswers() {
    //get current question & answers
    final currentQuestion = widget.questions[_currentIndex];
    final answers = List<String>.from(currentQuestion['incorrect_answers'])
    //add correct answer
      ..add(currentQuestion['correct_answer'])
      //shuffle answers
      ..shuffle();

    setState(() {
      //decode answers
      _shuffledAnswers = answers.map((answer) {
        try {
          return Uri.decodeComponent(answer);
        } catch (e) {
          return answer;
        }
      }).toList();
    });
  }

  //answer question function
  void _answerQuestion(String? selectedAnswer) {
    //get current question & correct answer
    final currentQuestion = widget.questions[_currentIndex];
    final correctAnswer = currentQuestion['correct_answer'];

    //store user answers
    _userAnswers[_currentIndex] = selectedAnswer ?? 'No Answer';

    //update score & feedback
    setState(() {
      //check if answer is correct
      if (selectedAnswer == correctAnswer) {
        _score++;
        _feedback = 'Correct!';
        //time runs out
      } else if (_timeLeft == 0) {
        _feedback =
            'Time is up! Correct Answer: ${Uri.decodeComponent(correctAnswer)}';
      }
      //incorrect answer 
      else {
        _feedback =
            'Incorrect! Correct Answer: ${Uri.decodeComponent(correctAnswer)}';
      }
      //display feedback
      _showFeedback = true;
    });

    //delay next question to show feedback
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        //next question or end quiz
        if (_currentIndex + 1 < widget.questions.length) {
          setState(() {
            _currentIndex++;
            _shuffleAnswers();
            _resetTimer();
          });
        } else {
          //end quiz
          _timer.cancel();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => QuizResultsScreen(
                score: _score,
                total: widget.questions.length,
                questions: widget.questions,
                //store user answers
                userAnswers: {
                  for (var i = 0; i < widget.questions.length; i++)
                    i: {
                      'question': widget.questions[i]['question'],
                      'correctAnswer': widget.questions[i]['correct_answer'],
                      'userAnswer': _userAnswers[i],
                    },
                },
              ),
            ),
          );
        }
      }
    });
  }

  //quiz screen
  @override
  Widget build(BuildContext context) {
    //get current question & answers
    final currentQuestion = widget.questions[_currentIndex];
    final questionText = currentQuestion['question'];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //question
          Text(
            'Question ${_currentIndex + 1} of ${widget.questions.length}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          //time left
          Text(
            'Time Left: $_timeLeft seconds',
            style: const TextStyle(fontSize: 16, color: Colors.red),
          ),
          const SizedBox(height: 8),
          //score
          Text(
            'Score: $_score',
            style: const TextStyle(fontSize: 16, color: Colors.green),
          ),
          const SizedBox(height: 16),
          //question 
          Text(
            Uri.decodeComponent(questionText),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          //shuffled answers btns
          ..._shuffledAnswers.map((answer) {
            return Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed:
                      _showFeedback ? null : () => _answerQuestion(answer),
                  child: Text(
                    answer,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8), // Added SizedBox here
              ],
            );
          }),
          //feedback
          if (_showFeedback)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                _feedback!,
                style: TextStyle(
                  fontSize: 18,
                  color: _feedback == 'Correct!' ? Colors.green : Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

//quiz results screen
class QuizResultsScreen extends StatelessWidget {
  //get quiz results
  final int score;
  final int total;
  final List<Map<String, dynamic>> questions;
  final Map<int, Map<String, dynamic>> userAnswers;

//store quiz results
  const QuizResultsScreen({
    super.key,
    required this.score,
    required this.total,
    required this.questions,
    required this.userAnswers,
  });

  //decode answers with null check
  String safeDecode(String? value) {
    if (value == null) return 'No Answer';
    try {
      return Uri.decodeComponent(value);
    } catch (e) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quiz Completed!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            //score display
            Text(
              'Your Score: $score / $total',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            //correct answers & user answers
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = safeDecode(userAnswers[index]?['question']);
                  final correctAnswer =
                      safeDecode(userAnswers[index]?['correctAnswer']);
                  final userAnswer =
                      safeDecode(userAnswers[index]?['userAnswer']);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Q${index + 1}: $question',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Correct Answer: $correctAnswer'),
                        Text(
                          'Your Answer: $userAnswer',
                          style: TextStyle(
                            color: userAnswer == correctAnswer
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            //btn to retake / go back to setup
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Retake Quiz',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
