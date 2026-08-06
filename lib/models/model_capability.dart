/// A capability that an [LlmModel] may or may not support.
enum ModelCapability {
  vision('Vision'),
  functionCalling('Function calling'),
  reasoning('Reasoning'),
  code('Code generation'),
  audio('Audio'),
  embeddings('Embeddings');

  const ModelCapability(this.label);

  /// Human-readable label.
  final String label;

  /// Parses a capability from its label (case-insensitive), name, or
  /// space/comma-separated list of several.
  static Set<ModelCapability> parseSet(String input) {
    final parts = input
        .split(RegExp(r'[,;\s]+'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return <ModelCapability>{};
    return parts.map(fromInput).toSet();
  }

  /// Parses a single capability.
  static ModelCapability fromInput(String input) {
    return ModelCapability.values.firstWhere(
      (c) => c.label.toLowerCase() == input.trim().toLowerCase() ||
          c.name.toLowerCase() == input.trim().toLowerCase(),
      orElse: () => throw FormatException(
        "Unknown capability '$input'. Use: ${values.map((c) => c.label).join(', ')}",
      ),
    );
  }

  @override
  String toString() => label;
}