# LLM Prompt Manager & Tester (CLI)

A Dart console application to **manage LLM prompt templates** and **test them against an OpenAI-compatible API**, built to demonstrate **Riverpod dependency injection**, **data models**, and **service/controller architecture** in pure Dart (no Flutter).

## Features

- Interactive menu-driven console UI
- Create, list, filter, search, edit, and delete prompt templates
- Templates support `{{variables}}` — filled in before each test run
- Test prompts live against any OpenAI-compatible chat-completions API (OpenAI, local Ollama, proxies, etc.)
- Per-test latency measurement and a session test history (successes & failures)
- Dashboard with per-category prompt counts and test statistics
- Configurable via environment variables — no hardcoded secrets
- 27 passing unit tests (LLM client tested with a mocked HTTP client)

## Architecture

```
bin/main.dart          Entry point
lib/
├── console_app.dart         Interactive UI (talks only to Riverpod)
├── models/
│   ├── prompt.dart          Prompt template (immutable, {{variable}} parsing/rendering)
│   ├── prompt_category.dart Category enum
│   └── prompt_test_result.dart  Outcome of one LLM test run
├── services/
│   ├── prompt_service.dart      Prompt library (business logic + storage)
│   ├── test_history_service.dart  Test-run history store
│   └── llm_service.dart         OpenAI-compatible HTTP client + config
├── controllers/
│   ├── prompt_controller.dart Riverpod Notifier exposing prompts as state
│   └── history_controller.dart Riverpod Notifier orchestrating test runs
└── providers/
    └── providers.dart       Riverpod providers — the dependency injection layer
```

### How Riverpod is used

All dependencies are declared as providers in `lib/providers/providers.dart`:

- `llmConfigProvider` — LLM settings resolved from environment variables.
- `llmServiceProvider` — the HTTP client for chat completions.
- `promptServiceProvider` / `testHistoryServiceProvider` — the services holding business logic.
- `promptControllerProvider` / `historyControllerProvider` — `NotifierProvider`s whose controllers receive their dependencies via `ref.read`/`ref.watch`, never via manual construction.

The UI layer (`ConsoleApp`) resolves everything through a `ProviderContainer`, so no class in the app constructs its own dependencies. Tests swap implementations via provider overrides — e.g. the LLM service is replaced with one backed by a `MockClient`, so tests never touch the network:

```dart
final container = ProviderContainer(
  overrides: [
    llmServiceProvider.overrideWithValue(fakeService),
  ],
);
```

## Requirements & setup

- Dart SDK 3.12+
- An OpenAI-compatible API endpoint (optional — the app runs and stores prompts without it)

```sh
dart pub get

# Optional configuration (defaults work out of the box):
export OPENAI_API_KEY="sk-..."              # required to run live tests
export OPENAI_BASE_URL="https://api.openai.com/v1"   # or any compatible endpoint
export OPENAI_MODEL="gpt-4o-mini"           # default model for tests
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
| 1 | Add a prompt template (name, category, description, content) |
| 2 | List all prompts |
| 3 | Filter by category |
| 4 | Search prompts |
| 5 | View prompt details (incl. detected variables) |
| 6 | Edit a prompt (rename / content / description / category) |
| 7 | Delete a prompt |
| 8 | **Test a prompt** — fill in variables, pick a model, get the reply |
| 9 | Test history — review rendered prompts and responses |
| 10 | Dashboard — prompt counts and test statistics |
| 0 | Exit |

Example prompt template with variables:

```
Summarize the following code and explain what it does:

{{code}}
```

When testing, the app asks for a value for `code`, renders the prompt, sends it to the model, measures latency, and stores the result in the history.
