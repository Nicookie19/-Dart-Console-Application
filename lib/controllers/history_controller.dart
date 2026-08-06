import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/prompt.dart';
import '../models/prompt_test_result.dart';
import '../providers/providers.dart';
import '../services/llm_service.dart';
import '../services/test_history_service.dart';

/// Orchestrates LLM test runs and exposes the session's test history as
/// immutable Riverpod state.
///
/// [LLMService] and [TestHistoryService] are injected by Riverpod, never
/// constructed here.
class HistoryController extends Notifier<List<PromptTestResult>> {
  @override
  List<PromptTestResult> build() =>
      ref.watch(testHistoryServiceProvider).getAll();

  TestHistoryService get _history => ref.read(testHistoryServiceProvider);

  /// Renders [prompt] with [variables] and sends it to the LLM.
  ///
  /// The result — successful or not — is recorded in the history and exposed
  /// through the state. Returns the recorded [PromptTestResult].
  Future<PromptTestResult> runTest(
    Prompt prompt,
    Map<String, String> variables, {
    String? model,
  }) async {
    final config = ref.read(llmConfigProvider);
    final selectedModel = (model == null || model.trim().isEmpty)
        ? config.defaultModel
        : model.trim();

    final rendered = prompt.render(variables);
    final stopwatch = Stopwatch()..start();

    String? response;
    String? error;
    int latencyMs;
    try {
      final result = await ref
          .read(llmServiceProvider)
          .complete(prompt: rendered, model: selectedModel);
      response = result.text;
      latencyMs = result.latencyMs;
    } on LlmException catch (e) {
      error = e.message;
      latencyMs = stopwatch.elapsedMilliseconds;
    } catch (e) {
      error = 'Unexpected error: $e';
      latencyMs = stopwatch.elapsedMilliseconds;
    }

    final entry = PromptTestResult(
      id: const Uuid().v4(),
      promptId: prompt.id,
      promptName: prompt.name,
      model: selectedModel,
      renderedPrompt: rendered,
      response: response,
      error: error,
      latencyMs: latencyMs,
      testedAt: DateTime.now(),
    );
    _history.add(entry);
    state = _history.getAll();
    return entry;
  }

  /// Removes every recorded test result.
  void clearHistory() {
    _history.clear();
    state = _history.getAll();
  }
}
