/// Immutable data model for a single MCQ question.
class McqQuestion {
  final int id;
  final String question;
  final List<String> options;
  final String answer;
  final String topic;

  const McqQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
    required this.topic,
  });
}
