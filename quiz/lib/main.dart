import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customizable Quiz App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SetupScreen(),
    );
  }
}

// Setup Screen for Quiz Customization
class SetupScreen extends StatefulWidget {
  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int numberOfQuestions = 5;
  String selectedCategory = 'General Knowledge';
  String selectedDifficulty = 'easy';
  String selectedType = 'multiple';

  // Categories and their IDs will be fetched from the Open Trivia Database
  List<String> categories = ["General Knowledge", "Sports", "Movies"];
  List<String> difficulties = ["easy", "medium", "hard"];
  List<String> types = ["multiple", "boolean"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quiz Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<int>(
              value: numberOfQuestions,
              onChanged: (int? newValue) {
                setState(() {
                  numberOfQuestions = newValue!;
                });
              },
              items: [5, 10, 15]
                  .map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
            ),
            DropdownButton<String>(
              value: selectedCategory,
              onChanged: (String? newValue) {
                setState(() {
                  selectedCategory = newValue!;
                });
              },
              items: categories
                  .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
            ),
            DropdownButton<String>(
              value: selectedDifficulty,
              onChanged: (String? newValue) {
                setState(() {
                  selectedDifficulty = newValue!;
                });
              },
              items: difficulties
                  .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
            ),
            DropdownButton<String>(
              value: selectedType,
              onChanged: (String? newValue) {
                setState(() {
                  selectedType = newValue!;
                });
              },
              items: types
                  .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to quiz screen and pass selected options
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizScreen(
                      numberOfQuestions: numberOfQuestions,
                      selectedCategory: selectedCategory,
                      selectedDifficulty: selectedDifficulty,
                      selectedType: selectedType,
                    ),
                  ),
                );
              },
              child: Text('Start Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}

// Model for Question
class Question {
  final String questionText;
  final List<String> options;
  final String correctAnswer;

  Question({
    required this.questionText,
    required this.options,
    required this.correctAnswer,
  });
}

// Quiz Screen
class QuizScreen extends StatefulWidget {
  final int numberOfQuestions;
  final String selectedCategory;
  final String selectedDifficulty;
  final String selectedType;

  QuizScreen({
    required this.numberOfQuestions,
    required this.selectedCategory,
    required this.selectedDifficulty,
    required this.selectedType,
  });

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int score = 0;
  int currentQuestionIndex = 0;
  List<Question> questions = [];
  String feedback = '';
  Timer? _timer;
  int _timeRemaining = 10; // 10 seconds for each question
  bool _timeUp = false;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
    _startTimer();
  }

  void _fetchQuestions() async {
    final response = await http.get(Uri.parse(
      'https://opentdb.com/api.php?amount=${widget.numberOfQuestions}&category=9&difficulty=${widget.selectedDifficulty}&type=${widget.selectedType}',
    ));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        questions = (data['results'] as List)
            .map((q) => Question(
                  questionText: q['question'],
                  options: List<String>.from(q['incorrect_answers']..add(q['correct_answer'])),
                  correctAnswer: q['correct_answer'],
                ))
            .toList();
      });
    } else {
      // Handle error if API call fails
      setState(() {
        feedback = "Error fetching questions!";
      });
    }
  }

  void _checkAnswer(String selectedAnswer) {
    if (_timeUp) return;

    if (selectedAnswer == questions[currentQuestionIndex].correctAnswer) {
      setState(() {
        score++;
        feedback = "Correct!";
      });
    } else {
      setState(() {
        feedback = "Incorrect! Correct answer: ${questions[currentQuestionIndex].correctAnswer}";
      });
    }

    setState(() {
      currentQuestionIndex++;
      _timeUp = false; // Reset the time-up flag for next question
      _startTimer();
    });
  }

  void _startTimer() {
    _timeRemaining = 10;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timeRemaining == 0) {
        _timer?.cancel();
        setState(() {
          _timeUp = true;
        });
        _checkAnswer(""); // Time's up
      } else {
        setState(() {
          _timeRemaining--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / widget.numberOfQuestions,
            ),
            SizedBox(height: 20),
            Text('Score: $score'),
            SizedBox(height: 20),
            Text('Time Remaining: $_timeRemaining'),
            SizedBox(height: 20),
            Text(questions[currentQuestionIndex].questionText),
            SizedBox(height: 20),
            ...questions[currentQuestionIndex]
                .options
                .map((option) => ElevatedButton(
                      onPressed: () => _checkAnswer(option),
                      child: Text(option),
                    ))
                .toList(),
            SizedBox(height: 20),
            Text(feedback),
          ],
        ),
      ),
    );
  }
}

// End Screen for Quiz Summary
class EndScreen extends StatelessWidget {
  final int score;
  final List<Question> questions;

  EndScreen({required this.score, required this.questions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quiz Summary')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Your score: $score/${questions.length}'),
            SizedBox(height: 20),
            ...List.generate(questions.length, (index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q${index + 1}: ${questions[index].questionText}'),
                  Text('Your answer: ${questions[index].correctAnswer}'),
                  SizedBox(height: 10),
                ],
              );
            }),
            ElevatedButton(
              onPressed: () {
                // Restart the quiz
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SetupScreen()),
                );
              },
              child: Text('Retake Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
