import 'package:llm_model_manager_cli/models/llm_model.dart';
import 'package:llm_model_manager_cli/models/llm_provider.dart';
import 'package:llm_model_manager_cli/models/model_capability.dart';
import 'package:llm_model_manager_cli/models/model_status.dart';
import 'package:test/test.dart';

void main() {
  LlmModel base() => LlmModel(
        id: '1',
        name: 'gpt-4o',
        displayName: 'GPT-4o',
        provider: LlmProvider.openai,
        contextWindow: 128000,
        maxOutputTokens: 16384,
        inputCostPerMillion: 2.5,
        outputCostPerMillion: 10,
        capabilities: {ModelCapability.vision, ModelCapability.reasoning},
        createdAt: DateTime(2024),
      );

  group('LlmModel', () {
    test('label falls back to the model id when no display name is set', () {
      final noDisplay = base().changeDisplayName(null);
      expect(noDisplay.label, 'gpt-4o');
      expect(base().label, 'GPT-4o');
    });

    test('costForTokens computes a 50/50 input/output round trip', () {
      final model = base();
      final cost = model.costForTokens(10000);
      expect(cost, closeTo(0.0625, 0.0001));
    });

    test('hasCapabilities requires every listed capability', () {
      final model = base();
      expect(model.hasCapabilities([ModelCapability.vision]), isTrue);
      expect(
        model.hasCapabilities([
          ModelCapability.vision,
          ModelCapability.code,
        ]),
        isFalse,
      );
    });

    test('copy helpers preserve id and stamp updatedAt', () {
      final updated = base().rename('gpt-5').changeStatus(ModelStatus.preview);
      expect(updated.id, '1');
      expect(updated.name, 'gpt-5');
      expect(updated.status, ModelStatus.preview);
      expect(updated.updatedAt, isNotNull);
    });
  });

  group('enums', () {
    test('parse by label and name, case-insensitively', () {
      expect(LlmProvider.fromInput('Anthropic'), LlmProvider.anthropic);
      expect(LlmProvider.fromInput('meta'), LlmProvider.meta);
      expect(ModelStatus.fromInput('preview'), ModelStatus.preview);
      expect(ModelCapability.fromInput('Vision'), ModelCapability.vision);
    });

    test('parseSet accepts comma/space separated lists', () {
      final set = ModelCapability.parseSet('vision, code reasoning');
      expect(set, {
        ModelCapability.vision,
        ModelCapability.code,
        ModelCapability.reasoning,
      });
      expect(ModelCapability.parseSet(''), isEmpty);
    });

    test('throw FormatException on unknown values', () {
      expect(() => LlmProvider.fromInput('nasa'), throwsA(isA<FormatException>()));
      expect(() => ModelStatus.fromInput('zzz'), throwsA(isA<FormatException>()));
      expect(() => ModelCapability.fromInput('x'),
          throwsA(isA<FormatException>()));
    });
  });
}