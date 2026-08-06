# LLM Model Manager (CLI)

A Dart console application to **catalog, list, and compare LLM models** — provider, context window, max output, token pricing, capabilities, and status — built to demonstrate **Riverpod dependency injection**, **data models**, and **service/controller architecture** in pure Dart (no Flutter).

## Features

- Interactive menu-driven console UI with every choice listed up front
- Create, list, filter, search, edit, and delete model catalog entries
- Record provider, context window, max output, token pricing, capabilities, and status per model
- Side-by-side model comparison with cost estimates
- Model detail views with full specifications
- Dashboard with per-provider counts, average context size, cheapest model, and widest context
- Every prompt with predefined choices (provider, status, capability) shows the available options
- 17 passing unit tests

## Architecture

```
bin/main.dart          Entry point
lib/
├── console_app.dart         Interactive UI (talks only to Riverpod)
├── models/
│   ├── llm_model.dart       Catalog entity (immutable, cost math)
│   ├── llm_provider.dart    Provider enum (OpenAI, Anthropic, Google, ...)
│   ├── model_status.dart    Status enum (Available, Preview, ...)
│   └── model_capability.dart Capability enum (Vision, Reasoning, ...)
├── services/
│   └── model_service.dart       Catalog (business logic + storage)
├── controllers/
│   └── model_controller.dart  Riverpod Notifier exposing the catalog as state
└── providers/
    └── providers.dart       Riverpod providers — the dependency injection layer
```

### How Riverpod is used

All dependencies are declared as providers in `lib/providers/providers.dart`:

- `modelServiceProvider` — the service holding catalog business logic.
- `modelControllerProvider` — a `NotifierProvider` whose controller receives its dependency via `ref.read`/`ref.watch`, never via manual construction.

The UI layer (`ConsoleApp`) resolves everything through a `ProviderContainer`, so no class in the app constructs its own dependencies. Tests read providers through the same container:

```dart
final container = ProviderContainer();
final controller = container.read(modelControllerProvider.notifier);
```

## Requirements & setup

- Dart SDK 3.12+

```sh
dart pub get
```

## Run

```sh
dart run bin/main.dart
```

## Test

```sh
dart test
```

## Demo walkthrough

| Key | Action |
|-----|--------|
| 1 | Add a model entry (id, display name, provider, context, costs, capabilities, status, description) |
| 2 | List all models |
| 3 | Filter by provider / status / capability |
| 4 | Search models |
| 5 | View model details |
| 6 | Edit a model |
| 7 | Delete a model |
| 8 | Compare two models side by side |
| 9 | Dashboard |
| 0 | Exit |

Example entries:

```
[OpenAI] GPT-4o   — 128,000 ctx, $2.50 / $10.00 per 1M, Vision + Code
[Meta]   Llama 3  — 131,072 ctx, $0.15 / $0.60 per 1M
```