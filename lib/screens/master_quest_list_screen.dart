import 'package:flutter/material.dart';

import '../models/master_quest.dart';
import '../services/master_quest_catalog_service.dart';

class MasterQuestListScreen extends StatefulWidget {
  const MasterQuestListScreen({super.key});

  @override
  State<MasterQuestListScreen> createState() => _MasterQuestListScreenState();
}

class _MasterQuestListScreenState extends State<MasterQuestListScreen> {
  final _catalog = MasterQuestCatalogService();
  final _searchController = TextEditingController();
  late final Future<List<MasterQuest>> _questsFuture;
  MasterQuestCategory? _selectedCategory;
  String _difficulty = 'All';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _questsFuture = _catalog.loadQuests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _categoryName(MasterQuestCategory category) {
    switch (category) {
      case MasterQuestCategory.walkingJogging:
        return 'Walking / Jogging';
      case MasterQuestCategory.cafeExploration:
        return 'Café Exploration';
      case MasterQuestCategory.photography:
        return 'Photography';
      case MasterQuestCategory.reset:
        return 'Reset / Mindfulness';
    }
  }

  void _showDetails(MasterQuest quest) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.8,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(quest.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('${quest.id} • ${_categoryName(quest.category)}'),
              const SizedBox(height: 12),
              const Chip(label: Text('Catalog preview — not approved')),
              const SizedBox(height: 16),
              _detail('Difficulty', quest.difficulty),
              _detail('Estimated time', '${quest.estimatedMinutes} minutes'),
              _detail('Instructions', quest.instructions),
              _detail('Success condition', quest.successCondition),
              _detail('Validation method', quest.validationMethod),
              _detail('Safety notes', quest.safetyNotes),
              if (quest.validationTokens.isNotEmpty)
                _detail('Validation tokens', quest.validationTokens.join(', ')),
              const SizedBox(height: 12),
              const Text(
                'Starting these quests will be enabled after their category-specific validation and approval are implemented.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master Quest Library')),
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
                child: Text('Unable to load quest catalog: ${snapshot.error}'),
              ),
            );
          }

          final allQuests = snapshot.data ?? <MasterQuest>[];
          final filtered = allQuests.where((quest) {
            if (_selectedCategory != null &&
                quest.category != _selectedCategory) {
              return false;
            }
            if (_difficulty != 'All' &&
                quest.difficulty.toLowerCase() != _difficulty.toLowerCase()) {
              return false;
            }
            final query = _search.trim().toLowerCase();
            return query.isEmpty ||
                quest.title.toLowerCase().contains(query) ||
                quest.id.toLowerCase().contains(query) ||
                quest.instructions.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search quests by title or ID',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(() => _search = value),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<MasterQuestCategory?>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<MasterQuestCategory?>(
                          value: null,
                          child: Text('All categories'),
                        ),
                        ...MasterQuestCategory.values.map(
                          (category) => DropdownMenuItem<MasterQuestCategory?>(
                            value: category,
                            child: Text(_categoryName(category)),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedCategory = value),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _difficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                        border: OutlineInputBorder(),
                      ),
                      items: ['All', 'Easy', 'Medium', 'Hard']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _difficulty = value ?? 'All'),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Showing ${filtered.length} of ${allQuests.length} quests',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No matching quests'))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final quest = filtered[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: ListTile(
                              title: Text(quest.title),
                              subtitle: Text(
                                '${quest.id} • ${quest.difficulty} • ${quest.estimatedMinutes} min\n'
                                '${_categoryName(quest.category)}',
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showDetails(quest),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
