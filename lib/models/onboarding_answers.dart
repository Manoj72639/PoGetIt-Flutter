class OnboardingAnswers {
  final String name;
  final List<String> interests;
  final String goals;
  final String activityLevel;
  final int preferredMinutes;
  final int weeklyTarget;

  final List<String> lifeGoals;
  final String primaryInterest;
  final String secondaryInterest;
  final String preferredQuestDuration;
  final String preferredActivityTime;

  const OnboardingAnswers({
    required this.name,
    required this.interests,
    required this.goals,
    required this.activityLevel,
    required this.preferredMinutes,
    required this.weeklyTarget,
    required this.lifeGoals,
    required this.primaryInterest,
    required this.secondaryInterest,
    required this.preferredQuestDuration,
    required this.preferredActivityTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'interests': interests,
      'goals': goals,
      'activityLevel': activityLevel,
      'preferredMinutes': preferredMinutes,
      'weeklyTarget': weeklyTarget,
      'lifeGoals': lifeGoals,
      'primaryInterest': primaryInterest,
      'secondaryInterest': secondaryInterest,
      'preferredQuestDuration': preferredQuestDuration,
      'preferredActivityTime': preferredActivityTime,
    };
  }
}
