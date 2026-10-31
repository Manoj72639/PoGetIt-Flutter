import 'package:flutter/material.dart';

import '../data/sample_quest_profiles.dart';
import 'recommended_quests_screen.dart';

class SampleProfilesScreen extends StatelessWidget {
  const SampleProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Profiles')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sampleQuestProfiles.length,
        itemBuilder: (context, index) {
          final sample = sampleQuestProfiles[index];
          final profile = sample.profile;

          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(sample.id)),
              title: Text('Profile ${sample.id} — ${sample.name}'),
              subtitle: Text(
                '${profile.interests.join(", ")}\n'
                '${profile.activityLevel} • '
                '${profile.minMinutes}–'
                '${profile.maxMinutes} min • '
                '${profile.weeklyGoal} quests/week',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => RecommendedQuestsScreen(profile: profile),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
