import '../models/day3_quest.dart';
import '../models/master_quest.dart';

/// A conservative bridge: prose and estimated duration are not proof of
/// required session counts or successful completion.
class MindfulnessQuestConfig {
  final MasterQuest master;
  final Day3Quest quest;
  final bool requiresReview;
  const MindfulnessQuestConfig({
    required this.master,
    required this.quest,
    this.requiresReview = true,
  });
}

class MasterMindfulnessQuestAdapter {
  static MindfulnessQuestConfig parse(MasterQuest master) {
    if (master.category != MasterQuestCategory.reset) {
      throw ArgumentError('Not a Reset quest: ${master.id}');
    }
    return MindfulnessQuestConfig(
      master: master,
      quest: Day3Quest(
        id: master.id,
        title: master.title,
        difficulty: master.difficulty,
        instructions: master.instructions.trim().isNotEmpty
            ? master.instructions
            : master.description,
        category: Day3Category.mindfulness,
        // Do not infer session count from estimatedMinutes or prose.
        requiredSessions: 0,
      ),
    );
  }
}
