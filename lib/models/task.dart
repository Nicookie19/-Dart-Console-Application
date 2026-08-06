import 'task_priority.dart';
import 'task_status.dart';

/// Represents a single task managed by the application.
///
/// Immutable by design: updating a task produces a new [Task] instance via
/// the `copyWith` helpers, keeping state changes predictable.
class Task {
  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    required this.createdAt,
    this.completedAt,
  });

  /// Unique identifier (UUID).
  final String id;

  /// Short name of the task.
  final String title;

  /// Optional longer description.
  final String description;

  /// Urgency level of the task.
  final TaskPriority priority;

  /// Current lifecycle status.
  final TaskStatus status;

  /// When the task was created.
  final DateTime createdAt;

  /// When the task was marked as done, if ever.
  final DateTime? completedAt;

  /// Returns a copy with a new [status], stamping [completedAt] when done.
  Task copyWithStatus(TaskStatus newStatus) {
    return Task(
      id: id,
      title: title,
      description: description,
      priority: priority,
      status: newStatus,
      createdAt: createdAt,
      completedAt: newStatus == TaskStatus.done ? DateTime.now() : null,
    );
  }

  /// Returns a copy with a new [priority].
  Task copyWithPriority(TaskPriority newPriority) {
    return Task(
      id: id,
      title: title,
      description: description,
      priority: newPriority,
      status: status,
      createdAt: createdAt,
      completedAt: completedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.priority == priority &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, title, description, priority, status, createdAt, completedAt);

  @override
  String toString() {
    final statusIcon = switch (status) {
      TaskStatus.done => '[x]',
      TaskStatus.inProgress => '[-]',
      TaskStatus.todo => '[ ]',
    };
    return '$statusIcon $title (${priority.label} - ${status.label})';
  }
}
