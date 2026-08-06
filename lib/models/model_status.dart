/// Availability status of an [LlmModel].
enum ModelStatus {
  available('Available'),
  preview('Preview'),
  deprecated('Deprecated'),
  private('Private');

  const ModelStatus(this.label);

  /// Human-readable label.
  final String label;

  /// Parses a status from its label (case-insensitive) or name.
  static ModelStatus fromInput(String input) {
    return ModelStatus.values.firstWhere(
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