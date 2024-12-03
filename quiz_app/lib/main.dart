import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quiz_app/quiz.dart';

void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Quiz App',
      home: SetupScreen(),
    );
  }
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  //quiz settings
  int _numQuestions = 5;
  String? _category;
  String _difficulty = 'easy';
  String _type = 'multiple';
  //cateogry list
  List<Map<String, dynamic>> _categories = [];

  //loading
  bool _isLoading = true;

  //init categories
  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  //fetch categories from api
  Future<void> _fetchCategories() async {
    try {
      //api call
      final response =
          await http.get(Uri.parse('https://opentdb.com/api_category.php'));
      if (response.statusCode == 200) {
        //parse response
        final data = json.decode(response.body);

        setState(() {
          //map response into category list
          _categories = List<Map<String, dynamic>>.from(
            data['trivia_categories'].map(
              (cat) => {'id': cat['id'].toString(), 'name': cat['name']},
            ),
          );
          _isLoading = false;
        });
      } else {
        //error
        _showError(
            'Error fetching categories (Status Code: ${response.statusCode})');
      }
    } catch (e) {
      //error
      _showError('Error fetching categories');
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
          'Quiz Setup',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
      ),
      body: _isLoading
          ? const Center(
            //show loading
              child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column( crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //categories
                  DropdownButtonFormField(
                    value: _category,
                    decoration:const InputDecoration(labelText: 'Select Category'),
                    items: _categories
                        .map((category) => DropdownMenuItem<String>(
                              value: category['id'],
                              child: Text(category['name']!),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _category = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Number of Questions: $_numQuestions',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Slider(
                    value: _numQuestions.toDouble(),
                    min: 5,
                    max: 15,
                    divisions: 2,
                    label: _numQuestions.toString(),
                    onChanged: (value) {
                      setState(() {
                        _numQuestions = value.toInt();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  //difficulty radios
                  const Text(
                    'Difficulty',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ['easy', 'medium', 'hard'].map((difficulty) {
                      return RadioListTile<String>(
                        title: Text(difficulty[0].toUpperCase() +
                            difficulty.substring(1)),
                        value: difficulty,
                        groupValue: _difficulty,
                        onChanged: (value) {
                          setState(() {
                            _difficulty = value!;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  //question type radios
                  const Text(
                    'Question Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ['multiple', 'boolean'].map((type) {
                      return RadioListTile<String>(
                        title: Text(type == 'boolean'
                            ? 'True/False'
                            : 'Multiple Choice'),
                        value: type,
                        groupValue: _type,
                        onChanged: (value) {
                          setState(() {
                            _type = value!;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  //submit button
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        textStyle: const TextStyle(fontSize: 16),
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      onPressed: () {
                        if (_category == null) {
                          _showError('Select a category to continue!');
                        } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => QuizScreen(
                              category: _category!,
                              numQuestions: _numQuestions,
                              difficulty: _difficulty,
                              type: _type,
                            ),
                          ),
                        );
                        }
                      },
                      child: const Text('Start Quiz'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
