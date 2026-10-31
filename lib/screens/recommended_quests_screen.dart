import 'package:flutter/material.dart';

import '../models/quest_profile.dart';
import '../models/day3_quest.dart';
import '../models/running_quest.dart';
import '../models/cafe_quest.dart';

import '../services/quest_recommendation_service.dart';
import '../services/quest_progress_service.dart';

import 'running_screen.dart';
import 'cafe_screen.dart';
import 'day3_photography_screen.dart';
import 'day3_reset_screen.dart';
import 'home_screen.dart';
import 'all_quests_screen.dart';

class RecommendedQuestsScreen extends StatefulWidget {
  final QuestProfile profile;

  const RecommendedQuestsScreen({super.key, required this.profile});

  @override
  State<RecommendedQuestsScreen> createState() =>
      _RecommendedQuestsScreenState();
}

class _RecommendedQuestsScreenState extends State<RecommendedQuestsScreen> {
  late Future<Map<String, dynamic>> _progress;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _progress = QuestProgressService().read();
  }

  Future<void> _open(QuestSuggestion suggestion) async {
    try {
      late final Widget page;

      switch (suggestion.category) {
        case 'running':
          final quest = runningQuests.firstWhere(
            (item) => item.id == suggestion.id,
          );

          page = RunningScreen(quest: quest);
          break;

        case 'cafe':
          final quest = cafeQuests.firstWhere(
            (item) => item.id == suggestion.id,
          );

          page = CafeScreen(quest: quest);
          break;

        case 'photography':
          final quest = day3Quests.firstWhere(
            (item) => item.id == suggestion.id,
          );

          page = Day3PhotographyScreen(quest: quest);
          break;

        case 'mindfulness':
          final quest = day3Quests.firstWhere(
            (item) => item.id == suggestion.id,
          );

          page = Day3ResetScreen(quest: quest);
          break;

        default:
          throw StateError('Unknown quest category: ${suggestion.category}');
      }

      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => page),
      );

      if (!mounted) return;

      setState(_refresh);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open quest: $error')));
    }
  }

  void _openHome() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => HomeScreen(profile: widget.profile),
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
            tooltip: 'Day 1 to Day 4',
            icon: const Icon(Icons.apps),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const AllQuestsScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Refresh recommendations',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(_refresh);
            },
          ),
        ],
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        future: _progress,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load quest progress.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        setState(_refresh);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final state = snapshot.data;

          if (state == null) {
            return const Center(child: Text('No progress data available.'));
          }

          final easyIds = ((state['easyRunningIds'] as List?) ?? [])
              .whereType<String>()
              .toSet();

          final xp = state['xp'] ?? 0;

          final suggestions = QuestRecommendationService().recommend(
            widget.profile,
            validEasyRunningQuestIds: easyIds,
          );

          return RefreshIndicator(
            onRefresh: () async {
              setState(_refresh);
              await _progress;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Weekly goal: '
                  '${widget.profile.weeklyGoal} quests',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                // Text(
                //   'Total XP: $xp',
                //   style: const TextStyle(fontSize: 14, color: Colors.teal),
                // ),
                const SizedBox(height: 16),

                const Text(
                  'Recommended for You',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                if (suggestions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No matching quests yet. '
                      'Try a longer duration or another interest.',
                    ),
                  ),

                ...suggestions.map(
                  (quest) => Card(
                    child: ListTile(
                      title: Text(quest.title),

                      subtitle: Text(
                        '${quest.category} • '
                        '${quest.difficulty.name}'
                        '${quest.estimatedMinutes == null ? '' : ' • approx. ${quest.estimatedMinutes} min'}',
                      ),

                      trailing: const Icon(Icons.chevron_right),

                      onTap: () => _open(quest),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Duration estimates are for '
                  'recommendations only. '
                  'Quest validators determine '
                  'actual completion.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
