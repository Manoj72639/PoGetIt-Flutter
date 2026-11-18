import '../models/master_quest.dart';
import '../models/running_quest.dart';
import '../models/cafe_quest.dart';

class UnsupportedMasterQuestException implements Exception {
  const UnsupportedMasterQuestException(this.message);
  final String message;
  @override
  String toString() => message;
}

class GpsStepsQuestConfig {
  const GpsStepsQuestConfig({
    required this.runningQuest,
    required this.requiredSteps,
    required this.requiresTaskDeclaration,
    required this.requiresReview,
  });
  final RunningQuest runningQuest;
  final int requiredSteps;
  final bool requiresTaskDeclaration;
  final bool requiresReview;
}

class MasterQuestAdapter {
  MasterQuestAdapter._();

  static Set<String> verificationTokens(MasterQuest quest) {
    return <String>{
          ...quest.validationTokens,
          ...quest.verificationMode.split(';'),
        }
        .expand((value) => value.split(';'))
        .map((value) => value.trim().toUpperCase())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  static bool usesGpsAndSteps(MasterQuest quest) =>
      verificationTokens(quest).contains('GPS_AND_STEPS');

  static String _requiredToken(Set<String> tokens, String key) {
    final matches = tokens.where((token) => token.startsWith('$key=')).toList();
    if (matches.length != 1) {
      throw UnsupportedMasterQuestException(
        'Exactly one $key requirement is needed.',
      );
    }
    return matches.single.substring(key.length + 1);
  }

  static double _positiveDouble(Map<String, dynamic> values, String key) {
    final value = values[key];
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    if (number == null || !number.isFinite || number <= 0) {
      throw UnsupportedMasterQuestException(
        'Invalid or missing parameter: $key',
      );
    }
    return number;
  }

  static int _positiveInt(Map<String, dynamic> values, String key) {
    final number = _positiveDouble(values, key);
    if (number != number.roundToDouble()) {
      throw UnsupportedMasterQuestException('$key must be a whole number.');
    }
    return number.toInt();
  }

  static bool _boolParameter(dynamic value) => value == true;

  static GpsStepsQuestConfig toGpsStepsQuest(MasterQuest quest) {
    if (quest.category != MasterQuestCategory.walkingJogging) {
      throw const UnsupportedMasterQuestException(
        'Not a Walking/Jogging quest.',
      );
    }

    final tokens = verificationTokens(quest);
    if (!tokens.contains('GPS_AND_STEPS')) {
      throw const UnsupportedMasterQuestException('GPS_AND_STEPS is missing.');
    }

    final gps = double.tryParse(_requiredToken(tokens, 'GPS_MIN_M'));
    final steps = int.tryParse(_requiredToken(tokens, 'QUEST_STEPS_MIN'));
    if (gps == null ||
        !gps.isFinite ||
        gps <= 0 ||
        steps == null ||
        steps <= 0) {
      throw const UnsupportedMasterQuestException(
        'Invalid GPS or step threshold.',
      );
    }

    const supportedFlags = <String>{
      'GPS_AND_STEPS',
      'SAME_ACTIVITY_INTERVALS_REQUIRED',
      'AGGREGATED_STEPS_NO_DUPLICATES',
      'TASK_SELF_DECLARATION',
      'PHOTO_OPTIONAL',
      'GPS_RELIABLE_OUTDOOR_EQUIVALENT',
    };
    for (final token in tokens) {
      if (supportedFlags.contains(token) ||
          token.startsWith('GPS_MIN_M=') ||
          token.startsWith('QUEST_STEPS_MIN=')) {
        continue;
      }
      throw UnsupportedMasterQuestException(
        'Unsupported verification token: $token',
      );
    }

    // All uploaded Walking/Jogging quests use this imported rule shape.
    // Check its values against the canonical verification tokens rather
    // than dropping structured requirements or bypassing validation.
    if (quest.rules.length != 1) {
      throw const UnsupportedMasterQuestException(
        'Expected one structured GPS and steps rule.',
      );
    }
    final rule = quest.rules.single;
    if (rule.type.trim().toLowerCase() != 'source_validation_method') {
      throw UnsupportedMasterQuestException(
        'Unsupported structured rule: ${rule.type}',
      );
    }
    final parameters = rule.parameters;
    final expectedKeys = <String>{
      'GPS_AND_STEPS',
      'GPS_MIN_M',
      'QUEST_STEPS_MIN',
      'SAME_ACTIVITY_INTERVALS_REQUIRED',
      'AGGREGATED_STEPS_NO_DUPLICATES',
      'TASK_SELF_DECLARATION',
      'PHOTO_OPTIONAL',
      'GPS_RELIABLE_OUTDOOR_EQUIVALENT',
    };
    for (final key in parameters.keys) {
      if (!expectedKeys.contains(key.toUpperCase())) {
        throw UnsupportedMasterQuestException(
          'Unsupported structured requirement: $key',
        );
      }
    }
    if (!_boolParameter(parameters['GPS_AND_STEPS']) ||
        _positiveDouble(parameters, 'GPS_MIN_M') != gps ||
        _positiveInt(parameters, 'QUEST_STEPS_MIN') != steps) {
      throw const UnsupportedMasterQuestException(
        'Structured GPS/step requirements do not match verification tokens.',
      );
    }
    for (final key in expectedKeys.difference(<String>{
      'GPS_MIN_M',
      'QUEST_STEPS_MIN',
    })) {
      if (key == 'GPS_AND_STEPS') continue;
      if (_boolParameter(parameters[key]) != tokens.contains(key)) {
        throw UnsupportedMasterQuestException(
          'Structured requirement $key does not match verification tokens.',
        );
      }
    }

    return GpsStepsQuestConfig(
      runningQuest: RunningQuest(
        id: quest.id,
        title: quest.title,
        kind: QuestKind.timeDistance,
        minSeconds: 0,
        minMetres: gps,
      ),
      requiredSteps: steps,
      requiresTaskDeclaration: tokens.contains('TASK_SELF_DECLARATION'),
      requiresReview: rule.requiresReview,
    );
  }

  static QuestRule _singleRule(MasterQuest quest) {
    if (quest.rules.length != 1) {
      throw const UnsupportedMasterQuestException(
        'Exactly one supported validation rule is required.',
      );
    }
    // A review flag never blocks starting a quest. Review still needs
    // handling when the attempt is evaluated.
    return quest.rules.single;
  }

  static RunningQuest toRunningQuest(MasterQuest quest) {
    if (quest.category != MasterQuestCategory.walkingJogging) {
      throw const UnsupportedMasterQuestException(
        'Not a Walking/Jogging quest.',
      );
    }
    if (usesGpsAndSteps(quest)) {
      throw const UnsupportedMasterQuestException(
        'Use toGpsStepsQuest for GPS and steps verification.',
      );
    }
    final rule = _singleRule(quest);
    final p = rule.parameters;
    switch (rule.type) {
      case 'time_distance':
        return RunningQuest(
          id: quest.id,
          title: quest.title,
          kind: QuestKind.timeDistance,
          minSeconds: _positiveInt(p, 'minSeconds'),
          minMetres: _positiveDouble(p, 'minMetres'),
        );
      case 'loop':
        return RunningQuest(
          id: quest.id,
          title: quest.title,
          kind: QuestKind.loop,
          minSeconds: _positiveInt(p, 'minSeconds'),
          minMetres: _positiveDouble(p, 'minMetres'),
          finishRadiusMetres: _positiveDouble(p, 'finishRadiusMetres'),
        );
      case 'stages':
        final raw = p['stages'];
        if (raw is! List || raw.isEmpty) {
          throw const UnsupportedMasterQuestException('Stages are missing.');
        }
        final stages = raw.map((value) {
          final number = value is num
              ? value.toDouble()
              : double.tryParse('$value');
          if (number == null || !number.isFinite || number <= 0) {
            throw const UnsupportedMasterQuestException(
              'Invalid stage distance.',
            );
          }
          return number;
        }).toList();
        return RunningQuest(
          id: quest.id,
          title: quest.title,
          kind: QuestKind.stages,
          stages: stages,
        );
      default:
        throw UnsupportedMasterQuestException(
          'Unsupported running rule: ${rule.type}',
        );
    }
  }

  static CafeQuest toCafeQuest(MasterQuest quest) {
    if (quest.category != MasterQuestCategory.cafeExploration) {
      throw const UnsupportedMasterQuestException(
        'Not a Café Exploration quest.',
      );
    }
    final rule = _singleRule(quest);
    final p = rule.parameters;
    switch (rule.type) {
      case 'cafe_photo':
        return CafeQuest(
          id: quest.id,
          title: quest.title,
          kind: CafeQuestKind.photo,
          radiusMetres: _positiveDouble(p, 'radiusMetres'),
          requiresPhoto: true,
        );
      case 'cafe_dwell':
        return CafeQuest(
          id: quest.id,
          title: quest.title,
          kind: CafeQuestKind.dwell,
          radiusMetres: _positiveDouble(p, 'radiusMetres'),
          dwellMinutes: _positiveInt(p, 'dwellMinutes'),
        );
      default:
        throw UnsupportedMasterQuestException(
          'Unsupported café rule: ${rule.type}',
        );
    }
  }
}
