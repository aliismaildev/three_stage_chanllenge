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