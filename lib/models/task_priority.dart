/// The priority level assigned to a [Task].
enum TaskPriority {
  low(1, 'Low'),
  medium(2, 'Medium'),
  high(3, 'High'),
  urgent(4, 'Urgent');

  const TaskPriority(this.level, this.label);

  /// Numeric weight used for sorting (higher = more urgent).
  final int level;

  /// Human-readable label.
  final String label;

  /// Parses a priority from its label (case-insensitive) or name.
  static TaskPriority fromInput(String input) {
    return TaskPriority.values.firstWhere(
      (p) => p.label.toLowerCase() == input.trim().toLowerCase() ||
          p.name.toLowerCase() == input.trim().toLowerCase(),
      orElse: () => throw FormatException(
        "Unknown priority '$input'. Use: ${values.map((p) => p.label).join(', ')}",
      ),
    );
  }

  @override
  String toString() => label;
}
