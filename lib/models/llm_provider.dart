/// The organization that provides an [LlmModel].
enum LlmProvider {
  openai('OpenAI'),
  anthropic('Anthropic'),
  google('Google'),
  meta('Meta'),
  mistral('Mistral'),
  local('Local'),
  other('Other');

  const LlmProvider(this.label);

  /// Human-readable label.
  final String label;

  /// Parses a provider from its label (case-insensitive) or name.
  static LlmProvider fromInput(String input) {
    return LlmProvider.values.firstWhere(
      (p) => p.label.toLowerCase() == input.trim().toLowerCase() ||
          p.name.toLowerCase() == input.trim().toLowerCase(),
      orElse: () => throw FormatException(
        "Unknown provider '$input'. Use: ${values.map((p) => p.label).join(', ')}",
      ),
    );
  }

  @override
  String toString() => label;
}