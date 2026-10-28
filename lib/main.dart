import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_storage.dart';
import 'core/calculator_controller.dart';
import 'ui/calculator_screen.dart';
import 'ui/palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final controller = CalculatorController(DeviceStorage());
  await controller.restore();
  runApp(LumaApp(controller: controller));
}

class LumaApp extends StatelessWidget {
  const LumaApp({super.key, required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final palette = CalcPalette(controller.dark);
      return MaterialApp(
        title: 'Luma Calc',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: controller.dark ? Brightness.dark : Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: palette.accentStrong,
            brightness: controller.dark ? Brightness.dark : Brightness.light,
            surface: palette.surface,
          ),
          scaffoldBackgroundColor: palette.background,
          textTheme:
              ThemeData(
                brightness: controller.dark
                    ? Brightness.dark
                    : Brightness.light,
              ).textTheme.apply(
                bodyColor: palette.text,
                displayColor: palette.text,
              ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: palette.operator,
            contentTextStyle: TextStyle(color: palette.text),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        home: CalculatorScreen(controller: controller),
      );
    },
  );
}
