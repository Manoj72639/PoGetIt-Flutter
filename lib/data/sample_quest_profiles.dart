import '../models/quest_profile.dart';

class SampleQuestProfile {
  final String id;
  final String name;
  final QuestProfile profile;

  const SampleQuestProfile({
    required this.id,
    required this.name,
    required this.profile,
  });
}

final sampleQuestProfiles = <SampleQuestProfile>[
  SampleQuestProfile(
    id: 'A',
    name: 'New to activity',
    profile: QuestProfile(
      interests: {'running'},
      activityLevel: 'beginner',
      minMinutes: 10,
      maxMinutes: 15,
      weeklyGoal: 3,
    ),
  ),
  SampleQuestProfile(
    id: 'B',
    name: 'Local explorer',
    profile: QuestProfile(
      interests: {'cafe'},
      activityLevel: 'occasional',
      minMinutes: 20,
      maxMinutes: 30,
      weeklyGoal: 2,
    ),
  ),
  SampleQuestProfile(
    id: 'C',
    name: 'Creative explorer',
    profile: QuestProfile(
      interests: {'photography'},
      activityLevel: 'consistent',
      minMinutes: 15,
      maxMinutes: 30,
      weeklyGoal: 4,
    ),
  ),
  SampleQuestProfile(
    id: 'D',
    name: 'Low-energy reset',
    profile: QuestProfile(
      interests: {'mindfulness'},
      activityLevel: 'beginner',
      minMinutes: 5,
      maxMinutes: 10,
      weeklyGoal: 3,
    ),
  ),
  SampleQuestProfile(
    id: 'E',
    name: 'Mixed interests',
    profile: QuestProfile(
      interests: {'running', 'photography'},
      activityLevel: 'occasional',
      minMinutes: 15,
      maxMinutes: 30,
      weeklyGoal: 4,
    ),
  ),
];
