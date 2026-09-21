import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const PmpExamApp());
}

class PmpExamApp extends StatelessWidget {
  const PmpExamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PMP Exam Prep 2026',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A365D),
          primary: const Color(0xFF1A365D),
          secondary: const Color(0xFF2B6CB0),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7FAFC),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // Domain Performance Metrics
  int totalSolved = 0;
  int correctPeople = 0;
  int totalPeople = 0;
  int correctProcess = 0;
  int totalProcess = 0;
  int correctBusiness = 0;
  int totalBusiness = 0;

  void _recordAnswer(String domain, bool isCorrect) {
    setState(() {
      totalSolved++;
      if (domain == 'People') {
        totalPeople++;
        if (isCorrect) correctPeople++;
      } else if (domain == 'Process') {
        totalProcess++;
        if (isCorrect) correctProcess++;
      } else if (domain == 'Business') {
        totalBusiness++;
        if (isCorrect) correctBusiness++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      PracticeModeSelectionScreen(onQuestionAnswered: _recordAnswer),
      PerformanceDashboard(
        totalSolved: totalSolved,
        correctPeople: correctPeople,
        totalPeople: totalPeople,
        correctProcess: correctProcess,
        totalProcess: totalProcess,
        correctBusiness: correctBusiness,
        totalBusiness: totalBusiness,
      ),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1A365D),
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Practice'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Performance'),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// Mode Selection Screen (Sprint, Full Test, Domain)
// ----------------------------------------------------
class PracticeModeSelectionScreen extends StatelessWidget {
  final Function(String domain, bool isCorrect) onQuestionAnswered;

  const PracticeModeSelectionScreen({super.key, required this.onQuestionAnswered});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A365D),
        title: const Text('PMP® Exam Practice Modes', style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Choose Practice Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A365D)),
          ),
          const SizedBox(height: 16),
          _buildModeCard(
            context,
            title: 'Sprint Practice Test',
            subtitle: '10 Questions • 15 Minutes Timer',
            icon: Icons.bolt,
            color: Colors.orange,
            durationSeconds: 15 * 60,
            modeName: 'Sprint Practice',
          ),
          _buildModeCard(
            context,
            title: 'Full Mock Exam',
            subtitle: '180 Questions • 230 Minutes Timer',
            icon: Icons.assignment,
            color: Colors.blue,
            durationSeconds: 230 * 60,
            modeName: 'Full Mock Exam',
          ),
          _buildModeCard(
            context,
            title: 'Domain Specific Practice',
            subtitle: 'ECO Domains (People, Process, Business)',
            icon: Icons.category,
            color: Colors.green,
            durationSeconds: 30 * 60,
            modeName: 'Domain Practice',
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int durationSeconds,
    required String modeName,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExamQuizScreen(
                modeName: modeName,
                durationSeconds: durationSeconds,
                onQuestionAnswered: onQuestionAnswered,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------
// Active Quiz Screen with Timer & Working Option Selection
// ----------------------------------------------------
class ExamQuizScreen extends StatefulWidget {
  final String modeName;
  final int durationSeconds;
  final Function(String domain, bool isCorrect) onQuestionAnswered;

  const ExamQuizScreen({
    super.key,
    required this.modeName,
    required this.durationSeconds,
    required this.onQuestionAnswered,
  });

  @override
  State<ExamQuizScreen> createState() => _ExamQuizScreenState();
}

class _ExamQuizScreenState extends State<ExamQuizScreen> {
  late int _remainingSeconds;
  Timer? _timer;

  int currentQuestionIndex = 0;
  int? selectedAnswer;
  bool isSubmitted = false;

  final List<Map<String, dynamic>> questions = [
    {
      "id": "Q1",
      "domain": "People",
      "question": "A conflict arises between team members regarding deliverables. What should the PM do FIRST?",
      "options": [
        "Escalate to the project sponsor",
        "Encourage team members to resolve it directly",
        "Reassign team members immediately",
        "Issue a formal warning"
      ],
      "correctAnswers": 1,
      "explanation": "PM Mindset: Direct collaboration and empowering the team is preferred before escalation."
    },
    {
      "id": "Q2",
      "domain": "Process",
      "question": "A high-impact risk materializes during project execution. What is the FIRST step?",
      "options": [
        "Evaluate impact & consult the Risk Response Plan",
        "Request contingency budget immediately",
        "Change the baseline schedule",
        "Inform executive management"
      ],
      "correctAnswers": 0,
      "explanation": "PM Mindset: Always evaluate impact and execute planned responses prior to taking corrective measures."
    },
    {
      "id": "Q3",
      "domain": "Business",
      "question": "A regulatory compliance policy changes during execution. What should the PM do FIRST?",
      "options": [
        "Update the business case and analyze compliance gaps",
        "Halt all project deliverables immediately",
        "Request additional funding from stakeholders",
        "Ignore changes until the next project phase"
      ],
      "correctAnswers": 0,
      "explanation": "PM Mindset: Understand business environment impacts and evaluate compliance requirements thoroughly."
    }
  ];

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final q = questions[currentQuestionIndex];
    final options = List<String>.from(q['options']);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A365D),
        title: Text(widget.modeName, style: const TextStyle(color: Colors.white, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.amber, size: 20),
                const SizedBox(width: 6),
                Text(
                  _formatTimer(_remainingSeconds),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Domain: ${q['domain']}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                Text("Question ${currentQuestionIndex + 1} of ${questions.length}", style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            Text(q['question'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Option List
            ...List.generate(
              options.length,
              (index) => Card(
                color: selectedAnswer == index ? Colors.blue.shade50 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: selectedAnswer == index ? const Color(0xFF1A365D) : Colors.grey.shade300,
                  ),
                ),
                child: RadioListTile<int>(
                  value: index,
                  groupValue: selectedAnswer,
                  title: Text(options[index]),
                  activeColor: const Color(0xFF1A365D),
                  onChanged: isSubmitted
                      ? null
                      : (val) {
                          setState(() {
                            selectedAnswer = val;
                          });
                        },
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (!isSubmitted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A365D)),
                  onPressed: selectedAnswer == null
                      ? null
                      : () {
                          setState(() => isSubmitted = true);
                          bool isCorrect = selectedAnswer == q['correctAnswers'];
                          widget.onQuestionAnswered(q['domain'], isCorrect);
                        },
                  child: const Text("Submit Answer", style: TextStyle(color: Colors.white)),
                ),
              ),

            if (isSubmitted) ...[
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selectedAnswer == q['correctAnswers'] ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selectedAnswer == q['correctAnswers'] ? Colors.green : Colors.red,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedAnswer == q['correctAnswers'] ? "Correct Answer!" : "Incorrect Answer",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: selectedAnswer == q['correctAnswers'] ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text("Explanation: ${q['explanation']}", style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              if (currentQuestionIndex < questions.length - 1)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        currentQuestionIndex++;
                        selectedAnswer = null;
                        isSubmitted = false;
                      });
                    },
                    child: const Text("Next Question"),
                  ),
                )
            ]
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// PMP Style Performance Dashboard
// ----------------------------------------------------
class PerformanceDashboard extends StatelessWidget {
  final int totalSolved;
  final int correctPeople;
  final int totalPeople;
  final int correctProcess;
  final int totalProcess;
  final int correctBusiness;
  final int totalBusiness;

  const PerformanceDashboard({
    super.key,
    required this.totalSolved,
    required this.correctPeople,
    required this.totalPeople,
    required this.correctProcess,
    required this.totalProcess,
    required this.correctBusiness,
    required this.totalBusiness,
  });

  String _getPmpGrade(int correct, int total) {
    if (total == 0) return "Needs Improvement (NI)";
    double percentage = (correct / total) * 100;
    if (percentage >= 80) return "Above Target (AT)";
    if (percentage >= 65) return "Target (T)";
    return "Needs Improvement (NI)";
  }

  Color _getGradeColor(String grade) {
    if (grade.contains("Above Target")) return Colors.green.shade700;
    if (grade.contains("Target")) return Colors.blue.shade700;
    return Colors.orange.shade800;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A365D),
        title: const Text('PMP® Performance Dashboard', style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total Questions Attempted", style: TextStyle(fontSize: 14, color: Colors.grey)),
                        SizedBox(height: 4),
                        Text("Exam Readiness Tracker", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(
                      "$totalSolved",
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A365D)),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Domain Performance Analysis",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A365D)),
            ),
            const SizedBox(height: 4),
            const Text("Aligned with PMI Exam Content Outline (ECO)", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 15),

            _buildDomainCard("1. People Domain", correctPeople, totalPeople),
            _buildDomainCard("2. Process Domain", correctProcess, totalProcess),
            _buildDomainCard("3. Business Environment", correctBusiness, totalBusiness),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainCard(String title, int correct, int total) {
    String grade = _getPmpGrade(correct, total);
    Color statusColor = _getGradeColor(grade);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    grade,
                    style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 12),
                  ),
                )
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: total == 0 ? 0 : correct / total,
              backgroundColor: Colors.grey.shade200,
              color: statusColor,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text("$correct / $total Score Points", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
