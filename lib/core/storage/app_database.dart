import 'package:hive_ce_flutter/hive_flutter.dart';

/// Initializes the local Hive database and exposes the app's key-value table.
class AppDatabase {
  AppDatabase._();

  static const String _boxName = 'app_preferences';
  static Box<dynamic>? _box;

  static Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  static Box<dynamic> get _preferences {
    final Box<dynamic>? box = _box;
    if (box == null || !box.isOpen) {
      throw StateError('AppDatabase.initialize() must complete first.');
    }
    return box;
  }

  static String? readString(String key) {
    return _preferences.get(key) as String?;
  }

  static Future<void> writeString(String key, String value) {
    return _preferences.put(key, value);
  }

  static Future<void> delete(String key) {
    return _preferences.delete(key);
  }
}
