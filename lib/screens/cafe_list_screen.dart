import 'package:flutter/material.dart';

import '../adapter/master_cafe_quest_adapter.dart';
import '../models/master_quest.dart';
import '../services/master_quest_catalog_service.dart';
import 'master_cafe_screen.dart';

class CafeListScreen extends StatefulWidget {
  const CafeListScreen({super.key});

  @override
  State<CafeListScreen> createState() => _CafeListScreenState();
}

class _CafeListScreenState extends State<CafeListScreen> {
  final MasterQuestCatalogService _catalogService = MasterQuestCatalogService();

  late Future<List<MasterQuest>> _questsFuture;

  String _searchQuery = '';
  String _selectedDifficulty = 'All';

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  void _loadQuests() {
    _questsFuture = _catalogService.byCategory(
      MasterQuestCategory.cafeExploration,
    );
  }

  Future<void> _refreshQuests() async {
    setState(() {
      _questsFuture = _catalogService
          .loadQuests(refresh: true)
          .then(
            (quests) => quests
                .where(
                  (quest) =>
                      quest.category == MasterQuestCategory.cafeExploration,
                )
                .toList(),
          );
    });

    await _questsFuture;
  }

  void _openQuest(MasterQuest quest) {
    try {
      final config = MasterCafeQuestAdapter.parse(quest);

      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => MasterCafeScreen(config: config),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open quest: $error')));
    }
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
      case 'basic':
        return Colors.green;

      case 'medium':
      case 'intermediate':
        return Colors.orange;

      case 'hard':
      case 'advanced':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  List<MasterQuest> _filterQuests(List<MasterQuest> quests) {
    return quests.where((quest) {
      final query = _searchQuery.toLowerCase();

      final matchesSearch =
          quest.title.toLowerCase().contains(query) ||
          quest.id.toLowerCase().contains(query) ||
          quest.description.toLowerCase().contains(query) ||
          quest.instructions.toLowerCase().contains(query);

      final matchesDifficulty =
          _selectedDifficulty == 'All' ||
          quest.difficulty.toLowerCase() == _selectedDifficulty.toLowerCase();

      return matchesSearch && matchesDifficulty;
    }).toList();
  }

  Widget _buildQuestCard(MasterQuest quest) {
    final color = _difficultyColor(quest.difficulty);

    final description = quest.description.trim().isNotEmpty
        ? quest.description
        : quest.instructions;

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openQuest(quest),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_cafe_outlined,
                    color: Colors.brown,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      quest.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      quest.difficulty.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (quest.estimatedMinutes > 0) ...[
                    Icon(
                      Icons.schedule_outlined,
                      size: 15,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${quest.estimatedMinutes} min',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    quest.id,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Cafe Exploration',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh quests',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refreshQuests();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<MasterQuest>>(
        future: _questsFuture,
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
                    const Icon(
                      Icons.error_outline,
                      size: 42,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Unable to load Cafe quests.\n'
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _refreshQuests,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final allQuests = snapshot.data ?? <MasterQuest>[];

          final filteredQuests = _filterQuests(allQuests);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search Cafe quests...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${filteredQuests.length} of '
                        '${allQuests.length} quests',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    DropdownButton<String>(
                      value: _selectedDifficulty,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: 'All',
                          child: Text('All levels'),
                        ),
                        DropdownMenuItem(value: 'Easy', child: Text('Easy')),
                        DropdownMenuItem(
                          value: 'Medium',
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(value: 'Hard', child: Text('Hard')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _selectedDifficulty = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredQuests.isEmpty
                    ? const Center(child: Text('No Cafe quests found.'))
                    : RefreshIndicator(
                        onRefresh: _refreshQuests,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredQuests.length,
                          itemBuilder: (context, index) {
                            return _buildQuestCard(filteredQuests[index]);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
