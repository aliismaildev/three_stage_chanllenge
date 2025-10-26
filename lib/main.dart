
import 'package:flutter/material.dart';
import 'package:three_stage_challenge/screens/start_screen.dart';

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




