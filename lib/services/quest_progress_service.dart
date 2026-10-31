import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Local-only prototype. Production XP needs an atomic server transaction.
class QuestProgressService {
  static const _key = 'pogetit_progress_v1';

  Future<Map<String,dynamic>> read() async {
    final p = await SharedPreferences.getInstance();
    return Map<String,dynamic>.from(jsonDecode(p.getString(_key) ??
      '{"xp":0,"awards":{},"easyRunningIds":[]}') as Map);
  }

  Future<bool> recordValidCompletion({required String completionId,
    required String questId, required bool valid, required int xp}) async {
    if (!valid || completionId.isEmpty || xp < 0) return false;
    final p = await SharedPreferences.getInstance();
    final state = await read();
    final awards = Map<String,dynamic>.from(state['awards'] as Map);
    if (awards.containsKey(completionId)) return false;
    awards[completionId] = {'questId': questId, 'xp': xp};
    final easyIds = (state['easyRunningIds'] as List).cast<String>().toSet();
    // The current running catalog contains only one Easy quest.
    if (questId == 'RUN-01') easyIds.add(questId);
    state['awards'] = awards;
    state['easyRunningIds'] = easyIds.toList();
    state['xp'] = (state['xp'] as int) + xp;
    if (!await p.setString(_key, jsonEncode(state))) return false;
    return true;
  }
}
