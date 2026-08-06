# LLM Model Manager (CLI)

A Dart console application to **manage a catalog of LLM models** and **ping-test them against an OpenAI-compatible API**, built to demonstrate **Riverpod dependency injection**, **data models**, and **service/controller architecture** in pure Dart (no Flutter).

## Features

- Interactive menu-driven console UI
- Create, list, filter, search, edit, and delete model catalog entries
- Record provider, context window, max output, token pricing, capabilities, and status per model
- Side-by-side model comparison with cost estimates
- Ping-test any model through an OpenAI-compatible endpoint (latency measured)
- Session test history (successes & failures)
- Dashboard with per-provider counts, average context size, and test statistics
- Configurable via environment variables — no hardcoded secrets
- 28 passing unit tests (LLM client tested with a mocked HTTP client)

## Architecture

```
bin/main.dart          Entry point
lib/
├── console_app.dart         Interactive UI (talks only to Riverpod)
├── models/
│   ├── llm_model.dart       Catalog entity (immutable, cost math)
│   ├── llm_provider.dart    Provider enum (OpenAI, Anthropic, Google, ...)
│   ├── model_status.dart    Status enum (Available, Preview, ...)
│   ├── model_capability.dart Capability enum (Vision, Reasoning, ...)
│   └── model_test_result.dart Outcome of one ping test
├── services/
│   ├── model_service.dart       Catalog (business logic + storage)
│   ├── test_history_service.dart  Test-run history store
│   └── llm_service.dart         OpenAI-compatible ping client + config
├── controllers/
│   ├── model_controller.dart  Riverpod Notifier exposing the catalog as state
│   └── test_history_controller.dart Riverpod Notifier orchestrating pings
└── providers/
    └── providers.dart       Riverpod providers — the dependency injection layer
```

### How Riverpod is used

All dependencies are declared as providers in `lib/providers/providers.dart`:

- `llmConfigProvider` — connection settings resolved from environment variables.
- `llmServiceProvider` — the HTTP client used to ping models.
- `modelServiceProvider` / `testHistoryServiceProvider` — the services holding business logic.
- `modelControllerProvider` / `testHistoryControllerProvider` — `NotifierProvider`s whose controllers receive their dependencies via `ref.read`/`ref.watch`, never via manual construction.

The UI layer (`ConsoleApp`) resolves everything through a `ProviderContainer`, so no class in the app constructs its own dependencies. Tests swap implementations via provider overrides — e.g. the LLM service is replaced with one backed by a `http.MockClient`, so tests never touch the network:

```dart
final container = ProviderContainer(
  overrides: [
    llmServiceProvider.overrideWithValue(fakeService),
  ],
);
```

## Requirements & setup

- Dart SDK 3.12+
- An OpenAI-compatible API endpoint (optional — the catalog works without it)

```sh
dart pub get

# Optional configuration for ping-testing models:
export OPENAI_API_KEY="sk-..."               # required to ping-test
export OPENAI_BASE_URL="https://api.openai.com/v1"   # or any compatible endpoint
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
| 1 | Add a model entry (id, display name, provider, context, costs, capabilities, status) |
| 2 | List all models |
| 3 | Filter by provider / status / capability |
| 4 | Search models |
| 5 | View model details |
| 6 | Edit a model |
| 7 | Delete a model |
| 8 | Compare two models side by side |
| 9 | Test a model — send a ping and measure latency |
| 10 | Test history |
| 11 | Dashboard |
| 0 | Exit |

Example entries:

```
[OpenAI] GPT-4o   — 128,000 ctx, $2.50 / $10.00 per 1M, Vision + Code
[Meta]   Llama 3  — 131,072 ctx, $0.15 / $0.60 per 1M
```