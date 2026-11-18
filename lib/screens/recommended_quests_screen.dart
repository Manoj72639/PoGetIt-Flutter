import 'package:flutter/material.dart';

import '../adapter/master_quest_adapter.dart';
import '../adapter/master_cafe_quest_adapter.dart';
import '../models/master_quest.dart';
import '../services/profile_service.dart';
import '../services/quest_recommendation_service.dart';

import 'running_screen.dart';
import 'master_cafe_screen.dart';
import 'master_quest_list_screen.dart';

class RecommendedQuestsScreen extends StatefulWidget {
  const RecommendedQuestsScreen({super.key});

  @override
  State<RecommendedQuestsScreen> createState() =>
      _RecommendedQuestsScreenState();
}

class _RecommendedQuestsScreenState extends State<RecommendedQuestsScreen> {
  final QuestRecommendationService _recommendationService =
      QuestRecommendationService();

  final ProfileService _profileService = ProfileService();

  late Future<List<MasterQuest>> _recommendations;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  void _loadRecommendations() {
    _recommendations = _recommendationService.recommend();
  }

  void _refreshRecommendations() {
    setState(_loadRecommendations);
  }

  IconData _categoryIcon(MasterQuestCategory category) {
    switch (category) {
      case MasterQuestCategory.walkingJogging:
        return Icons.directions_run;

      case MasterQuestCategory.cafeExploration:
        return Icons.local_cafe_outlined;

      case MasterQuestCategory.photography:
        return Icons.camera_alt_outlined;

      case MasterQuestCategory.reset:
        return Icons.self_improvement;
    }
  }

  String _categoryName(MasterQuestCategory category) {
    switch (category) {
      case MasterQuestCategory.walkingJogging:
        return 'Walking/Jogging';

      case MasterQuestCategory.cafeExploration:
        return 'Café Exploration';

      case MasterQuestCategory.photography:
        return 'Photography';

      case MasterQuestCategory.reset:
        return 'Mindfulness';
    }
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.trim().toLowerCase()) {
      case 'easy':
        return Colors.green;

      case 'medium':
        return Colors.orange;

      case 'hard':
        return Colors.red;

      default:
        return Colors.blueGrey;
    }
  }

  String? _executionIssue(MasterQuest quest) {
    try {
      switch (quest.category) {
        case MasterQuestCategory.walkingJogging:
          if (MasterQuestAdapter.usesGpsAndSteps(quest)) {
            MasterQuestAdapter.toGpsStepsQuest(quest);
          } else {
            MasterQuestAdapter.toRunningQuest(quest);
          }
          return null;
        case MasterQuestCategory.cafeExploration:
          MasterCafeQuestAdapter.parse(quest);
          return null;
        case MasterQuestCategory.photography:
          return 'Photography quest execution is not yet integrated.';
        case MasterQuestCategory.reset:
          return 'Mindfulness quest execution is not yet integrated.';
      }
    } on UnsupportedCafeRule catch (e) {
      return e.message;
    } on UnsupportedMasterQuestException catch (e) {
      return e.message;
    } catch (e) {
      return 'Unable to prepare quest: $e';
    }
  }

  Future<void> _startQuest(MasterQuest quest) async {
    final issue = _executionIssue(quest);

    if (issue != null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(issue), duration: const Duration(seconds: 4)),
      );
      return;
    }

    try {
      switch (quest.category) {
        case MasterQuestCategory.walkingJogging:
          if (MasterQuestAdapter.usesGpsAndSteps(quest)) {
            final config = MasterQuestAdapter.toGpsStepsQuest(quest);
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RunningScreen(
                  quest: config.runningQuest,
                  requiredSteps: config.requiredSteps,
                  requiresTaskDeclaration: config.requiresTaskDeclaration,
                ),
              ),
            );
          } else {
            final runningQuest = MasterQuestAdapter.toRunningQuest(quest);
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RunningScreen(quest: runningQuest),
              ),
            );
          }
          break;

        case MasterQuestCategory.cafeExploration:
          final config = MasterCafeQuestAdapter.parse(quest);
          await Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => MasterCafeScreen(config: config),
            ),
          );
          break;

        case MasterQuestCategory.photography:
        case MasterQuestCategory.reset:
          return;
      }
    } on UnsupportedCafeRule catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } on UnsupportedMasterQuestException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to start quest: $e')));
    }
  }

  void _showQuestDetails(MasterQuest quest) {
    final issue = _executionIssue(quest);
    final canStart = issue == null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: FractionallySizedBox(
            heightFactor: 0.85,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                    children: [
                      Text(
                        quest.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_categoryName(quest.category)}'
                        ' • ${quest.difficulty}'
                        ' • ${quest.estimatedMinutes} min',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Quest ID: ${quest.id}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Version: ${quest.version}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Divider(height: 28),
                      if (quest.description.trim().isNotEmpty) ...[
                        _sectionTitle('Description'),
                        Text(quest.description),
                        const SizedBox(height: 16),
                      ],
                      if (quest.instructions.trim().isNotEmpty) ...[
                        _sectionTitle('Instructions'),
                        Text(quest.instructions),
                        const SizedBox(height: 16),
                      ],
                      if (quest.successCondition.trim().isNotEmpty) ...[
                        _sectionTitle('Success condition'),
                        Text(quest.successCondition),
                        const SizedBox(height: 16),
                      ],
                      if (quest.evidenceRule.trim().isNotEmpty) ...[
                        _sectionTitle('Required evidence'),
                        Text(quest.evidenceRule),
                        const SizedBox(height: 16),
                      ],
                      if (quest.validationThreshold.trim().isNotEmpty) ...[
                        _sectionTitle('Validation threshold'),
                        Text(quest.validationThreshold),
                        const SizedBox(height: 16),
                      ],
                      if (quest.verificationMode.trim().isNotEmpty) ...[
                        _sectionTitle('Verification mode'),
                        Text(quest.verificationMode),
                        const SizedBox(height: 16),
                      ],
                      if (quest.safetyNotes.trim().isNotEmpty) ...[
                        _sectionTitle('Safety notes'),
                        Text(quest.safetyNotes),
                        const SizedBox(height: 16),
                      ],
                      if (issue != null) ...[
                        const Divider(height: 28),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Colors.deepOrange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                issue,
                                style: const TextStyle(
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: canStart
                          ? () {
                              Navigator.pop(sheetContext);
                              _startQuest(quest);
                            }
                          : null,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        canStart ? 'Start Quest' : 'Execution Not Available',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _profileHeader() {
    return StreamBuilder(
      stream: _profileService.watchProfile(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final name = (data?['name'] ?? 'Explorer').toString().trim();

        final weeklyTarget = (data?['weeklyTarget'] as num?)?.toInt() ?? 3;

        final preferredMinutes =
            (data?['preferredMinutes'] as num?)?.toInt() ?? 20;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, ${name.isEmpty ? 'Explorer' : name}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Weekly goal: $weeklyTarget quests'
                ' • Preferred: $preferredMinutes min',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _questCard(MasterQuest quest) {
    final difficultyColor = _difficultyColor(quest.difficulty);

    final canStart = _executionIssue(quest) == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showQuestDetails(quest),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 21,
                child: Icon(_categoryIcon(quest.category), size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_categoryName(quest.category)}'
                      ' • ${quest.estimatedMinutes} min',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _smallTag(quest.difficulty, difficultyColor),
                        if (canStart)
                          _smallTag('Ready', Colors.green)
                        else
                          _smallTag('Preview', Colors.blueGrey),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended Quests'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshRecommendations,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'library') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MasterQuestListScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'library',
                child: Text('Master Quest Library'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: _profileHeader(),
            ),
            Expanded(
              child: FutureBuilder<List<MasterQuest>>(
                future: _recommendations,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 40),
                            const SizedBox(height: 12),
                            Text(
                              'Unable to load recommendations:\n'
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _refreshRecommendations,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final quests = snapshot.data ?? <MasterQuest>[];

                  if (quests.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.explore_outlined, size: 40),
                            const SizedBox(height: 12),
                            const Text(
                              'No matching quests found.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Check your selected interests '
                              'and try refreshing.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _refreshRecommendations,
                              child: const Text('Refresh'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _refreshRecommendations();
                      await _recommendations;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                      itemCount: quests.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '${quests.length} recommended quests',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          );
                        }

                        return _questCard(quests[index - 1]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
