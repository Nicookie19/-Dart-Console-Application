import 'package:task_manager_cli/models/prompt.dart';
import 'package:task_manager_cli/models/prompt_category.dart';
import 'package:task_manager_cli/models/prompt_test_result.dart';
import 'package:test/test.dart';

void main() {
  group('Prompt model', () {
    test('extracts unique {{variables}} from content', () {
      final prompt = Prompt(
        id: '1',
        name: 'x',
        content: '{{a}} and {{a}} and {{b}}',
        createdAt: DateTime(2024),
      );
      expect(prompt.variables, {'a', 'b'});
    });

    test('detects no variables when content is plain', () {
      final prompt = Prompt(
        id: '1',
        name: 'x',
        content: 'Hello world',
        createdAt: DateTime(2024),
      );
      expect(prompt.variables, isEmpty);
    });

    test('render substitutes known variables and leaves unknown ones intact', () {
      final prompt = Prompt(
        id: '1',
        name: 'x',
        content: 'Hi {{name}}, your code is {{code}}.',
        createdAt: DateTime(2024),
      );
      final rendered = prompt.render({'name': 'Ana', 'code': '42'});
      expect(rendered, 'Hi Ana, your code is 42.');
    });

    test('copyWith helpers preserve id and createdAt', () {
      final prompt = Prompt(
        id: '1',
        name: 'Old',
        content: 'abc',
        createdAt: DateTime(2024),
      );
      final renamed = prompt.rename('New');
      expect(renamed.id, '1');
      expect(renamed.name, 'New');
      expect(renamed.content, 'abc');
      expect(renamed.updatedAt, isNotNull);
    });
  });

  group('PromptCategory', () {
    test('parses by label and name, case-insensitively', () {
      expect(PromptCategory.fromInput('code'), PromptCategory.code);
      expect(PromptCategory.fromInput('Code'), PromptCategory.code);
      expect(PromptCategory.fromInput('reasoning'), PromptCategory.reasoning);
    });

    test('throws FormatException on an unknown category', () {
      expect(() => PromptCategory.fromInput('sports'),
          throwsA(isA<FormatException>()));
    });
  });

  group('PromptTestResult', () {
    test('success is true only when there is a response and no error', () {
      final ok = PromptTestResult(
        id: '1',
        promptId: 'p',
        promptName: 'n',
        model: 'm',
        renderedPrompt: 'x',
        latencyMs: 10,
        testedAt: DateTime(2024),
        response: 'reply',
      );
      final fail = PromptTestResult(
        id: '2',
        promptId: 'p',
        promptName: 'n',
        model: 'm',
        renderedPrompt: 'x',
        latencyMs: 5,
        testedAt: DateTime(2024),
        error: 'boom',
      );
      expect(ok.success, isTrue);
      expect(fail.success, isFalse);
    });
  });
}