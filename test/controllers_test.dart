import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:riverpod/riverpod.dart';
import 'package:llm_model_manager_cli/controllers/model_controller.dart';
import 'package:llm_model_manager_cli/controllers/test_history_controller.dart';
import 'package:llm_model_manager_cli/models/llm_model.dart';
import 'package:llm_model_manager_cli/models/llm_provider.dart';
import 'package:llm_model_manager_cli/models/model_capability.dart';
import 'package:llm_model_manager_cli/models/model_status.dart';
import 'package:llm_model_manager_cli/providers/providers.dart';
import 'package:llm_model_manager_cli/services/llm_service.dart';
import 'package:test/test.dart';

/// Builds a container with the LLM service pointed at a mock endpoint.
ProviderContainer makeContainer({http.Response Function(http.Request)? respond}) {
  return ProviderContainer(
    overrides: [
      llmConfigProvider.overrideWithValue(
        const LlmConfig(
          apiKey: 'sk-test',
          baseUrl: 'https://mock.test/v1',
          defaultModel: 'mock-model',
        ),
      ),
      llmServiceProvider.overrideWithValue(
        LlmService(
          const LlmConfig(
            apiKey: 'sk-test',
            baseUrl: 'https://mock.test/v1',
            defaultModel: 'mock-model',
          ),
          client: MockClient((request) async {
            return respond?.call(request) ?? http.Response('{}', 200);
          }),
        ),
      ),
    ],
  );
}

LlmModel makeModel(
  ModelController controller, {
  String name = 'gpt-4o',
  LlmProvider provider = LlmProvider.openai,
}) {
  return controller.addModel(
    name: name,
    provider: provider,
    contextWindow: 128000,
    maxOutputTokens: 4096,
    inputCostPerMillion: 2.5,
    outputCostPerMillion: 10,
    capabilities: {ModelCapability.vision},
  );
}

void main() {
  group('ModelController (Riverpod DI)', () {
    late ProviderContainer container;
    late ModelController controller;

    setUp(() {
      container = makeContainer();
      addTearDown(container.dispose);
      controller = container.read(modelControllerProvider.notifier);
    });

    test('addModel updates state through the service', () {
      makeModel(controller);

      final state = container.read(modelControllerProvider);
      expect(state, hasLength(1));
      expect(state.first.name, 'gpt-4o');
      expect(state.first.capabilities, contains(ModelCapability.vision));
      expect(container.read(modelServiceProvider).length, 1,
          reason: 'service is the single source of truth');
    });

    test('rename and update transform state', () {
      final model = makeModel(controller);

      expect(controller.rename(model.id, 'gpt-4o-mini'), isTrue);
      expect(container.read(modelControllerProvider).first.name, 'gpt-4o-mini');

      final ok = controller.update(model.id, (m) => m.changeStatus(ModelStatus.preview));
      expect(ok, isTrue);
      expect(container.read(modelControllerProvider).first.status, ModelStatus.preview);

      expect(controller.delete(model.id), isTrue);
      expect(container.read(modelControllerProvider), isEmpty);
    });

    test('operations on a missing id fail gracefully', () {
      expect(controller.rename('nope', 'x'), isFalse);
      expect(controller.delete('nope'), isFalse);
      expect(controller.update('nope', (m) => m), isFalse);
    });
  });

  group('TestHistoryController (Riverpod DI + mocked LLM)', () {
    late ProviderContainer container;
    late TestHistoryController controller;

    setUp(() {
      container = makeContainer();
      addTearDown(container.dispose);
      controller = container.read(testHistoryControllerProvider.notifier);
    });

    test('pingModel records a success and exposes it as state', () async {
      final model = makeModel(container.read(modelControllerProvider.notifier));

      final result = await controller.pingModel(model);

      expect(result.success, isTrue);
      expect(result.modelName, 'gpt-4o');
      expect(result.provider, LlmProvider.openai);

      final state = container.read(testHistoryControllerProvider);
      expect(state, hasLength(1));
      expect(state.first, same(result));
    });

    test('pingModel records failures without throwing', () async {
      container = makeContainer(respond: (_) => http.Response('nope', 500));
      addTearDown(container.dispose);
      controller = container.read(testHistoryControllerProvider.notifier);
      final model = makeModel(container.read(modelControllerProvider.notifier));

      final result = await controller.pingModel(model);

      expect(result.success, isFalse);
      expect(result.error, contains('500'));
      expect(container.read(testHistoryControllerProvider), hasLength(1));
    });

    test('clearHistory empties state', () async {
      final model = makeModel(container.read(modelControllerProvider.notifier));
      await controller.pingModel(model);
      controller.clearHistory();

      expect(container.read(testHistoryControllerProvider), isEmpty);
    });
  });
}