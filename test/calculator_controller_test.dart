import 'package:flutter_test/flutter_test.dart';
import 'package:luma_calc/core/app_storage.dart';
import 'package:luma_calc/core/calculator_controller.dart';
import 'package:luma_calc/core/calculator_engine.dart';

class MemoryStorage implements AppStorage {
  Map<String, Object?> state = {};

  @override
  Future<Map<String, Object?>> read() async => state;

  @override
  Future<void> write(Map<String, Object?> state) async => this.state = state;
}

void main() {
  late MemoryStorage storage;
  late CalculatorController calc;

  setUp(() {
    storage = MemoryStorage();
    calc = CalculatorController(storage);
  });

  tearDown(() => calc.dispose());

  test('decimal point and leading zero entry', () {
    calc.digit('.');
    calc.digit('5');
    calc.digit('.');
    expect(calc.expression, '0.5');
    calc.clear();
    calc.digit('0');
    calc.digit('0');
    calc.digit('7');
    expect(calc.expression, '7');
  });

  test('new digits replace results while operators continue', () {
    calc.replaceExpression('2+3');
    expect(calc.calculate(), isTrue);
    calc.operator('×');
    calc.digit('4');
    calc.calculate();
    expect(calc.answer, 20);
    calc.digit('7');
    expect(calc.expression, '7');
  });

  test('operators can be corrected and negative operands work', () {
    calc.digit('5');
    calc.operator('+');
    calc.operator('×');
    calc.operator('−');
    calc.digit('2');
    calc.calculate();
    expect(calc.answer, -10);
  });

  test('open functions close on equals and delete is token aware', () {
    calc.function('sin');
    calc.digit('3');
    calc.digit('0');
    expect(calc.calculate(), isTrue);
    expect(calc.answer, closeTo(.5, 1e-12));
    calc.clear();
    calc.function('sqrt');
    calc.erase();
    expect(calc.expression, isEmpty);
  });

  test('constants multiply digits and decimal entry', () {
    calc.constant('e');
    calc.digit('.');
    calc.digit('5');
    expect(calc.expression, 'e×0.5');
    calc.clear();
    calc.digit('2');
    calc.constant('π');
    expect(calc.expression, '2×π');
  });

  test('history resolves Ans and restores the original angle', () {
    calc.replaceExpression('4');
    calc.calculate();
    calc.replaceExpression('Ans+2');
    calc.calculate();
    final entry = calc.history.first;
    expect(entry.expression, '(4.0)+2');
    calc.toggleAngle();
    calc.reuse(entry);
    expect(calc.angleUnit, AngleUnit.degrees);
    calc.calculate();
    expect(calc.answer, 6);
  });

  test('memory addition subtraction recall and clear', () {
    calc.replaceExpression('10');
    calc.memoryAction('M+');
    calc.replaceExpression('3');
    calc.memoryAction('M−');
    expect(calc.memory, 7);
    calc.clear();
    calc.memoryAction('MR');
    calc.calculate();
    expect(calc.answer, 7);
    calc.memoryAction('MC');
    expect(calc.hasMemory, isFalse);
  });

  test('state survives a new controller', () async {
    calc.toggleTheme();
    calc.toggleAngle();
    calc.toggleScientific();
    calc.replaceExpression('7*8');
    calc.calculate();
    calc.memoryAction('M+');
    await calc.persist();
    final restored = CalculatorController(storage);
    await restored.restore();
    expect(restored.answer, 56);
    expect(restored.memory, 56);
    expect(restored.dark, isFalse);
    expect(restored.scientific, isTrue);
    expect(restored.angleUnit, AngleUnit.radians);
    expect(restored.history.length, 1);
    restored.dispose();
  });

  test('errors preserve input for correction', () {
    calc.replaceExpression('10/0');
    expect(calc.calculate(), isFalse);
    expect(calc.expression, '10÷0');
    expect(calc.error, isNotNull);
    calc.erase();
    calc.digit('2');
    calc.calculate();
    expect(calc.answer, 5);
    expect(calc.error, isNull);
  });

  test('history is capped and malformed stored entries are ignored', () async {
    for (var i = 0; i < 110; i++) {
      calc.replaceExpression('$i+1');
      calc.calculate();
    }
    expect(calc.history.length, 100);
    storage.state = {
      'history': [
        {'expression': '1', 'value': 'bad'},
        null,
        1,
      ],
    };
    final restored = CalculatorController(storage);
    await restored.restore();
    expect(restored.history, isEmpty);
    restored.dispose();
  });

  test('transforms preserve the current expression', () {
    calc.replaceExpression('2+3');
    calc.transform('square');
    calc.calculate();
    expect(calc.answer, 25);
    calc.transform('reciprocal');
    calc.calculate();
    expect(calc.answer, .04);
  });
}
