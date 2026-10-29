import '../models/running_quest.dart';

enum ValidationStatus { passed, failed, incomplete }

class ValidationResult {
  const ValidationResult(this.status, this.reason);
  final ValidationStatus status;
  final String reason;
}

class RunningValidator {
  static ValidationResult validate({required RunningQuest quest,
    required int elapsedSeconds, required double distanceMetres,
    required bool gpsValid, double? finishFromStartMetres}) {
    if (!gpsValid) {
      return const ValidationResult(ValidationStatus.incomplete,
          'Reliable GPS unavailable; completion cannot be verified.');
    }
    if (quest.kind == QuestKind.stages) {
      final requiredDistance = quest.stages.fold<double>(0, (a, b) => a + b);
      return distanceMetres >= requiredDistance
          ? const ValidationResult(ValidationStatus.passed, 'All distance stages reached.')
          : ValidationResult(ValidationStatus.failed,
              'Only ${distanceMetres.toStringAsFixed(0)} / ${requiredDistance.toStringAsFixed(0)} m completed.');
    }
    if (elapsedSeconds < quest.minSeconds || distanceMetres < quest.minMetres) {
      return ValidationResult(ValidationStatus.failed,
          'Need ${quest.minSeconds}s and ${quest.minMetres.toStringAsFixed(0)}m; got ${elapsedSeconds}s and ${distanceMetres.toStringAsFixed(0)}m.');
    }
    if (quest.kind == QuestKind.loop) {
      if (finishFromStartMetres == null) {
        return const ValidationResult(ValidationStatus.incomplete,
            'Start/finish GPS comparison unavailable.');
      }
      if (finishFromStartMetres > quest.finishRadiusMetres) {
        return ValidationResult(ValidationStatus.failed,
            'Finish ${finishFromStartMetres.toStringAsFixed(0)}m from start (maximum ${quest.finishRadiusMetres.toStringAsFixed(0)}m).');
      }
    }
    return const ValidationResult(ValidationStatus.passed, 'Quest requirements met.');
  }
}
