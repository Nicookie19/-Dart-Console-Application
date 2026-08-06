import 'package:uuid/uuid.dart';

import '../models/llm_model.dart';

/// Manages the catalog of LLM models.
///
/// This service is the single source of truth for models and is injected
/// into [ModelController] through Riverpod, keeping the controller free of
/// data-management details.
class ModelService {
  ModelService({Uuid? uuid, DateTime Function()? clock})
      : _uuid = uuid ?? const Uuid(),
        _clock = clock ?? DateTime.now;

  final Uuid _uuid;
  final DateTime Function() _clock;

  final List<LlmModel> _models = [];

  /// Number of stored models.
  int get length => _models.length;

  /// Unmodifiable snapshot of all models, newest first.
  List<LlmModel> getAll() => List.unmodifiable(_models.reversed);

  /// Finds a model by its unique id.
  LlmModel? findById(String id) {
    for (final model in _models) {
      if (model.id == id) return model;
    }
    return null;
  }

  /// Creates and stores a model. Throws [ArgumentError] on invalid values.
  LlmModel createModel({
    required String name,
    required String provider,
    required int contextWindow,
    required int maxOutputTokens,
    required double inputCostPerMillion,
    required double outputCostPerMillion,
    String? displayName,
    Set<String> capabilities = const {},
    String status = 'Available',
    String description = '',
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Model name cannot be empty.');
    }
    if (contextWindow < 1) {
      throw ArgumentError('Context window must be at least 1 token.');
    }
    if (maxOutputTokens < 1) {
      throw ArgumentError('Max output tokens must be at least 1.');
    }
    if (inputCostPerMillion < 0 || outputCostPerMillion < 0) {
      throw ArgumentError('Costs cannot be negative.');
    }

    final model = LlmModel(
      id: _uuid.v4(),
      name: name.trim(),
      displayName: displayName?.trim().isEmpty ?? true
          ? null
          : displayName!.trim(),
      provider: provider.trim().isEmpty ? 'Other' : provider.trim(),
      contextWindow: contextWindow,
      maxOutputTokens: maxOutputTokens,
      inputCostPerMillion: inputCostPerMillion,
      outputCostPerMillion: outputCostPerMillion,
      capabilities: Set.unmodifiable(capabilities),
      status: status.trim().isEmpty ? 'Available' : status.trim(),
      description: description.trim(),
      createdAt: _clock(),
    );
    _models.add(model);
    return model;
  }

  /// Renames the model with [id]. Returns the updated model, or null if no
  /// such model exists.
  LlmModel? rename(String id, String newName) {
    final index = _indexOf(id);
    if (index == -1) return null;
    final updated = _models[index].rename(newName.trim());
    _models[index] = updated;
    return updated;
  }

  /// Updates a display-name field on the model with [id].
  LlmModel? updateField(
    String id,
    LlmModel Function(LlmModel model) transform,
  ) {
    final index = _indexOf(id);
    if (index == -1) return null;
    final updated = transform(_models[index]);
    _models[index] = updated;
    return updated;
  }

  /// Removes the model with [id]. Returns true if a model was removed.
  bool deleteModel(String id) {
    final index = _indexOf(id);
    if (index == -1) return false;
    _models.removeAt(index);
    return true;
  }

  /// Models matching a case-insensitive search on name, display name, and
  /// description.
  List<LlmModel> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return _models.where((m) {
      return m.name.toLowerCase().contains(q) ||
          m.label.toLowerCase().contains(q) ||
          m.description.toLowerCase().contains(q);
    }).toList();
  }

  /// Models by [provider] (case-insensitive), newest first.
  List<LlmModel> byProvider(String provider) {
    final q = provider.toLowerCase();
    return _models
        .where((m) => m.provider.toLowerCase() == q)
        .toList()
        .reversed
        .toList();
  }

  /// Models by [status] (case-insensitive), newest first.
  List<LlmModel> byStatus(String status) {
    final q = status.toLowerCase();
    return _models
        .where((m) => m.status.toLowerCase() == q)
        .toList()
        .reversed
        .toList();
  }

  /// Models supporting [capability] (case-insensitive substring match on the
  /// free-form labels), newest first.
  List<LlmModel> byCapability(String capability) {
    final q = capability.toLowerCase();
    return _models
        .where((m) => m.capabilities.any((c) => c.toLowerCase().contains(q)))
        .toList()
        .reversed
        .toList();
  }

  /// All models sorted by estimated cost to process 10,000 tokens, cheapest
  /// first.
  List<LlmModel> sortedByCost() {
    final sorted = [..._models]
      ..sort((a, b) => a.costForTokens(10000).compareTo(b.costForTokens(10000)));
    return List.unmodifiable(sorted);
  }

  /// Aggregated numbers used to render the dashboard.
  Map<String, int> statistics() {
    final result = <String, int>{'total': _models.length};
    for (final model in _models) {
      result['prov_${model.provider}'] = (result['prov_${model.provider}'] ?? 0) + 1;
      result['status_${model.status}'] = (result['status_${model.status}'] ?? 0) + 1;
    }
    return result;
  }

  /// Clears the catalog. Used by tests.
  void clear() => _models.clear();

  int _indexOf(String id) {
    for (var i = 0; i < _models.length; i++) {
      if (_models[i].id == id) return i;
    }
    return -1;
  }
}