import '../models/prompt_test_result.dart';

/// Stores the results of every LLM test run in the current session.
class TestHistoryService {
  final List<PromptTestResult> _results = [];

  /// Number of stored results.
  int get length => _results.length;

  /// Unmodifiable snapshot of all results, newest first.
  List<PromptTestResult> getAll() => List.unmodifiable(_results.reversed);

  /// Stores a result.
  void add(PromptTestResult result) => _results.add(result);

  /// Results limited to the [limit] most recent entries, newest first.
  List<PromptTestResult> recent(int limit) {
    final start = _results.length > limit ? _results.length - limit : 0;
    return _results.sublist(start).reversed.toList();
  }

  /// Number of successful tests.
  int get successCount => _results.where((r) => r.success).length;

  /// Number of failed tests.
  int get failureCount => _results.length - successCount;

  /// Average latency over all tests, or 0 when empty.
  int get averageLatencyMs {
    if (_results.isEmpty) return 0;
    final total = _results.fold<int>(0, (sum, r) => sum + r.latencyMs);
    return total ~/ _results.length;
  }

  /// Clears the history. Used by tests.
  void clear() => _results.clear();
}
