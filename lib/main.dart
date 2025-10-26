import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() => runApp(ThreeStageApp());

class ThreeStageApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Three Stage Challenge',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StartScreen(),
    );
  }
}

class StageData {
  final String prompt;
  final String answer;
  final String hint;

  StageData({required this.prompt, required this.answer, required this.hint});

  factory StageData.fromJson(Map<String, dynamic> j) => StageData(
    prompt: j['prompt'] as String,
    answer: j['answer'] as String,
    hint: j['hint'] as String,
  );
}

class StartScreen extends StatefulWidget {
  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late Future<List<StageData>> _stagesFuture;

  @override
  void initState() {
    super.initState();
    _stagesFuture = loadStages();
  }

  Future<List<StageData>> loadStages() async {
    final jsonStr = await rootBundle.loadString('assets/stages.json');
    final Map<String, dynamic> data = json.decode(jsonStr);
    final List stages = data['stages'];
    return stages.map((s) => StageData.fromJson(s)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StageData>>(
      future: _stagesFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return Scaffold(body: Center(child: CircularProgressIndicator()));
        if (snap.hasError) return Scaffold(body: Center(child: Text('Error loading stages: ${snap.error}')));
        final stages = snap.data!;

        return Scaffold(
          appBar: AppBar(title: Text('Three Stage Challenge')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ready to start?', style: Theme.of(context).textTheme.labelSmall),
                  SizedBox(height: 16),
                  Text('This challenge has ${stages.length} stages.'),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => StageFlowScreen(stages: stages)));
                    },
                    child: Text('Begin Challenge'),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class StageFlowScreen extends StatefulWidget {
  final List<StageData> stages;
  StageFlowScreen({required this.stages});

  @override
  _StageFlowScreenState createState() => _StageFlowScreenState();
}

class StageResult {
  final bool cleared;
  final int misses;
  final bool hintUsed;
  StageResult({required this.cleared, required this.misses, required this.hintUsed});
}

class _StageFlowScreenState extends State<StageFlowScreen> {
  int currentIndex = 0;
  List<StageResult> results = [];
  int totalHints = 0;
  int totalMisses = 0;

  // Per-stage state
  int missesThisStage = 0;
  bool hintUsedThisStage = false;
  final TextEditingController _controller = TextEditingController();
  String feedback = '';

  @override
  void initState() {
    super.initState();
    results = List.generate(widget.stages.length, (_) => StageResult(cleared: false, misses: 0, hintUsed: false));
  }

  void resetStageState() {
    missesThisStage = 0;
    hintUsedThisStage = false;
    _controller.clear();
    feedback = '';
  }

  void submitAnswer() {
    final user = _controller.text.trim();
    final correct = widget.stages[currentIndex].answer.trim().toLowerCase();
    if (user.toLowerCase() == correct) {
      // cleared
      results[currentIndex] = StageResult(cleared: true, misses: missesThisStage, hintUsed: hintUsedThisStage);
      totalMisses += missesThisStage;
      if (hintUsedThisStage) totalHints += 1;
      setState(() {
        feedback = 'Correct! Moving to next stage...';
      });
      Future.delayed(Duration(milliseconds: 600), () => moveNext());
    } else {
      setState(() {
        missesThisStage += 1;
        feedback = 'Incorrect (${missesThisStage}/3)';
      });
      if (missesThisStage >= 3) {
        // fail this stage
        results[currentIndex] = StageResult(cleared: false, misses: missesThisStage, hintUsed: hintUsedThisStage);
        totalMisses += missesThisStage;
        if (hintUsedThisStage) totalHints += 1;
        Future.delayed(Duration(milliseconds: 600), () => moveNext());
      }
    }
  }

  void useHint() {
    if (hintUsedThisStage) return;
    setState(() {
      hintUsedThisStage = true;
      feedback = 'Hint: ${widget.stages[currentIndex].hint}';
    });
  }

  void moveNext() {
    if (currentIndex + 1 < widget.stages.length) {
      setState(() {
        currentIndex += 1;
        resetStageState();
      });
    } else {
      // finished all stages
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ResultScreen(results: results, totalHints: totalHints, totalMisses: totalMisses, stages: widget.stages)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stages[currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text('Stage ${currentIndex + 1} of ${widget.stages.length}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(stage.prompt, style: Theme.of(context).textTheme.labelSmall),
            SizedBox(height: 12),
            TextField(
              controller: _controller,
              onSubmitted: (_) => submitAnswer(),
              decoration: InputDecoration(labelText: 'Your answer', border: OutlineInputBorder()),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: submitAnswer, child: Text('Submit'))),
                SizedBox(width: 12),
                OutlinedButton(
                  onPressed: hintUsedThisStage ? null : useHint,
                  child: Text(hintUsedThisStage ? 'Hint used' : 'Hint'),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(feedback, style: TextStyle(color: Colors.black54)),
            SizedBox(height: 16),
            // Visual counters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(label: Text('Misses: $missesThisStage/3')),
                Chip(label: Text('Hint used: ${hintUsedThisStage ? 'Yes' : 'No'}')),
                Chip(label: Text('Stage ${currentIndex + 1}')),
              ],
            ),
            SizedBox(height: 16),
            // Progress bar
            LinearProgressIndicator(value: (currentIndex + (missesThisStage / 3)) / widget.stages.length),
            SizedBox(height: 8),
            Text('Total hints used (so far): $totalHints'),
            Text('Total misses counted (so far): $totalMisses'),
            Spacer(),
            TextButton(
              onPressed: () {
                // confirm reset to start screen
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Quit challenge?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => StartScreen()));
                        },
                        child: Text('Quit'),
                      )
                    ],
                  ),
                );
              },
              child: Text('Exit to Start'),
            )
          ],
        ),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final List<StageResult> results;
  final int totalHints;
  final int totalMisses;
  final List<StageData> stages;
  ResultScreen({required this.results, required this.totalHints, required this.totalMisses, required this.stages});

  String computeSummary() {
    final failedIndices = <int>[];
    for (var i = 0; i < results.length; i++) if (!results[i].cleared) failedIndices.add(i + 1);

    if (failedIndices.isEmpty) {
      if (totalHints == 0 && totalMisses == 0) return 'Perfect run';
      return 'All stages cleared';
    }
    return 'Stage(s) failed: ${failedIndices.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final summary = computeSummary();
    return Scaffold(
      appBar: AppBar(title: Text('Result')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(summary, style: Theme.of(context).textTheme.labelSmall),
            SizedBox(height: 12),
            Text('Total hints used: $totalHints'),
            Text('Total misses: $totalMisses'),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, idx) {
                  final r = results[idx];
                  return Card(
                    child: ListTile(
                      title: Text('Stage ${idx + 1}: ${stages[idx].prompt}'),
                      subtitle: Text(r.cleared ? 'Cleared (misses: ${r.misses}, hint: ${r.hintUsed ? 'Yes' : 'No'})' : 'Failed (misses: ${r.misses}, hint: ${r.hintUsed ? 'Yes' : 'No'})'),
                      trailing: r.cleared ? Icon(Icons.check_circle, color: Colors.green) : Icon(Icons.cancel, color: Colors.red),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // reset and go back to start
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => StartScreen()));
              },
              child: Text('Play Again'),
            )
          ],
        ),
      ),
    );
  }
}
