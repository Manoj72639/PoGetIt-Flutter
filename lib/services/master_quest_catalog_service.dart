import 'dart:convert';

import 'package:flutter/services.dart';
import '../models/master_quest.dart';

class MasterQuestCatalogService {
  static const String assetPath = 'assets/data/quest_catalog.json';

  List<MasterQuest>? _cache;

  Future<List<MasterQuest>> loadQuests({bool refresh = false}) async {
    if (!refresh && _cache != null) {
      return List<MasterQuest>.unmodifiable(_cache!);
    }

    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Quest catalog must be a JSON array.');
    }

    final quests = <MasterQuest>[];
    final ids = <String>{};
    for (final entry in decoded) {
      if (entry is! Map) {
        throw const FormatException('Quest catalog entry must be an object.');
      }
      final quest = MasterQuest.fromMap(Map<String, dynamic>.from(entry));
      if (quest.id.isEmpty || quest.title.isEmpty || !ids.add(quest.id)) {
        throw FormatException('Invalid or duplicate quest: ${quest.id}');
      }
      quests.add(quest);
    }
    _cache = quests;
    return List<MasterQuest>.unmodifiable(quests);
  }

  Future<List<MasterQuest>> byCategory(MasterQuestCategory category) async {
    final quests = await loadQuests();
    return quests.where((quest) => quest.category == category).toList();
  }

  Future<MasterQuest?> byId(String id) async {
    final quests = await loadQuests();
    for (final quest in quests) {
      if (quest.id == id) return quest;
    }
    return null;
  }
}
