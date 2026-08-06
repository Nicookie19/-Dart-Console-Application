import 'package:uuid/uuid.dart';

import '../models/prompt.dart';
import '../models/prompt_category.dart';

/// Manages the prompt library.
///
/// This service is the single source of truth for prompts and is injected
/// into [PromptController] through Riverpod, keeping the controller free of
/// data-management details.
class PromptService {
  PromptService({Uuid? uuid, DateTime Function()? clock})
      : _uuid = uuid ?? const Uuid(),
        _clock = clock ?? DateTime.now;

  final Uuid _uuid;
  final DateTime Function() _clock;

  final List<Prompt> _prompts = [];

  /// Number of stored prompts.
  int get length => _prompts.length;

  /// Unmodifiable snapshot of all prompts, newest first.
  List<Prompt> getAll() => List.unmodifiable(_prompts.reversed);

  /// Finds a prompt by its unique id.
  Prompt? findById(String id) {
    for (final prompt in _prompts) {
      if (prompt.id == id) return prompt;
    }
    return null;
  }

  /// Creates and stores a prompt. Throws [ArgumentError] on a blank name.
  Prompt createPrompt({
    required String name,
    required String content,
    PromptCategory category = PromptCategory.general,
    String description = '',
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Prompt name cannot be empty.');
    }
    if (content.trim().isEmpty) {
      throw ArgumentError('Prompt content cannot be empty.');
    }
    final prompt = Prompt(
      id: _uuid.v4(),
      name: name.trim(),
      content: content.trim(),
      category: category,
      description: description.trim(),
      createdAt: _clock(),
    );
    _prompts.add(prompt);
    return prompt;
  }

  /// Renames the prompt with [id]. Returns the updated prompt, or null if
  /// no such prompt exists.
  Prompt? rename(String id, String newName) {
    final index = _indexOf(id);
    if (index == -1) return null;
    final updated = _prompts[index].rename(newName.trim());
    _prompts[index] = updated;
    return updated;
  }

  /// Replaces the content of the prompt with [id].
  Prompt? updateContent(String id, String newContent) {
    final index = _indexOf(id);
    if (index == -1) return null;
    final updated = _prompts[index].updateContent(newContent.trim());
    _prompts[index] = updated;
    return updated;
  }

  /// Replaces the description of the prompt with [id].
  Prompt? updateDescription(String id, String newDescription) {
    final index = _indexOf(id);
    if (index == -1) return null;
    final updated = _prompts[index].updateDescription(newDescription.trim());
    _prompts[index] = updated;
    return updated;
  }

  /// Re-categorizes the prompt with [id].
  Prompt? changeCategory(String id, PromptCategory category) {
    final index = _indexOf(id);
    if (index == -1) return null;
    final updated = _prompts[index].changeCategory(category);
    _prompts[index] = updated;
    return updated;
  }

  /// Removes the prompt with [id]. Returns true if a prompt was removed.
  bool deletePrompt(String id) {
    final index = _indexOf(id);
    if (index == -1) return false;
    _prompts.removeAt(index);
    return true;
  }

  /// Prompts matching a case-insensitive search on name and description.
  List<Prompt> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return _prompts.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();
  }

  /// Prompts in [category], newest first.
  List<Prompt> byCategory(PromptCategory category) =>
      _prompts.where((p) => p.category == category).toList().reversed.toList();

  /// Prompts grouped by category, newest first.
  Map<PromptCategory, List<Prompt>> groupedByCategory() {
    final result = <PromptCategory, List<Prompt>>{};
    for (final prompt in _prompts.reversed) {
      result.putIfAbsent(prompt.category, () => []).add(prompt);
    }
    return result;
  }

  /// Clears the library. Used by tests.
  void clear() => _prompts.clear();

  int _indexOf(String id) {
    for (var i = 0; i < _prompts.length; i++) {
      if (_prompts[i].id == id) return i;
    }
    return -1;
  }
}
