import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/master_quest.dart';
import 'master_quest_catalog_service.dart';
import 'profile_service.dart';

class QuestRecommendationService {
  final ProfileService _profileService = ProfileService();

  final MasterQuestCatalogService _catalogService = MasterQuestCatalogService();

  // Fixed category order for balanced recommendations.
  static const List<MasterQuestCategory> _categoryOrder = [
    MasterQuestCategory.walkingJogging,
    MasterQuestCategory.cafeExploration,
    MasterQuestCategory.photography,
    MasterQuestCategory.reset,
  ];

  // Map Firebase interests to Master Quest categories.
  static const Map<MasterQuestCategory, List<String>> _categoryInterests = {
    MasterQuestCategory.walkingJogging: [
      'running',
      'jogging',
      'walking',
      'walking/jogging',
      'walking & jogging',
      'walking / jogging',
      'running/jogging',
      'running / jogging',
    ],
    MasterQuestCategory.cafeExploration: [
      'cafe',
      'café',
      'cafe exploration',
      'café exploration',
    ],
    MasterQuestCategory.photography: ['photography', 'photo'],
    MasterQuestCategory.reset: [
      'mindfulness',
      'reset',
      'mindfulness/reset',
      'mindfulness / reset',
    ],
  };

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Set<String> _readInterests(dynamic value) {
    if (value is! List) {
      return <String>{};
    }

    return value
        .map((item) => _normalize(item.toString()))
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  int _readInt(dynamic value, int fallback) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value.trim()) ?? fallback;
    }

    return fallback;
  }

  bool _matchesInterest(MasterQuest quest, Set<String> interests) {
    final aliases = _categoryInterests[quest.category];

    if (aliases == null) {
      return false;
    }

    return aliases.any((alias) => interests.contains(_normalize(alias)));
  }

  bool _matchesDifficulty(MasterQuest quest, String activityLevel) {
    final difficulty = _normalize(quest.difficulty);
    final activity = _normalize(activityLevel);

    if (!['easy', 'medium', 'hard'].contains(difficulty)) {
      return false;
    }

    // Beginner users receive Easy quests.
    if (activity == 'beginner' ||
        activity == 'just getting started' ||
        activity == 'new to activity') {
      return difficulty == 'easy';
    }

    // Occasionally active users receive Easy and Medium.
    if (activity == 'occasional' || activity == 'occasionally active') {
      return difficulty == 'easy' || difficulty == 'medium';
    }

    // Fairly consistent users receive all difficulties.
    if (activity == 'consistent' ||
        activity == 'fairly consistent' ||
        activity == 'very active' ||
        activity == 'active' ||
        activity == 'advanced') {
      return true;
    }

    // Safe default for unknown activity values.
    return difficulty == 'easy';
  }

  int _difficultyRank(MasterQuest quest) {
    switch (_normalize(quest.difficulty)) {
      case 'easy':
        return 0;
      case 'medium':
        return 1;
      case 'hard':
        return 2;
      default:
        return 3;
    }
  }

  int _durationDifference(MasterQuest quest, int preferredMinutes) {
    return (quest.estimatedMinutes - preferredMinutes).abs();
  }

  Future<List<MasterQuest>> recommend() async {
    // STEP 1: Read logged-in user's Firebase profile.
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _profileService.watchProfile().first;

    final profile = snapshot.data();

    if (profile == null) {
      throw StateError('User profile not found in Firestore.');
    }

    final interests = _readInterests(profile['interests']);

    final activityLevel = profile['activityLevel']?.toString() ?? '';

    final preferredMinutes = _readInt(profile['preferredMinutes'], 20);

    final weeklyTarget = _readInt(profile['weeklyTarget'], 3);

    if (interests.isEmpty) {
      return <MasterQuest>[];
    }

    // STEP 2: Load quests only from JSON.
    final allQuests = await _catalogService.loadQuests();

    // STEP 3: Filter by selected interests,
    // activity level and approval status.
    final matchingQuests = allQuests.where((quest) {
      if (!_matchesInterest(quest, interests)) {
        return false;
      }

      if (!_matchesDifficulty(quest, activityLevel)) {
        return false;
      }

      // Do not recommend rejected or retired quests.
      if (quest.approvalStatus == QuestApprovalStatus.rejected ||
          quest.approvalStatus == QuestApprovalStatus.retired) {
        return false;
      }

      return true;
    }).toList();

    if (matchingQuests.isEmpty) {
      return <MasterQuest>[];
    }

    // STEP 4: Sort quests by duration similarity.
    //
    // For example, if the user prefers 60 minutes:
    // 60 min -> highest duration match
    // 55 min -> next
    // 45 min -> after that
    //
    // Difficulty and ID break ties.
    matchingQuests.sort((a, b) {
      final aDifference = _durationDifference(a, preferredMinutes);

      final bDifference = _durationDifference(b, preferredMinutes);

      final durationComparison = aDifference.compareTo(bDifference);

      if (durationComparison != 0) {
        return durationComparison;
      }

      final difficultyComparison = _difficultyRank(
        a,
      ).compareTo(_difficultyRank(b));

      if (difficultyComparison != 0) {
        return difficultyComparison;
      }

      return a.id.compareTo(b.id);
    });

    // STEP 5: Group matching quests by category.
    //
    // The quests inside each category remain sorted
    // by duration and difficulty.
    final categoryQueues = <MasterQuestCategory, List<MasterQuest>>{};

    for (final quest in matchingQuests) {
      categoryQueues
          .putIfAbsent(quest.category, () => <MasterQuest>[])
          .add(quest);
    }

    // STEP 6: Use only categories with matching quests.
    final activeCategories = _categoryOrder
        .where(categoryQueues.containsKey)
        .toList();

    // STEP 7: Limit the result using the weekly target.
    final limit = weeklyTarget.clamp(1, 20).toInt();

    // STEP 8: Alternate categories (round-robin).
    //
    // For Walking/Jogging + Café Exploration,
    // the selection becomes:
    //
    // Walking -> Café -> Walking -> Café -> Walking
    //
    // This prevents all five recommendations from
    // coming from one category.
    final recommendations = <MasterQuest>[];

    while (recommendations.length < limit &&
        categoryQueues.values.any((queue) => queue.isNotEmpty)) {
      for (final category in activeCategories) {
        final queue = categoryQueues[category]!;

        if (queue.isEmpty) {
          continue;
        }

        recommendations.add(queue.removeAt(0));

        if (recommendations.length >= limit) {
          break;
        }
      }
    }

    return recommendations;
  }
}
