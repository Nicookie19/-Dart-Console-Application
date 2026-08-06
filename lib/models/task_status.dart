/// The lifecycle status of a [Task].
enum TaskStatus {
  todo('Todo'),
  inProgress('In Progress'),
  done('Done');

  const TaskStatus(this.label);

  /// Human-readable label.
  final String label;

  /// Parses a status from its label (case-insensitive) or name.
  static TaskStatus fromInput(String input) {
    return TaskStatus.values.firstWhere(
      (s) => s.label.toLowerCase() == input.trim().toLowerCase() ||
          s.name.toLowerCase() == input.trim().toLowerCase(),
      orElse: () => throw FormatException(
        "Unknown status '$input'. Use: ${values.map((s) => s.label).join(', ')}",
      ),
    );
  }

  @override
  String toString() => label;
}
