import 'package:task_manager_cli/models/prompt_category.dart';
import 'package:task_manager_cli/models/prompt_test_result.dart';
import 'package:task_manager_cli/services/prompt_service.dart';
import 'package:task_manager_cli/services/test_history_service.dart';
import 'package:test/test.dart';

void main() {
  group('PromptService', () {
    late PromptService service;

    setUp(() {
      service = PromptService();
      addTearDown(service.clear);
    });

    test('createPrompt validates input and assigns unique ids', () {
      final a = service.createPrompt(name: '  A  ', content: 'Hi {{name}}');
      final b = service.createPrompt(name: 'B', content: 'Yo');

      expect(a.name, 'A');
      expect(a.id, isNot(b.id));
      expect(service.length, 2);
      expect(() => service.createPrompt(name: '', content: 'x'),
          throwsA(isA<ArgumentError>()));
      expect(() => service.createPrompt(name: 'x', content: '  '),
          throwsA(isA<ArgumentError>()));
    });

    test('getAll returns newest first', () {
      service.createPrompt(name: 'a', content: '1');
      service.createPrompt(name: 'b', content: '2');
      expect(service.getAll().map((p) => p.name), ['b', 'a']);
    });

    test('rename, updateContent and changeCategory mutate the prompt', () {
      final p = service.createPrompt(name: 'a', content: 'x');
      service.rename(p.id, 'b');
      service.updateContent(p.id, 'y {{v}}');
      service.changeCategory(p.id, PromptCategory.code);

      final updated = service.findById(p.id)!;
      expect(updated.name, 'b');
      expect(updated.content, 'y {{v}}');
      expect(updated.category, PromptCategory.code);
      expect(updated.variables, {'v'});
      expect(service.rename('missing', 'z'), isNull);
    });

    test('deletePrompt removes and reports existence', () {
      final p = service.createPrompt(name: 'a', content: 'x');
      expect(service.deletePrompt(p.id), isTrue);
      expect(service.deletePrompt(p.id), isFalse);
      expect(service.length, 0);
    });

    test('byCategory filters, search matches name and description', () {
      service.createPrompt(name: 'Translate', content: 'a', category: PromptCategory.translation);
      service.createPrompt(name: 'Fix bug', content: 'b', category: PromptCategory.code, description: 'make tests pass');

      expect(service.byCategory(PromptCategory.code), hasLength(1));
      expect(service.search('bug'), hasLength(1));
      expect(service.search('TESTS'), hasLength(1));
      expect(service.search('zzz'), isEmpty);
    });
  });

  group('TestHistoryService', () {
    test('stores results newest first and computes statistics', () {
      final history = TestHistoryService();
      PromptTestResult result({
        required String id,
        required bool success,
        required int latency,
      }) =>
          PromptTestResult(
            id: id,
            promptId: 'p',
            promptName: 'p',
            model: 'm',
            renderedPrompt: 'x',
            latencyMs: latency,
            testedAt: DateTime(2024),
            response: success ? 'ok' : null,
            error: success ? null : 'boom',
          );

      history.add(result(id: 'a', success: true, latency: 100));
      history.add(result(id: 'b', success: false, latency: 200));
      history.add(result(id: 'c', success: true, latency: 300));

      expect(history.length, 3);
      expect(history.getAll().map((r) => r.id), ['c', 'b', 'a']);
      expect(history.successCount, 2);
      expect(history.failureCount, 1);
      expect(history.averageLatencyMs, 200);
      expect(history.recent(2).map((r) => r.id), ['c', 'b']);
    });
  });
}