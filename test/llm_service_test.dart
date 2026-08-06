import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_cli/services/llm_service.dart';
import 'package:test/test.dart';

void main() {
  group('LlmService', () {
    const okBody = {
      'choices': [
        {
          'message': {'content': 'Hello from the model'},
        },
      ],
    };

    test('sends the prompt to chat/completions with the auth header', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode(okBody), 200,
            headers: {'content-type': 'application/json'});
      });

      final service = LlmService(
        const LlmConfig(apiKey: 'secret', baseUrl: 'https://api.test/v1', defaultModel: 'm1'),
        client: client,
      );
      final result = await service.complete(prompt: 'Hello {{name}}', model: 'm2');

      expect(result.text, 'Hello from the model');
      expect(captured.url.path, '/v1/chat/completions');
      expect(captured.headers['Authorization'], 'Bearer secret');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['model'], 'm2');
      expect(body['temperature'], 0.7);
    });

    test('uses the default model when none is provided', () async {
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['model'], 'default-x');
        return http.Response(jsonEncode(okBody), 200,
            headers: {'content-type': 'application/json'});
      });

      final service = LlmService(
        const LlmConfig(apiKey: 'k', baseUrl: 'https://api.test/v1', defaultModel: 'default-x'),
        client: client,
      );
      final result = await service.complete(prompt: 'hey');
      expect(result.latencyMs, greaterThanOrEqualTo(0));
      expect(result.text, 'Hello from the model');
    });

    test('throws LlmException on a non-200 response', () async {
      final client = MockClient((_) async => http.Response('bad key', 401));
      final service = LlmService(
        const LlmConfig(apiKey: 'k', baseUrl: 'https://api.test/v1', defaultModel: 'm'),
        client: client,
      );

      expect(
        () => service.complete(prompt: 'p'),
        throwsA(isA<LlmException>()
            .having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('throws LlmException when the API key is missing, without calling the network', () async {
      var called = false;
      final client = MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      });
      final service = LlmService(
        const LlmConfig(apiKey: '', baseUrl: 'https://api.test/v1', defaultModel: 'm'),
        client: client,
      );

      expect(
        () => service.complete(prompt: 'p'),
        throwsA(isA<LlmException>()
            .having((e) => e.statusCode, 'statusCode', isNull)),
      );
      expect(called, isFalse);
    });

    test('throws LlmException on a network failure', () async {
      final client = MockClient((_) async => throw http.ClientException('refused'));
      final service = LlmService(
        const LlmConfig(apiKey: 'k', baseUrl: 'https://api.test/v1', defaultModel: 'm'),
        client: client,
      );

      expect(
        () => service.complete(prompt: 'p'),
        throwsA(isA<LlmException>()
            .having((e) => e.message, 'message', contains('refused'))),
      );
    });
  });

  group('LlmConfig.fromEnvironment', () {
    test('applies defaults when no variables are set', () {
      final config = LlmConfig.fromEnvironment({});
      expect(config.apiKey, isEmpty);
      expect(config.baseUrl, 'https://api.openai.com/v1');
      expect(config.defaultModel, 'gpt-4o-mini');
    });

    test('reads values from environment variables', () {
      final config = LlmConfig.fromEnvironment({
        'OPENAI_API_KEY': 'sk-test',
        'OPENAI_BASE_URL': 'https://proxy.test/v1',
        'OPENAI_MODEL': 'gpt-4o',
      });
      expect(config.apiKey, 'sk-test');
      expect(config.baseUrl, 'https://proxy.test/v1');
      expect(config.defaultModel, 'gpt-4o');
    });
  });
}