import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../validators/running_validator.dart';

class AttemptRepository {
  static const _key = 'pogetit_running_attempts_v1';

  Future<void> save({required String questId, required int seconds,
    required double metres, required ValidationResult result,
    double? finishFromStartMetres}) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(_key) ?? [];
    entries.add(jsonEncode({
      'questId': questId,
      'timestamp': DateTime.now().toIso8601String(),
      'seconds': seconds,
      'metres': metres,
      'finishFromStartMetres': finishFromStartMetres,
      'status': result.status.name,
      'reason': result.reason,
    }));
    await prefs.setStringList(_key, entries);
  }

  Future<List<Map<String, dynamic>>> all() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).reversed
        .map((item) => Map<String, dynamic>.from(jsonDecode(item) as Map))
        .toList();
  }
}
