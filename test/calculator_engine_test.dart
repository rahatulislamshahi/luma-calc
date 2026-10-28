import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:luma_calc/core/calculator_engine.dart';

void main() {
  const engine = CalculatorEngine();

  final examples = <String, double>{
    '2+3*4': 14,
    '(2+3)*4': 20,
    '12÷3×2': 8,
    '10−3−2': 5,
    '2^3^2': 512,
    '-2^2': -4,
    '(-2)^2': 4,
    '2^-2': .25,
    '5*-2': -10,
    '2(3+4)': 14,
    '(2+1)(4-1)': 9,
    '2π': math.pi * 2,
    '2e': math.e * 2,
    '.5+.25': .75,
    '1e-7*1E7': 1,
    '0.1+0.2': .3,
    '50%': .5,
    '200+10%': 220,
    '200-10%': 180,
    '200*10%': 20,
    '200/10%': 2000,
    '200+10%+10%': 242,
    '200+(10%)': 220,
    '200+-10%': 180,
    '0!': 1,
    '5!': 120,
    '3!^2': 36,
    'sqrt(81)': 9,
    '√(64)': 8,
    'cbrt(-27)': -3,
    'abs(-9)': 9,
    'sin(30)': .5,
    'cos(60)': .5,
    'sin(180)': 0,
    'cos(90)': 0,
    'tan(45)': 1,
    'asin(0.5)': 30,
    'acos(0.5)': 60,
    'atan(1)': 45,
    'ln(e)': 1,
    'log(1000)': 3,
    'powten(3)': 1000,
    'exp(0)': 1,
    'sin(30)cos(60)': .25,
    ' 2 + 3 ': 5,
  };

  for (final entry in examples.entries) {
    test(entry.key, () {
      expect(
        engine.evaluate(entry.key),
        closeTo(entry.value, math.max(1e-12, entry.value.abs() * 1e-12)),
      );
    });
  }

  for (final input in [
    '',
    '2+',
    '1/0',
    '0^-1',
    '(-2)^0.5',
    'sqrt(-1)',
    'ln(0)',
    'log(-1)',
    'asin(2)',
    'acos(-2)',
    'tan(90)',
    'tan(270)',
    '171!',
    '(-1)!',
    '2.5!',
    '2..3',
    '1.2.3',
    'sin30',
    'unknown(2)',
    '(2+3',
    '2+3)',
    '2^^3',
    '1e999',
  ]) {
    test('rejects $input', () {
      expect(
        () => engine.evaluate(input),
        throwsA(isA<CalculationException>()),
      );
    });
  }

  test('radian functions and inverse functions', () {
    expect(
      engine.evaluate('sin(π/2)', angleUnit: AngleUnit.radians),
      closeTo(1, 1e-12),
    );
    expect(
      engine.evaluate('asin(1)', angleUnit: AngleUnit.radians),
      closeTo(math.pi / 2, 1e-12),
    );
  });

  test('tiny and near right angles retain valid values', () {
    expect(engine.evaluate('sin(1e-14)'), greaterThan(0));
    expect(engine.evaluate('tan(89.9999999999999)').isFinite, isTrue);
  });

  test('previous answer keeps its numeric value', () {
    expect(engine.evaluate('Ans*3', answer: 4), 12);
    expect(engine.evaluate('Ans^2', answer: -2), 4);
  });

  test('factorial and scientific ranges remain finite', () {
    expect(engine.evaluate('170!').isFinite, isTrue);
    expect(engine.evaluate('1e-300'), 1e-300);
    expect(
      () => engine.evaluate('1e308*10'),
      throwsA(isA<CalculationException>()),
    );
  });

  test('display formatting removes floating point noise', () {
    expect(CalculatorEngine.format(.1 + .2), '0.3');
    expect(CalculatorEngine.format(-0.0), '0');
    expect(CalculatorEngine.format(42), '42');
    expect(CalculatorEngine.format(1e15), '1e15');
    expect(CalculatorEngine.format(1e-12), '1e-12');
  });

  test('oversized and deeply nested inputs are bounded', () {
    expect(
      () => engine.evaluate('${'1+' * 512}1'),
      throwsA(isA<CalculationException>()),
    );
    expect(
      () => engine.evaluate('${'(' * 70}1${')' * 70}'),
      throwsA(isA<CalculationException>()),
    );
  });
}
