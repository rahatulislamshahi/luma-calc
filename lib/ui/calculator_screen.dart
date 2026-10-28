import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/calculator_controller.dart';
import '../core/calculator_engine.dart';
import 'glass_widgets.dart';
import 'palette.dart';
import 'expression_editor.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key, required this.controller});

  final CalculatorController controller;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with WidgetsBindingObserver {
  CalculatorController get calc => widget.controller;
  CalcPalette get palette => CalcPalette(calc.dark);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(calc.persist());
  }

  void _tap(VoidCallback action) {
    if (calc.haptics) unawaited(HapticFeedback.selectionClick());
    action();
  }

  void _equals() {
    _tap(() {
      calc.calculate();
      if (calc.error != null) _message(calc.error!);
    });
  }

  void _message(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(value), duration: const Duration(seconds: 2)),
      );
  }

  Future<void> _copy(String value) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (mounted) _message('Copied to clipboard');
    } on PlatformException {
      if (mounted) _message('Clipboard is unavailable. Try again.');
    }
  }

  Future<void> _paste() async {
    try {
      final value = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted) return;
      if (value?.text == null || value!.text!.trim().isEmpty) {
        _message('Your clipboard is empty.');
        return;
      }
      calc.replaceExpression(value.text!);
    } on PlatformException {
      if (mounted) _message('Clipboard is unavailable. Try again.');
    }
  }

  KeyEventResult _keyboard(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent)
      return KeyEventResult.ignored;
    if (ModalRoute.of(context)?.isCurrent != true)
      return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        event.character == '=') {
      _equals();
    } else if (key == LogicalKeyboardKey.backspace) {
      calc.erase();
    } else if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.delete) {
      calc.clear();
    } else if (HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed) {
      if (key == LogicalKeyboardKey.keyV) {
        unawaited(_paste());
      } else if (key == LogicalKeyboardKey.keyC) {
        unawaited(
          _copy(
            calc.displayValue.isEmpty ? calc.expression : calc.displayValue,
          ),
        );
      } else {
        return KeyEventResult.ignored;
      }
    } else {
      final character = event.character;
      if (character == null) return KeyEventResult.ignored;
      if (RegExp(r'^[0-9.]$').hasMatch(character)) {
        calc.digit(character);
      } else if ('+-*/^'.contains(character) && character.length == 1) {
        calc.operator(switch (character) {
          '-' => '−',
          '*' => '×',
          '/' => '÷',
          _ => character,
        });
      } else if (character == '(' || character == ')') {
        calc.parenthesis(character == '(');
      } else if (character == '%' || character == '!') {
        calc.postfix(character);
      } else {
        return KeyEventResult.ignored;
      }
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (calc.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarDividerColor: Colors.transparent,
              ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Focus(
          autofocus: true,
          onKeyEvent: _keyboard,
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: p.background)),
              Positioned(
                top: -170,
                right: -180,
                child: _orb(
                  500,
                  p.accentStrong.withValues(alpha: calc.dark ? .17 : .15),
                ),
              ),
              Positioned(
                bottom: -180,
                left: -240,
                child: _orb(
                  550,
                  const Color(
                    0xFF499B9D,
                  ).withValues(alpha: calc.dark ? .13 : .1),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, bounds) {
                    final wide =
                        bounds.maxWidth >= 840 ||
                        (bounds.maxWidth >= 520 &&
                            bounds.maxWidth > bounds.maxHeight);
                    final width = math.min(
                      bounds.maxWidth,
                      wide ? 1100.0 : 560.0,
                    );
                    final inset = width < 700 ? 12.0 : 20.0;
                    final room = math.max(0.0, bounds.maxHeight - 88);
                    return Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: width,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(inset, 8, inset, 16),
                          child: Column(
                            children: [
                              _header(p),
                              const SizedBox(height: 16),
                              Expanded(
                                child: wide
                                    ? _wideLayout(p, width - inset * 2, room)
                                    : SingleChildScrollView(
                                        key: const ValueKey(
                                          'calculator-scroll',
                                        ),
                                        child: _portraitLayout(p, room),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orb(double size, Color color) => IgnorePointer(
    child: SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    ),
  );

  Widget _header(CalcPalette p) => SizedBox(
    height: 48,
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFFD4BDFF), Color(0xFF9570D8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0x44FFFFFF)),
          ),
          child: const Icon(
            Icons.drag_handle_rounded,
            color: Color(0xFF2D2047),
            size: 27,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 29,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1.2,
                    color: p.text,
                  ),
                  children: [
                    const TextSpan(text: 'luma'),
                    TextSpan(
                      text: '.',
                      style: TextStyle(color: p.accent),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        QuietButton(
          icon: Icons.history_rounded,
          label: 'Calculation history',
          palette: p,
          onPressed: _historySheet,
        ),
        const SizedBox(width: 8),
        QuietButton(
          icon: Icons.tune_rounded,
          label: 'Settings',
          palette: p,
          onPressed: _settingsSheet,
        ),
      ],
    ),
  );

  Widget _portraitLayout(CalcPalette p, double room) {
    final width = math.min(MediaQuery.sizeOf(context).width, 560.0) - 24;
    final columns = ((width + 8) / 56).floor().clamp(3, 5);
    final scienceHeight = calc.scientific
        ? (15 / columns).ceil() * 56.0 + 4
        : 0.0;
    final fixedHeight = 166 + scienceHeight;
    final minimumDisplay = 164.0;
    final keyHeight = ((room - fixedHeight - minimumDisplay) / 5).clamp(
      48.0,
      78.0,
    );
    final displayHeight = (room - fixedHeight - keyHeight * 5).clamp(
      minimumDisplay,
      260.0,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _modeBar(p),
        const SizedBox(height: 12),
        _display(p, displayHeight),
        const SizedBox(height: 12),
        _memoryBar(p),
        const SizedBox(height: 8),
        if (calc.scientific) ...[
          _scientificKeys(p),
          const SizedBox(height: 12),
        ],
        _numberKeys(p, keyHeight),
      ],
    );
  }

  Widget _wideLayout(CalcPalette p, double width, double room) {
    final compact = room < 440;
    final columns = compact ? 5 : 4;
    final rows = compact ? 4 : 5;
    final keyHeight = ((room - (rows - 1) * 8) / rows).clamp(48.0, 86.0);
    final leftWidth = math.min(width * .44, width - (compact ? 272 : 216) - 16);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: leftWidth,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _modeBar(p),
                const SizedBox(height: 12),
                _display(p, room > 480 ? 220 : 164),
                const SizedBox(height: 12),
                _memoryBar(p),
                if (calc.scientific) ...[
                  const SizedBox(height: 12),
                  _scientificKeys(p),
                ],
                if (room > 480 && !calc.scientific) ...[
                  const SizedBox(height: 22),
                  _recentCalculations(p),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SingleChildScrollView(
            child: _numberKeys(p, keyHeight, columns: columns),
          ),
        ),
      ],
    );
  }

  Widget _modeBar(CalcPalette p) => SizedBox(
    height: 54,
    child: Row(
      children: [
        Expanded(
          child: GlassSurface(
            palette: p,
            radius: 15,
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _modeOption('Standard', false, p),
                _modeOption('Scientific', true, p),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 66,
          child: Tooltip(
            message: 'Switch between degrees and radians',
            child: TextButton(
              onPressed: () => _tap(calc.toggleAngle),
              style: TextButton.styleFrom(
                foregroundColor: p.mint,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              child: FittedBox(
                child: Text(
                  calc.angleUnit == AngleUnit.degrees ? 'DEG' : 'RAD',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _modeOption(String text, bool scientific, CalcPalette p) => Expanded(
    child: Semantics(
      selected: calc.scientific == scientific,
      child: TextButton(
        key: ValueKey('mode-$text'),
        onPressed: () {
          if (calc.scientific != scientific) _tap(calc.toggleScientific);
        },
        style: TextButton.styleFrom(
          foregroundColor: calc.scientific == scientific ? p.text : p.secondary,
          backgroundColor: calc.scientific == scientific
              ? p.key
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ),
  );

  Widget _display(CalcPalette p, double height) => GlassSurface(
    palette: p,
    blur: true,
    radius: 26,
    child: SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        calc.hasMemory
                            ? 'M  ${CalculatorEngine.format(calc.memory)}'
                            : 'LET’S WORK IT OUT',
                        style: TextStyle(
                          color: calc.hasMemory ? p.mint : p.secondary,
                          fontSize: 10,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  _displayAction(
                    Icons.edit_outlined,
                    'Edit expression',
                    _editExpression,
                    p,
                  ),
                  _displayAction(
                    Icons.content_paste_rounded,
                    'Paste expression',
                    () => unawaited(_paste()),
                    p,
                  ),
                  _displayAction(
                    Icons.copy_rounded,
                    'Copy result',
                    () => unawaited(
                      _copy(
                        calc.displayValue.isEmpty
                            ? calc.expression
                            : calc.displayValue,
                      ),
                    ),
                    p,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: calc.justEvaluated ? 32 : 42,
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _editExpression,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        prettyExpression(
                          calc.displayExpression.isEmpty
                              ? '0'
                              : calc.displayExpression,
                        ),
                        key: const ValueKey('expression-display'),
                        maxLines: 1,
                        style: TextStyle(
                          color: calc.justEvaluated ? p.secondary : p.text,
                          fontSize: calc.justEvaluated ? 22 : 32,
                          fontWeight: FontWeight.w400,
                          letterSpacing: .5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: calc.justEvaluated ? 3 : 2,
              child: Semantics(
                liveRegion: calc.justEvaluated || calc.error != null,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: calc.error != null
                      ? Text(
                          calc.error!,
                          key: const ValueKey('error-display'),
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: p.error, fontSize: 13),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            calc.displayValue.isEmpty
                                ? ' '
                                : '${calc.justEvaluated || calc.expression.isEmpty ? '' : '≈ '}${calc.displayValue}',
                            key: const ValueKey('result-display'),
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: calc.justEvaluated ? 68 : 44,
                              height: 1.1,
                              letterSpacing: -1.5,
                              fontWeight: FontWeight.w300,
                              color: calc.justEvaluated ? p.text : p.accent,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _displayAction(
    IconData icon,
    String label,
    VoidCallback onPressed,
    CalcPalette p,
  ) => SizedBox(
    width: 48,
    height: 48,
    child: IconButton(
      tooltip: label,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Icon(icon, size: 15, color: p.secondary),
    ),
  );

  Widget _memoryBar(CalcPalette p) => LayoutBuilder(
    builder: (context, bounds) => SizedBox(
      height: 48,
      child: Row(
        children: [
          if (calc.scientific && bounds.maxWidth >= 240)
            Expanded(
              child: TextButton(
                key: const ValueKey('inverse-key'),
                onPressed: () => _tap(calc.toggleInverse),
                style: TextButton.styleFrom(
                  foregroundColor: calc.inverse ? p.text : p.accent,
                  backgroundColor: calc.inverse
                      ? p.operator
                      : Colors.transparent,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: const FittedBox(
                  child: Text('2nd', style: TextStyle(fontSize: 13)),
                ),
              ),
            ),
          for (final action in ['MC', 'MR', 'M+', 'M−'])
            Expanded(
              child: TextButton(
                key: ValueKey('memory-$action'),
                onPressed: () => _tap(() => calc.memoryAction(action)),
                style: TextButton.styleFrom(
                  foregroundColor:
                      (action == 'MC' || action == 'MR') && !calc.hasMemory
                      ? p.secondary.withValues(alpha: .55)
                      : p.secondary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: FittedBox(
                  child: Text(
                    action,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _scientificKeys(CalcPalette p) {
    final inverse = calc.inverse;
    final functions = <(String, String, VoidCallback)>[
      (
        inverse ? 'sin⁻¹' : 'sin',
        inverse ? 'Inverse sine' : 'Sine',
        () => calc.function(inverse ? 'asin' : 'sin'),
      ),
      (
        inverse ? 'cos⁻¹' : 'cos',
        inverse ? 'Inverse cosine' : 'Cosine',
        () => calc.function(inverse ? 'acos' : 'cos'),
      ),
      (
        inverse ? 'tan⁻¹' : 'tan',
        inverse ? 'Inverse tangent' : 'Tangent',
        () => calc.function(inverse ? 'atan' : 'tan'),
      ),
      (
        inverse ? 'eˣ' : 'ln',
        inverse ? 'Exponential' : 'Natural logarithm',
        () => calc.function(inverse ? 'exp' : 'ln'),
      ),
      (
        inverse ? '10ˣ' : 'log',
        inverse ? 'Ten to the power' : 'Base ten logarithm',
        () => calc.function(inverse ? 'powten' : 'log'),
      ),
      (
        inverse ? '∛' : '√',
        inverse ? 'Cube root' : 'Square root',
        () => calc.function(inverse ? 'cbrt' : 'sqrt'),
      ),
      (
        inverse ? 'x³' : 'x²',
        inverse ? 'Cube the expression' : 'Square the expression',
        () => calc.transform(inverse ? 'cube' : 'square'),
      ),
      ('x^y', 'Power', () => calc.operator('^')),
      ('n!', 'Factorial', () => calc.postfix('!')),
      (
        inverse ? '|x|' : '1/x',
        inverse ? 'Absolute value of expression' : 'Reciprocal of expression',
        () => calc.transform(inverse ? 'abs' : 'reciprocal'),
      ),
      ('(', 'Open parenthesis', () => calc.parenthesis(true)),
      (')', 'Close parenthesis', () => calc.parenthesis(false)),
      ('π', 'Pi', () => calc.constant('π')),
      ('e', 'Euler’s number', () => calc.constant('e')),
      ('Ans', 'Previous answer', () => calc.constant('Ans')),
    ];
    final width = math.min(MediaQuery.sizeOf(context).width, 560.0) - 24;
    return LayoutBuilder(
      builder: (context, bounds) => _grid(
        columns: ((math.min(width, bounds.maxWidth) + 8) / 56).floor().clamp(
          3,
          5,
        ),
        height: 48,
        children: [
          if (bounds.maxWidth < 240)
            CalcKey(
              key: const ValueKey('inverse-key'),
              label: '2nd',
              semanticLabel: 'Toggle inverse functions',
              palette: p,
              small: true,
              kind: KeyKind.function,
              onPressed: () => _tap(calc.toggleInverse),
            ),
          for (final function in functions)
            CalcKey(
              key: ValueKey('key-${function.$1}'),
              label: function.$1,
              semanticLabel: function.$2,
              palette: p,
              small: true,
              kind: KeyKind.function,
              onPressed: () => _tap(function.$3),
            ),
        ],
      ),
    );
  }

  Widget _numberKeys(CalcPalette p, double height, {int columns = 4}) {
    final keys = columns == 5
        ? [
            '7',
            '8',
            '9',
            '⌫',
            'AC',
            '4',
            '5',
            '6',
            '×',
            '÷',
            '1',
            '2',
            '3',
            '+',
            '−',
            '±',
            '0',
            '.',
            '%',
            '=',
          ]
        : [
            'AC',
            '%',
            '⌫',
            '÷',
            '7',
            '8',
            '9',
            '×',
            '4',
            '5',
            '6',
            '−',
            '1',
            '2',
            '3',
            '+',
            '±',
            '0',
            '.',
            '=',
          ];
    return _grid(
      columns: columns,
      height: height,
      children: [
        for (final key in keys)
          CalcKey(
            key: ValueKey('key-$key'),
            label: key,
            semanticLabel: switch (key) {
              'AC' => 'Clear calculation',
              '%' => 'Percent',
              '⌫' => 'Delete last character',
              '÷' => 'Divide',
              '×' => 'Multiply',
              '−' => 'Subtract',
              '+' => 'Add',
              '±' => 'Change sign',
              '.' => 'Decimal point',
              '=' => 'Equals',
              _ => key,
            },
            palette: p,
            icon: key == '⌫' ? Icons.backspace_outlined : null,
            kind: key == '='
                ? KeyKind.equals
                : key == 'AC'
                ? KeyKind.clear
                : ['÷', '×', '−', '+'].contains(key)
                ? KeyKind.operation
                : ['%', '⌫', '±'].contains(key)
                ? KeyKind.function
                : KeyKind.number,
            onLongPress: key == '⌫' ? () => _tap(calc.clear) : null,
            onPressed: () {
              if (key == '=') {
                _equals();
                return;
              }
              _tap(() {
                switch (key) {
                  case 'AC':
                    calc.clear();
                  case '⌫':
                    calc.erase();
                  case '%':
                    calc.postfix('%');
                  case '±':
                    calc.negate();
                  case '÷' || '×' || '−' || '+':
                    calc.operator(key);
                  default:
                    calc.digit(key);
                }
              });
            },
          ),
      ],
    );
  }

  Widget _grid({
    required int columns,
    required double height,
    required List<Widget> children,
  }) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var row = 0; row < (children.length / columns).ceil(); row++) ...[
        if (row != 0) const SizedBox(height: 8),
        SizedBox(
          height: height,
          child: Row(
            children: [
              for (var column = 0; column < columns; column++) ...[
                if (column != 0) const SizedBox(width: 8),
                Expanded(
                  child: row * columns + column < children.length
                      ? children[row * columns + column]
                      : const SizedBox(),
                ),
              ],
            ],
          ),
        ),
      ],
    ],
  );

  Widget _recentCalculations(CalcPalette p) => Align(
    alignment: Alignment.centerLeft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'RECENT CALCULATIONS',
          style: TextStyle(
            color: p.secondary,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        if (calc.history.isEmpty)
          Text(
            'Your next bright idea starts here.',
            style: TextStyle(color: p.secondary, fontSize: 15, height: 1.7),
          ),
        for (final entry in calc.history.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              onTap: () => calc.reuse(entry),
              title: Text(
                prettyExpression(entry.expression),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.secondary),
              ),
              subtitle: Text(
                entry.result,
                style: TextStyle(color: p.accent, fontSize: 19),
              ),
            ),
          ),
      ],
    ),
  );

  Future<void> _editExpression() async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => ExpressionEditor(expression: calc.displayExpression),
    );
    if (mounted && value != null) calc.replaceExpression(value);
  }

  void _historySheet() => _sheet(
    (context, p) => ListView(
      children: [
        _sheetHeader(
          context,
          p,
          'History',
          '${calc.history.length} of 100 saved on this device',
          trailing: calc.history.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear history',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _confirmClear(context),
                ),
        ),
        if (calc.history.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.history_rounded, color: p.accent, size: 48),
                const SizedBox(height: 20),
                const Text('A fresh start', style: TextStyle(fontSize: 22)),
                const SizedBox(height: 10),
                Text(
                  'Finished calculations will appear here. Tap one to use it again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.secondary, height: 1.6),
                ),
              ],
            ),
          )
        else
          for (var index = 0; index < calc.history.length; index++)
            Builder(
              builder: (context) {
                final entry = calc.history[index];
                final date = entry.createdAt.toLocal();
                final time =
                    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: GlassSurface(
                    palette: p,
                    radius: 20,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  time,
                                  style: TextStyle(
                                    color: p.secondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Text(
                                entry.angleUnit == AngleUnit.degrees
                                    ? 'DEG'
                                    : 'RAD',
                                style: TextStyle(
                                  color: p.mint,
                                  fontSize: 10,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () {
                              calc.reuse(entry);
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Text(
                                prettyExpression(entry.expression),
                                style: TextStyle(
                                  color: p.secondary,
                                  fontSize: 17,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                          SelectableText(
                            '= ${entry.result}',
                            style: TextStyle(
                              color: p.text,
                              fontSize: 27,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () => unawaited(_copy(entry.result)),
                                child: const Text('Copy'),
                              ),
                              TextButton(
                                onPressed: () {
                                  calc.useResult(entry);
                                  Navigator.pop(context);
                                },
                                child: const Text('Use result'),
                              ),
                              TextButton(
                                onPressed: () {
                                  calc.reuse(entry);
                                  Navigator.pop(context);
                                },
                                child: const Text('Edit'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        const SizedBox(height: 24),
      ],
    ),
  );

  void _confirmClear(BuildContext sheetContext) {
    unawaited(
      showDialog<void>(
        context: sheetContext,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: const Text('Clear history?'),
          content: const Text(
            'This removes all saved calculations from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep history'),
            ),
            FilledButton(
              onPressed: () {
                calc.clearHistory();
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }

  void _settingsSheet() => _sheet(
    (context, p) => ListView(
      children: [
        _sheetHeader(
          context,
          p,
          'Make it yours',
          'Small details. A calmer way to calculate.',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          child: Column(
            children: [
              SwitchListTile(
                secondary:
                    MediaQuery.sizeOf(context).width < 360 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.5
                    ? null
                    : Icon(
                        calc.dark
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        color: p.accent,
                      ),
                title: const Text('Dark appearance'),
                subtitle: const Text('Soft glass, day or night'),
                value: calc.dark,
                onChanged: (_) => calc.toggleTheme(),
              ),
              SwitchListTile(
                secondary:
                    MediaQuery.sizeOf(context).width < 360 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.5
                    ? null
                    : Icon(Icons.vibration_rounded, color: p.accent),
                title: const Text('Touch feedback'),
                subtitle: const Text('A light tap with each key'),
                value: calc.haptics,
                onChanged: (_) => calc.toggleHaptics(),
              ),
              ListTile(
                title: const Text('Angle unit'),
                subtitle: Text(
                  calc.angleUnit == AngleUnit.degrees
                      ? 'Degrees · a full circle is 360°'
                      : 'Radians · a full circle is 2π',
                ),
                trailing: TextButton(
                  onPressed: calc.toggleAngle,
                  child: FittedBox(
                    child: Text(
                      calc.angleUnit == AngleUnit.degrees ? 'DEG' : 'RAD',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GlassSurface(
                  palette: p,
                  radius: 22,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A FEW BRIGHT SHORTCUTS',
                        style: TextStyle(
                          color: p.mint,
                          fontSize: 10,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _tip(
                        'Everyday percentages',
                        '200 + 10% = 220. Multiply or divide by a percentage as usual.',
                        p,
                      ),
                      _tip(
                        'A little more science',
                        'Tap 2nd for inverse trig, cube roots, eˣ, 10ˣ and absolute value.',
                        p,
                      ),
                      _tip(
                        'Keep your flow',
                        'Open parentheses close when you press =. Hold delete to clear. Tap the expression to edit it.',
                        p,
                      ),
                      _tip(
                        'Whole-expression tools',
                        'x², x³, 1/x and |x| apply to the entire expression. ± changes the last value. Trig and log functions wrap the last value.',
                        p,
                      ),
                      _tip(
                        'Memory & precision',
                        'M+ and M− add or subtract the current value. MR recalls it. Results show up to 12 significant digits; calculations use double precision.',
                        p,
                      ),
                      Text(
                        'Keyboard: Enter = calculate · Esc = clear\nCtrl/Cmd+C = copy · Ctrl/Cmd+V = paste',
                        style: TextStyle(
                          color: p.secondary,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'luma.  1.0.1',
                  style: TextStyle(
                    color: p.secondary,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Offline. On your device. Always yours.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.secondary, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _tip(String title, String text, CalcPalette p) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        Text(
          text,
          style: TextStyle(color: p.secondary, fontSize: 12, height: 1.6),
        ),
      ],
    ),
  );

  Widget _sheetHeader(
    BuildContext context,
    CalcPalette p,
    String title,
    String subtitle, {
    Widget? trailing,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 12, 12, 16),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(color: p.secondary, fontSize: 12),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    ),
  );

  void _sheet(Widget Function(BuildContext, CalcPalette) builder) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: false,
        backgroundColor: Colors.transparent,
        builder: (context) => FractionallySizedBox(
          heightFactor: .88,
          child: ListenableBuilder(
            listenable: calc,
            builder: (context, _) {
              final p = palette;
              return Container(
                decoration: BoxDecoration(
                  color: p.background,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  border: Border.all(color: p.line),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            const SizedBox(width: 48),
                            Expanded(
                              child: Center(
                                child: Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: p.secondary.withValues(alpha: .4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: builder(context, p)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
