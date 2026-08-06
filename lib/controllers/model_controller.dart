import 'package:riverpod/riverpod.dart';

import '../models/llm_model.dart';
import '../providers/providers.dart';
import '../services/model_service.dart';

/// Coordinates catalog requests with the [ModelService] and exposes the
/// resulting model list as immutable Riverpod state.
///
/// Dependencies are never constructed manually: RIVERPOD injects the
/// [ModelService] via [Ref.read]/[Ref.watch].
class ModelController extends Notifier<List<LlmModel>> {
  /// Seeded with the models currently held by the service.
  @override
  List<LlmModel> build() => ref.watch(modelServiceProvider).getAll();

  ModelService get _service => ref.read(modelServiceProvider);

  /// Creates a model and refreshes state. Returns the created model.
  LlmModel addModel({
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
    final model = _service.createModel(
      name: name,
      provider: provider,
      contextWindow: contextWindow,
      maxOutputTokens: maxOutputTokens,
      inputCostPerMillion: inputCostPerMillion,
      outputCostPerMillion: outputCostPerMillion,
      displayName: displayName,
      capabilities: capabilities,
      status: status,
      description: description,
    );
    state = _service.getAll();
    return model;
  }

  /// Renames a model. Returns true on success.
  bool rename(String id, String newName) {
    final updated = _service.rename(id, newName);
    if (updated == null) return false;
    state = _service.getAll();
    return true;
  }

  /// Applies a field update to the model with [id]. Returns true on success.
  bool update(String id, LlmModel Function(LlmModel model) transform) {
    final updated = _service.updateField(id, transform);
    if (updated == null) return false;
    state = _service.getAll();
    return true;
  }

  /// Deletes a model. Returns true on success.
  bool delete(String id) {
    final removed = _service.deleteModel(id);
    if (removed) state = _service.getAll();
    return removed;
  }
}