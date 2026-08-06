import 'package:riverpod/riverpod.dart';

import '../models/prompt.dart';
import '../models/prompt_category.dart';
import '../providers/providers.dart';
import '../services/prompt_service.dart';

/// Coordinates prompt-library requests with the [PromptService] and exposes
/// the resulting list as immutable Riverpod state.
///
/// Dependencies are never constructed manually: RIVERPOD injects the
/// [PromptService] via [Ref.read]/[Ref.watch].
class PromptController extends Notifier<List<Prompt>> {
  /// Seeded with the prompts currently held by the service.
  @override
  List<Prompt> build() => ref.watch(promptServiceProvider).getAll();

  PromptService get _service => ref.read(promptServiceProvider);

  /// Creates a prompt and refreshes state. Returns the created prompt.
  Prompt addPrompt({
    required String name,
    required String content,
    PromptCategory category = PromptCategory.general,
    String description = '',
  }) {
    final prompt = _service.createPrompt(
      name: name,
      content: content,
      category: category,
      description: description,
    );
    state = _service.getAll();
    return prompt;
  }

  /// Renames a prompt. Returns true on success.
  bool rename(String id, String newName) {
    final updated = _service.rename(id, newName);
    if (updated == null) return false;
    state = _service.getAll();
    return true;
  }

  /// Replaces a prompt's content. Returns true on success.
  bool updateContent(String id, String newContent) {
    final updated = _service.updateContent(id, newContent);
    if (updated == null) return false;
    state = _service.getAll();
    return true;
  }

  /// Replaces a prompt's description. Returns true on success.
  bool updateDescription(String id, String newDescription) {
    final updated = _service.updateDescription(id, newDescription);
    if (updated == null) return false;
    state = _service.getAll();
    return true;
  }

  /// Re-categorizes a prompt. Returns true on success.
  bool changeCategory(String id, PromptCategory category) {
    final updated = _service.changeCategory(id, category);
    if (updated == null) return false;
    state = _service.getAll();
    return true;
  }

  /// Deletes a prompt. Returns true on success.
  bool delete(String id) {
    final removed = _service.deletePrompt(id);
    if (removed) state = _service.getAll();
    return removed;
  }
}
