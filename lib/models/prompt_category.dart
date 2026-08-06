/// The category a [Prompt] belongs to.
enum PromptCategory {
  general('General'),
  code('Code'),
  writing('Writing'),
  reasoning('Reasoning'),
  translation('Translation');

  const PromptCategory(this.label);

  /// Human-readable label.
  final String label;

  /// Parses a category from its label (case-insensitive) or name.
  static PromptCategory fromInput(String input) {
    return PromptCategory.values.firstWhere(
      (c) => c.label.toLowerCase() == input.trim().toLowerCase() ||
          c.name.toLowerCase() == input.trim().toLowerCase(),
      orElse: () => throw FormatException(
        "Unknown category '$input'. Use: ${values.map((c) => c.label).join(', ')}",
      ),
    );
  }

  @override
  String toString() => label;
}
