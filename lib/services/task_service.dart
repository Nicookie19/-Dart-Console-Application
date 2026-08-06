import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../models/task_priority.dart';
import '../models/task_status.dart';

/// Result of an attempted mutation on the task collection.
enum OperationResult {
  success('Success'),
  notFound('Task was not found');

  const OperationResult(this.label);
  final String label;
}

/// Holds the business rules of the application.
///
/// This service is the single source of truth for task data and is injected
/// into the [TaskController] through Riverpod, keeping the controller free
/// of data-management details.
class TaskService {
  TaskService({Uuid? uuid, DateTime Function()? clock})
      : _uuid = uuid ?? const Uuid(),
        _clock = clock ?? DateTime.now;

  final Uuid _uuid;
  final DateTime Function() _clock;

  /// In-memory task store.
  final List<Task> _tasks = [];

  /// Number of tasks currently stored.
  int get length => _tasks.length;

  /// Unmodifiable snapshot of all tasks, newest first.
  List<Task> getAll() => List.unmodifiable(_tasks.reversed);

  /// Finds a task by its unique id.
  Task? findById(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  /// Creates a task and adds it to the store.
  Task createTask({
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    TaskStatus status = TaskStatus.todo,
  }) {
    final task = Task(
      id: _uuid.v4(),
      title: title.trim(),
      description: description.trim(),
      priority: priority,
      status: status,
      createdAt: _clock(),
    );
    _tasks.add(task);
    return task;
  }

  /// Changes the status of a task by id. Returns the updated task, or null
  /// if no task with [id] exists.
  Task? changeStatus(String id, TaskStatus newStatus) {
    final index = _indexOf(id);
    if (index == -1) return null;
    final updated = _tasks[index].copyWithStatus(newStatus);
    _tasks[index] = updated;
    return updated;
  }

  /// Changes the priority of a task by id. Returns the updated task, or null
  /// if no task with [id] exists.
  Task? changePriority(String id, TaskPriority newPriority) {
    final index = _indexOf(id);
    if (index == -1) return null;
    final updated = _tasks[index].copyWithPriority(newPriority);
    _tasks[index] = updated;
    return updated;
  }

  /// Removes the task with [id]. Returns true if a task was removed.
  bool deleteTask(String id) {
    final index = _indexOf(id);
    if (index == -1) return false;
    _tasks.removeAt(index);
    return true;
  }

  /// Tasks matching a case-insensitive search on title and description.
  List<Task> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return _tasks.where((t) {
      return t.title.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q);
    }).toList();
  }

  /// Tasks filtered by [status], newest first.
  List<Task> byStatus(TaskStatus status) =>
      _tasks.where((t) => t.status == status).toList().reversed.toList();

  /// Tasks filtered by [priority], newest first.
  List<Task> byPriority(TaskPriority priority) =>
      _tasks.where((t) => t.priority == priority).toList().reversed.toList();

  /// Tasks ordered by priority weight (descending) then creation date.
  List<Task> sortedByPriority() {
    final sorted = [..._tasks]..sort((a, b) {
        final byLevel = b.priority.level.compareTo(a.priority.level);
        return byLevel != 0 ? byLevel : a.createdAt.compareTo(b.createdAt);
      });
    return List.unmodifiable(sorted);
  }

  /// Aggregated numbers used to render the dashboard.
  Map<String, int> statistics() {
    return {
      'total': _tasks.length,
      for (final status in TaskStatus.values)
        status.name: _tasks.where((t) => t.status == status).length,
      for (final priority in TaskPriority.values)
        'priority_${priority.name}': _tasks.where((t) => t.priority == priority).length,
    };
  }

  /// Clears every task. Used by tests.
  void clear() => _tasks.clear();

  int _indexOf(String id) {
    for (var i = 0; i < _tasks.length; i++) {
      if (_tasks[i].id == id) return i;
    }
    return -1;
  }
}
