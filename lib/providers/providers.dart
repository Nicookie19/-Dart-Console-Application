import 'package:riverpod/riverpod.dart';

import '../controllers/task_controller.dart';
import '../models/task.dart';
import '../services/task_service.dart';

/// --- Dependency Injection (Riverpod) ---
///
/// All dependencies of the application are declared here as providers:
///
/// 1. [taskServiceProvider]    - the service containing business logic.
/// 2. [taskControllerProvider] - the stateful controller, which receives the
///                               service through Riverpod's DI (never via
///                               manual construction).

/// Provides the single shared [TaskService] instance.
final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService();
});

/// Provides the [TaskController], which exposes the list of tasks as state.
///
/// Riverpod injects the [TaskService] into the controller when it is first
/// read, and keeps the same controller instance alive for the whole session.
final taskControllerProvider =
    NotifierProvider<TaskController, List<Task>>(TaskController.new);
