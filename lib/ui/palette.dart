import 'package:flutter/material.dart';

class CalcPalette {
  const CalcPalette(this.dark);

  final bool dark;

  Color get background =>
      dark ? const Color(0xFF10111E) : const Color(0xFFF1F0FA);
  Color get text => dark ? const Color(0xFFF7F5FF) : const Color(0xFF222039);
  Color get secondary =>
      dark ? const Color(0xFFAAA7C3) : const Color(0xFF68617E);
  Color get accent => dark ? const Color(0xFFC5ACFF) : const Color(0xFF7250C3);
  Color get accentStrong => const Color(0xFF9B79E8);
  Color get mint => dark ? const Color(0xFFA3E4D5) : const Color(0xFF247A68);
  Color get error => dark ? const Color(0xFFFFA8B8) : const Color(0xFFAA2A48);
  Color get surface => dark ? const Color(0xFF252537) : const Color(0xFFFCFBFF);
  Color get line => dark ? const Color(0x22FFFFFF) : const Color(0x1C635284);
  Color get key => dark ? const Color(0xFF303043) : const Color(0xFFE8E5F2);
  Color get function =>
      dark ? const Color(0xFF353047) : const Color(0xFFE2DAF1);
  Color get operator =>
      dark ? const Color(0xFF45385E) : const Color(0xFFDBCEEF);
}

String prettyExpression(String expression) => expression
    .replaceAll('powten(', '10^(')
    .replaceAll('sqrt(', '√(')
    .replaceAll('cbrt(', '∛(')
    .replaceAll('asin(', 'sin⁻¹(')
    .replaceAll('acos(', 'cos⁻¹(')
    .replaceAll('atan(', 'tan⁻¹(')
    .replaceAll('exp(', 'e^(')
    .replaceAll('*', '×')
    .replaceAll('/', '÷')
    .replaceAll('-', '−');
