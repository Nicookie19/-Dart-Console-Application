# Task Manager CLI

A Dart console task manager built to demonstrate **Riverpod dependency injection**, **data models**, and **service/controller architecture** in a pure-Dart (non-Flutter) application.

## Features

- Interactive menu-driven console UI
- Add, list, filter, search, update, and delete tasks
- Priority levels (Low / Medium / High / Urgent) and statuses (Todo / In Progress / Done)
- Dashboard with per-status and per-priority statistics
- 12 passing unit tests

## Architecture

```
bin/main.dart          Entry point
lib/
├── console_app.dart         Interactive UI (talks only to Riverpod)
├── models/
│   ├── task.dart            Task entity (immutable, value equality)
│   ├── task_priority.dart   Priority enum
│   └── task_status.dart     Status enum
├── services/
│   └── task_service.dart    Business logic + data store (single source of truth)
├── controllers/
│   └── task_controller.dart Riverpod Notifier exposing tasks as state
└── providers/
    └── providers.dart       Riverpod providers — the dependency injection layer
```

### How Riverpod is used

All dependencies are declared as providers in `lib/providers/providers.dart`:

- `taskServiceProvider` — exposes the shared `TaskService` instance.
- `taskControllerProvider` — a `NotifierProvider` whose `TaskController` receives the service via `ref.read`/`ref.watch`, never via manual construction.

The UI layer (`ConsoleApp`) resolves everything through a `ProviderContainer`, so no class in the app constructs its own dependencies. Swapping implementations for tests is done with provider overrides:

```dart
final container = ProviderContainer(
  overrides: [
    taskServiceProvider.overrideWithValue(fakeService),
  ],
);
```

## Requirements

- Dart SDK 3.12+

## Run

```sh
dart pub get
dart run bin/main.dart
```

## Test

```sh
dart test
```

## Demo walkthrough

| Key | Action |
|-----|--------|
| 1 | Add a task (title, description, priority) |
| 2 | List all tasks |
| 3 | Filter by status |
| 4 | Filter by priority |
| 5 | Search tasks |
| 6–8 | Mark in progress / done / reopen |
| 9 | Change priority |
| 10 | Delete a task |
| 11 | Dashboard |
| 0 | Exit |
