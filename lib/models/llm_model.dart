/// An LLM model entry in the managed catalog.
///
/// Immutable by design: updates produce new instances via the `copyWith`
/// helpers, keeping state changes predictable. Provider, status, and
/// capabilities are free-form text so any value can be typed.
class LlmModel {
  const LlmModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.contextWindow,
    required this.maxOutputTokens,
    required this.inputCostPerMillion,
    required this.outputCostPerMillion,
    required this.createdAt,
    this.displayName,
    this.capabilities = const {},
    this.status = 'Available',
    this.description = '',
    this.updatedAt,
  });

  /// Unique identifier (UUID).
  final String id;

  /// The model identifier used in API calls, e.g. `gpt-4o`.
  final String name;

  /// Optional human-friendly name shown instead of [name].
  final String? displayName;

  /// Provider/vendor of the model, e.g. `OpenAI`.
  final String provider;

  /// Maximum context size in tokens.
  final int contextWindow;

  /// Maximum number of tokens the model can output.
  final int maxOutputTokens;

  /// USD per 1,000,000 input tokens.
  final double inputCostPerMillion;

  /// USD per 1,000,000 output tokens.
  final double outputCostPerMillion;

  /// Capabilities this model supports (free-form labels).
  final Set<String> capabilities;

  /// Availability status, e.g. `Available` or `Preview`.
  final String status;

  /// Optional notes.
  final String description;

  /// When the entry was created.
  final DateTime createdAt;

  /// When the entry was last edited, if ever.
  final DateTime? updatedAt;

  /// The label to display: short display name when set, otherwise [name].
  String get label => displayName ?? name;

  /// Total cost, in dollars, of a round trip of exactly [tokens] tokens.
  double costForTokens(int tokens) {
    final half = tokens / 2;
    return (half / 1e6 * inputCostPerMillion) +
        (half / 1e6 * outputCostPerMillion);
  }

  /// True when the model supports every capability in [requiredCapabilities]
  /// (case-insensitive).
  bool hasCapabilities(Iterable<String> requiredCapabilities) {
    final own = capabilities.map((c) => c.toLowerCase()).toSet();
    return requiredCapabilities
        .map((c) => c.toLowerCase())
        .every(own.contains);
  }

  LlmModel rename(String newName) => _copyWith(name: newName);

  LlmModel changeDisplayName(String? newDisplayName) =>
      _copyWith(displayName: newDisplayName);

  LlmModel changeProvider(String newProvider) => _copyWith(provider: newProvider);

  LlmModel changeContextWindow(int value) => _copyWith(contextWindow: value);

  LlmModel changeMaxOutput(int value) => _copyWith(maxOutputTokens: value);

  LlmModel changeCosts({required double input, required double output}) =>
      _copyWith(inputCostPerMillion: input, outputCostPerMillion: output);

  LlmModel changeCapabilities(Set<String> value) =>
      _copyWith(capabilities: Set.unmodifiable(value));

  LlmModel changeStatus(String value) => _copyWith(status: value);

  LlmModel changeDescription(String value) => _copyWith(description: value);

  static const _unset = Object();

  LlmModel _copyWith({
    String? name,
    Object? displayName = _unset,
    String? provider,
    int? contextWindow,
    int? maxOutputTokens,
    double? inputCostPerMillion,
    double? outputCostPerMillion,
    Set<String>? capabilities,
    String? status,
    String? description,
  }) {
    return LlmModel(
      id: id,
      name: name ?? this.name,
      displayName: identical(displayName, _unset)
          ? this.displayName
          : displayName as String?,
      provider: provider ?? this.provider,
      contextWindow: contextWindow ?? this.contextWindow,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      inputCostPerMillion:
          inputCostPerMillion ?? this.inputCostPerMillion,
      outputCostPerMillion:
          outputCostPerMillion ?? this.outputCostPerMillion,
      capabilities: capabilities ?? this.capabilities,
      status: status ?? this.status,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LlmModel &&
        other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '[$provider] $label';
}