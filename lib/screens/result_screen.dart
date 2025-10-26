import 'package:flutter/material.dart';
import 'package:three_stage_challenge/models/stage_model.dart';
import 'package:three_stage_challenge/screens/stage_flow_screen.dart';
import 'package:three_stage_challenge/screens/start_screen.dart';

class ResultScreen extends StatelessWidget {
  final List<StageResult> results;
  final int totalHints;
  final int totalMisses;
  final List<StageData> stages;

  ResultScreen(
      {required this.results,
      required this.totalHints,
      required this.totalMisses,
      required this.stages});

  String computeSummary() {
    final failedIndices = <int>[];
    for (var i = 0; i < results.length; i++)
      if (!results[i].cleared) failedIndices.add(i + 1);

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
                      subtitle: Text(r.cleared
                          ? 'Cleared (misses: ${r.misses}, hint: ${r.hintUsed ? 'Yes' : 'No'})'
                          : 'Failed (misses: ${r.misses}, hint: ${r.hintUsed ? 'Yes' : 'No'})'),
                      trailing: r.cleared
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : Icon(Icons.cancel, color: Colors.red),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // reset and go back to start
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => StartScreen()));
              },
              child: Text('Play Again'),
            )
          ],
        ),
      ),
    );
  }
}
