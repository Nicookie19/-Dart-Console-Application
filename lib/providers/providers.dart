import 'package:riverpod/riverpod.dart';

import '../controllers/model_controller.dart';
import '../models/llm_model.dart';
import '../services/model_service.dart';

/// --- Dependency Injection (Riverpod) ---
///
/// Every dependency is declared here as a provider:
///
/// 1. [modelServiceProvider]   - model catalog (business logic).
/// 2. [modelControllerProvider] - stateful controller for the catalog.
///
/// No class in the app ever constructs its own dependencies; everything
/// flows through this container. Tests swap implementations via overrides.

/// The shared [ModelService].
final modelServiceProvider = Provider<ModelService>((ref) => ModelService());

/// Exposes the model catalog as state.
final modelControllerProvider =
    NotifierProvider<ModelController, List<LlmModel>>(ModelController.new);