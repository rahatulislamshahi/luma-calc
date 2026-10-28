import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:luma_calc/core/calculator_controller.dart';
import 'package:luma_calc/core/calculator_engine.dart';

import 'calculator_controller_test.dart' show MemoryStorage;

void main() {
  const engine = CalculatorEngine();
  late CalculatorController calc;
  setUp(() => calc = CalculatorController(MemoryStorage()));
  tearDown(() => calc.dispose());

  test('sign toggle before and during number entry', () {
    calc.negate();
    calc.negate();
    expect(calc.expression, '');
    calc.digit('5');
    calc.operator('+');
    calc.negate();
    calc.digit('2');
    calc.digit('3');
    expect(calc.preview, -18);
    calc.negate();
    expect(calc.preview, 28);
  });

  test('function wraps the last operand', () {
    calc.replaceExpression('2+30');
    calc.function('sin');
    expect(calc.preview, closeTo(2.5, 1e-12));
    calc.replaceExpression('2+sqrt(9)');
    calc.function('log');
    expect(calc.preview, closeTo(2 + math.log(3) / math.ln10, 1e-12));
  });

  test('pasted operators can be replaced with keypad operators', () {
    calc.replaceExpression('8/');
    calc.operator('*');
    calc.digit('2');
    expect(calc.preview, 16);
  });

  test('grouped thousands work and decimal commas are rejected', () {
    calc.replaceExpression('1,234.5+2');
    expect(calc.preview, 1236.5);
    calc.replaceExpression('1,5');
    expect(calc.calculate(), isFalse);
    expect(engine.evaluate('1,000,000'), 1000000);
    expect(
      () => engine.evaluate('12,34'),
      throwsA(isA<CalculationException>()),
    );
  });

  test('adjacent bare numbers require an operator', () {
    expect(() => engine.evaluate('2 3'), throwsA(isA<CalculationException>()));
    expect(engine.evaluate('2(3)'), 6);
    expect(engine.evaluate('(2)3'), 6);
  });

  test('angle reduction preserves tiny negative angles', () {
    expect(engine.evaluate('tan(180)'), 0);
    expect(engine.evaluate('sin(-0.000000000000001)'), lessThan(0));
    expect(engine.evaluate('cos(360000000000)'), 1);
  });

  test('factorial accepts floating point integer roundoff', () {
    expect(engine.evaluate('log(1000)!'), 6);
    expect(
      () => engine.evaluate('3.000000000001!'),
      throwsA(isA<CalculationException>()),
    );
  });

  test('normalization handles uppercase names and pasted roots', () {
    expect(engine.evaluate('SIN(30)+PI'), closeTo(.5 + math.pi, 1e-12));
    expect(engine.evaluate('√(9)+∛(8)'), closeTo(5, 1e-12));
  });

  test('restore does not duplicate history', () async {
    calc.replaceExpression('1+2');
    calc.calculate();
    await calc.persist();
    await calc.restore();
    await calc.restore();
    expect(calc.history.length, 1);
  });

  test('expression edits retain the resolved original calculation', () {
    calc.replaceExpression('4');
    calc.calculate();
    calc.replaceExpression('Ans+2');
    calc.calculate();
    expect(calc.displayExpression, '(4.0)+2');
  });

  test('long input is rejected without changing its meaning', () {
    calc.replaceExpression('2+3');
    calc.replaceExpression('1' * 481);
    expect(calc.expression, '2+3');
    expect(calc.error, isNotNull);
  });
}
