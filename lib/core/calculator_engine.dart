import 'dart:math' as math;

enum AngleUnit { degrees, radians }

class CalculationException implements Exception {
  const CalculationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CalculatorEngine {
  const CalculatorEngine();

  double evaluate(
    String expression, {
    AngleUnit angleUnit = AngleUnit.degrees,
    double answer = 0,
  }) {
    if (expression.length > 1024) {
      throw const CalculationException('This expression is too long.');
    }
    return _Parser(normalize(expression), angleUnit, answer).evaluate();
  }

  static String normalize(String value) {
    return value
        .trim()
        .replaceAll('*', '×')
        .replaceAll('/', '÷')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3')
        .replaceAll('√', 'sqrt')
        .replaceAll('∛', 'cbrt')
        .replaceAllMapped(RegExp(r'[a-zA-Z]+'), (match) {
          final name = match.group(0)!.toLowerCase();
          return switch (name) {
            'pi' => 'π',
            'ans' => 'Ans',
            _ => name,
          };
        })
        .replaceAllMapped(
          RegExp(r'(?<![\d.,])\d{1,3}(?:,\d{3})+(?:\.\d+)?(?![\d.,])'),
          (match) => match.group(0)!.replaceAll(',', ''),
        );
  }

  static String format(double value) {
    if (!value.isFinite) {
      throw const CalculationException(
        'The result is outside the number range.',
      );
    }
    if (value == 0) return '0';
    final magnitude = value.abs();
    if (magnitude >= 1e12 || magnitude < 1e-9) {
      final parts = value.toStringAsExponential(11).split('e');
      final mantissa = _trim(parts.first);
      final exponent = int.parse(parts.last);
      return '${mantissa}e$exponent';
    }
    return _trim(value.toStringAsPrecision(12));
  }

  static String literal(double value) => value == 0 ? '0' : value.toString();

  static String _trim(String value) {
    if (value.contains('e')) {
      final parts = value.split('e');
      return '${_trim(parts.first)}e${int.parse(parts.last)}';
    }
    return value.contains('.')
        ? value
              .replaceFirst(RegExp(r'0+$'), '')
              .replaceFirst(RegExp(r'\.$'), '')
        : value;
  }
}

class _Quantity {
  const _Quantity(this.value, {this.percent = false});

  final double value;
  final bool percent;
}

class _Parser {
  _Parser(String source, this.angleUnit, this.answer)
    : source = source
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('−', '-')
          .replaceAll('√', 'sqrt');

  final String source;
  final AngleUnit angleUnit;
  final double answer;
  int position = 0;
  int depth = 0;

  double evaluate() {
    if (source.trim().isEmpty) {
      throw const CalculationException('Enter a calculation first.');
    }
    if (source.contains(',')) {
      throw const CalculationException(
        'Use . for decimals and groups of three for thousands.',
      );
    }
    final result = _sum().value;
    _space();
    if (position != source.length) {
      throw const CalculationException('Check the expression and try again.');
    }
    return _finite(result);
  }

  _Quantity _sum() {
    var left = _product();
    while (true) {
      final add = _take('+');
      if (!add && !_take('-')) return left;
      final right = _product();
      final amount = right.percent ? left.value * right.value : right.value;
      left = _Quantity(_finite(left.value + (add ? amount : -amount)));
    }
  }

  _Quantity _product() {
    var left = _unary();
    while (true) {
      if (_take('*')) {
        left = _Quantity(_finite(left.value * _unary().value));
      } else if (_take('/')) {
        final divisor = _unary().value;
        if (divisor == 0) {
          throw const CalculationException('You cannot divide by zero.');
        }
        left = _Quantity(_finite(left.value / divisor));
      } else if (_startsPrimary()) {
        final prefix = source.substring(0, position).trimRight();
        if (RegExp(r'[\d.]').hasMatch(source[position]) &&
            prefix.isNotEmpty &&
            RegExp(r'[\d.]$').hasMatch(prefix)) {
          throw const CalculationException(
            'Separate numbers with an operator.',
          );
        }
        left = _Quantity(_finite(left.value * _unary().value));
      } else {
        return left;
      }
    }
  }

  _Quantity _unary() {
    _enter();
    try {
      if (_take('+')) return _unary();
      if (_take('-')) {
        final value = _unary();
        return _Quantity(-value.value, percent: value.percent);
      }
      return _power();
    } finally {
      depth--;
    }
  }

  _Quantity _power() {
    final base = _postfix();
    if (!_take('^')) return base;
    final exponent = _unary().value;
    if (base.value == 0 && exponent < 0) {
      throw const CalculationException('Zero cannot have a negative power.');
    }
    if (base.value < 0 && exponent != exponent.truncateToDouble()) {
      throw const CalculationException('That power has no real number result.');
    }
    return _Quantity(_finite(math.pow(base.value, exponent).toDouble()));
  }

  _Quantity _postfix() {
    var value = _primary();
    while (true) {
      if (_take('%')) {
        value = _Quantity(value.value / 100, percent: true);
      } else if (_take('!')) {
        final n = value.value;
        final rounded = n.roundToDouble();
        if (n < 0 || (n - rounded).abs() > math.max(1, n.abs()) * 1e-15) {
          throw const CalculationException(
            'Factorial needs a whole number from 0 to 170.',
          );
        }
        if (rounded > 170) {
          throw const CalculationException('Factorial is limited to 170.');
        }
        var result = 1.0;
        for (var i = 2; i <= rounded; i++) {
          result *= i;
        }
        value = _Quantity(_finite(result));
      } else {
        return value;
      }
    }
  }

  _Quantity _primary() {
    _space();
    if (_take('(')) {
      final value = _sum();
      if (!_take(')')) {
        throw const CalculationException('Close the open parenthesis.');
      }
      return value;
    }
    if (position >= source.length) {
      throw const CalculationException('Finish the expression first.');
    }
    final number = RegExp(
      r'(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?',
    ).matchAsPrefix(source, position);
    if (number != null) {
      position = number.end;
      if (position < source.length && source[position] == '.') {
        throw const CalculationException(
          'A number can only have one decimal point.',
        );
      }
      return _Quantity(_finite(double.parse(number.group(0)!)));
    }
    if (_take('π')) return const _Quantity(math.pi);
    final identifier = RegExp(r'[a-zA-Z]+').matchAsPrefix(source, position);
    if (identifier == null) {
      throw const CalculationException('Check the expression and try again.');
    }
    position = identifier.end;
    final name = identifier.group(0)!.toLowerCase();
    if (name == 'pi') return const _Quantity(math.pi);
    if (name == 'e') return const _Quantity(math.e);
    if (name == 'ans') return _Quantity(answer);
    if (!_take('(')) {
      throw const CalculationException(
        'A function needs parentheses, like sin(30).',
      );
    }
    final input = _sum().value;
    if (!_take(')')) {
      throw const CalculationException('Close the function parenthesis.');
    }
    return _Quantity(_finite(_function(name, input)));
  }

  double _function(String name, double input) {
    final radians = angleUnit == AngleUnit.degrees
        ? input.remainder(360) / 180 * math.pi
        : input;
    double fromRadians(double value) =>
        angleUnit == AngleUnit.degrees ? value * 180 / math.pi : value;
    switch (name) {
      case 'sin':
        if (angleUnit == AngleUnit.degrees && input % 180 == 0) return 0;
        if (angleUnit == AngleUnit.radians && input % math.pi == 0) return 0;
        return math.sin(radians);
      case 'cos':
        if (angleUnit == AngleUnit.degrees && input.abs() % 180 == 90) return 0;
        if (angleUnit == AngleUnit.radians &&
            input.abs() % math.pi == math.pi / 2)
          return 0;
        return math.cos(radians);
      case 'tan':
        if ((angleUnit == AngleUnit.degrees && input.abs() % 180 == 90) ||
            (angleUnit == AngleUnit.radians &&
                input.abs() % math.pi == math.pi / 2)) {
          throw const CalculationException(
            'Tangent is undefined at this angle.',
          );
        }
        if (angleUnit == AngleUnit.degrees && input % 180 == 0) return 0;
        if (angleUnit == AngleUnit.radians && input % math.pi == 0) return 0;
        return math.tan(radians);
      case 'asin':
      case 'acos':
        if (input < -1 || input > 1) {
          throw const CalculationException('Use a value between −1 and 1.');
        }
        return fromRadians(
          name == 'asin' ? math.asin(input) : math.acos(input),
        );
      case 'atan':
        return fromRadians(math.atan(input));
      case 'ln':
      case 'log':
        if (input <= 0) {
          throw const CalculationException(
            'Logarithms need a number greater than zero.',
          );
        }
        return name == 'ln' ? math.log(input) : math.log(input) / math.ln10;
      case 'sqrt':
        if (input < 0) {
          throw const CalculationException(
            'A square root needs a nonnegative number.',
          );
        }
        return math.sqrt(input);
      case 'cbrt':
        return input.sign * math.pow(input.abs(), 1 / 3).toDouble();
      case 'abs':
        return input.abs();
      case 'exp':
        return math.exp(input);
      case 'powten':
        return math.pow(10, input).toDouble();
      default:
        throw const CalculationException('That function is not supported.');
    }
  }

  bool _startsPrimary() {
    _space();
    if (position == source.length) return false;
    return RegExp(r'[\d.a-zA-Zπ(]').hasMatch(source[position]);
  }

  bool _take(String token) {
    _space();
    if (!source.startsWith(token, position)) return false;
    position += token.length;
    return true;
  }

  void _space() {
    while (position < source.length && source[position].trim().isEmpty) {
      position++;
    }
  }

  void _enter() {
    if (++depth > 64) {
      throw const CalculationException('Use fewer nested operations.');
    }
  }

  double _finite(double value) {
    if (!value.isFinite) {
      throw const CalculationException(
        'The result is outside the real number range.',
      );
    }
    return value == 0 ? 0 : value;
  }
}
