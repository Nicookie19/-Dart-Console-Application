import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/llm_model.dart';
import '../models/model_test_result.dart';
import '../providers/providers.dart';
import '../services/llm_service.dart';
import '../services/test_history_service.dart';

/// Orchestrates model connectivity tests ("pings") and exposes the session's
/// test history as immutable Riverpod state.
///
/// [LlmService] and [TestHistoryService] are injected by Riverpod, never
/// constructed here.
class TestHistoryController extends Notifier<List<ModelTestResult>> {
  @override
  List<ModelTestResult> build() =>
      ref.watch(testHistoryServiceProvider).getAll();

  TestHistoryService get _history => ref.read(testHistoryServiceProvider);

  /// Pings [model] through the configured API and records the outcome.
  ///
  /// The result — successful or not — is exposed through the state. Returns
  /// the recorded [ModelTestResult].
  Future<ModelTestResult> pingModel(LlmModel model) async {
    final stopwatch = Stopwatch()..start();

    String? error;
    int latencyMs;
    try {
      await ref.read(llmServiceProvider).ping(model: model.name);
      latencyMs = stopwatch.elapsedMilliseconds;
    } on LlmException catch (e) {
      error = e.message;
      latencyMs = stopwatch.elapsedMilliseconds;
    } catch (e) {
      error = 'Unexpected error: $e';
      latencyMs = stopwatch.elapsedMilliseconds;
    }

    final entry = ModelTestResult(
      id: const Uuid().v4(),
      modelId: model.id,
      modelName: model.label,
      provider: model.provider,
      latencyMs: latencyMs,
      error: error,
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