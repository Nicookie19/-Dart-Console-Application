import 'dart:convert';

import 'package:http/http.dart' as http;

/// Configuration for the LLM API connection.
class LlmConfig {
  const LlmConfig({
    required this.apiKey,
    required this.baseUrl,
    required this.defaultModel,
  });

  /// Builds a config from process environment variables, applying sane
  /// defaults so the app runs without any setup.
  factory LlmConfig.fromEnvironment(Map<String, String> env) {
    return LlmConfig(
      apiKey: env['OPENAI_API_KEY'] ?? '',
      baseUrl: env['OPENAI_BASE_URL'] ?? 'https://api.openai.com/v1',
      defaultModel: env['OPENAI_MODEL'] ?? 'gpt-4o-mini',
    );
  }

  /// API key sent as the `Authorization: Bearer` header. Empty when unset.
  final String apiKey;

  /// Base URL of an OpenAI-compatible chat completions endpoint.
  final String baseUrl;

  /// Model used when the user does not specify one.
  final String defaultModel;
}

/// Thrown when an LLM call fails.
class LlmException implements Exception {
  const LlmException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => statusCode == null
      ? 'LlmException: $message'
      : 'LlmException ($statusCode): $message';
}

/// A successful connectivity reply.
class LlmPing {
  const LlmPing({required this.latencyMs});

  final int latencyMs;
}

/// Sends lightweight connectivity checks ("pings") to an OpenAI-compatible
/// chat completions API.
///
/// The underlying [http.Client] is injected through the constructor so tests
/// can substitute a [MockClient] — no real network is ever required.
class LlmService {
  LlmService(this._config, {http.Client? client})
      : _client = client ?? http.Client();

  final LlmConfig _config;
  final http.Client _client;

  /// Sends a minimal one-token request for [model] to confirm the model is
  /// reachable and authenticated.
  ///
  /// Throws [LlmException] when the request fails for any reason.
  Future<LlmPing> ping({required String model}) async {
    if (_config.apiKey.isEmpty) {
      throw const LlmException(
        'No API key configured. Set the OPENAI_API_KEY environment variable, '
        'e.g. OPENAI_API_KEY=sk-... dart run bin/main.dart',
      );
    }

    final stopwatch = Stopwatch()..start();
    final uri = Uri.parse('${_config.baseUrl}/chat/completions');

    http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config.apiKey}',
        },
        body: jsonEncode({
          'model': model,
          'max_tokens': 1,
          'messages': [
            {'role': 'user', 'content': 'ping'},
          ],
        }),
      );
    } catch (e) {
      throw LlmException('Network error while contacting $uri: $e');
    }
    stopwatch.stop();

    if (response.statusCode != 200) {
      throw LlmException(
        'The LLM API responded with HTTP ${response.statusCode}:\n${response.body}',
        statusCode: response.statusCode,
      );
    }

    return LlmPing(latencyMs: stopwatch.elapsedMilliseconds);
  }
}