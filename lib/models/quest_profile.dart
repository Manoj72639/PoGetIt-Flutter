class QuestProfile {
  final Set<String> interests;
  final String activityLevel;
  final int minMinutes;
  final int maxMinutes;
  final int weeklyGoal;

  const QuestProfile({required this.interests, required this.activityLevel,
    required this.minMinutes, required this.maxMinutes, required this.weeklyGoal});

  Map<String, dynamic> toJson() => {
    'interests': interests.toList(), 'activityLevel': activityLevel,
    'preferredDurationMin': minMinutes, 'preferredDurationMax': maxMinutes,
    'weeklyGoal': weeklyGoal,
  };

  factory QuestProfile.fromJson(Map<String, dynamic> json) => QuestProfile(
    interests: (json['interests'] as List).cast<String>().toSet(),
    activityLevel: json['activityLevel'] as String,
    minMinutes: json['preferredDurationMin'] as int,
    maxMinutes: json['preferredDurationMax'] as int,
    weeklyGoal: json['weeklyGoal'] as int,
  );
}
