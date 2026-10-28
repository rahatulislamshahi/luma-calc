import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma_calc/core/calculator_controller.dart';
import 'package:luma_calc/core/calculator_engine.dart';
import 'package:luma_calc/main.dart';

import 'calculator_controller_test.dart' show MemoryStorage;

void main() {
  final cases = <(String, String, double, bool, AngleUnit)>[
    ('sin', '30', .5, false, AngleUnit.degrees),
    ('cos', '60', .5, false, AngleUnit.degrees),
    ('tan', '45', 1, false, AngleUnit.degrees),
    ('sin⁻¹', '0.5', 30, true, AngleUnit.degrees),
    ('cos⁻¹', '0.5', 60, true, AngleUnit.degrees),
    ('tan⁻¹', '1', 45, true, AngleUnit.degrees),
    ('sin', '(π/2)', 1, false, AngleUnit.radians),
    ('cos', 'π', -1, false, AngleUnit.radians),
    ('tan', '(π/4)', 1, false, AngleUnit.radians),
    ('sin⁻¹', '1', math.pi / 2, true, AngleUnit.radians),
    ('cos⁻¹', '0', math.pi / 2, true, AngleUnit.radians),
    ('tan⁻¹', '1', math.pi / 4, true, AngleUnit.radians),
    ('ln', 'e', 1, false, AngleUnit.degrees),
    ('log', '1000', 3, false, AngleUnit.degrees),
    ('eˣ', '2', math.exp(2), true, AngleUnit.degrees),
    ('10ˣ', '-2', .01, true, AngleUnit.degrees),
    ('√', '81', 9, false, AngleUnit.degrees),
    ('∛', '-27', -3, true, AngleUnit.degrees),
    ('x²', '-3', 9, false, AngleUnit.degrees),
    ('x³', '-3', -27, true, AngleUnit.degrees),
    ('1/x', '4', .25, false, AngleUnit.degrees),
    ('|x|', '-9', 9, true, AngleUnit.degrees),
    ('n!', '5', 120, false, AngleUnit.degrees),
    ('%', '50', .5, false, AngleUnit.degrees),
    ('±', '23', -23, false, AngleUnit.degrees),
  ];

  Future<void> tap(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey('key-$key'));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester, CalculatorController calc) async {
    await tester.pumpWidget(const SizedBox());
    calc.dispose();
  }

  for (final item in cases) {
    testWidgets('${item.$1} button in ${item.$5.name}', (tester) async {
      final calc = CalculatorController(MemoryStorage())
        ..scientific = true
        ..angleUnit = item.$5;
      await tester.pumpWidget(LumaApp(controller: calc));
      if (item.$4) {
        await tester.ensureVisible(find.byKey(const ValueKey('inverse-key')));
        await tester.tap(find.byKey(const ValueKey('inverse-key')));
        await tester.pumpAndSettle();
      }
      calc.replaceExpression(item.$2);
      await tester.pumpAndSettle();
      await tap(tester, item.$1);
      await tap(tester, '=');
      expect(calc.error, isNull);
      expect(
        calc.answer,
        closeTo(item.$3, math.max(1e-12, item.$3.abs() * 1e-12)),
      );
      expect(tester.takeException(), isNull);
      await close(tester, calc);
    });
  }

  for (final item in <(String, String, bool)>[
    ('√', '-1', false),
    ('ln', '0', false),
    ('log', '-1', false),
    ('tan', '90', false),
    ('sin⁻¹', '2', true),
    ('cos⁻¹', '-2', true),
    ('n!', '2.5', false),
    ('n!', '171', false),
    ('1/x', '0', false),
    ('eˣ', '1000', true),
    ('10ˣ', '1000', true),
  ]) {
    testWidgets('${item.$1} rejects ${item.$2}', (tester) async {
      final calc = CalculatorController(MemoryStorage())
        ..scientific = true
        ..inverse = item.$3;
      calc.replaceExpression(item.$2);
      await tester.pumpWidget(LumaApp(controller: calc));
      await tap(tester, item.$1);
      await tap(tester, '=');
      expect(calc.error, isNotNull);
      expect(calc.history, isEmpty);
      expect(tester.takeException(), isNull);
      await tap(tester, 'AC');
      expect(calc.expression, isEmpty);
      expect(calc.error, isNull);
      await close(tester, calc);
    });
  }

  for (final item in <(List<String>, double)>[
    (['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '='], 1234567890),
    (['.', '5', '+', '.', '2', '5', '='], .75),
    (['8', '+', '2', '='], 10),
    (['8', '−', '2', '='], 6),
    (['8', '×', '2', '='], 16),
    (['8', '÷', '2', '='], 4),
    (['2', 'x^y', '3', '='], 8),
    (['(', '2', '+', '3', ')', '4', '='], 20),
    (['2', '0', '0', '+', '1', '0', '%', '='], 220),
    (['2', '0', '0', '−', '1', '0', '%', '='], 180),
    (['5', '×', '±', '2', '='], -10),
    (['1', '2', '⌫', '3', '='], 13),
    (['π', '='], math.pi),
    (['e', '='], math.e),
    (['Ans', '+', '1', '='], 8),
  ]) {
    testWidgets('key sequence ${item.$1.join(" ")}', (tester) async {
      final calc = CalculatorController(MemoryStorage())
        ..scientific = true
        ..answer = 7;
      await tester.pumpWidget(LumaApp(controller: calc));
      for (final key in item.$1) {
        await tap(tester, key);
      }
      expect(calc.error, isNull);
      expect(
        calc.answer,
        closeTo(item.$2, math.max(1e-12, item.$2.abs() * 1e-12)),
      );
      await close(tester, calc);
    });
  }

  testWidgets('memory buttons add subtract recall and clear', (tester) async {
    final calc = CalculatorController(MemoryStorage());
    await tester.pumpWidget(LumaApp(controller: calc));
    Future<void> memory(String key) async {
      final target = find.byKey(ValueKey('memory-$key'));
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    calc.replaceExpression('10');
    await tester.pumpAndSettle();
    await memory('M+');
    calc.replaceExpression('3');
    await tester.pumpAndSettle();
    await memory('M−');
    expect(calc.memory, 7);
    await tap(tester, 'AC');
    await memory('MR');
    await tap(tester, '=');
    expect(calc.answer, 7);
    await memory('MC');
    expect(calc.hasMemory, isFalse);
    await close(tester, calc);
  });

  testWidgets('copy paste history editing and clear confirmation', (
    tester,
  ) async {
    var clipboard = '';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String;
          return null;
        }
        if (call.method == 'Clipboard.getData') return {'text': clipboard};
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final calc = CalculatorController(MemoryStorage());
    await tester.pumpWidget(LumaApp(controller: calc));
    calc.replaceExpression('8/2');
    calc.calculate();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Copy result'));
    await tester.tap(find.byTooltip('Copy result'));
    await tester.pumpAndSettle();
    expect(clipboard, '4');
    clipboard = 'sqrt(81)+1';
    await tester.tap(find.byTooltip('Paste expression'));
    await tester.pumpAndSettle();
    await tap(tester, '=');
    expect(calc.answer, 10);
    await tester.tap(find.byTooltip('Calculation history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy').first);
    await tester.pumpAndSettle();
    expect(clipboard, '10');
    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();
    expect(calc.expression, 'sqrt(81)+1');
    await tester.tap(find.byTooltip('Calculation history'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Clear history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep history'));
    await tester.pumpAndSettle();
    expect(calc.history.length, 2);
    await tester.tap(find.byTooltip('Clear history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(calc.history, isEmpty);
    expect(find.text('A fresh start'), findsOneWidget);
    await close(tester, calc);
  });

  testWidgets('angle mode feedback and held delete controls', (tester) async {
    final calc = CalculatorController(MemoryStorage())..scientific = true;
    await tester.pumpWidget(LumaApp(controller: calc));
    await tester.tap(find.byTooltip('Switch between degrees and radians'));
    await tester.pumpAndSettle();
    expect(calc.angleUnit, AngleUnit.radians);
    calc.replaceExpression('12345');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('key-⌫')));
    await tester.longPress(find.byKey(const ValueKey('key-⌫')));
    await tester.pumpAndSettle();
    expect(calc.expression, isEmpty);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Touch feedback'));
    await tester.pumpAndSettle();
    expect(calc.haptics, isFalse);
    expect(tester.takeException(), isNull);
    await close(tester, calc);
  });
}
