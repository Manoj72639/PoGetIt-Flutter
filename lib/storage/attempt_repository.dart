import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../validators/running_validator.dart';

class AttemptRepository {
  // Keep the existing key to preserve saved attempts.
  static const String _key = 'pogetit_running_attempts_v1';

  Future<void> save({
    required String questId,
    required int seconds,
    required double metres,
    required ValidationResult result,
    double? finishFromStartMetres,

    // New GPS + Steps fields.
    int? questSteps,
    double? requiredGpsMetres,
    int? requiredSteps,
    bool? taskDeclared,
    bool? gpsReliable,
    bool? stepsReliable,
    bool? requiresReview,
    String? taskNotes,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final entries = prefs.getStringList(_key) ?? <String>[];

    final attempt = <String, dynamic>{
      'questId': questId,
      'timestamp': DateTime.now().toIso8601String(),
      'seconds': seconds,
      'metres': metres,
      'finishFromStartMetres': finishFromStartMetres,
      'status': result.status.name,
      'reason': result.reason,

      // New fields are optional for legacy quests.
      'questSteps': questSteps,
      'requiredGpsMetres': requiredGpsMetres,
      'requiredSteps': requiredSteps,
      'taskDeclared': taskDeclared,
      'gpsReliable': gpsReliable,
      'stepsReliable': stepsReliable,
      'requiresReview': requiresReview,
      'taskNotes': taskNotes,
    };

    entries.add(jsonEncode(attempt));

    final saved = await prefs.setStringList(_key, entries);

    if (!saved) {
      throw StateError('Unable to save quest attempt.');
    }
  }

  Future<List<Map<String, dynamic>>> all() async {
    final prefs = await SharedPreferences.getInstance();

    final entries = prefs.getStringList(_key) ?? <String>[];

    final attempts = <Map<String, dynamic>>[];

    // Newest attempts first.
    for (final item in entries.reversed) {
      try {
        final decoded = jsonDecode(item);

        if (decoded is Map) {
          attempts.add(Map<String, dynamic>.from(decoded));
        }
      } on FormatException {
        // Skip corrupted entries without losing
        // access to other saved attempts.
        continue;
      } on TypeError {
        continue;
      }
    }

    return attempts;
  }
}
