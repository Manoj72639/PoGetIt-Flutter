import '../models/quest_profile.dart';

enum QuestDifficulty { easy, medium, hard }

class QuestSuggestion {
  final String id;
  final String title;
  final String category;
  final QuestDifficulty difficulty;
  final int? estimatedMinutes;

  const QuestSuggestion(
    this.id,
    this.title,
    this.category,
    this.difficulty,
    this.estimatedMinutes,
  );
}

// Quest durations are recommendation estimates.
// They are not quest validation requirements.
// Null means no reliable duration estimate is available.
const questCatalog = <QuestSuggestion>[
  // Day 1 - Running / Jogging
  QuestSuggestion(
    'RUN-01',
    'The 7-Minute Escape',
    'running',
    QuestDifficulty.easy,
    7,
  ),
  QuestSuggestion(
    'RUN-02',
    "The Explorer's Loop",
    'running',
    QuestDifficulty.medium,
    12,
  ),
  QuestSuggestion(
    'RUN-03',
    'The Momentum Challenge',
    'running',
    QuestDifficulty.hard,
    null,
  ),

  // Day 2 - Cafe Exploration
  QuestSuggestion(
    'CE-E001',
    'Coffee Break Outside',
    'cafe',
    QuestDifficulty.easy,
    20,
  ),
  QuestSuggestion(
    'CE-E008',
    'Quiet Corner',
    'cafe',
    QuestDifficulty.medium,
    20,
  ),
  QuestSuggestion(
    'CE-H001',
    'Three Café Expedition',
    'cafe',
    QuestDifficulty.hard,
    null,
  ),

  // Day 3 - Photography
  QuestSuggestion(
    'PHOTO-E001',
    'Bench Portrait',
    'photography',
    QuestDifficulty.easy,
    15,
  ),
  QuestSuggestion(
    'PHOTO-M001',
    'One-Object Reinvention',
    'photography',
    QuestDifficulty.medium,
    20,
  ),
  QuestSuggestion(
    'PHOTO-H001',
    'Street Story in Five Frames',
    'photography',
    QuestDifficulty.hard,
    30,
  ),

  // Day 3 - Mindfulness / Reset
  QuestSuggestion(
    'RESET-E001',
    'Bedside Reset',
    'mindfulness',
    QuestDifficulty.easy,
    5,
  ),
  QuestSuggestion(
    'RESET-M001',
    'Handwritten Words',
    'mindfulness',
    QuestDifficulty.medium,
    15,
  ),
  QuestSuggestion(
    'RESET-H001',
    'Two-Option Pause',
    'mindfulness',
    QuestDifficulty.hard,
    null,
  ),
];

class QuestRecommendationService {
  static const categoryOrder = [
    'running',
    'cafe',
    'photography',
    'mindfulness',
  ];

  List<QuestSuggestion> recommend(
    QuestProfile profile, {
    Set<String> validEasyRunningQuestIds = const {},
  }) {
    // Only known Easy Running quest IDs can
    // contribute to progression.
    final validEasyIds = questCatalog
        .where(
          (quest) =>
              quest.category == 'running' &&
              quest.difficulty == QuestDifficulty.easy,
        )
        .map((quest) => quest.id)
        .toSet();

    // Unlock Medium Running after two distinct,
    // valid Easy Running quests.
    final mediumRunningUnlocked =
        validEasyRunningQuestIds.intersection(validEasyIds).length >= 2;

    // Step 1 - Filter quests.
    final matches = questCatalog.where((quest) {
      // Only recommend selected interests.
      if (!profile.interests.contains(quest.category)) {
        return false;
      }

      // Exclude quests longer than the user's
      // preferred maximum duration.
      if (quest.estimatedMinutes != null &&
          quest.estimatedMinutes! > profile.maxMinutes) {
        return false;
      }

      // Beginners start with Easy quests.
      if (profile.activityLevel == 'beginner') {
        if (quest.difficulty == QuestDifficulty.hard) {
          return false;
        }

        if (quest.difficulty == QuestDifficulty.medium) {
          return quest.category == 'running' && mediumRunningUnlocked;
        }
      }

      // Occasionally active users receive
      // Easy and Medium quests.
      if (profile.activityLevel == 'occasional' &&
          quest.difficulty == QuestDifficulty.hard) {
        return false;
      }

      // Consistent users may receive all
      // difficulty levels.
      return true;
    }).toList();

    // Step 2 - Sort from Easy to Hard.
    matches.sort((a, b) => a.difficulty.index.compareTo(b.difficulty.index));

    // Step 3 - Use a stable category order.
    final activeCategories = categoryOrder
        .where((category) => profile.interests.contains(category))
        .toList();

    // Step 4 - Group matching quests by category.
    final queues = <String, List<QuestSuggestion>>{
      for (final category in activeCategories)
        category: matches.where((quest) => quest.category == category).toList(),
    };

    // Step 5 - Alternate categories so mixed-interest
    // profiles receive a balanced list.
    final results = <QuestSuggestion>[];

    while (queues.values.any((items) => items.isNotEmpty)) {
      for (final category in activeCategories) {
        final items = queues[category]!;

        if (items.isNotEmpty) {
          results.add(items.removeAt(0));
        }
      }
    }

    return results;
  }
}
