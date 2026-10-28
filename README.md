# Luma Calc

An offline scientific calculator for Android, built with Flutter and Dart.

Luma Calc features a glass-inspired interface, standard and scientific modes, local calculation history, and memory controls.

## Features

- Standard and scientific calculator modes
- Degree and radian angle units
- Trigonometric and inverse trigonometric functions
- Natural and base-10 logarithms
- Exponential functions, powers, square roots, and cube roots
- Factorial, percentage, reciprocal, and absolute value
- Memory controls: MC, MR, M+, and M−
- Previous-answer recall using Ans
- Editable expressions and clipboard support
- Up to 100 locally saved calculations
- Dark and light themes
- Portrait and landscape layouts
- Optional touch feedback
- Keyboard shortcuts and screen-reader actions

## Requirements

- Flutter 3.35.5 with Dart 3.9.2
- Android Studio with the Flutter and Dart plugins
- JDK 17 or 21
- Android SDK Platform 36
- Android SDK Build-Tools 35.0.0
- Android SDK Platform-Tools
- Android NDK 27.0.12077973
- CMake 3.22.1

Minimum supported Android version: Android 7.0, API 24.

An internet connection is required for the initial dependency downloads and build. The calculator works offline.

## Getting Started

Clone the repository:

```bash
git clone https://github.com/rahatulislamshahi/luma-calc.git
cd luma-calc
```

Install dependencies:

```bash
flutter pub get
```

Check your development environment:

```bash
flutter doctor
```

Connect an Android device or start an emulator, then run:

```bash
flutter run
```

For Android Studio, open the repository folder containing `pubspec.yaml` and select your Flutter SDK.

## Build an APK

Build a release APK:

```bash
flutter build apk --release
```

The APK will be available at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

To build separate APKs for each supported architecture:

```bash
flutter build apk --release --split-per-abi
```

Supported architectures:

- armeabi-v7a
- arm64-v8a
- x86_64

## Release Signing

Without a custom signing configuration, release builds use the debug signing key for local installation.

Before publishing the app, create your own release keystore and add an `android/key.properties` file:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=YOUR_KEY_ALIAS
storeFile=C:/Keys/luma-release.jks
```

Replace the placeholders with your own values.

Keep signing passwords, keystores, and `key.properties` out of version control.

## Usage

### Scientific Functions

Switch to Scientific mode to access additional functions.

Tap `2nd` to switch between regular and inverse functions, including inverse trigonometry, cube roots, exponential functions, and absolute value.

Function buttons apply to the last operand. To calculate the sine of an entire expression such as π/2, enter `sin(π/2)` in the expression editor, or enter `(π/2)` before pressing `sin`.

The square, cube, reciprocal, and absolute-value tools apply to the entire current expression. The sign button changes the last operand's sign.

Open parentheses are automatically closed when you press equals.

### Percentages

```text
200 + 10% = 220
200 − 10% = 180
200 × 10% = 20
200 ÷ 10% = 2000
```

### Memory

- `M+` adds the current value to memory.
- `M−` subtracts the current value from memory.
- `MR` recalls the stored value.
- `MC` clears memory.

### Expression Editing

Tap the expression or the edit icon to modify a calculation.

Pasted expressions support ASCII operators, uppercase function names, PI, root symbols, and superscript squares and cubes.

Use a period for decimals. Grouped thousands such as `1,234.5` are accepted. Decimal commas such as `1,5` are not supported.

Hold the delete button to clear the current calculation.

### History and Storage

The app stores up to 100 calculations locally, together with memory, the unfinished expression, the previous answer, and supported settings.

Clearing app data or uninstalling the app removes this information.

### Smaller Screens

Scroll when needed on smaller screens or with larger system fonts.

In landscape mode, the function panel and number keypad scroll independently. Short landscape layouts use a five-column number keypad.

History, settings, and the expression editor also support scrolling.

## Keyboard Shortcuts

| Shortcut | Action |
| --- | --- |
| Enter | Calculate |
| Backspace | Delete the last character |
| Escape | Clear the calculation |
| Ctrl/Cmd+C | Copy the current result or expression |
| Ctrl/Cmd+V | Paste an expression |

## Validation

Run static analysis:

```bash
flutter analyze
```

Run the automated tests:

```bash
flutter test
```

The provided version passed 390 automated tests and static analysis with no issues using Flutter 3.35.5 and Dart 3.9.2.

Test coverage includes:

- Calculation accuracy and operator precedence
- Scientific and inverse-function button actions
- Degree and radian calculations
- Invalid inputs and numeric limits
- Negative-number entry and pasted expressions
- Memory, history, and state restoration
- Clipboard actions and expression editing
- Responsive layouts across 16 screen sizes
- Standard and scientific modes in both themes
- Text scaling at 1×, 2×, and 3×
- Keyboard insets, safe areas, and screen rotation
- Calculator-key touch targets and screen-reader tap actions

Portrait, landscape, scientific, and light/dark interfaces were also rendered for visual inspection.

A release APK was built and its signature verified using JDK 17, Gradle 8.12, Android Gradle Plugin 8.9.1, Kotlin 2.1.0, and Android SDK 36.

Physical-device testing and Android Studio GUI testing were not performed. Automated checks do not guarantee identical behavior on every device.

## Numeric Precision

Calculations use Dart double-precision floating-point numbers. Displayed results use up to 12 significant digits.

The calculator supports real-number calculations. Complex-number results are not supported.

## Project Structure

```text
android/    Android configuration, native storage, and app icons
lib/core/   Calculation engine, controller, and storage interface
lib/ui/     Calculator interface and reusable widgets
test/       Automated calculation, interaction, and layout tests
```