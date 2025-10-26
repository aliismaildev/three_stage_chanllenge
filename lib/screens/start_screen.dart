import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:three_stage_challenge/models/stage_model.dart';
import 'package:three_stage_challenge/screens/stage_flow_screen.dart';

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
        if (snap.connectionState == ConnectionState.waiting)
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        if (snap.hasError)
          return Scaffold(
              body: Center(child: Text('Error loading stages: ${snap.error}')));
        final stages = snap.data!;

        return Scaffold(
          appBar: AppBar(title: Text('Three Stage Challenge')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ready to start?',
                      style: Theme.of(context).textTheme.labelSmall),
                  SizedBox(height: 16),
                  Text('This challenge has ${stages.length} stages.'),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (_) => StageFlowScreen(stages: stages)));
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
