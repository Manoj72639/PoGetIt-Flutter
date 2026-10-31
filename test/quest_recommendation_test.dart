import 'package:flutter_test/flutter_test.dart';
import 'package:pogetit_quests/models/quest_profile.dart';
import 'package:pogetit_quests/services/quest_recommendation_service.dart';

void main() {
  final service = QuestRecommendationService();
  QuestProfile profile(Set<String> interests, String level, int min, int max, int goal) =>
    QuestProfile(interests: interests, activityLevel: level,
      minMinutes: min, maxMinutes: max, weeklyGoal: goal);

  test('A: beginner running recommends easy only', () {
    final r = service.recommend(profile({'running'}, 'beginner', 10, 15, 3));
    expect(r.map((x) => x.id), contains('RUN-01'));
    expect(r.any((x) => x.difficulty != QuestDifficulty.easy), false);
  });
  test('B: cafe easy and medium', () {
    final r = service.recommend(profile({'cafe'}, 'occasional', 20, 30, 2));
    expect(r.map((x) => x.id), containsAll(['CE-E001','CE-E008']));
  });
  test('C: photography increasing difficulty', () {
    final r = service.recommend(profile({'photography'}, 'consistent', 15, 30, 4));
    expect(r.map((x) => x.id), orderedEquals(['PHOTO-E001','PHOTO-M001','PHOTO-H001']));
  });
  test('D: short beginner mindfulness', () {
    final r = service.recommend(profile({'mindfulness'}, 'beginner', 5, 10, 3));
    expect(r.map((x) => x.id), orderedEquals(['RESET-E001']));
  });
  test('E: mixed interests', () {
    final r = service.recommend(profile({'running','photography'}, 'occasional', 15, 30, 4));
    expect(r.any((x) => x.category == 'running'), true);
    expect(r.any((x) => x.category == 'photography'), true);
  });
  test('two distinct valid easy IDs unlock medium running', () {
    final p = profile({'running'}, 'beginner', 10, 15, 3);
    final r = service.recommend(p, validEasyRunningQuestIds: {'RUN-01','RUN-E002'});
    expect(r.map((x) => x.id), containsAll(['RUN-01','RUN-02']));
  });
}
