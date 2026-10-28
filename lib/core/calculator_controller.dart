import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'app_storage.dart';
import 'calculator_engine.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.expression,
    required this.value,
    required this.angleUnit,
    required this.createdAt,
  });

  final String expression;
  final double value;
  final AngleUnit angleUnit;
  final DateTime createdAt;

  String get result => CalculatorEngine.format(value);

  Map<String, Object?> toJson() => {
    'expression': expression,
    'value': value,
    'angle': angleUnit.name,
    'date': createdAt.toUtc().toIso8601String(),
  };

  static HistoryEntry? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final expression = value['expression'];
    final number = value['value'];
    final date = value['date'];
    if (expression is! String ||
        expression.length > 1024 ||
        number is! num ||
        date is! String) {
      return null;
    }
    final createdAt = DateTime.tryParse(date);
    if (!number.toDouble().isFinite || createdAt == null) return null;
    return HistoryEntry(
      expression: expression,
      value: number.toDouble(),
      angleUnit: value['angle'] == 'radians'
          ? AngleUnit.radians
          : AngleUnit.degrees,
      createdAt: createdAt,
    );
  }
}

class CalculatorController extends ChangeNotifier {
  CalculatorController(this.storage);

  static const maxExpressionLength = 480;

  final AppStorage storage;
  String _acceptedExpression = '';
  final CalculatorEngine engine = const CalculatorEngine();
  String expression = '';
  String lastExpression = '';
  String? error;
  double answer = 0;
  double memory = 0;
  bool hasMemory = false;
  bool justEvaluated = false;
  bool scientific = false;
  bool inverse = false;
  bool dark = true;
  bool haptics = true;
  bool storageAvailable = true;
  AngleUnit angleUnit = AngleUnit.degrees;
  final List<HistoryEntry> _history = [];
  Timer? _saveTimer;
  Future<void> _writes = Future<void>.value();

  List<HistoryEntry> get history => List.unmodifiable(_history);

  String get displayExpression => justEvaluated ? lastExpression : expression;

  String get displayValue {
    if (justEvaluated) return CalculatorEngine.format(answer);
    if (expression.isEmpty) return '0';
    final value = preview;
    return value == null ? '' : CalculatorEngine.format(value);
  }

  double? get preview {
    if (expression.isEmpty) return null;
    try {
      return engine.evaluate(
        _closedExpression,
        angleUnit: angleUnit,
        answer: answer,
      );
    } on CalculationException {
      return null;
    }
  }

  String get _closedExpression {
    final opens = '('.allMatches(expression).length;
    final closes = ')'.allMatches(expression).length;
    return expression + ')' * math.max(0, opens - closes);
  }

  Future<void> restore() async {
    final state = await storage.read();
    dark = state['dark'] != false;
    haptics = state['haptics'] != false;
    scientific = state['scientific'] == true;
    angleUnit = state['angle'] == 'radians'
        ? AngleUnit.radians
        : AngleUnit.degrees;
    final savedAnswer = state['answer'];
    final savedMemory = state['memory'];
    if (savedAnswer is num && savedAnswer.toDouble().isFinite)
      answer = savedAnswer.toDouble();
    if (savedMemory is num && savedMemory.toDouble().isFinite)
      memory = savedMemory.toDouble();
    hasMemory = state['hasMemory'] == true;
    final savedExpression = state['expression'];
    if (savedExpression is String &&
        savedExpression.length <= maxExpressionLength) {
      expression = CalculatorEngine.normalize(savedExpression);
      _acceptedExpression = expression;
    }
    final savedLast = state['lastExpression'];
    if (savedLast is String && savedLast.length <= 512)
      lastExpression = savedLast;
    justEvaluated = state['justEvaluated'] == true;
    _history.clear();
    final entries = state['history'];
    if (entries is List) {
      for (final item in entries.take(100)) {
        final entry = HistoryEntry.fromJson(item);
        if (entry != null) _history.add(entry);
      }
    }
    notifyListeners();
  }

  void digit(String digit) {
    _startFresh();
    if (expression.length >= 480) return;
    final number = _endsNonNumberValue
        ? ''
        : RegExp(
            r'(?:\d*\.?\d*(?:[eE][+-]?\d*)?)$',
          ).firstMatch(expression)!.group(0)!;
    if (digit == '.') {
      if (number.contains('.') || number.contains(RegExp('[eE]'))) return;
      if (number.isEmpty) {
        if (_endsValue) expression += '×';
        expression += '0';
      }
    } else if (_endsNonNumberValue) {
      expression += '×';
    } else if (number == '0') {
      expression = expression.substring(0, expression.length - 1);
    }
    expression += digit;
    _changed();
  }

  void operator(String symbol) {
    symbol = switch (symbol) {
      '-' => '−',
      '*' => '×',
      '/' => '÷',
      _ => symbol,
    };
    error = null;
    if (justEvaluated) {
      expression = answer < 0
          ? '(${CalculatorEngine.literal(answer)})'
          : CalculatorEngine.literal(answer);
      justEvaluated = false;
    }
    if (expression.isEmpty || expression.endsWith('(')) {
      if (symbol == '−') expression += '-';
      _changed();
      return;
    }
    if (RegExp(r'[+×÷^−-]$').hasMatch(expression)) {
      if (symbol == '−' && !RegExp(r'[−-]$').hasMatch(expression)) {
        expression += '-';
      } else {
        expression = expression.replaceFirst(RegExp(r'[+×÷^−-]+$'), symbol);
      }
    } else {
      expression += symbol;
    }
    _changed();
  }

  void constant(String value) {
    _startFresh();
    if (_endsValue) expression += '×';
    expression += value;
    _changed();
  }

  void function(String name) {
    error = null;
    if (justEvaluated) {
      expression = '$name(${CalculatorEngine.literal(answer)})';
      justEvaluated = false;
    } else {
      if (_endsValue) {
        final start = _operandStart();
        expression =
            '${expression.substring(0, start)}$name(${expression.substring(start)})';
      } else {
        expression += '$name(';
      }
    }
    _changed();
  }

  void parenthesis(bool opening) {
    error = null;
    if (opening) {
      _startFresh();
      if (_endsValue) expression += '×';
      expression += '(';
    } else {
      if (justEvaluated || !_endsValue) return;
      if ('('.allMatches(expression).length <=
          ')'.allMatches(expression).length)
        return;
      expression += ')';
    }
    _changed();
  }

  void postfix(String value) {
    error = null;
    _continueResult();
    if (!_endsValue) return;
    if (value == '%' && expression.endsWith('%')) return;
    if (value == '!' && expression.endsWith('!')) return;
    expression += value;
    _changed();
  }

  void transform(String operation) {
    error = null;
    _continueResult();
    if (expression.isEmpty || preview == null) return;
    final closed = _closedExpression;
    switch (operation) {
      case 'square':
        expression = '($closed)^2';
      case 'cube':
        expression = '($closed)^3';
      case 'reciprocal':
        expression = '1/($closed)';
      case 'abs':
        expression = 'abs($closed)';
      case 'negate':
        if (expression.startsWith('-(') && expression.endsWith(')')) {
          expression = expression.substring(2, expression.length - 1);
        } else {
          expression = '-($closed)';
        }
    }
    _changed();
  }

  int _operandStart() {
    var end = expression.length;
    while (end > 0 && '!%'.contains(expression[end - 1])) {
      end--;
    }
    var start = end;
    if (end > 0 && expression[end - 1] == ')') {
      var depth = 1;
      start = end - 1;
      while (start > 0 && depth > 0) {
        start--;
        if (expression[start] == ')') depth++;
        if (expression[start] == '(') depth--;
      }
      while (start > 0 && RegExp(r'[a-zA-Z]').hasMatch(expression[start - 1])) {
        start--;
      }
    } else {
      final token = RegExp(
        r'(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$|Ans$|[πe]$',
      ).firstMatch(expression.substring(0, end));
      if (token != null) start = token.start;
    }
    if (start > 0 &&
        expression[start - 1] == '-' &&
        (start == 1 || '(+×÷^−-'.contains(expression[start - 2]))) {
      start--;
    }
    return start;
  }

  void negate() {
    error = null;
    _continueResult();
    if (!_endsValue) {
      if (expression.endsWith('-')) {
        expression = expression.substring(0, expression.length - 1);
      } else {
        expression += '-';
      }
    } else {
      final start = _operandStart();
      final operand = expression.substring(start);
      expression =
          expression.substring(0, start) +
          (operand.startsWith('-') ? operand.substring(1) : '-$operand');
    }
    _changed();
  }

  void erase() {
    error = null;
    if (justEvaluated) {
      expression = CalculatorEngine.format(answer);
      justEvaluated = false;
    }
    if (expression.isEmpty) return;
    final function = RegExp(r'[a-zA-Z]+\($').firstMatch(expression);
    if (function != null) {
      expression = expression.substring(0, function.start);
    } else if (expression.endsWith('Ans')) {
      expression = expression.substring(0, expression.length - 3);
    } else {
      expression = expression.substring(0, expression.length - 1);
    }
    _changed();
  }

  void clear() {
    expression = '';
    lastExpression = '';
    justEvaluated = false;
    error = null;
    _changed();
  }

  bool calculate() {
    if (expression.isEmpty || justEvaluated) return false;
    try {
      final input = _closedExpression;
      final result = engine.evaluate(
        input,
        angleUnit: angleUnit,
        answer: answer,
      );
      final resolved = input.replaceAll(
        RegExp('ans', caseSensitive: false),
        '(${CalculatorEngine.literal(answer)})',
      );
      if (_history.isEmpty ||
          _history.first.expression != resolved ||
          _history.first.value != result ||
          _history.first.angleUnit != angleUnit) {
        _history.insert(
          0,
          HistoryEntry(
            expression: resolved,
            value: result,
            angleUnit: angleUnit,
            createdAt: DateTime.now(),
          ),
        );
        if (_history.length > 100) _history.removeLast();
      }
      lastExpression = resolved;
      answer = result;
      expression = CalculatorEngine.literal(result);
      justEvaluated = true;
      error = null;
      _changed();
      return true;
    } on CalculationException catch (exception) {
      error = exception.message;
      _changed();
      return false;
    }
  }

  void replaceExpression(String value) {
    final normalized = CalculatorEngine.normalize(value);
    if (normalized.length > 480) {
      error = 'Keep the expression under 480 characters.';
    } else {
      expression = normalized;
      justEvaluated = false;
      error = null;
    }
    _changed();
  }

  void reuse(HistoryEntry entry) {
    expression = entry.expression;
    angleUnit = entry.angleUnit;
    justEvaluated = false;
    error = null;
    _changed();
  }

  void useResult(HistoryEntry entry) {
    _startFresh();
    if (_endsValue) expression += '×';
    expression += '(${CalculatorEngine.literal(entry.value)})';
    _changed();
  }

  void memoryAction(String action) {
    error = null;
    if (action == 'MC') {
      memory = 0;
      hasMemory = false;
    } else if (action == 'MR') {
      if (!hasMemory) return;
      _startFresh();
      if (_endsValue) expression += '×';
      expression += '(${CalculatorEngine.literal(memory)})';
    } else {
      final value = justEvaluated ? answer : preview;
      if (value == null) {
        error = 'Enter a valid number before using memory.';
      } else {
        final result = memory + (action == 'M−' ? -value : value);
        if (result.isFinite) {
          memory = result;
          hasMemory = true;
        } else {
          error = 'Memory is outside the number range.';
        }
      }
    }
    _changed();
  }

  void clearHistory() {
    _history.clear();
    _changed();
  }

  void toggleScientific() {
    scientific = !scientific;
    _changed();
  }

  void toggleAngle() {
    angleUnit = angleUnit == AngleUnit.degrees
        ? AngleUnit.radians
        : AngleUnit.degrees;
    error = null;
    _changed();
  }

  void toggleInverse() {
    inverse = !inverse;
    _changed();
  }

  void toggleTheme() {
    dark = !dark;
    _changed();
  }

  void toggleHaptics() {
    haptics = !haptics;
    _changed();
  }

  bool get _endsNonNumberValue =>
      RegExp(r'(?:[πe)!%]|Ans)$').hasMatch(expression);
  bool get _endsValue => RegExp(r'(?:[0-9.πe)!%]|Ans)$').hasMatch(expression);

  void _startFresh() {
    error = null;
    if (justEvaluated) {
      expression = '';
      lastExpression = '';
      justEvaluated = false;
    }
  }

  void _continueResult() {
    if (!justEvaluated) return;
    expression = '(${CalculatorEngine.literal(answer)})';
    justEvaluated = false;
  }

  void _changed() {
    if (expression.length > maxExpressionLength) {
      expression = _acceptedExpression;
      error = 'Keep the expression under 480 characters.';
    } else {
      _acceptedExpression = expression;
    }
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 250),
      () => unawaited(persist()),
    );
  }

  Future<void> persist() {
    _saveTimer?.cancel();
    final state = <String, Object?>{
      'dark': dark,
      'haptics': haptics,
      'scientific': scientific,
      'angle': angleUnit.name,
      'answer': answer,
      'memory': memory,
      'hasMemory': hasMemory,
      'expression': expression,
      'lastExpression': lastExpression,
      'justEvaluated': justEvaluated,
      'history': _history.map((entry) => entry.toJson()).toList(),
    };
    _writes = _writes.then((_) async {
      try {
        await storage.write(state);
        storageAvailable = true;
      } on Object {
        storageAvailable = false;
      }
    });
    return _writes;
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
