import '../models/running_quest.dart';

enum ValidationStatus { passed, failed, incomplete }

class ValidationResult {
  const ValidationResult(this.status, this.reason);

  final ValidationStatus status;
  final String reason;
}

class RunningValidator {
  static ValidationResult validate({
    required RunningQuest quest,
    required int elapsedSeconds,
    required double distanceMetres,
    required bool gpsValid,
    double? finishFromStartMetres,
  }) {
    if (!gpsValid) {
      return const ValidationResult(
        ValidationStatus.incomplete,
        'Reliable GPS unavailable.',
      );
    }

    if (quest.kind == QuestKind.stages) {
      final requiredDistance = quest.stages.fold<double>(
        0,
        (sum, stage) => sum + stage,
      );

      if (distanceMetres < requiredDistance) {
        return ValidationResult(
          ValidationStatus.failed,
          'Only ${distanceMetres.toStringAsFixed(0)} '
          'of ${requiredDistance.toStringAsFixed(0)} m completed.',
        );
      }

      return const ValidationResult(
        ValidationStatus.passed,
        'All distance stages reached.',
      );
    }

    if (elapsedSeconds < quest.minSeconds || distanceMetres < quest.minMetres) {
      return ValidationResult(
        ValidationStatus.failed,
        'Need ${quest.minSeconds}s and '
        '${quest.minMetres.toStringAsFixed(0)}m; '
        'recorded ${elapsedSeconds}s and '
        '${distanceMetres.toStringAsFixed(0)}m.',
      );
    }

    if (quest.kind == QuestKind.loop) {
      if (finishFromStartMetres == null) {
        return const ValidationResult(
          ValidationStatus.incomplete,
          'Start/finish comparison unavailable.',
        );
      }

      if (finishFromStartMetres > quest.finishRadiusMetres) {
        return const ValidationResult(
          ValidationStatus.failed,
          'Finish location is outside the required radius.',
        );
      }
    }

    return const ValidationResult(
      ValidationStatus.passed,
      'Quest requirements met.',
    );
  }

  static ValidationResult validateGpsAndSteps({
    required double distanceMetres,
    required int questSteps,
    required double requiredGpsMetres,
    required int requiredSteps,
    required bool gpsReliable,
    required bool stepsReliable,
    required bool taskDeclared,
    bool requiresReview = false,
  }) {
    if (!gpsReliable || !stepsReliable) {
      return const ValidationResult(
        ValidationStatus.incomplete,
        'GPS or quest-specific step evidence '
        'cannot be reliably verified.',
      );
    }

    if (distanceMetres < requiredGpsMetres || questSteps < requiredSteps) {
      return ValidationResult(
        ValidationStatus.failed,
        'Required: ${requiredGpsMetres.toStringAsFixed(0)} m '
        'and $requiredSteps steps. '
        'Recorded: ${distanceMetres.toStringAsFixed(0)} m '
        'and $questSteps steps.',
      );
    }

    if (!taskDeclared) {
      return const ValidationResult(
        ValidationStatus.incomplete,
        'Complete the required task declaration.',
      );
    }

    if (requiresReview) {
      return const ValidationResult(
        ValidationStatus.incomplete,
        'GPS and steps requirements met. '
        'Additional quest evidence requires verification.',
      );
    }

    return const ValidationResult(
      ValidationStatus.passed,
      'GPS, steps, and task declaration '
      'requirements met.',
    );
  }
}
