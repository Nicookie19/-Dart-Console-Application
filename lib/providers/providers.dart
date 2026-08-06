import 'dart:io';

import 'package:riverpod/riverpod.dart';

import '../controllers/history_controller.dart';
import '../controllers/prompt_controller.dart';
import '../models/prompt.dart';
import '../models/prompt_test_result.dart';
import '../services/llm_service.dart';
import '../services/prompt_service.dart';
import '../services/test_history_service.dart';

/// --- Dependency Injection (Riverpod) ---
///
/// Every dependency is declared here as a provider:
///
/// 1. [llmConfigProvider]    - LLM connection settings (env vars + defaults).
/// 2. [llmServiceProvider]   - HTTP client for chat completions.
/// 3. [promptServiceProvider]- prompt library (business logic).
/// 4. [testHistoryServiceProvider] - session test-history store.
/// 5. [promptControllerProvider]   - stateful controller for prompts.
/// 6. [historyControllerProvider]  - stateful controller for test runs.
///
/// No class in the app ever constructs its own dependencies; everything
/// flows through this container. Tests swap implementations via overrides,
/// e.g. `llmServiceProvider.overrideWithValue(fakeService)`.

/// Connection settings resolved from process environment variables.
final llmConfigProvider = Provider<LlmConfig>((ref) {
  return LlmConfig.fromEnvironment(Platform.environment);
});

/// The shared [LlmService], wired with the injected config.
final llmServiceProvider = Provider<LlmService>((ref) {
  return LlmService(ref.watch(llmConfigProvider));
});

/// The shared [PromptService].
final promptServiceProvider = Provider<PromptService>((ref) => PromptService());

/// The shared [TestHistoryService].
final testHistoryServiceProvider =
    Provider<TestHistoryService>((ref) => TestHistoryService());

/// Exposes the prompt list as state.
final promptControllerProvider =
    NotifierProvider<PromptController, List<Prompt>>(PromptController.new);

/// Exposes the test history as state.
final historyControllerProvider =
    NotifierProvider<HistoryController, List<PromptTestResult>>(HistoryController.new);