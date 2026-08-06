import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:riverpod/riverpod.dart';
import 'package:task_manager_cli/controllers/history_controller.dart';
import 'package:task_manager_cli/controllers/prompt_controller.dart';
import 'package:task_manager_cli/models/prompt_category.dart';
import 'package:task_manager_cli/providers/providers.dart';
import 'package:task_manager_cli/services/llm_service.dart';
import 'package:test/test.dart';

/// Builds a container with the LLM service pointed at a mocked endpoint.
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
            return respond?.call(request) ??
                http.Response(
                  jsonEncode({
                    'choices': [
                      {
                        'message': {'content': 'Mocked reply'},
                      },
                    ],
                  }),
                  200,
                );
          }),
        ),
      ),
    ],
  );
}

void main() {
  group('PromptController (Riverpod DI)', () {
    late ProviderContainer container;
    late PromptController controller;

    setUp(() {
      container = makeContainer();
      addTearDown(container.dispose);
      controller = container.read(promptControllerProvider.notifier);
    });

    test('addPrompt updates state through the service', () {
      controller.addPrompt(
        name: 'Summarizer',
        content: 'Summarize {{text}}',
        category: PromptCategory.writing,
      );

      final state = container.read(promptControllerProvider);
      expect(state, hasLength(1));
      expect(state.first.name, 'Summarizer');
      expect(state.first.variables, {'text'});
      expect(container.read(promptServiceProvider).length, 1,
          reason: 'service is the single source of truth');
    });

    test('rename and delete update state', () {
      final p = controller.addPrompt(name: 'a', content: 'x');
      expect(controller.rename(p.id, 'b'), isTrue);
      expect(container.read(promptControllerProvider).first.name, 'b');

      expect(controller.delete(p.id), isTrue);
      expect(container.read(promptControllerProvider), isEmpty);
    });

    test('operations on a missing id fail gracefully', () {
      expect(controller.rename('nope', 'x'), isFalse);
      expect(controller.delete('nope'), isFalse);
      expect(controller.updateContent('nope', 'x'), isFalse);
    });
  });

  group('HistoryController (Riverpod DI + mocked LLM)', () {
    late ProviderContainer container;
    late HistoryController controller;

    setUp(() {
      container = makeContainer();
      addTearDown(container.dispose);
      controller = container.read(historyControllerProvider.notifier);
    });

    test('runTest records a successful result and exposes it as state', () async {
      final prompt = container
          .read(promptControllerProvider.notifier)
          .addPrompt(name: 'Greeter', content: 'Hello {{name}}!');

      final result = await controller.runTest(prompt, {'name': 'World'});

      expect(result.success, isTrue);
      expect(result.response, 'Mocked reply');
      expect(result.model, 'mock-model');
      expect(result.renderedPrompt, 'Hello World!');

      final state = container.read(historyControllerProvider);
      expect(state, hasLength(1));
      expect(state.first, same(result));
    });

    test('runTest records failures without throwing', () async {
      container = makeContainer(respond: (_) => http.Response('nope', 500));
      container.dispose();
      container = makeContainer(respond: (_) => http.Response('nope', 500));
      addTearDown(container.dispose);
      controller = container.read(historyControllerProvider.notifier);

      final prompt = container
          .read(promptControllerProvider.notifier)
          .addPrompt(name: 'Broken', content: 'boom');

      final result = await controller.runTest(prompt, {});

      expect(result.success, isFalse);
      expect(result.error, contains('500'));
      expect(container.read(historyControllerProvider), hasLength(1));
    });

    test('an explicit model overrides the configured default', () async {
      final prompt = container
          .read(promptControllerProvider.notifier)
          .addPrompt(name: 'P', content: 'x');

      final result = await controller.runTest(prompt, {}, model: 'custom-1');

      expect(result.model, 'custom-1');
    });

    test('clearHistory empties state', () async {
      final prompt = container
          .read(promptControllerProvider.notifier)
          .addPrompt(name: 'P', content: 'x');
      await controller.runTest(prompt, {});
      controller.clearHistory();

      expect(container.read(historyControllerProvider), isEmpty);
    });
  });
}