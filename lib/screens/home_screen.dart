import 'package:flutter/material.dart';

import '../models/quest_profile.dart';
import '../data/sample_quest_profiles.dart';

import 'recommended_quests_screen.dart';

class HomeScreen extends StatelessWidget {
  final QuestProfile? profile;

  const HomeScreen({super.key, this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PoGetIt - Select Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose a Test Profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select one of the five predefined profiles '
            'to view recommended quests.',
          ),
          const SizedBox(height: 16),

          ...sampleQuestProfiles.map((sample) {
            final selected = sample.profile;

            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(sample.id)),
                title: Text('Profile ${sample.id} - ${sample.name}'),
                subtitle: Text(
                  '${selected.interests.join(", ")}\n'
                  '${selected.activityLevel} • '
                  '${selected.minMinutes}-${selected.maxMinutes} min • '
                  '${selected.weeklyGoal} quests/week',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          RecommendedQuestsScreen(profile: selected),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
