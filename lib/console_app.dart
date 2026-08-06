import 'dart:io';

import 'package:riverpod/riverpod.dart';

import 'controllers/task_controller.dart';
import 'models/task.dart';
import 'models/task_priority.dart';
import 'models/task_status.dart';
import 'providers/providers.dart';

/// Interactive console front-end.
///
/// The UI layer only talks to Riverpod (via a [ProviderContainer]); it never
/// creates services or models directly.
class ConsoleApp {
  ConsoleApp({
    ProviderContainer? container,
    String Function(String prompt)? readLineOverride,
  })  : _container = container ?? ProviderContainer(),
        _readLine = readLineOverride ?? _readLineFromStdin;

  final ProviderContainer _container;
  final String Function(String prompt) _readLine;

  void run() {
    _printBanner();
    var running = true;
    while (running) {
      _printMenu();
      final choice = _readLine('> ').trim();
      switch (choice) {
        case '1':
          _addTask();
        case '2':
          _listAll();
        case '3':
          _filterByStatus();
        case '4':
          _filterByPriority();
        case '5':
          _search();
        case '6':
          _changeStatus(TaskStatus.inProgress);
        case '7':
          _changeStatus(TaskStatus.done);
        case '8':
          _changeStatus(TaskStatus.todo);
        case '9':
          _changePriority();
        case '10':
          _deleteTask();
        case '11':
          _dashboard();
        case '0':
          running = false;
        default:
          _error("Unknown option '$choice'. Enter a number from the menu.");
      }
    }
    _success('Goodbye!');
    _container.dispose();
  }

  // ---------------------------------------------------------------- actions

  void _addTask() {
    final title = _readLine('Title: ').trim();
    if (title.isEmpty) return _error('Title cannot be empty.');
    final description = _readLine('Description (optional): ').trim();
    final priority = _readPriority(_readLine('Priority [Medium]: '));

    final task = _controller.addTask(
      title: title,
      description: description,
      priority: priority,
    );
    _success('Task created: ${task.title} (${task.priority})');
  }

  void _listAll() {
    final tasks = _state;
    if (tasks.isEmpty) return _info('No tasks yet. Add one from the menu.');
    _info('${tasks.length} task(s):');
    _printTasks(tasks);
  }

  void _filterByStatus() {
    final status = _readStatus(_readLine('Status (${TaskStatus.values.map((s) => s.label).join(' / ')}): '));
    _printTasks(_container.read(taskServiceProvider).byStatus(status));
  }

  void _filterByPriority() {
    final priority = _readPriority(_readLine('Priority: '));
    _printTasks(_container.read(taskServiceProvider).byPriority(priority));
  }

  void _search() {
    final query = _readLine('Search: ').trim();
    final results = _container.read(taskServiceProvider).search(query);
    _info('${results.length} match(es) for "$query":');
    _printTasks(results);
  }

  void _changeStatus(TaskStatus newStatus) {
    final task = _selectTask();
    if (task == null) return;

    final ok = switch (newStatus) {
      TaskStatus.inProgress => _controller.markInProgress(task.id),
      TaskStatus.done => _controller.markDone(task.id),
      TaskStatus.todo => _controller.reopen(task.id),
    };
    ok ? _success('"${task.title}" is now ${newStatus.label}.') : _error('Update failed.');
  }

  void _changePriority() {
    final task = _selectTask();
    if (task == null) return;

    final priority = _readPriority(_readLine('New priority: '));
    _controller.reprioritize(task.id, priority)
        ? _success('"${task.title}" priority is now ${priority.label}.')
        : _error('Update failed.');
  }

  void _deleteTask() {
    final task = _selectTask();
    if (task == null) return;

    final confirm = _readLine('Delete "${task.title}"? (y/N): ').trim().toLowerCase();
    if (confirm != 'y' && confirm != 'yes') return _info('Deletion cancelled.');

    _controller.delete(task.id)
        ? _success('"${task.title}" deleted.')
        : _error('Delete failed.');
  }

  void _dashboard() {
    final stats = _container.read(taskServiceProvider).statistics();
    final width = 46;
    _divider(width);
    _center('DASHBOARD', width);
    _center('total: ${stats['total']}', width);
    for (final status in TaskStatus.values) {
      _center('  ${status.label}: ${stats[status.name]}', width);
    }
    _center('by priority:', width);
    for (final priority in TaskPriority.values) {
      _center('  ${priority.label}: ${stats['priority_${priority.name}']}', width);
    }
    _divider(width);
  }

  // ------------------------------------------------------------------ helpers

  TaskController get _controller =>
      _container.read(taskControllerProvider.notifier);

  List<Task> get _state => _container.read(taskControllerProvider);

  /// Lets the user pick a task from the current list; returns null if aborted.
  Task? _selectTask() {
    final tasks = _state;
    if (tasks.isEmpty) {
      _info('No tasks to choose from.');
      return null;
    }
    _info('Choose a task:');
    for (var i = 0; i < tasks.length; i++) {
      print('  ${i + 1}. ${tasks[i]}');
    }
    final raw = _readLine('Task number (or 0 to cancel): ').trim();
    final index = int.tryParse(raw);
    if (index == null || index < 0 || index > tasks.length) {
      _error('Invalid task number.');
      return null;
    }
    if (index == 0) return null;
    return tasks[index - 1];
  }

  TaskStatus _readStatus(String raw) {
    try {
      return TaskStatus.fromInput(raw);
    } on FormatException catch (e) {
      _error(e.message);
      return _readStatus(_readLine('Status: '));
    }
  }

  TaskPriority _readPriority(String raw) {
    try {
      return TaskPriority.fromInput(raw);
    } on FormatException catch (e) {
      _error(e.message);
      return _readPriority(_readLine('Priority: '));
    }
  }

  // ------------------------------------------------------------------ output

  void _printTasks(List<Task> tasks) {
    if (tasks.isEmpty) return _info('No tasks match.');
    for (final task in tasks) {
      print(_formatTask(task));
    }
  }

  String _formatTask(Task task) {
    final lines = <String>[
      '  ${task.status == TaskStatus.done ? '[x]' : task.status == TaskStatus.inProgress ? '[-]' : '[ ]'} '
          '${task.title}  (${task.priority.label}, ${task.status.label})'
    ];
    if (task.description.isNotEmpty) lines.add('      ${task.description}');
    lines.add('      id: ${task.id}');
    return lines.join('\n');
  }

  void _printBanner() {
    _divider(46);
    _center('TASK MANAGER CLI', 46);
    _center('Dart + Riverpod (DI) demo', 46);
    _center('Models / Services / Controllers', 46);
    _divider(46);
  }

  void _printMenu() {
    print('''
MAIN MENU
  1. Add task
  2. List all tasks
  3. Filter by status
  4. Filter by priority
  5. Search tasks
  6. Mark task in progress
  7. Mark task done
  8. Reopen task
  9. Change priority
 10. Delete task
 11. Dashboard
  0. Exit''');
  }

  static void _divider(int width) => print('=' * width);

  static void _center(String text, int width) {
    final pad = (width - text.length) ~/ 2;
    print('${' ' * pad}$text');
  }

  void _info(String message) => print('\x1B[36m$message\x1B[0m');

  void _success(String message) => print('\x1B[32m$message\x1B[0m');

  void _error(String message) => print('\x1B[31m$message\x1B[0m');

  static String _readLineFromStdin(String prompt) {
    stdout.write(prompt);
    return stdin.readLineSync() ?? '';
  }
}
