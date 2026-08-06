import 'llm_provider.dart';

/// The outcome of a connectivity test (ping) against a model.
class ModelTestResult {
  const ModelTestResult({
    required this.id,
    required this.modelId,
    required this.modelName,
    required this.provider,
    required this.latencyMs,
    required this.testedAt,
    this.error,
  });

  /// Unique identifier (UUID).
  final String id;

  /// The model that was pinged.
  final String modelId;

  /// Snapshot of the model's label (models may be edited later).
  final String modelName;

  /// Provider of the model.
  final LlmProvider provider;

  /// Round-trip latency in milliseconds.
  final int latencyMs;

  /// When the test ran.
  final DateTime testedAt;

  /// Error message when the test failed, otherwise null.
  final String? error;

  /// Whether the ping succeeded.
  bool get success => error == null;
}