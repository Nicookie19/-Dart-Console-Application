import 'package:riverpod/riverpod.dart';

import '../models/task.dart';
import '../models/task_priority.dart';
import '../models/task_status.dart';
import '../providers/providers.dart';
import '../services/task_service.dart';

/// Coordinates the user's requests with the [TaskService] and exposes the
/// resulting task list as immutable Riverpod state.
///
/// The controller never constructs its dependencies: RIVERPOD injects the
/// [TaskService] via [Ref.read] inside [build].
class TaskController extends Notifier<List<Task>> {
  /// Seeded with the current tasks held by the service.
  @override
  List<Task> build() {
    return ref.watch(taskServiceProvider).getAll();
  }

  TaskService get _service => ref.read(taskServiceProvider);

  /// Adds a new task and refreshes state. Returns the created task.
  Task addTask({
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
  }) {
    final task = _service.createTask(
      title: title,
      description: description,
      priority: priority,
    );
    state = _service.getAll();
    return task;
  }

  /// Marks a task as in progress.
  bool markInProgress(String id) =>
      _changeStatus(id, TaskStatus.inProgress);

  /// Marks a task as completed.
  bool markDone(String id) => _changeStatus(id, TaskStatus.done);

  /// Returns a task to the todo list.
  bool reopen(String id) => _changeStatus(id, TaskStatus.todo);

  /// Changes the priority of a task.
  bool reprioritize(String id, TaskPriority newPriority) {
    final updated = _service.changePriority(id, newPriority);
    if (updated == null) return false;
    state = _service.getAll();
    return true;
  }

  /// Deletes the task with [id]. Returns true if deleted.
  bool delete(String id) {
    final removed = _service.deleteTask(id);
    if (removed) state = _service.getAll();
    return removed;
  }

  bool _changeStatus(String id, TaskStatus status) {
    final updated = _service.changeStatus(id, status);
    if (updated == null) return false;
    state = _service.getAll();
    return true;
  }
}