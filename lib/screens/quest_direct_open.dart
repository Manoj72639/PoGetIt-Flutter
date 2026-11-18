import 'package:flutter/material.dart';

import '../adapter/master_cafe_quest_adapter.dart';
import '../adapter/master_photography_quest_adapter.dart';
import '../adapter/master_mindfulness_quest_adapter.dart';
import '../adapter/master_quest_adapter.dart';
import '../models/master_quest.dart';
import 'master_cafe_screen.dart';
import 'day3_photography_screen.dart';
import 'day3_reset_screen.dart';
import 'running_screen.dart';

/// Opens the selected catalog quest, never a generic list page.
/// Unsupported quest types show their own details rather than silently
/// routing to an unrelated quest.
Future<void> openSelectedQuest(BuildContext context, MasterQuest quest) async {
  try {
    switch (quest.category) {
      case MasterQuestCategory.walkingJogging:
        if (MasterQuestAdapter.usesGpsAndSteps(quest)) {
          final config = MasterQuestAdapter.toGpsStepsQuest(quest);
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => RunningScreen(
                quest: config.runningQuest,
                requiredSteps: config.requiredSteps,
                requiresTaskDeclaration: config.requiresTaskDeclaration,
                requiresReview: config.requiresReview,
              ),
            ),
          );
        } else {
          final runningQuest = MasterQuestAdapter.toRunningQuest(quest);
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => RunningScreen(quest: runningQuest),
            ),
          );
        }
        return;
      case MasterQuestCategory.cafeExploration:
        final config = MasterCafeQuestAdapter.parse(quest);
        if (!context.mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => MasterCafeScreen(config: config),
          ),
        );
        return;
      case MasterQuestCategory.photography:
        final config = MasterPhotographyQuestAdapter.parse(quest);
        if (!context.mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => Day3PhotographyScreen(
              quest: config.quest,
              masterConfig: config,
            ),
          ),
        );
        return;
      case MasterQuestCategory.reset:
        final config = MasterMindfulnessQuestAdapter.parse(quest);
        if (!context.mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) =>
                Day3ResetScreen(quest: config.quest, masterConfig: config),
          ),
        );
        return;
    }
  } catch (error) {
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _QuestDetailsScreen(
          quest: quest,
          issue: 'Quest cannot start: $error',
        ),
      ),
    );
  }
}

class _QuestDetailsScreen extends StatelessWidget {
  const _QuestDetailsScreen({required this.quest, required this.issue});
  final MasterQuest quest;
  final String issue;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quest details')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(quest.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          '${quest.id} · ${quest.difficulty} · ${quest.estimatedMinutes} min',
        ),
        const SizedBox(height: 24),
        if (quest.description.trim().isNotEmpty) ...[
          const Text(
            'Description',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(quest.description),
          const SizedBox(height: 20),
        ],
        if (quest.instructions.trim().isNotEmpty) ...[
          const Text(
            'Instructions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(quest.instructions),
          const SizedBox(height: 20),
        ],
        if (quest.successCondition.trim().isNotEmpty) ...[
          const Text(
            'Success condition',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(quest.successCondition),
          const SizedBox(height: 20),
        ],
        const Divider(),
        Text(issue, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
