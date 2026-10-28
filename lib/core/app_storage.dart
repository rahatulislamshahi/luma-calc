import 'dart:convert';

import 'package:flutter/services.dart';

abstract interface class AppStorage {
  Future<Map<String, Object?>> read();
  Future<void> write(Map<String, Object?> state);
}

class DeviceStorage implements AppStorage {
  static const _channel = MethodChannel('app.luma.calculator/storage');

  @override
  Future<Map<String, Object?>> read() async {
    try {
      final value = await _channel.invokeMethod<String>('read');
      if (value == null) return {};
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : {};
    } on Object {
      return {};
    }
  }

  @override
  Future<void> write(Map<String, Object?> state) async {
    await _channel.invokeMethod<void>('write', jsonEncode(state));
  }
}
