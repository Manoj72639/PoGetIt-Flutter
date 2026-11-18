import '../models/day3_quest.dart';
import '../models/master_quest.dart';

class PhotographyQuestConfig {
  final Day3Quest quest;
  final MasterQuest master;
  final bool countConfigured;
  final bool requiresReview;
  const PhotographyQuestConfig({
    required this.quest,
    required this.master,
    required this.countConfigured,
    required this.requiresReview,
  });
}

class MasterPhotographyQuestAdapter {
  static PhotographyQuestConfig parse(MasterQuest master) {
    if (master.category != MasterQuestCategory.photography) {
      throw ArgumentError('Not a photography quest: ${master.id}');
    }
    int? count;
    // Only accept explicit structured counts. Do not guess from prose.
    for (final rule in master.rules) {
      final type = rule.type.toLowerCase();
      if (type.contains('photo') ||
          type.contains('image') ||
          type.contains('evidence')) {
        for (final key in [
          'requiredPhotos',
          'photoCount',
          'minPhotos',
          'minCount',
          'count',
        ]) {
          final raw = rule.parameters[key];
          final value = raw is num ? raw.toInt() : int.tryParse('$raw');
          if (value != null && value > 0) {
            count = count == null ? value : (value > count ? value : count);
          }
        }
      }
    }
    final needsReview =
        master.rules.any((r) => r.requiresReview) ||
        master.rules.any(
          (r) => ![
            'photo_count',
            'image_count',
            'min_photos',
            'required_photos',
          ].contains(r.type.toLowerCase()),
        ) ||
        master.verificationMode.toLowerCase().contains('review') ||
        master.validationMethod.toLowerCase().contains('review') ||
        master.evidenceRule.trim().isNotEmpty ||
        master.successCondition.trim().isNotEmpty;
    return PhotographyQuestConfig(
      master: master,
      countConfigured: count != null,
      requiresReview: needsReview || count == null,
      quest: Day3Quest(
        id: master.id,
        title: master.title,
        difficulty: master.difficulty,
        instructions: master.instructions.isNotEmpty
            ? master.instructions
            : master.description,
        category: Day3Category.photography,
        requiredPhotos: count ?? 0,
      ),
    );
  }
}
