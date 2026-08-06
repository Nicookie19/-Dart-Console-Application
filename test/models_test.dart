import 'package:llm_model_manager_cli/models/llm_model.dart';
import 'package:test/test.dart';

void main() {
  LlmModel base() => LlmModel(
        id: '1',
        name: 'gpt-4o',
        displayName: 'GPT-4o',
        provider: 'OpenAI',
        contextWindow: 128000,
        maxOutputTokens: 16384,
        inputCostPerMillion: 2.5,
        outputCostPerMillion: 10,
        capabilities: {'Vision', 'Reasoning'},
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

    test('hasCapabilities requires every listed capability, case-insensitive', () {
      final model = base();
      expect(model.hasCapabilities(['vision']), isTrue);
      expect(
        model.hasCapabilities([
          'Vision',
          'Code generation',
        ]),
        isFalse,
      );
      expect(model.hasCapabilities(['VISION']), isTrue);
    });

    test('copy helpers preserve id and stamp updatedAt', () {
      final updated =
          base().rename('gpt-5').changeStatus('Preview').changeProvider('Meta');
      expect(updated.id, '1');
      expect(updated.name, 'gpt-5');
      expect(updated.status, 'Preview');
      expect(updated.provider, 'Meta');
      expect(updated.updatedAt, isNotNull);
    });

    test('capabilities accept free-form text as typed', () {
      final updated = base().changeCapabilities({'generation', 'Generation', 'audio'});
      expect(updated.capabilities, {'generation', 'Generation', 'audio'});
      expect(updated.capabilities, isNot(same(base().capabilities)));
    });
  });

  group('free-form fields', () {
    test('provider, status, and capabilities are plain strings', () {
      final model = base();
      expect(model.provider, 'OpenAI');
      expect(model.status, 'Available');
      expect(model.capabilities, contains('Vision'));
    });

    test('custom values are stored as typed, with no validation', () {
      final model = base()
          .changeProvider('NVIDIA')
          .changeStatus('Coming Soon')
          .changeCapabilities({'generation'});
      expect(model.provider, 'NVIDIA');
      expect(model.status, 'Coming Soon');
      expect(model.capabilities, contains('generation'));
      expect(model.toString(), '[NVIDIA] GPT-4o');
    });
  });
}