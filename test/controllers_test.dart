import 'package:riverpod/riverpod.dart';
import 'package:llm_model_manager_cli/controllers/model_controller.dart';
import 'package:llm_model_manager_cli/models/llm_model.dart';
import 'package:llm_model_manager_cli/providers/providers.dart';
import 'package:test/test.dart';

/// Builds a container with all real providers.
ProviderContainer makeContainer() {
  return ProviderContainer();
}

LlmModel makeModel(
  ModelController controller, {
  String name = 'gpt-4o',
  String provider = 'OpenAI',
}) {
  return controller.addModel(
    name: name,
    provider: provider,
    contextWindow: 128000,
    maxOutputTokens: 4096,
    inputCostPerMillion: 2.5,
    outputCostPerMillion: 10,
    capabilities: {'Vision'},
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
      expect(state.first.capabilities, contains('Vision'));
      expect(container.read(modelServiceProvider).length, 1,
          reason: 'service is the single source of truth');
    });

    test('rename and update transform state', () {
      final model = makeModel(controller);

      expect(controller.rename(model.id, 'gpt-4o-mini'), isTrue);
      expect(container.read(modelControllerProvider).first.name, 'gpt-4o-mini');

      final ok = controller.update(model.id, (m) => m.changeStatus('Preview'));
      expect(ok, isTrue);
      expect(container.read(modelControllerProvider).first.status, 'Preview');

      expect(controller.delete(model.id), isTrue);
      expect(container.read(modelControllerProvider), isEmpty);
    });

    test('free-form values pass through unchanged', () {
      final model = makeModel(controller, provider: 'DeepSeek');
      expect(model.provider, 'DeepSeek');
    });

    test('operations on a missing id fail gracefully', () {
      expect(controller.rename('nope', 'x'), isFalse);
      expect(controller.delete('nope'), isFalse);
      expect(controller.update('nope', (m) => m), isFalse);
    });
  });
}