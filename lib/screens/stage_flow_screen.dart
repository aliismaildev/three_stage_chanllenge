import 'package:flutter/material.dart';
import 'package:three_stage_challenge/main.dart';
import 'package:three_stage_challenge/models/stage_model.dart';
import 'package:three_stage_challenge/screens/result_screen.dart';
import 'package:three_stage_challenge/screens/start_screen.dart';


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

  StageResult(
      {required this.cleared, required this.misses, required this.hintUsed});
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
    results = List.generate(widget.stages.length,
            (_) => StageResult(cleared: false, misses: 0, hintUsed: false));
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
      results[currentIndex] = StageResult(
          cleared: true, misses: missesThisStage, hintUsed: hintUsedThisStage);
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
        results[currentIndex] = StageResult(
            cleared: false,
            misses: missesThisStage,
            hintUsed: hintUsedThisStage);
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
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ResultScreen(
              results: results,
              totalHints: totalHints,
              totalMisses: totalMisses,
              stages: widget.stages)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stages[currentIndex];

    return Scaffold(
      appBar: AppBar(
          title: Text('Stage ${currentIndex + 1} of ${widget.stages.length}')),
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
              decoration: InputDecoration(
                  labelText: 'Your answer', border: OutlineInputBorder()),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: ElevatedButton(
                        onPressed: submitAnswer, child: Text('Submit'))),
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
                Chip(
                    label:
                    Text('Hint used: ${hintUsedThisStage ? 'Yes' : 'No'}')),
                Chip(label: Text('Stage ${currentIndex + 1}')),
              ],
            ),
            SizedBox(height: 16),
            // Progress bar
            LinearProgressIndicator(
                value: (currentIndex + (missesThisStage / 3)) /
                    widget.stages.length),
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
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => StartScreen()));
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