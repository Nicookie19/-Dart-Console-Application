/// The outcome of a single LLM test run.
class PromptTestResult {
  const PromptTestResult({
    required this.id,
    required this.promptId,
    required this.promptName,
    required this.model,
    required this.renderedPrompt,
    required this.latencyMs,
    required this.testedAt,
    this.response,
    this.error,
  });

  /// Unique identifier (UUID).
  final String id;

  /// The prompt that was tested.
  final String promptId;

  /// Snapshot of the prompt's name (prompts may be renamed later).
  final String promptName;

  /// The model used for the test.
  final String model;

  /// The fully rendered prompt that was sent to the API.
  final String renderedPrompt;

  /// The model's reply, or null if the test failed.
  final String? response;

  /// Round-trip latency in milliseconds.
  final int latencyMs;

  /// Error message when the test failed, otherwise null.
  final String? error;

  /// When the test was executed.
  final DateTime testedAt;

  /// Whether the test completed successfully.
  bool get success => error == null && response != null;
}
