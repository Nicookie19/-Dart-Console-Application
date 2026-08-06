import '../models/model_test_result.dart';

/// Stores the results of every model connectivity test in the session.
class TestHistoryService {
  final List<ModelTestResult> _results = [];

  /// Number of stored results.
  int get length => _results.length;

  /// Unmodifiable snapshot of all results, newest first.
  List<ModelTestResult> getAll() => List.unmodifiable(_results.reversed);

  /// Stores a result.
  void add(ModelTestResult result) => _results.add(result);

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