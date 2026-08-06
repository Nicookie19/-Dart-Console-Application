import 'dart:io';

import 'package:riverpod/riverpod.dart';

import 'controllers/model_controller.dart';
import 'models/llm_model.dart';
import 'providers/providers.dart';
import 'services/model_service.dart';

/// Interactive console front-end for the LLM Model Manager.
///
/// The UI layer only talks to Riverpod (via a [ProviderContainer]); it never
/// creates services or controllers directly.
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
          _addModel();
        case '2':
          _listModels(_modelState);
        case '3':
          _filterModels();
        case '4':
          _search();
        case '5':
          _viewDetails();
        case '6':
          _editModel();
        case '7':
          _deleteModel();
        case '8':
          _compareModels();
        case '9':
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

  // --------------------------------------------------------------- add/list

  void _addModel() {
    final name = _readLine('Model id (e.g. gpt-4o): ').trim();
    if (name.isEmpty) return _error('Model id cannot be empty.');
    final displayName = _readLine('Display name (optional): ').trim();
    final provider = _readText(
        'Provider (e.g. OpenAI, Anthropic, Google, Meta, Mistral, Local, Other): ',
        defaultTo: 'OpenAI');
    final contextWindow = _readInt('Context window (tokens, e.g. 128000): ',
        minValue: 1, defaultTo: 128000);
    final maxOutput = _readInt('Max output tokens (e.g. 4096): ',
        minValue: 1, defaultTo: 4096);
    final inputCost =
        _readDouble('Input cost per 1M tokens (USD, e.g. 2.50): ', minValue: 0);
    final outputCost =
        _readDouble('Output cost per 1M tokens (USD): ', minValue: 0);
    final capabilities = _parseCapabilities(
        _readLine('Capabilities (comma-separated, optional, e.g. Vision, Reasoning): '));
    final status = _readText(
        'Status (e.g. Available, Preview, Deprecated, Private): ',
        defaultTo: 'Available');
    _info('Description (finish with a line containing only "."):');
    final description = _readMultiline();

    try {
      final model = _modelController.addModel(
        name: name,
        displayName: displayName.isEmpty ? null : displayName,
        provider: provider,
        contextWindow: contextWindow,
        maxOutputTokens: maxOutput,
        inputCostPerMillion: inputCost,
        outputCostPerMillion: outputCost,
        capabilities: capabilities,
        status: status,
        description: description,
      );
      _success('Model "$model" added.');
    } on ArgumentError catch (e) {
      _error(e.message ?? 'Invalid model.');
    }
  }

  void _listModels(List<LlmModel> models) {
    if (models.isEmpty) return _info('No models in the catalog yet. Add one from the menu.');
    _success('${models.length} model(s):');
    _printModels(models);
  }

  void _filterModels() {
    print('''
FILTER BY
  1. Provider
  2. Status
  3. Capability
  0. Back''');
    switch (_readLine('> ').trim()) {
      case '1':
        final provider = _readText('Provider: ');
        _listModels(_service.byProvider(provider));
      case '2':
        final status = _readText('Status: ');
        _listModels(_service.byStatus(status));
      case '3':
        final capability = _readText('Capability: ');
        _listModels(_service.byCapability(capability));
      case '0':
        return;
      default:
        _error('Unknown option.');
    }
  }

  void _search() {
    final query = _readLine('Search: ').trim();
    final results = _service.search(query);
    if (results.isEmpty) return _info('No models match "$query".');
    _listModels(results);
  }

  // ---------------------------------------------------------------- details

  void _viewDetails() {
    final model = _selectModel();
    if (model == null) return;
    _printModel(model);
  }

  void _editModel() {
    final model = _selectModel();
    if (model == null) return;

    var editing = true;
    while (editing) {
      print('\nEDIT "${model.label}"');
      print('  1. Rename');
      print('  2. Display name');
      print('  3. Provider');
      print('  4. Context window');
      print('  5. Max output tokens');
      print('  6. Costs (input/output per 1M)');
      print('  7. Capabilities');
      print('  8. Status');
      print('  9. Description');
      print('  0. Back');
      switch (_readLine('> ').trim()) {
        case '1':
          final name = _readLine('New name: ').trim();
          name.isEmpty
              ? _error('Name cannot be empty.')
              : _apply(() => _modelController.rename(model.id, name));
        case '2':
          final display = _readLine('New display name (empty to clear): ').trim();
          _apply(() => _modelController
              .update(model.id, (m) => m.changeDisplayName(display.isEmpty ? null : display)));
        case '3':
          final provider = _readText('New provider: ');
          _apply(() =>
              _modelController.update(model.id, (m) => m.changeProvider(provider)));
        case '4':
          final value = _readInt('New context window: ', minValue: 1);
          _apply(() => _modelController
              .update(model.id, (m) => m.changeContextWindow(value)));
        case '5':
          final value = _readInt('New max output tokens: ', minValue: 1);
          _apply(() =>
              _modelController.update(model.id, (m) => m.changeMaxOutput(value)));
        case '6':
          final input = _readDouble('New input cost per 1M: ', minValue: 0);
          final output = _readDouble('New output cost per 1M: ', minValue: 0);
          _apply(() => _modelController
              .update(model.id, (m) => m.changeCosts(input: input, output: output)));
        case '7':
          final caps =
              _parseCapabilities(_readLine('New capabilities (comma-separated): '));
          _apply(() => _modelController
              .update(model.id, (m) => m.changeCapabilities(caps)));
        case '8':
          final status = _readText('New status: ');
          _apply(() =>
              _modelController.update(model.id, (m) => m.changeStatus(status)));
        case '9':
          _info('New description (".", empty, to keep):');
          final description = _readMultiline();
          if (description == model.description && description.isNotEmpty == false) {
            break;
          }
          _apply(() => _modelController
              .update(model.id, (m) => m.changeDescription(description)));
        case '0':
          editing = false;
        default:
          _error('Unknown option.');
      }
    }
  }

  void _deleteModel() {
    final model = _selectModel();
    if (model == null) return;

    final confirm =
        _readLine('Delete "${model.label}"? (y/N): ').trim().toLowerCase();
    if (confirm != 'y' && confirm != 'yes') return _info('Deletion cancelled.');

    _modelController.delete(model.id)
        ? _success('"${model.label}" deleted.')
        : _error('Delete failed.');
  }

  void _compareModels() {
    final a = _selectModel(prompt: 'first model');
    if (a == null) return;
    final b = _selectModel(prompt: 'second model');
    if (b == null) return;

    final w1 = a.label.length > b.label.length ? a.label.length : b.label.length;
    final w2 = 6;
    String cell(String header, String va, String vb) {
      final h = header.padRight(w1 + w2 + 4);
      return '  $h| $va | $vb';
    }

    print('\n  ${'Field'.padRight(w1 + w2 + 4)}| ${a.label.padRight(w1)} | $b');
    print('  ${'-' * (w1 + w2 + 4 + w1 + 7)}');
    print(cell('provider', a.provider, b.provider));
    print(cell('context', _fmtInt(a.contextWindow), _fmtInt(b.contextWindow)));
    print(cell('max out', _fmtInt(a.maxOutputTokens), _fmtInt(b.maxOutputTokens)));
    print(cell('cost/1M in/out', _fmtCost(a), _fmtCost(b)));
    print(cell('10k tokens', '\$${a.costForTokens(10000).toStringAsFixed(3)}',
        '\$${b.costForTokens(10000).toStringAsFixed(3)}'));
    print(cell('caps', a.capabilities.isEmpty ? '-' : a.capabilities.length.toString(),
        b.capabilities.isEmpty ? '-' : b.capabilities.length.toString()));
    print(cell('status', a.status, b.status));
  }

  // --------------------------------------------------------------- dashboard

  void _dashboard() {
    final models = _modelState;
    final avgCtx = models.isEmpty
        ? 0
        : models.fold<int>(0, (s, m) => s + m.contextWindow) ~/ models.length;

    final width = 46;
    _divider(width);
    _center('DASHBOARD', width);
    _center('models: ${models.length}', width);
    final byProvider = <String, int>{};
    for (final model in models) {
      byProvider[model.provider] = (byProvider[model.provider] ?? 0) + 1;
    }
    for (final entry in byProvider.entries) {
      _center('  ${entry.key}: ${entry.value}', width);
    }
    _center('average context: ${_fmtInt(avgCtx)} tokens', width);
    _divider(width);

    if (models.isEmpty) {
      _info('Nothing to show yet. Add a model from the main menu.');
      return;
    }

    final cheapest = _service.sortedByCost().first;
    final widest =
        models.reduce((a, b) => a.contextWindow > b.contextWindow ? a : b);
    _info('Cheapest to run 10k tokens: ${cheapest.label} '
        '(\$${cheapest.costForTokens(10000).toStringAsFixed(3)})');
    _info('Widest context window: ${widest.label} '
        '(${_fmtInt(widest.contextWindow)} tokens)');
  }

  // ------------------------------------------------------------------ helpers

  ModelController get _modelController =>
      _container.read(modelControllerProvider.notifier);

  List<LlmModel> get _modelState => _container.read(modelControllerProvider);

  ModelService get _service => _container.read(modelServiceProvider);

  void _apply(bool Function() action) {
    action() ? _success('Updated.') : _error('Update failed.');
  }

  String _fmtInt(int value) => value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  String _fmtCost(LlmModel model) =>
      '\$${model.inputCostPerMillion.toStringAsFixed(2)} / '
      '\$${model.outputCostPerMillion.toStringAsFixed(2)}';

  LlmModel? _selectModel({String prompt = 'a model'}) {
    final models = _modelState;
    if (models.isEmpty) {
      _info('No models in the catalog yet.');
      return null;
    }
    _info('Choose $prompt:');
    for (var i = 0; i < models.length; i++) {
      final m = models[i];
      print('  ${i + 1}. $m (${_fmtInt(m.contextWindow)} ctx, ${_fmtCost(m)})');
    }
    final raw = _readLine('Number (or 0 to cancel): ').trim();
    final index = int.tryParse(raw);
    if (index == null || index < 0 || index > models.length) {
      _error('Invalid number.');
      return null;
    }
    return index == 0 ? null : models[index - 1];
  }

  void _printModels(List<LlmModel> models) {
    for (final model in models) {
      print('  ${model.provider}: ${model.label} '
          '(${_fmtInt(model.contextWindow)} ctx, ${_fmtCost(model)}) - ${model.status}');
    }
  }

  void _printModel(LlmModel model) {
    print('\n[${model.provider}] ${model.label} (${model.status})');
    if (model.displayName != null) _info('model id: ${model.name}');
    print('  context window : ${_fmtInt(model.contextWindow)} tokens');
    print('  max output     : ${_fmtInt(model.maxOutputTokens)} tokens');
    print('  cost / 1M in   : \$${model.inputCostPerMillion.toStringAsFixed(2)}');
    print('  cost / 1M out   : \$${model.outputCostPerMillion.toStringAsFixed(2)}');
    print('  10k round trip  : \$${model.costForTokens(10000).toStringAsFixed(2)}');
    if (model.capabilities.isNotEmpty) {
      print('  capabilities   : ${model.capabilities.join(', ')}');
    }
    if (model.description.isNotEmpty) {
      _info('Description:');
      print(model.description);
    }
  }

  /// Reads a free-form text value. No validation: anything the user types is
  /// accepted. Falls back to [defaultTo] on empty input.
  String _readText(String prompt, {String defaultTo = ''}) {
    final raw = _readLine(prompt).trim();
    return raw.isEmpty && defaultTo.isNotEmpty ? defaultTo : raw;
  }

  /// Splits free-form capability text into unique, trimmed labels.
  Set<String> _parseCapabilities(String raw) {
    final seen = <String>{};
    for (final part in raw.split(RegExp(r'[,;\s]+'))) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty) seen.add(trimmed);
    }
    return seen;
  }

  int _readInt(String prompt, {int? minValue, int defaultTo = -1}) {
    while (true) {
      final raw = _readLine(prompt).trim();
      if (raw.isEmpty && defaultTo > 0) return defaultTo;
      final value = int.tryParse(raw);
      if (value == null || (minValue != null && value < minValue)) {
        _error('Enter a valid number${minValue == null ? '' : ' (>= $minValue)'}.');
        continue;
      }
      return value;
    }
  }

  double _readDouble(String prompt, {double? minValue}) {
    while (true) {
      final raw = _readLine(prompt).trim();
      final value = double.tryParse(raw);
      if (value == null || (minValue != null && value < minValue)) {
        _error('Enter a valid number${minValue == null ? '' : ' (>= $minValue)'}.');
        continue;
      }
      return value;
    }
  }

  String _readMultiline() {
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
    _divider(46);
    _center('LLM MODEL MANAGER', 46);
    _center('Dart + Riverpod (DI) demo', 46);
    _center('Models / Services / Controllers', 46);
    _divider(46);
  }

  void _printMenu() {
    print('''
MAIN MENU
  1. Add model
  2. List all models
  3. Filter models
  4. Search models
  5. View model details
  6. Edit model
  7. Delete model
  8. Compare models
  9. Dashboard
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