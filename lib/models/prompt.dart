import 'prompt_category.dart';

/// A prompt template managed by the application.
///
/// Prompts may contain `{{variable}}` placeholders which are resolved at
/// test time with user-supplied values (see [render]).
class Prompt {
  const Prompt({
    required this.id,
    required this.name,
    required this.content,
    required this.createdAt,
    this.category = PromptCategory.general,
    this.description = '',
    this.updatedAt,
  });

  /// Unique identifier (UUID).
  final String id;

  /// Short, human-friendly name.
  final String name;

  /// Grouping category.
  final PromptCategory category;

  /// Optional notes about the prompt's purpose.
  final String description;

  /// The actual prompt template, possibly containing `{{variables}}`.
  final String content;

  /// When the prompt was first stored.
  final DateTime createdAt;

  /// When the prompt was last edited, if ever.
  final DateTime? updatedAt;

  /// The set of unique `{{variable}}` names found in [content].
  Set<String> get variables {
    final pattern = RegExp(r'\{\{\s*([a-zA-Z0-9_]+)\s*\}\}');
    return pattern.allMatches(content).map((m) => m.group(1)!).toSet();
  }

  /// Returns [content] with every `{{name}}` placeholder replaced by the
  /// matching value in [values]. Unknown variables are left untouched.
  String render(Map<String, String> values) {
    var result = content;
    for (final entry in values.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }

  /// Returns a copy with a new [name].
  Prompt rename(String newName) => _copyWith(name: newName);

  /// Returns a copy with a new [content].
  Prompt updateContent(String newContent) => _copyWith(content: newContent);

  /// Returns a copy with a new [description].
  Prompt updateDescription(String newDescription) =>
      _copyWith(description: newDescription);

  /// Returns a copy with a new [category].
  Prompt changeCategory(PromptCategory newCategory) =>
      _copyWith(category: newCategory);

  Prompt _copyWith({
    String? name,
    String? description,
    String? content,
    PromptCategory? category,
  }) {
    return Prompt(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      content: content ?? this.content,
      category: category ?? this.category,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Prompt &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.category == category &&
        other.content == content;
  }

  @override
  int get hashCode => Object.hash(id, name, description, category, content);

  @override
  String toString() => '[${category.label}] $name';
}
