import 'package:llm_model_manager_cli/models/llm_provider.dart';
import 'package:llm_model_manager_cli/models/model_capability.dart';
import 'package:llm_model_manager_cli/models/model_status.dart';
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
        provider: LlmProvider.openai,
        contextWindow: 128000,
        maxOutputTokens: 4096,
        inputCostPerMillion: 2.5,
        outputCostPerMillion: 10,
        capabilities: {ModelCapability.code},
      );
      final b = service.createModel(
        name: 'claude-3',
        provider: LlmProvider.anthropic,
        contextWindow: 200000,
        maxOutputTokens: 8192,
        inputCostPerMillion: 3,
        outputCostPerMillion: 15,
      );

      expect(a.name, 'gpt-4o');
      expect(a.capabilities, contains(ModelCapability.code));
      expect(a.id, isNot(b.id));
      expect(service.length, 2);

      expect(
        () => service.createModel(
            name: '', provider: LlmProvider.openai, contextWindow: 1,
            maxOutputTokens: 1, inputCostPerMillion: 0, outputCostPerMillion: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => service.createModel(
            name: 'x', provider: LlmProvider.openai, contextWindow: 0,
            maxOutputTokens: 1, inputCostPerMillion: 0, outputCostPerMillion: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => service.createModel(
            name: 'x', provider: LlmProvider.openai, contextWindow: 1,
            maxOutputTokens: 1, inputCostPerMillion: -1, outputCostPerMillion: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('getAll returns newest first', () {
      service.createModel(
          name: 'a', provider: LlmProvider.openai, contextWindow: 1,
          maxOutputTokens: 1, inputCostPerMillion: 0, outputCostPerMillion: 0);
      service.createModel(
          name: 'b', provider: LlmProvider.openai, contextWindow: 1,
          maxOutputTokens: 1, inputCostPerMillion: 0, outputCostPerMillion: 0);
      expect(service.getAll().map((m) => m.name), ['b', 'a']);
    });

    test('updateField transforms and stores the new model', () {
      final m = service.createModel(
          name: 'a', provider: LlmProvider.openai, contextWindow: 1000,
          maxOutputTokens: 100, inputCostPerMillion: 1, outputCostPerMillion: 2);
      service.updateField(m.id, (model) => model.changeCapabilities(
          {ModelCapability.audio}));
      service.updateField(m.id, (model) => model.changeStatus(ModelStatus.preview));

      final updated = service.findById(m.id)!;
      expect(updated.capabilities, contains(ModelCapability.audio));
      expect(updated.status, ModelStatus.preview);
      expect(service.updateField('missing', (m) => m), isNull);
    });

    test('deleteModel removes and reports existence', () {
      final m = service.createModel(
          name: 'a', provider: LlmProvider.openai, contextWindow: 1,
          maxOutputTokens: 1, inputCostPerMillion: 0, outputCostPerMillion: 0);
      expect(service.deleteModel(m.id), isTrue);
      expect(service.deleteModel(m.id), isFalse);
      expect(service.length, 0);
    });

    test('filters by provider, status, and capability; search matches names', () {
      service.createModel(
          name: 'gpt-4o', provider: LlmProvider.openai, contextWindow: 128000,
          maxOutputTokens: 4096, inputCostPerMillion: 2.5,
          outputCostPerMillion: 10,
          capabilities: {ModelCapability.vision},
          description: 'flagship vision model');
      service.createModel(
          name: 'llama3', provider: LlmProvider.meta, contextWindow: 8192,
          maxOutputTokens: 2048, inputCostPerMillion: 0.1,
          outputCostPerMillion: 0.4,
          status: ModelStatus.deprecated);

      expect(service.byProvider(LlmProvider.openai), hasLength(1));
      expect(service.byStatus(ModelStatus.deprecated), hasLength(1));
      expect(service.byCapability(ModelCapability.vision), hasLength(1));
      expect(service.search('FLAGSHIP'), hasLength(1));
      expect(service.search('zzz'), isEmpty);
    });

    test('sortedByCost orders cheapest first', () {
      service.createModel(
          name: 'cheap', provider: LlmProvider.local, contextWindow: 1,
          maxOutputTokens: 1, inputCostPerMillion: 0.01,
          outputCostPerMillion: 0.01);
      service.createModel(
          name: 'pricey', provider: LlmProvider.openai, contextWindow: 1,
          maxOutputTokens: 1, inputCostPerMillion: 10,
          outputCostPerMillion: 40);

      expect(service.sortedByCost().first.name, 'cheap');
      expect(service.sortedByCost().last.name, 'pricey');
    });

    test('statistics counts providers and statuses', () {
      service.createModel(
          name: 'a', provider: LlmProvider.openai, contextWindow: 1,
          maxOutputTokens: 1, inputCostPerMillion: 0, outputCostPerMillion: 0);
      service.createModel(
          name: 'b', provider: LlmProvider.openai, contextWindow: 1,
          maxOutputTokens: 1, inputCostPerMillion: 0, outputCostPerMillion: 0,
          status: ModelStatus.preview);

      final stats = service.statistics();
      expect(stats['total'], 2);
      expect(stats['openai'], 2);
      expect(stats['status_available'], 1);
      expect(stats['status_preview'], 1);
    });
  });
}