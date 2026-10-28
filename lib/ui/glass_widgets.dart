import 'dart:ui';

import 'package:flutter/material.dart';

import 'palette.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.palette,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 28,
    this.blur = false,
  });

  final CalcPalette palette;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: palette.line),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.surface.withValues(alpha: palette.dark ? .82 : .85),
            palette.surface.withValues(alpha: palette.dark ? .58 : .65),
          ],
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: blur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: content,
            )
          : content,
    );
  }
}

class CalcKey extends StatelessWidget {
  const CalcKey({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.palette,
    required this.onPressed,
    this.onLongPress,
    this.kind = KeyKind.number,
    this.small = false,
    this.icon,
  });

  final String label;
  final String semanticLabel;
  final CalcPalette palette;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final KeyKind kind;
  final bool small;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final equals = kind == KeyKind.equals;
    final foreground = equals
        ? const Color(0xFF25183F)
        : switch (kind) {
            KeyKind.operation => palette.accent,
            KeyKind.function => palette.mint,
            KeyKind.clear => palette.error,
            _ => palette.text,
          };
    final background = switch (kind) {
      KeyKind.operation => palette.operator,
      KeyKind.function || KeyKind.clear => palette.function,
      _ => palette.key,
    };
    final radius = BorderRadius.circular(small ? 14 : 20);
    return Semantics(
      label: semanticLabel,
      button: true,
      excludeSemantics: true,
      onTap: onPressed,
      onLongPress: onLongPress,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: equals
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFDDC7FF), Color(0xFFB897F0)],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [background, background.withValues(alpha: .72)],
                ),
          border: Border.all(
            color: equals
                ? const Color(0x55FFFFFF)
                : palette.line.withValues(alpha: .065),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            onLongPress: onLongPress,
            splashColor: foreground.withValues(alpha: .12),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: small ? 5 : 9,
                vertical: 5,
              ),
              child: Center(
                child: icon != null
                    ? Icon(icon, color: foreground, size: small ? 20 : 24)
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          style: TextStyle(
                            color: foreground,
                            fontSize: small ? 17 : (equals ? 32 : 27),
                            fontWeight: small
                                ? FontWeight.w500
                                : FontWeight.w400,
                            height: 1.1,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum KeyKind { number, operation, function, clear, equals }

class QuietButton extends StatelessWidget {
  const QuietButton({
    super.key,
    required this.icon,
    required this.label,
    required this.palette,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final CalcPalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      foregroundColor: palette.secondary,
      backgroundColor: palette.surface.withValues(alpha: .6),
      side: BorderSide(color: palette.line),
      minimumSize: const Size(48, 48),
    ),
    icon: Icon(icon, size: 21),
  );
}
