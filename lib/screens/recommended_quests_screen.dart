import 'package:flutter/material.dart';

import '../models/master_quest.dart';
import '../services/profile_service.dart';
import '../services/quest_recommendation_service.dart';

import 'all_quests_screen.dart';
import 'health_screen.dart';

class RecommendedQuestsScreen extends StatefulWidget {
  const RecommendedQuestsScreen({super.key});

  @override
  State<RecommendedQuestsScreen> createState() =>
      _RecommendedQuestsScreenState();
}

class _RecommendedQuestsScreenState extends State<RecommendedQuestsScreen> {
  final _service = QuestRecommendationService();
  final _profileService = ProfileService();

  late Future<List<MasterQuest>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _service.recommend();
  }

  Future<void> _refresh() async {
    setState(_load);

    try {
      await _future;
    } catch (_) {
      // Error displayed by FutureBuilder.
    }
  }

  String _category(MasterQuestCategory category) {
    switch (category) {
      case MasterQuestCategory.walkingJogging:
        return 'Walking / Jogging';
      case MasterQuestCategory.cafeExploration:
        return 'Café';
      case MasterQuestCategory.photography:
        return 'Photography';
      case MasterQuestCategory.reset:
        return 'Mindfulness';
    }
  }

  IconData _icon(MasterQuestCategory category) {
    switch (category) {
      case MasterQuestCategory.walkingJogging:
        return Icons.directions_walk;
      case MasterQuestCategory.cafeExploration:
        return Icons.local_cafe;
      case MasterQuestCategory.photography:
        return Icons.camera_alt_outlined;
      case MasterQuestCategory.reset:
        return Icons.self_improvement;
    }
  }

  void _showDetails(MasterQuest quest) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: FractionallySizedBox(
            heightFactor: 0.75,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Text(
                  quest.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_category(quest.category)} • '
                  '${quest.difficulty} • '
                  '${quest.estimatedMinutes} min',
                ),
                const Divider(height: 24),
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(quest.description),
                const SizedBox(height: 14),
                const Text(
                  'Instructions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(quest.instructions),
                const SizedBox(height: 14),
                const Text(
                  'Success Condition',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(quest.successCondition),
                const SizedBox(height: 14),
                const Text(
                  'Quest ID',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(quest.id),
                const SizedBox(height: 14),
                const Text(
                  'Preview only — quest validation '
                  'is not enabled yet.',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recommended Quests',
          style: TextStyle(fontSize: 17),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Day 1 to Day 4',
            icon: const Icon(Icons.apps, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const AllQuestsScreen(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'library') {
                Navigator.pushNamed(context, '/master-quests');
              } else if (value == 'health') {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const HealthScreen()),
                );
              } else if (value == 'refresh') {
                setState(_load);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'library',
                child: Text('Master Quest Library'),
              ),
              PopupMenuItem(value: 'health', child: Text('Health Connect')),
              PopupMenuItem(value: 'refresh', child: Text('Refresh')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder(
          stream: _profileService.watchProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return Center(
                child: Text('Profile error: ${profileSnapshot.error}'),
              );
            }

            if (!profileSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final profile = profileSnapshot.data!.data();

            final name = profile?['name']?.toString() ?? 'Explorer';

            final target = (profile?['weeklyTarget'] as num?)?.toInt() ?? 0;

            return FutureBuilder<List<MasterQuest>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Unable to load quests:\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final quests = snapshot.data ?? [];

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: quests.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, $name',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${quests.length} quests • '
                                'Weekly goal: $target',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final quest = quests[index - 1];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          leading: Icon(
                            _icon(quest.category),
                            color: Colors.teal,
                          ),
                          title: Text(
                            quest.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${_category(quest.category)} • '
                            '${quest.difficulty} • '
                            '${quest.estimatedMinutes} min',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () => _showDetails(quest),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
