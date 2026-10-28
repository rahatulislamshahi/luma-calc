import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma_calc/core/calculator_controller.dart';
import 'package:luma_calc/main.dart';
import 'package:luma_calc/ui/glass_widgets.dart';

import 'calculator_controller_test.dart' show MemoryStorage;

void main() {
  const sizes = [
    Size(240, 480),
    Size(280, 360),
    Size(320, 568),
    Size(360, 640),
    Size(390, 844),
    Size(412, 915),
    Size(480, 800),
    Size(520, 280),
    Size(568, 320),
    Size(640, 360),
    Size(740, 360),
    Size(915, 412),
    Size(600, 960),
    Size(673, 841),
    Size(840, 1180),
    Size(1280, 800),
  ];

  void viewport(WidgetTester tester, Size size, double scale) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  for (final size in sizes) {
    for (final scale in [1.0, 2.0, 3.0]) {
      for (final scientific in [false, true]) {
        for (final dark in [false, true]) {
          testWidgets('$size scale=$scale science=$scientific dark=$dark', (
            tester,
          ) async {
            viewport(tester, size, scale);
            final calc = CalculatorController(MemoryStorage())
              ..scientific = scientific
              ..dark = dark;
            await tester.pumpWidget(LumaApp(controller: calc));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            for (final element in find.byType(CalcKey).evaluate()) {
              final box = element.renderObject! as RenderBox;
              expect(box.size.width, greaterThanOrEqualTo(47.9));
              expect(box.size.height, greaterThanOrEqualTo(47.9));
            }
            for (final key in ['7', '+', '2', '=']) {
              final target = find.byKey(ValueKey('key-$key'));
              await tester.ensureVisible(target);
              await tester.tap(target);
              await tester.pumpAndSettle();
            }
            expect(calc.answer, 9);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
            calc.dispose();
          });
        }
      }
    }
  }

  for (final size in [
    const Size(240, 480),
    const Size(568, 260),
    const Size(390, 844),
  ]) {
    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('panels and editing $size scale=$scale', (tester) async {
        viewport(tester, size, scale);
        final calc = CalculatorController(MemoryStorage());
        await tester.pumpWidget(LumaApp(controller: calc));
        await tester.tap(find.byTooltip('Calculation history'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        calc.replaceExpression('2+3');
        calc.calculate();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byTooltip('Edit expression'));
        await tester.tap(find.byTooltip('Edit expression'));
        await tester.pumpAndSettle();
        expect(find.widgetWithText(TextField, '2+3'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.enterText(
          find.byKey(const ValueKey('expression-editor')),
          '8/2',
        );
        await tester.ensureVisible(find.text('Apply'));
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();
        calc.calculate();
        expect(calc.answer, 4);
        await tester.pumpWidget(const SizedBox());
        calc.dispose();
      });
    }
  }

  testWidgets('screen reader can activate the calculator keys', (tester) async {
    final handle = tester.ensureSemantics();
    final calc = CalculatorController(MemoryStorage());
    await tester.pumpWidget(LumaApp(controller: calc));
    final node = tester.getSemantics(find.byKey(const ValueKey('key-7')));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    handle.dispose();
    await tester.pumpWidget(const SizedBox());
    calc.dispose();
  });
  for (final scale in [1.0, 2.0, 3.0]) {
    testWidgets('keyboard and safe insets scale=$scale', (tester) async {
      viewport(tester, const Size(240, 480), scale);
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewInsets);
      final calc = CalculatorController(MemoryStorage());
      await tester.pumpWidget(LumaApp(controller: calc));
      await tester.ensureVisible(find.byTooltip('Edit expression'));
      await tester.tap(find.byTooltip('Edit expression'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 200);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.enterText(
        find.byKey(const ValueKey('expression-editor')),
        '12/4',
      );
      await tester.ensureVisible(find.text('Apply'));
      await tester.tap(find.text('Apply'));
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      calc.calculate();
      expect(calc.answer, 3);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      calc.dispose();
    });
  }

  testWidgets('rotation preserves input and result on a dense screen', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844), 1);
    final calc = CalculatorController(MemoryStorage())..scientific = true;
    calc.replaceExpression('8+sin(30)');
    await tester.pumpWidget(LumaApp(controller: calc));
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(2532, 1170);
    await tester.pumpAndSettle();
    expect(calc.expression, '8+sin(30)');
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('key-=')));
    await tester.tap(find.byKey(const ValueKey('key-=')));
    await tester.pumpAndSettle();
    expect(calc.answer, 8.5);
    tester.view.physicalSize = const Size(1170, 2532);
    await tester.pumpAndSettle();
    expect(calc.answer, 8.5);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    calc.dispose();
  });
}
