import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_cli/services/llm_service.dart';
import 'package:test/test.dart';

void main() {
  group('LlmService', () {
    test('sends a minimal ping request for the chosen model', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('{}', 200,
            headers: {'content-type': 'application/json'});
      });

      final service = LlmService(
        const LlmConfig(apiKey: 'secret', baseUrl: 'https://api.test/v1', defaultModel: 'm'),
        client: client,
      );
      final result = await service.ping(model: 'gpt-4o');

      expect(result.latencyMs, greaterThanOrEqualTo(0));
      expect(captured.url.path, '/v1/chat/completions');
      expect(captured.headers['Authorization'], 'Bearer secret');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['model'], 'gpt-4o');
      expect(body['max_tokens'], 1);
      expect((body['messages'] as List).first['content'], 'ping');
    });

    test('throws LlmException on a non-200 response', () async {
      final client = MockClient((_) async => http.Response('bad key', 401));
      final service = LlmService(
        const LlmConfig(apiKey: 'k', baseUrl: 'https://api.test/v1', defaultModel: 'm'),
        client: client,
      );

      expect(
        () => service.ping(model: 'm'),
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
        () => service.ping(model: 'm'),
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
        () => service.ping(model: 'm'),
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