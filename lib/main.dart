import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const PmpSimulatorApp());
}

class PmpSimulatorApp extends StatelessWidget {
  const PmpSimulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PMBOK Training Simulator_Muni',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF073A57),
          primary: const Color(0xFF073A57),
          secondary: const Color(0xFF00A6B2),
        ),
        scaffoldBackgroundColor: const Color(0xFFEEF3F5),
        useMaterial3: true,
      ),
      home: const SimulatorHomeScreen(),
    );
  }
}

// ----------------------------------------------------
// Data Models
// ----------------------------------------------------
class Question {
  final String topic;
  final String q;
  final List<String> o;
  final int a;
  final String e;

  Question({
    required this.topic,
    required this.q,
    required this.o,
    required this.a,
    required this.e,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    var rawOptions = json['o'] ?? json['options'] ?? json['choices'];
    List<String> options = [];
    if (rawOptions is List) {
      options = rawOptions.map((e) => e.toString()).toList();
    }

    int answerIndex = 0;
    var rawA = json['a'] ?? json['answer'] ?? json['correctIndex'];
    if (rawA is int) {
      answerIndex = rawA;
    } else if (rawA is String) {
      if (RegExp(r'^[A-D]$', caseSensitive: false).hasMatch(rawA.trim())) {
        answerIndex = rawA.trim().toUpperCase().codeUnitAt(0) - 65;
      }
    }

    return Question(
      topic: json['topic']?.toString() ?? 'PMBOK',
      q: json['q']?.toString().replaceAll(RegExp(r'\s+'), ' ').trim() ?? '',
      o: options,
      a: answerIndex,
      e: json['e']?.toString() ?? 'No explanation provided.',
    );
  }
}

// ----------------------------------------------------
// Home Configuration Screen
// ----------------------------------------------------
class SimulatorHomeScreen extends StatefulWidget {
  const SimulatorHomeScreen({super.key});

  @override
  State<SimulatorHomeScreen> createState() => _SimulatorHomeScreenState();
}

class _SimulatorHomeScreenState extends State<SimulatorHomeScreen> {
  String practiceMode = 'sprint';
  int questionCount = 10;
  String candidateName = '';
  String domain = 'Schedule';
  String difficulty = 'Ultra-hard';
  String selectedModel = 'gemini-3.5-flash-lite';
  final TextEditingController _apiKeyController = TextEditingController();

  bool isConnected = false;
  bool isTesting = false;
  bool isGenerating = false;
  String statusMessage = 'Enter an API key and test the connection.';
  String statusType = ''; // 'ok', 'bad', or ''

  List<Question> questionBank = [];

  final List<Map<String, String>> models = [
    {'value': 'gemini-3.5-flash-lite', 'label': 'Gemini 3.5 Flash Lite'},
    {'value': 'gemini-3.1-flash-lite', 'label': 'Gemini 3.1 Flash Lite'},
  ];

  final List<String> domains = [
    'Mixed PMBOK 8',
    'Governance',
    'Scope',
    'Schedule',
    'Finance',
    'Stakeholders',
    'Resources',
    'Risk',
    'Procurement',
    'AI and PMO',
    'Adaptive and Hybrid',
  ];

  void _onModeChanged(String newMode) {
    setState(() {
      practiceMode = newMode;
      questionCount = practiceMode == 'sprint' ? 10 : 30;
      questionBank.clear();
      if (isConnected) {
        statusMessage = 'Generate a question set for the selected mode.';
        statusType = '';
      }
    });
  }

  Future<String> _callGemini(String prompt) async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) throw Exception('Gemini API key is required');

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$selectedModel:generateContent?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'temperature': 0.6,
        }
      }),
    );

    if (response.statusCode != 200) {
      final errData = jsonDecode(response.body);
      throw Exception(errData['error']?['message'] ?? 'HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
  }

  Map<String, dynamic> _extractJSON(String text) {
    String cleanText = text.trim().replaceAll(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '').replaceAll(RegExp(r'```\s*$'), '').trim();
    return jsonDecode(cleanText);
  }

  Future<void> _testConnection() async {
    setState(() {
      isTesting = true;
      statusMessage = 'Testing connection...';
      statusType = '';
    });

    try {
      final rawResponse = await _callGemini('Return only {"connected":true}');
      final data = _extractJSON(rawResponse);
      if (data['connected'] != true) throw Exception('Unexpected response');

      setState(() {
        isConnected = true;
        statusMessage = 'Connected to $selectedModel.';
        statusType = 'ok';
      });
    } catch (e) {
      setState(() {
        isConnected = false;
        statusMessage = 'Connection failed: ${e.toString().replaceAll('Exception: ', '')}';
        statusType = 'bad';
      });
    } finally {
      setState(() => isTesting = false);
    }
  }

  Future<void> _generateQuestions() async {
    if (!isConnected) return;

    setState(() {
      isGenerating = true;
      questionBank.clear();
      statusMessage = 'Generating questions...';
      statusType = '';
    });

    try {
      final style = practiceMode == 'sprint'
          ? 'Each question must be one sentence on one line and no more than 25 words.'
          : 'Use concise realistic scenario-based questions.';

      final prompt =
          'Create exactly $questionCount $difficulty PMBOK 8 multiple-choice questions for $domain. $style Return only JSON: {"questions":[{"q":"question","o":["option 1","option 2","option 3","option 4"],"a":0,"e":"explanation","topic":"topic"}]}. Use exactly four options and a zero-based answer index.';

      final rawResponse = await _callGemini(prompt);
      final data = _extractJSON(rawResponse);

      List items = data['questions'] ?? data['items'] ?? [];
      List<Question> fetched = items.map((i) => Question.fromJson(i)).toList();

      if (practiceMode == 'sprint') {
        for (var q in fetched) {
          var words = q.q.split(RegExp(r'\s+'));
          if (words.length > 25) {
            String truncated = words.take(25).join(' ').replaceAll(RegExp(r'[,:;]$'), '');
            q = Question(
              topic: q.topic,
              q: '$truncated?',
              o: q.o,
              a: q.a,
              e: q.e,
            );
          }
        }
      }

      setState(() {
        questionBank = fetched;
        statusMessage = 'Loaded ${questionBank.length} questions. Ready to start.';
        statusType = 'ok';
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Generation failed: ${e.toString().replaceAll('Exception: ', '')}';
        statusType = 'bad';
      });
    } finally {
      setState(() => isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF073A57),
        title: const Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            Text('PMBOK TRAINING SIMULATOR_Muni', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Ready', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                const Text('PMBOK Training Simulator_Muni', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF073A57))),
                const SizedBox(height: 16),

                // Fields Grid
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: 300,
                      child: DropdownButtonFormField<String>(
                        value: practiceMode,
                        decoration: const InputDecoration(labelText: 'Practice mode', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'sprint', child: Text('Sprint Drill')),
                          DropdownMenuItem(value: 'full', child: Text('Full Practice')),
                        ],
                        onChanged: (val) => _onModeChanged(val!),
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: DropdownButtonFormField<int>(
                        value: questionCount,
                        decoration: const InputDecoration(labelText: 'Question count', border: OutlineInputBorder()),
                        items: (practiceMode == 'sprint' ? [5, 10] : [10, 20, 30])
                            .map((c) => DropdownMenuItem(value: c, child: Text('$c')))
                            .toList(),
                        onChanged: (val) => setState(() => questionCount = val!),
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: DropdownButtonFormField<String>(
                        value: domain,
                        decoration: const InputDecoration(labelText: 'Domain', border: OutlineInputBorder()),
                        items: domains.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (val) => setState(() => domain = val!),
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: DropdownButtonFormField<String>(
                        value: difficulty,
                        decoration: const InputDecoration(labelText: 'Difficulty', border: OutlineInputBorder()),
                        items: ['Hard', 'Ultra-hard', 'Expert']
                            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (val) => setState(() => difficulty = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Provider Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBFCFC),
                    border: Border.all(color: const Color(0xFFB8C5CB)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedModel,
                        decoration: const InputDecoration(labelText: 'Model', border: OutlineInputBorder()),
                        items: models.map((m) => DropdownMenuItem(value: m['value'], child: Text(m['label']!))).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedModel = val!;
                            isConnected = false;
                            questionBank.clear();
                            statusMessage = 'Model changed. Test the connection again.';
                            statusType = '';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _apiKeyController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'API key',
                          hintText: 'Paste Gemini API key',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          setState(() {
                            isConnected = false;
                            questionBank.clear();
                            statusMessage = 'API key changed. Test the connection again.';
                            statusType = '';
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Status Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: statusType == 'ok'
                              ? const Color(0xFFEEF8F1)
                              : statusType == 'bad'
                                  ? const Color(0xFFFFF4F3)
                                  : const Color(0xFFEEF6F7),
                          border: Border(
                            left: BorderSide(
                              color: statusType == 'ok'
                                  ? const Color(0xFF17823B)
                                  : statusType == 'bad'
                                      ? const Color(0xFFC43832)
                                      : const Color(0xFF00A6B2),
                              width: 4,
                            ),
                          ),
                        ),
                        child: Text(statusMessage),
                      ),
                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: isTesting ? null : _testConnection,
                            child: isTesting ? const CircularProgressIndicator() : const Text('Test Connection'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: isConnected && !isGenerating ? _generateQuestions : null,
                            child: isGenerating ? const CircularProgressIndicator() : const Text('Generate Questions'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF073A57),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: questionBank.isNotEmpty
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ActiveQuizScreen(
                                          practiceMode: practiceMode,
                                          questions: questionBank,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            child: Text(practiceMode == 'sprint' ? 'Start Sprint Drill' : 'Start Full Practice'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Timing Rules Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF6F7),
                    border: Border(left: BorderSide(color: Color(0xFF00A6B2), width: 4)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Text('Timing rules', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 6),
                      Text('• Sprint Drill: 30 seconds per question, maximum 10 questions.'),
                      Text('• Full Practice: 60 seconds per question, maximum 30 questions.'),
                      Text('• Unanswered questions are skipped when time expires.'),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// Active Quiz Screen (Timer, Navigator, Options)
// ----------------------------------------------------
class ActiveQuizScreen extends StatefulWidget {
  final String practiceMode;
  final List<Question> questions;

  const ActiveQuizScreen({
    super.key,
    required this.practiceMode,
    required this.questions,
  });

  @override
  State<ActiveQuizScreen> createState() => _ActiveQuizScreenState();
}

class _ActiveQuizScreenState extends State<ActiveQuizScreen> {
  int currentIndex = 0;
  late List<int?> answers;
  late List<bool> flags;
  late List<bool> expired;

  late int remainingSeconds;
  Timer? timer;
  late DateTime startTime;

  @override
  void initState() {
    super.initState();
    answers = List.filled(widget.questions.length, null);
    flags = List.filled(widget.questions.length, false);
    expired = List.filled(widget.questions.length, false);
    startTime = DateTime.now();
    _resetTimer();
  }

  void _resetTimer() {
    timer?.cancel();
    remainingSeconds = widget.practiceMode == 'sprint' ? 30 : 60;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        t.cancel();
        if (answers[currentIndex] == null) {
          expired[currentIndex] = true;
        }
        if (currentIndex < widget.questions.length - 1) {
          setState(() {
            currentIndex++;
            _resetTimer();
          });
        } else {
          _finishPractice();
        }
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String _formatTimer(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '00:$m:$sec';
  }

  void _finishPractice() {
    timer?.cancel();
    final duration = DateTime.now().difference(startTime);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => FinalResultsScreen(
          questions: widget.questions,
          answers: answers,
          expired: expired,
          usedMinutes: duration.inMinutes < 1 ? 1 : duration.inMinutes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.questions[currentIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF073A57),
        title: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            const Text('PMBOK TRAINING SIMULATOR_Muni', style: TextStyle(color: Colors.white, fontSize: 16)),
            Text(widget.practiceMode == 'sprint' ? 'Sprint Drill' : 'Full Practice', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF6F8998))),
            child: Text(
              _formatTimer(remainingSeconds),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() => flags[currentIndex] = !flags[currentIndex]);
                    },
                    child: Text(flags[currentIndex] ? '⚑ Remove Flag' : '⚑ Flag for Review'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${currentIndex + 1} of ${widget.questions.length} · ${q.topic}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        expired[currentIndex] ? 'Skipped' : flags[currentIndex] ? '⚑ Flagged' : '',
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(q.q, style: const TextStyle(fontSize: 18, height: 1.5)),
                  const SizedBox(height: 20),

                  // Answers
                  ...List.generate(
                    q.o.length,
                    (k) => Card(
                      color: answers[currentIndex] == k ? const Color(0xFFEAF5F7) : Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: answers[currentIndex] == k ? const Color(0xFF073A57) : const Color(0xFFA8B6BD),
                          width: answers[currentIndex] == k ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListTile(
                        leading: Text(
                          '${String.fromCharCode(65 + k)}.',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        title: Text(q.o[k]),
                        onTap: expired[currentIndex]
                            ? null
                            : () {
                                setState(() {
                                  answers[currentIndex] = k;
                                });
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Grid Navigator
                  const Text('Question Navigator', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(
                      widget.questions.length,
                      (k) => SizedBox(
                        width: 44,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: answers[k] != null
                                ? const Color(0xFF073A57)
                                : expired[k]
                                    ? Colors.grey.shade300
                                    : Colors.white,
                            foregroundColor: answers[k] != null ? Colors.white : Colors.black,
                            side: BorderSide(
                              color: k == currentIndex
                                  ? const Color(0xFF00A6B2)
                                  : flags[k]
                                      ? const Color(0xFFF2A900)
                                      : Colors.grey,
                              width: k == currentIndex || flags[k] ? 3 : 1,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              currentIndex = k;
                              _resetTimer();
                            });
                          },
                          child: Text('${k + 1}'),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),

          // Footer Toolbar
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF3F6F7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: _finishPractice,
                  child: const Text('End Practice'),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: currentIndex == 0
                          ? null
                          : () {
                              setState(() {
                                currentIndex--;
                                _resetTimer();
                              });
                            },
                      child: const Text('Previous'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF073A57),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (currentIndex < widget.questions.length - 1) {
                          setState(() {
                            currentIndex++;
                            _resetTimer();
                          });
                        } else {
                          _finishPractice();
                        }
                      },
                      child: Text(currentIndex == widget.questions.length - 1 ? 'Finish' : 'Next'),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// Final Results Modal Screen
// ----------------------------------------------------
class FinalResultsScreen extends StatelessWidget {
  final List<Question> questions;
  final List<int?> answers;
  final List<bool> expired;
  final int usedMinutes;

  const FinalResultsScreen({
    super.key,
    required this.questions,
    required this.answers,
    required this.expired,
    required this.usedMinutes,
  });

  @override
  Widget build(BuildContext context) {
    int correctCount = 0;
    int answeredCount = 0;

    for (int i = 0; i < questions.length; i++) {
      if (answers[i] != null) {
        answeredCount++;
        if (answers[i] == questions[i].a) {
          correctCount++;
        }
      }
    }

    int percentage = ((correctCount / questions.length) * 100).round();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF073A57),
        title: const Text('Final Results', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                const Text('Final Results', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF073A57))),
                const SizedBox(height: 16),

                // Stats Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('$percentage%', 'Score'),
                    _buildStatCard('$correctCount/${questions.length}', 'Correct'),
                    _buildStatCard('$answeredCount/${questions.length}', 'Answered'),
                    _buildStatCard('${usedMinutes}m', 'Time used'),
                  ],
                ),
                const SizedBox(height: 24),

                // Itemized Results
                ...List.generate(questions.length, (k) {
                  final q = questions[k];
                  final isCorrect = answers[k] == q.a;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCorrect ? const Color(0xFFF3F8F5) : const Color(0xFFFFF4F3),
                      border: Border(
                        left: BorderSide(
                          color: isCorrect ? const Color(0xFF17823B) : const Color(0xFFC43832),
                          width: 5,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        Text(
                          'Question ${k + 1}: ${isCorrect ? "Correct" : expired[k] ? "Skipped" : "Incorrect"}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Your answer: ${answers[k] == null ? "Not answered" : q.o[answers[k]!]}'),
                        Text('Correct answer: ${q.o[q.a]}'),
                        Text('Explanation: ${q.e}'),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF073A57),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SimulatorHomeScreen()),
                      );
                    },
                    child: const Text('Return Home'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF073A57))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
