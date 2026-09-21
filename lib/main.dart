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

  // Domain Stats Tracker
  int totalSolved = 0;
  int correctPeople = 0;
  int totalPeople = 0;
  int correctProcess = 0;
  int totalProcess = 0;
  int correctBusiness = 0;
  int totalBusiness = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      ExamScreen(onQuestionAnswered: (domain, isCorrect) {
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
      }),
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

// --- PMP Style Performance Dashboard ---
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

// --- Main Quiz Engine ---
class QuestionModel {
  final String id;
  final String domain;
  final String type;
  final String question;
  final List<String> options;
  final dynamic correctAnswers;
  final String explanation;

  QuestionModel({
    required this.id,
    required this.domain,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswers,
    required this.explanation,
  });
}

class ExamScreen extends StatefulWidget {
  final Function(String domain, bool isCorrect) onQuestionAnswered;
  const ExamScreen({super.key, required this.onQuestionAnswered});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  int currentQuestionIndex = 0;
  int? selectedAnswer;
  bool isSubmitted = false;

  final List<QuestionModel> questions = [
    QuestionModel(
      id: "Q1",
      domain: "People",
      type: "single",
      question: "A conflict arises between team members regarding deliverables. What should the PM do FIRST?",
      options: [
        "Escalate to the project sponsor",
        "Encourage team members to resolve it directly",
        "Reassign team members immediately",
        "Issue a formal warning"
      ],
      correctAnswers: 1,
      explanation: "PM Mindset: Direct collaboration and empowering the team is preferred before escalation."
    ),
    QuestionModel(
      id: "Q2",
      domain: "Process",
      type: "single",
      question: "A high-impact risk materializes during project execution. What is the FIRST step?",
      options: [
        "Evaluate impact & consult the Risk Response Plan",
        "Request contingency budget immediately",
        "Change the baseline schedule",
        "Inform executive management"
      ],
      correctAnswers: 0,
      explanation: "PM Mindset: Always evaluate impact and execute planned responses prior to taking corrective measures."
    )
  ];

  @override
  Widget build(BuildContext context) {
    final q = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A365D),
        title: const Text('PMP Practice Exam', style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Domain: ${q.domain}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(q.question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...List.generate(
              q.options.length,
              (index) => Card(
                color: selectedAnswer == index ? Colors.blue.shade50 : null,
                child: ListTile(
                  title: Text(q.options[index]),
                  leading: Radio<int>(
                    value: index,
                    groupValue: selectedAnswer,
                    onChanged: isSubmitted ? null : (val) => setState(() => selectedAnswer = val),
                  ),
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
                          bool isCorrect = selectedAnswer == q.correctAnswers;
                          widget.onQuestionAnswered(q.domain, isCorrect);
                        },
                  child: const Text("Submit Answer", style: TextStyle(color: Colors.white)),
                ),
              ),
            if (isSubmitted) ...[
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("Explanation: ${q.explanation}", style: const TextStyle(color: Colors.black87)),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
