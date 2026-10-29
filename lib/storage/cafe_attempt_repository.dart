import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CafeAttemptRepository {
  static const key = 'pogetit_cafe_attempts_v1';
  Future<void> save(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(key) ?? <String>[];
    entries.add(jsonEncode(record));
    if (!await prefs.setStringList(key, entries))
      throw StateError('Could not save cafe attempt.');
  }

  Future<List<Map<String, dynamic>>> all() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(key) ?? <String>[]).reversed
        .map((e) => Map<String, dynamic>.from(jsonDecode(e) as Map))
        .toList();
  }
}
