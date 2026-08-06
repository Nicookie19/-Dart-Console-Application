import 'dart:io';

import 'package:riverpod/riverpod.dart';

import 'controllers/prompt_controller.dart';
import 'models/prompt.dart';
import 'models/prompt_category.dart';
import 'models/prompt_test_result.dart';
import 'providers/providers.dart';

/// Interactive console front-end for the LLM Prompt Manager & Tester.
///
/// The UI layer only talks to Riverpod (via a [ProviderContainer]); it never
/// creates services, controllers, or HTTP clients directly.
class ConsoleApp {
  ConsoleApp({ProviderContainer? container})
      : _container = container ?? ProviderContainer();

  final ProviderContainer _container;

  Future<void> run() async {
    _printBanner();
    var running = true;
    while (running) {
      _printMenu();
      switch (_readLine('> ').trim()) {
        case '1':
          _addPrompt();
        case '2':
          _listPrompts(_promptState);
        case '3':
          _filterByCategory();
        case '4':
          _search();
        case '5':
          _viewDetails();
        case '6':
          _editPrompt();
        case '7':
          _deletePrompt();
        case '8':
          await _testPrompt();
        case '9':
          _showHistory();
        case '10':
          _dashboard();
        case '0':
          running = false;
        default:
          _error('Unknown option. Enter a number from the menu.');
      }
    }
    _success('Goodbye!');
    _container.dispose();
  }

  // ------------------------------------------------------------- prompt menu

  void _addPrompt() {
    final name = _readLine('Name: ').trim();
    if (name.isEmpty) return _error('Name cannot be empty.');
    final category =
        _readCategory('Category [General]: ', defaultTo: PromptCategory.general);
    final description = _readLine('Description (optional): ').trim();
    _info('Enter the prompt template. You may use {{variables}}:');
    final content = _readMultiline('Content (finish with a line containing only "."): ');

    try {
      final prompt = _promptController.addPrompt(
        name: name,
        content: content,
        category: category,
        description: description,
      );
      _success('Prompt "${prompt.name}" created.');
      if (prompt.variables.isNotEmpty) {
        _info('Detected variables: ${prompt.variables.join(', ')}');
      }
    } on ArgumentError catch (e) {
      _error(e.message ?? 'Invalid prompt.');
    }
  }

  void _listPrompts(List<Prompt> prompts) {
    if (prompts.isEmpty) return _info('No prompts yet. Add one from the menu.');
    _success('${prompts.length} prompt(s):');
    _printPrompts(prompts);
  }

  void _filterByCategory() {
    final category = _readCategory(_readLine('Category: '));
    final list = _container.read(promptServiceProvider).byCategory(category);
    if (list.isEmpty) return _info('No prompts in the ${category.label} category.');
    _success('${list.length} prompt(s) in ${category.label}:');
    _printPrompts(list);
  }

  void _search() {
    final query = _readLine('Search: ').trim();
    final results = _container.read(promptServiceProvider).search(query);
    if (results.isEmpty) return _info('No prompts match "$query".');
    _listPrompts(results);
  }

  void _viewDetails() {
    final prompt = _selectPrompt();
    if (prompt == null) return;
    _showPrompt(prompt);
  }

  void _editPrompt() {
    final prompt = _selectPrompt();
    if (prompt == null) return;

    var editing = true;
    while (editing) {
      print('\nEDIT "${prompt.name}"');
      print('  1. Rename');
      print('  2. Edit content');
      print('  3. Edit description');
      print('  4. Change category');
      print('  0. Back');
      switch (_readLine('> ').trim()) {
        case '1':
          final name = _readLine('New name: ').trim();
          _promptController.rename(prompt.id, name)
              ? _success('Renamed to "$name".')
              : _error('Rename failed.');
        case '2':
          _info('Enter new content (current variables will be replaced):');
          final content = _readMultiline('Content (".", empty, to cancel): ');
          if (content.isNotEmpty) {
            _promptController.updateContent(prompt.id, content)
                ? _success('Content updated.')
                : _error('Update failed.');
          }
        case '3':
          final description = _readLine('New description: ').trim();
          _promptController.updateDescription(prompt.id, description)
              ? _success('Description updated.')
              : _error('Update failed.');
        case '4':
          final category = _readCategory(_readLine('New category: '));
          _promptController.changeCategory(prompt.id, category)
              ? _success('Category updated.')
              : _error('Update failed.');
        case '0':
          editing = false;
        default:
          _error('Unknown option.');
      }
    }
  }

  void _deletePrompt() {
    final prompt = _selectPrompt();
    if (prompt == null) return;

    final confirm =
        _readLine('Delete "${prompt.name}"? (y/N): ').trim().toLowerCase();
    if (confirm != 'y' && confirm != 'yes') return _info('Deletion cancelled.');

    _promptController.delete(prompt.id)
        ? _success('"${prompt.name}" deleted.')
        : _error('Delete failed.');
  }

  // ---------------------------------------------------------------- testing

  Future<void> _testPrompt() async {
    final prompt = _selectPrompt();
    if (prompt == null) return;

    final variables = <String, String>{};
    if (prompt.variables.isNotEmpty) {
      _info('This prompt uses variables: ${prompt.variables.join(', ')}');
      for (final variable in prompt.variables) {
        variables[variable] = _readLine('  $variable: ').trim();
      }
    }

    final defaultModel = _container.read(llmConfigProvider).defaultModel;
    final modelInput = _readLine('Model [$defaultModel]: ').trim();
    final model = modelInput.isEmpty ? defaultModel : modelInput;

    _info('Sending to $model ... (this may take a few seconds)');
    final result = await _container
        .read(historyControllerProvider.notifier)
        .runTest(prompt, variables, model: model);

    _printTestResult(result);
    _success(result.success
        ? 'Test recorded in history.'
        : 'Failure recorded in history.');
  }

  void _showHistory() {
    final results = _historyState;
    if (results.isEmpty) return _info('No tests run yet. Use menu option 8.');

    _success('${results.length} test(s):');
    for (var i = 0; i < results.length; i++) {
      final r = results[i];
      final icon = r.success ? '\x1B[32m[ok]\x1B[0m' : '\x1B[31m[!]\x1B[0m';
      print('  ${i + 1}. $icon ${r.promptName} (${r.model}) - ${r.latencyMs}ms');
    }

    final raw = _readLine('View details (number, 0 to go back): ').trim();
    final index = int.tryParse(raw);
    if (index == null || index < 1 || index > results.length) return;
    final r = results[index - 1];
    print('\n=== ${r.success ? 'SUCCESS' : 'FAILURE'} | ${r.promptName} | '
        '${r.model} | ${r.latencyMs}ms ===');
    _info('Sent prompt:');
    print(r.renderedPrompt);
    if (r.success) {
      _info('Response:');
      print(r.response);
    } else {
      _error('Error:');
      print(r.error);
    }
  }

  // ---------------------------------------------------------------- dashboard

  void _dashboard() {
    final prompts = _promptState;
    final history = _historyState;

    final width = 46;
    _divider(width);
    _center('DASHBOARD', width);
    _center('prompts: ${prompts.length}', width);
    for (final category in PromptCategory.values) {
      final count = prompts.where((p) => p.category == category).length;
      if (count > 0) _center('  ${category.label}: $count', width);
    }
    _center('tests: ${history.length}', width);
    _center('  succeeded: ${history.where((r) => r.success).length}', width);
    _center('  failed: ${history.where((r) => !r.success).length}', width);
    _center('  average latency: ${_avgLatency(history)}ms', width);
    _divider(width);
    _success('Tip: set OPENAI_API_KEY and OPENAI_MODEL to run live tests.');
  }

  // ------------------------------------------------------------------ helpers

  PromptController get _promptController =>
      _container.read(promptControllerProvider.notifier);

  List<Prompt> get _promptState => _container.read(promptControllerProvider);

  List<PromptTestResult> get _historyState =>
      _container.read(historyControllerProvider);

  int _avgLatency(List<PromptTestResult> results) {
    if (results.isEmpty) return 0;
    return results.fold<int>(0, (s, r) => s + r.latencyMs) ~/ results.length;
  }

  /// Lets the user pick a prompt from the list; returns null if aborted.
  Prompt? _selectPrompt() {
    final prompts = _promptState;
    if (prompts.isEmpty) {
      _info('No prompts yet. Add one first.');
      return null;
    }
    _info('Choose a prompt:');
    for (var i = 0; i < prompts.length; i++) {
      final prompt = prompts[i];
      final vars = prompt.variables.isEmpty
          ? ''
          : ' \x1B[33m({{${prompt.variables.join('}}, {{')}}})\x1B[0m';
      print('  ${i + 1}. $prompt$vars');
    }
    final raw = _readLine('Number (or 0 to cancel): ').trim();
    final index = int.tryParse(raw);
    if (index == null || index < 0 || index > prompts.length) {
      _error('Invalid number.');
      return null;
    }
    return index == 0 ? null : prompts[index - 1];
  }

  void _printPrompts(List<Prompt> prompts) {
    for (final prompt in prompts) {
      final vars = prompt.variables.isEmpty
          ? ''
          : ' \x1B[33m{{${prompt.variables.join(', ')}}}\x1B[0m';
      print('  ${prompt.category.label}: ${prompt.name}$vars'
          '${prompt.description.isEmpty ? '' : ' - ${prompt.description}'}');
    }
  }

  void _showPrompt(Prompt prompt) {
    print('\n${prompt.category.label} prompt: "${prompt.name}"');
    if (prompt.description.isNotEmpty) {
      _info('Description: ${prompt.description}');
    }
    if (prompt.variables.isNotEmpty) {
      _info('Variables: ${prompt.variables.join(', ')}');
    }
    _info('Content:');
    print(prompt.content);
  }

  void _printTestResult(PromptTestResult r) {
    print('\n=== ${r.success ? 'SUCCESS' : 'FAILURE'} | ${r.promptName} | '
        '${r.model} | ${r.latencyMs}ms ===');
    if (r.success) {
      _info('Response:');
      print(r.response);
    } else {
      _error('Error:');
      print(r.error);
    }
  }

  PromptCategory _readCategory(String prompt, {PromptCategory? defaultTo}) {
    while (true) {
      final raw = _readLine(prompt).trim();
      if (raw.isEmpty && defaultTo != null) return defaultTo;
      if (raw.isEmpty) {
        _error('Category cannot be empty.');
        continue;
      }
      try {
        return PromptCategory.fromInput(raw);
      } on FormatException catch (e) {
        _error(e.message);
      }
    }
  }

  /// Reads multiple lines of input terminated by an empty line or a line
  /// containing only a dot.
  String _readMultiline(String prompt) {
    _info(prompt);
    final buffer = StringBuffer();
    while (true) {
      final line = _readLine('> ');
      if (line.trim() == '.' || line.trim().isEmpty) break;
      buffer.writeln(line);
    }
    return buffer.toString().trimRight();
  }

  // ------------------------------------------------------------------ output

  void _printBanner() {
    final config = _container.read(llmConfigProvider);
    final keyStatus = config.apiKey.isEmpty ? 'NOT SET' : 'set';
    _divider(46);
    _center('LLM PROMPT MANAGER & TESTER', 46);
    _center('Dart + Riverpod (DI) demo', 46);
    _center('Models / Services / Controllers', 46);
    _divider(46);
    print('  api key : $keyStatus');
    print('  base url: ${config.baseUrl}');
    print('  model   : ${config.defaultModel}');
    if (config.apiKey.isEmpty) {
      print('  SET OPENAI_API_KEY to run live tests.');
    }
  }

  void _printMenu() {
    print('''
MAIN MENU
  1. Add prompt
  2. List all prompts
  3. Filter by category
  4. Search prompts
  5. View prompt details
  6. Edit prompt
  7. Delete prompt
  8. Test a prompt
  9. Test history
 10. Dashboard
  0. Exit''');
  }

  static void _divider(int width) => print('=' * width);

  static void _center(String text, int width) {
    final pad = (width - text.length) ~/ 2;
    print('${' ' * pad}$text');
  }

  String _readLine(String prompt) {
    stdout.write(prompt);
    return stdin.readLineSync() ?? '';
  }

  void _info(String message) => print('\x1B[36m$message\x1B[0m');

  void _success(String message) => print('\x1B[32m$message\x1B[0m');

  void _error(String message) => print('\x1B[31m$message\x1B[0m');
}
