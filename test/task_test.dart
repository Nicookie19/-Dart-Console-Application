import 'package:riverpod/riverpod.dart';
import 'package:task_manager_cli/controllers/task_controller.dart';
import 'package:task_manager_cli/models/task.dart';
import 'package:task_manager_cli/models/task_priority.dart';
import 'package:task_manager_cli/models/task_status.dart';
import 'package:task_manager_cli/providers/providers.dart';
import 'package:task_manager_cli/services/task_service.dart';
import 'package:test/test.dart';

void main() {
  group('TaskController (Riverpod DI)', () {
    late ProviderContainer container;
    late TaskController controller;
    late TaskService service;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      controller = container.read(taskControllerProvider.notifier);
      service = container.read(taskServiceProvider);
    });

    test('build() exposes the service\'s tasks as state', () {
      expect(container.read(taskControllerProvider), isEmpty);
      service.createTask(title: 'Seed task');
      expect(service.length, 1, reason: 'service is the source of truth');
    });

    test('addTask updates state through the service', () {
      controller.addTask(title: 'Write report', priority: TaskPriority.high);

      final state = container.read(taskControllerProvider);
      expect(state, hasLength(1));
      expect(state.first.title, 'Write report');
      expect(state.first.priority, TaskPriority.high);
      expect(service.length, 1, reason: 'service is the single source of truth');
    });

    test('markDone stamps completion and updates state', () {
      final task = controller.addTask(title: 'Ship feature');

      expect(controller.markDone(task.id), isTrue);
      final updated = container.read(taskControllerProvider).first;
      expect(updated.status, TaskStatus.done);
      expect(updated.completedAt, isNotNull);
    });

    test('delete removes the task from state and service', () {
      final task = controller.addTask(title: 'Cleanup');

      expect(controller.delete(task.id), isTrue);
      expect(container.read(taskControllerProvider), isEmpty);
      expect(service.findById(task.id), isNull);
    });

    test('reprioritize updates priority in state', () {
      final task = controller.addTask(title: 'Refactor');
      controller.reprioritize(task.id, TaskPriority.urgent);

      expect(container.read(taskControllerProvider).first.priority, TaskPriority.urgent);
    });

    test('operations on a missing id fail gracefully', () {
      expect(controller.markDone('nope'), isFalse);
      expect(controller.delete('nope'), isFalse);
      expect(service.findById('nope'), isNull);
    });
  });

  group('TaskService', () {
    late TaskService service;

    setUp(() {
      service = TaskService();
      addTearDown(service.clear);
    });

    test('createTask trims input and assigns a unique id', () {
      final a = service.createTask(title: '  One  ');
      final b = service.createTask(title: 'Two');
      expect(a.title, 'One');
      expect(a.id, isNot(b.id));
      expect(service.length, 2);
    });

    test('statistics counts by status and priority', () {
      service.createTask(title: 'a', priority: TaskPriority.high);
      service.createTask(title: 'b', priority: TaskPriority.low);
      final all = service.getAll();
      service.changeStatus(all.first.id, TaskStatus.done);

      final stats = service.statistics();
      expect(stats['total'], 2);
      expect(stats['done'], 1);
      expect(stats['todo'], 1);
      expect(stats['priority_high'], 1);
      expect(stats['priority_low'], 1);
      expect(TaskStatus.values.length, 3);
      expect(TaskPriority.values.length, 4);
    });

    test('search matches title and description case-insensitively', () {
      service.createTask(title: 'Buy milk', description: 'From the store');
      service.createTask(title: 'Walk dog');

      expect(service.search('milk'), hasLength(1));
      expect(service.search('STORE'), hasLength(1));
      expect(service.search('zzz'), isEmpty);
    });

    test('sortedByPriority orders urgent before low', () {
      service.createTask(title: 'low', priority: TaskPriority.low);
      service.createTask(title: 'urgent', priority: TaskPriority.urgent);

      final sorted = service.sortedByPriority();
      expect(sorted.first.title, 'urgent');
      expect(sorted.last.title, 'low');
    });
  });

  group('Task model', () {
    test('copyWithStatus preserves identity and stamps completion only when done', () {
      final base = Task(
        id: '1',
        title: 't',
        createdAt: DateTime(2024, 1, 1),
      );
      final inProgress = base.copyWithStatus(TaskStatus.inProgress);
      final done = inProgress.copyWithStatus(TaskStatus.done);

      expect(done.id, base.id);
      expect(done.status, TaskStatus.done);
      expect(done.completedAt, isNotNull);
      expect(inProgress.completedAt, isNull);
    });

    test('equality is value-based', () {
      final a = Task(id: '1', title: 't', createdAt: DateTime(2024));
      final b = Task(id: '1', title: 't', createdAt: DateTime(2024));
      expect(a, equals(b));
    });
  });
}