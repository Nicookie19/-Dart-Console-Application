import 'package:llm_model_manager_cli/services/model_service.dart';
import 'package:test/test.dart';

void main() {
  group('ModelService', () {
    late ModelService service;

    setUp(() {
      service = ModelService();
      addTearDown(service.clear);
    });

    test('createModel validates input and assigns unique ids', () {
      final a = service.createModel(
        name: '  gpt-4o  ',
        provider: 'OpenAI',
        contextWindow: 128000,
        maxOutputTokens: 4096,
        inputCostPerMillion: 2.5,
        outputCostPerMillion: 10,
        capabilities: {'Code generation'},
      );
      final b = service.createModel(
        name: 'claude-3',
        provider: 'Anthropic',
        contextWindow: 200000,
        maxOutputTokens: 8192,
        inputCostPerMillion: 3,
        outputCostPerMillion: 15,
      );

      expect(a.name, 'gpt-4o');
      expect(a.capabilities, contains('Code generation'));
      expect(a.id, isNot(b.id));
      expect(service.length, 2);

      expect(
        () => service.createModel(
            name: '', provider: 'OpenAI', contextWindow: 1,
            maxOutputTokens: 1, inputCostPerMillion: 0, outputCostPerMillion: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => service.createModel(
            name: 'x', provider: 'OpenAI', contextWindow: 0,
            maxOutputTokens: 1, inputCostPerMillion: 0, outputCostPerMillion: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => service.createModel(
            name: 'x', provider: 'OpenAI', contextWindow: 1,
            maxOutputTokens: 1, inputCostPerMillion: -1, outputCostPerMillion: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('getAll returns newest first', () {
      service.createModel(
          name: 'a', provider: 'OpenAI', contextWindow: 1,
          maxOutputTokens: 1, inputCostPerMillion: 0, outputCostPerMillion: 0);
      service.createModel(
          name: 'b', provider: 'OpenAI', contextWindow: 1,
          maxOutputTokens: 1, inputCostPerMillion: 0, outputCostPerMillion: 0);
      expect(service.getAll().map((m) => m.name), ['b', 'a']);
    });

    test('updateField transforms and stores the new model', () {
      final m = service.createModel(
          name: 'a', provider: 'OpenAI', contextWindow: 1000,
          maxOutputTokens: 100, inputCostPerMillion: 1, outputCostPerMillion: 2);
      service.updateField(m.id, (model) => model.changeCapabilities({'audio'}));
      service.updateField(m.id, (model) => model.changeStatus('Preview'));

      final updated = service.findById(m.id)!;
      expect(updated.capabilities, contains('audio'));
      expect(updated.status, 'Preview');
      expect(service.updateField('missing', (m) => m), isNull);
    });

    test('deleteModel removes and reports existence', () {
      final m = service.createModel(
          name: 'a', provider: 'OpenAI', contextWindow: 1,
          maxOutputTokens: 1, inputCostPerMillion: 0, outputCostPerMillion: 0);
      expect(service.deleteModel(m.id), isTrue);
      expect(service.deleteModel(m.id), isFalse);
      expect(service.length, 0);
    });

    test('filters by provider, status, and capability; search matches names', () {
      service.createModel(
          name: 'gpt-4o', provider: 'OpenAI', contextWindow: 128000,
          maxOutputTokens: 4096, inputCostPerMillion: 2.5,
          outputCostPerMillion: 10,
          capabilities: {'Vision'},
          description: 'flagship vision model');
      service.createModel(
          name: 'llama3', provider: 'Meta', contextWindow: 8192,
          maxOutputTokens: 2048, inputCostPerMillion: 0.1,
          outputCostPerMillion: 0.4,
          status: 'Deprecated');

      expect(service.byProvider('openai'), hasLength(1));
      expect(service.byProvider('OpenAI'), hasLength(1));
      expect(service.byStatus('Deprecated'), hasLength(1));
      expect(service.byStatus('deprecated'), hasLength(1));
      expect(service.byCapability('vision'), hasLength(1));
      expect(service.byCapability('vis'), hasLength(1), reason: 'substring match');
      expect(service.search('FLAGSHIP'), hasLength(1));
      expect(service.search('zzz'), isEmpty);
    });

    test('sortedByCost orders cheapest first', () {
      service.createModel(
          name: 'cheap', provider: 'Local', contextWindow: 1,
          maxOutputTokens: 1, inputCostPerMillion: 0.01,
          outputCostPerMillion: 0.01);
      service.createModel(
          name: 'pricey', provider: 'OpenAI', contextWindow: 1,
          maxOutputTokens: 1, inputCostPerMillion: 10,
          outputCostPerMillion: 40);

      expect(service.sortedByCost().first.name, 'cheap');
      expect(service.sortedByCost().last.name, 'pricey');
    });

    test('statistics counts providers and statuses by free-form label', () {
      service.createModel(
          name: 'a', provider: 'OpenAI', contextWindow: 1,
          maxOutputTokens: 1, inputCostPerMillion: 0, outputCostPerMillion: 0);
      service.createModel(
          name: 'b', provider: 'OpenAI', contextWindow: 1,
          maxOutputTokens: 1, inputCostPerMillion: 0, outputCostPerMillion: 0,
          status: 'Preview');
      service.createModel(
          name: 'c', provider: 'NVIDIA', contextWindow: 1,
          maxOutputTokens: 1, inputCostPerMillion: 0, outputCostPerMillion: 0);

      final stats = service.statistics();
      expect(stats['total'], 3);
      expect(stats['prov_OpenAI'], 2);
      expect(stats['prov_NVIDIA'], 1);
      expect(stats['status_Available'], 2);
      expect(stats['status_Preview'], 1);
    });
  });
}