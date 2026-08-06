import 'dart:io';

import 'package:riverpod/riverpod.dart';

import '../controllers/model_controller.dart';
import '../controllers/test_history_controller.dart';
import '../models/llm_model.dart';
import '../models/model_test_result.dart';
import '../services/llm_service.dart';
import '../services/model_service.dart';
import '../services/test_history_service.dart';

/// --- Dependency Injection (Riverpod) ---
///
/// Every dependency is declared here as a provider:
///
/// 1. [llmConfigProvider]    - LLM connection settings (env vars + defaults).
/// 2. [llmServiceProvider]   - HTTP client used to ping models.
/// 3. [modelServiceProvider] - model catalog (business logic).
/// 4. [testHistoryServiceProvider] - session test-history store.
/// 5. [modelControllerProvider]    - stateful controller for the catalog.
/// 6. [testHistoryControllerProvider] - stateful controller for test runs.
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

/// The shared [ModelService].
final modelServiceProvider = Provider<ModelService>((ref) => ModelService());

/// The shared [TestHistoryService].
final testHistoryServiceProvider =
    Provider<TestHistoryService>((ref) => TestHistoryService());

/// Exposes the model catalog as state.
final modelControllerProvider =
    NotifierProvider<ModelController, List<LlmModel>>(ModelController.new);

/// Exposes the test history as state.
final testHistoryControllerProvider =
    NotifierProvider<TestHistoryController, List<ModelTestResult>>(
        TestHistoryController.new);