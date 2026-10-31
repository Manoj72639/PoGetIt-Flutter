import 'package:flutter_test/flutter_test.dart';
import '../models/day3_quest.dart';
import '../models/day3_validator.dart';

void main() {
  test('Photography requires all images', () {
    final q = day3Quests.first;
    expect(Day3Validator.photography(q, 0).status, Day3Status.incomplete);
    expect(Day3Validator.photography(q, 1).status, Day3Status.passed);
  });

  test('Reset requires confirmation and checklist', () {
    final q = day3Quests.firstWhere((e) => e.id == 'RESET-M001');
    expect(
      Day3Validator.reset(
        q,
        confirmed: true,
        checklistComplete: false,
        sessions: 0,
      ).status,
      Day3Status.incomplete,
    );
    expect(
      Day3Validator.reset(
        q,
        confirmed: true,
        checklistComplete: true,
        sessions: 0,
      ).status,
      Day3Status.passed,
    );
  });

  test('Hard reset requires logged sessions', () {
    final q = day3Quests.firstWhere((e) => e.id == 'RESET-H001');
    expect(
      Day3Validator.reset(
        q,
        confirmed: true,
        checklistComplete: true,
        sessions: 2,
      ).status,
      Day3Status.incomplete,
    );
    expect(
      Day3Validator.reset(
        q,
        confirmed: true,
        checklistComplete: true,
        sessions: 3,
      ).status,
      Day3Status.passed,
    );
  });
}
