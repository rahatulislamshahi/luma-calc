import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma_calc/core/calculator_controller.dart';
import 'package:luma_calc/main.dart';

import 'calculator_controller_test.dart' show MemoryStorage;

void main() {
  for (final size in [
    const Size(280, 480),
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
    const Size(412, 915),
    const Size(600, 960),
    const Size(740, 360),
    const Size(1024, 768),
  ]) {
    for (final scientific in [false, true]) {
      for (final scale in [1.0, 1.8]) {
        testWidgets(
          'layout ${size.width}x${size.height} scientific=$scientific scale=$scale',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = size;
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            final calc = CalculatorController(MemoryStorage())
              ..scientific = scientific;
            await tester.pumpWidget(LumaApp(controller: calc));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.ensureVisible(find.byKey(const ValueKey('key-=')));
            await tester.tap(find.byKey(const ValueKey('key-=')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
            calc.dispose();
          },
        );
      }
    }
  }

  testWidgets('keypad calculation history reuse and clearing', (tester) async {
    final calc = CalculatorController(MemoryStorage());
    await tester.pumpWidget(LumaApp(controller: calc));
    for (final key in ['2', '+', '3', '×', '4', '=']) {
      await tester.ensureVisible(find.byKey(ValueKey('key-$key')));
      await tester.tap(find.byKey(ValueKey('key-$key')));
      await tester.pump();
    }
    expect(calc.answer, 14);
    await tester.ensureVisible(find.byTooltip('Calculation history'));
    await tester.tap(find.byTooltip('Calculation history'));
    await tester.pumpAndSettle();
    expect(find.text('= 14'), findsOneWidget);
    await tester.tap(find.text('Use result'));
    await tester.pumpAndSettle();
    expect(calc.expression, '(14.0)');
    await tester.pumpWidget(const SizedBox());
    calc.dispose();
  });

  testWidgets('scientific inverse keys and appearance controls', (
    tester,
  ) async {
    final calc = CalculatorController(MemoryStorage());
    await tester.pumpWidget(LumaApp(controller: calc));
    await tester.tap(find.byKey(const ValueKey('mode-Scientific')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('inverse-key')));
    await tester.pumpAndSettle();
    expect(find.text('sin⁻¹'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Settings'));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark appearance'));
    await tester.pumpAndSettle();
    expect(calc.dark, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    calc.dispose();
  });
}
