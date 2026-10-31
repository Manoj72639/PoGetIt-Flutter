import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Day3Repository {
  static const _key = 'pogetit_day3_attempts_v1';

  Future<List<Map<String, dynamic>>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> save(Map<String, dynamic> attempt) async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = await all();
    final index = attempts.indexWhere(
      (e) => e['attemptId'] == attempt['attemptId'],
    );
    if (index < 0) {
      attempts.insert(0, attempt);
    } else {
      attempts[index] = attempt;
    }
    await prefs.setString(_key, jsonEncode(attempts));
  }
}
