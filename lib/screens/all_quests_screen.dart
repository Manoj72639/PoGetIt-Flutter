import 'package:flutter/material.dart';

import '../models/day3_quest.dart';

import 'quest_list_screen.dart';
import 'cafe_list_screen.dart';
import 'day3_quest_list_screen.dart';
import 'sample_profiles_screen.dart';

class AllQuestsScreen extends StatelessWidget {
  const AllQuestsScreen({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Day 1 - Day 4 Quests')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.directions_run),
              title: const Text('Day 1 - Running / Jogging'),
              subtitle: const Text('3 running quests'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, const QuestListScreen()),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_cafe),
              title: const Text('Day 2 - Cafe Exploration'),
              subtitle: const Text('3 cafe quests'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, const CafeListScreen()),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Day 3 - Photography'),
              subtitle: const Text('3 photography quests'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(
                context,
                const Day3QuestListScreen(category: Day3Category.photography),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.self_improvement),
              title: const Text('Day 3 - Mindfulness / Reset'),
              subtitle: const Text('3 mindfulness quests'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(
                context,
                const Day3QuestListScreen(category: Day3Category.mindfulness),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Day 4 - Recommendations'),
              subtitle: const Text(
                'Five predefined profiles and personalized quests',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, const SampleProfilesScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
