import 'day3_quest.dart';

class Day3Validation {
  final Day3Status status;
  final String reason;
  const Day3Validation(this.status, this.reason);
}

class Day3Validator {
  static Day3Validation photography(Day3Quest quest, int photoCount) {
    if (photoCount >= quest.requiredPhotos) {
      return const Day3Validation(Day3Status.passed, 'Required photo set submitted. Image subject/content not verified.');
    }
    return Day3Validation(Day3Status.incomplete,
        '$photoCount of ${quest.requiredPhotos} required photos submitted.');
  }

  static Day3Validation reset(Day3Quest quest, {
    required bool confirmed,
    required bool checklistComplete,
    required int sessions,
  }) {
    if (!confirmed) return const Day3Validation(Day3Status.incomplete, 'Completion has not been confirmed.');
    if (!checklistComplete) return const Day3Validation(Day3Status.incomplete, 'Complete all checklist items.');
    if (sessions < quest.requiredSessions) {
      return Day3Validation(Day3Status.incomplete,
          '$sessions of ${quest.requiredSessions} required sessions logged.');
    }
    return const Day3Validation(Day3Status.passed, 'Self-reported requirements completed.');
  }
}
