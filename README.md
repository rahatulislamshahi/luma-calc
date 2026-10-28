# Luma Calc 1.0.1

Flutter 3.35.5 ও Dart 3.9.2 দিয়ে তৈরি Android scientific calculator। Target IDE: Android Studio 2025.1.5।

## Android Studio-তে চালাও

1. ZIP extract করে `luma_calc` folder রাখো, যেমন `C:\Projects\luma_calc`।
2. Android Studio-তে Flutter ও Dart plugins enabled রাখো। Flutter SDK path-এ তোমার Flutter 3.35.5 folder select করো।
3. SDK Manager থেকে Android SDK Platform 36, Build-Tools 35.0.0, Platform-Tools, NDK 27.0.12077973 এবং CMake 3.22.1 install করো। SDK Tools-এ Show Package Details চালু করলে নির্দিষ্ট versions পাওয়া যায়। Gradle প্রয়োজন হলে NDK/CMake নিজেও download করবে। Android SDK licences accepted থাকতে হবে।
4. Android Studio → Open → `luma_calc` folder select করো। Root folder-এ `pubspec.yaml` থাকবে।
5. Terminal-এ চালাও:

```sh
flutter --version
flutter doctor
flutter pub get
flutter run
```

JDK 17 অথবা 21 ব্যবহার করো। Android Studio-এর bundled JDK 21 ব্যবহার করা যায়। প্রথম Gradle sync ও build-এর জন্য internet লাগবে। App চালাতে internet লাগে না। কোনো machine-specific SDK path ZIP-এ নেই; Flutter তোমার computer অনুযায়ী `android/local.properties` তৈরি করবে।

## APK build

```sh
flutter build apk --release
```

APK: `build/app/outputs/flutter-apk/app-release.apk`

এই universal APK-তে `armeabi-v7a`, `arm64-v8a` ও `x86_64` architectures থাকে। ছোট আলাদা APK চাইলে:

```sh
flutter build apk --release --split-per-abi
```

Minimum Android: 7.0 / API 24। Flutter 3.35.5-এর minimum version অনুযায়ী পুরোনো Android 5/6 বা 32-bit x86 phones supported নয়। Supported device-এও সব manufacturer ও OS combination বাস্তবে পরীক্ষা করা হয়নি।

Default release build স্থানীয় installation-এর জন্য debug key দিয়ে signed হয়। Play Store-এ publish করার আগে নিজের release keystore তৈরি করে `android/key.properties` দাও:

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_alias
storeFile=C:/Keys/luma-release.jks
```

নিজের values ব্যবহার করো। Private keystore বা passwords ZIP-এ দেওয়া হয়নি। `key.properties` থাকলে build configuration সেই release key ব্যবহার করে।

## ব্যবহার

- Standard ও Scientific mode, DEG/RAD, dark/light theme এবং touch feedback।
- Scientific mode-এ `2nd` থেকে inverse trigonometry, cube root, eˣ, 10ˣ ও absolute value।
- `200 + 10% = 220`, `200 − 10% = 180`, `200 × 10% = 20`।
- Open parentheses `=` চাপলে close হয়। Expression-এ tap করে সরাসরি edit করা যায়। Copy/paste buttons display-এর ওপরে।
- `±` শেষ value-এর sign বদলায়। Trigonometric/log/root buttons শেষ value-কে function-এর মধ্যে রাখে; input খালি থাকলে নতুন function শুরু করে। `x²`, `x³`, `1/x` ও `|x|` পুরো current expression-এর ওপর কাজ করে। নির্দিষ্ট অংশে operation চাইলে parentheses বা expression editor ব্যবহার করো।
- Paste-এ `*`, `/`, uppercase function, `PI`, `√`, `∛` ও `²`/`³` ব্যবহার করা যায়। Decimal-এর জন্য `.` ব্যবহার করো; `1,234.5`-এর মতো হাজারের grouping গ্রহণ করা হয়, `1,5`-এর মতো decimal comma গ্রহণ করা হয় না।
- `M+`/`M−` বর্তমান value memory-তে যোগ/বিয়োগ করে; `MR` recall ও `MC` clear করে।
- সর্বশেষ 100টি calculation, memory, unfinished expression, angle unit ও settings app বন্ধ করেও থাকে। App data clear বা uninstall করলে মুছে যাবে।
- Very small screens ও বড় font-এ প্রয়োজন হলে scroll করো। Landscape-এ function panel ও number keypad আলাদা scroll হয়; short landscape-এ number keypad পাঁচ column-এ থাকে। History/settings এবং keyboard খোলা অবস্থায় expression editor-ও scroll করা যায়।
- Enter: calculate; Backspace: delete; Esc: clear; Ctrl/Cmd+C: copy; Ctrl/Cmd+V: paste।
- Calculations use Dart double precision; display shows up to 12 significant digits। App real numbers নিয়ে কাজ করে; complex-number results supported নয়।

## Project checks

```sh
flutter analyze
flutter test
```

এই revision-এ Flutter 3.35.5 / Dart 3.9.2 দিয়ে analyzer issue ছাড়া এবং 390টি automated test পাস হয়েছে। Automated coverage-এ calculation engine, sign entry, pasted operators, functions, decimal/thousands separators, factorial roundoff, memory, history ও state restoration আছে।

প্রতিটি exposed function-এর button wiring আলাদাভাবে পরীক্ষা করা হয়েছে। `test/all_functions_test.dart`-এ 54টি অতিরিক্ত test আছে: সাধারণ/inverse trig DEG ও RAD-এ, ln/log, eˣ/10ˣ, square/cube/root, reciprocal/absolute value, factorial, percentage/sign, সব digits/operators, power/parentheses/constants/Ans, memory, delete/held delete, clipboard, history edit/copy/clear এবং settings feedback। Domain error ও overflow inputs-এ ভুল result save না করে error দেখানো হয় কি না-ও পরীক্ষা করা হয়েছে। Function buttons শেষ operand-এ কাজ করে; যেমন পুরো π/2-এর sine চাইলে `sin(π/2)` লিখো অথবা `(π/2)`-কে brackets দিয়ে তারপর sin চাপো।

Responsive tests-এ 240×480, 280×360, 320×568, 360×640, 390×844, 412×915, 480×800, 520×280, 568×320, 640×360, 740×360, 915×412, 600×960, 673×841, 840×1180 এবং 1280×800 logical pixel sizes রাখা হয়েছে। প্রতিটিতে Standard/Scientific mode, dark/light theme এবং 1×/2×/3× text scale পরীক্ষা করা হয়। Tests keypad দিয়ে calculation করে ও calculator-key touch targets কমপক্ষে 48×48 logical pixels কি না দেখে। Short landscape-এ panel/editor flow, keyboard/safe-area insets, screen rotation, 3× pixel density এবং screen-reader tap action-এর checks-ও আছে।

Release APK build সফল হয়েছে এবং APK signature যাচাই করা হয়েছে: version 1.0.1+2, min SDK 24, target/compile SDK 36, arm64-v8a/armeabi-v7a/x86_64। Build environment: JDK 17, Gradle 8.12, AGP 8.9.1 ও Kotlin 2.1.0।

Dark/light portrait, scientific এবং landscape UI Flutter থেকে render করে দেখা হয়েছে। Physical Android phone বা Android Studio GUI-তে পরীক্ষা করা হয়নি; সব device/OS combination-এ শতভাগ bug-free হওয়ার নিশ্চয়তা এই checks দেয় না।

Source code-এ comments নেই। শুধু Android project রাখা হয়েছে; SDK, IDE cache, build output ও APK project ZIP-এর অংশ নয়।
