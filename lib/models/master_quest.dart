enum MasterQuestCategory { walkingJogging, cafeExploration, photography, reset }

enum QuestApprovalStatus { proposed, approved, rejected, retired }

class QuestRule {
  final String type;
  final Map<String, dynamic> parameters;
  final bool requiresReview;
  const QuestRule({
    required this.type,
    this.parameters = const {},
    this.requiresReview = false,
  });
  factory QuestRule.fromMap(Map<String, dynamic> map) => QuestRule(
    type: map['type']?.toString() ?? 'manual_review',
    parameters: Map<String, dynamic>.from(map['parameters'] as Map? ?? {}),
    requiresReview: map['requiresReview'] == true,
  );
  Map<String, dynamic> toMap() => {
    'type': type,
    'parameters': parameters,
    'requiresReview': requiresReview,
  };
}

class MasterQuest {
  final String id, version, title, description, instructions, difficulty;
  final String successCondition, verificationMode, evidenceRule, alternateProof;
  final String validationThreshold, safetyNotes;
  final int estimatedMinutes;
  final MasterQuestCategory category;
  final QuestApprovalStatus approvalStatus;
  final List<QuestRule> rules;
  // New workbook fields, optional for compatibility with existing model calls.
  final String pathwayType,
      progressionId,
      learningStage,
      theme,
      goalTag,
      validationMethod;
  final int? completionWindowDays;
  final List<String> validationTokens;
  const MasterQuest({
    required this.id,
    required this.version,
    required this.category,
    required this.title,
    required this.description,
    required this.instructions,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.successCondition,
    required this.verificationMode,
    required this.evidenceRule,
    required this.alternateProof,
    required this.validationThreshold,
    required this.safetyNotes,
    required this.approvalStatus,
    this.rules = const [],
    this.pathwayType = '',
    this.progressionId = '',
    this.learningStage = '',
    this.theme = '',
    this.goalTag = '',
    this.validationMethod = '',
    this.completionWindowDays,
    this.validationTokens = const [],
  });
  factory MasterQuest.fromMap(Map<String, dynamic> map) {
    T enumValue<T extends Enum>(List<T> values, dynamic value, T fallback) {
      for (final item in values) {
        if (item.name == value) return item;
      }
      return fallback;
    }

    return MasterQuest(
      id: '${map['id'] ?? ''}',
      version: '${map['version'] ?? '1'}',
      category: enumValue(
        MasterQuestCategory.values,
        map['category'],
        MasterQuestCategory.walkingJogging,
      ),
      title: '${map['title'] ?? ''}',
      description: '${map['description'] ?? ''}',
      instructions: '${map['instructions'] ?? ''}',
      difficulty: '${map['difficulty'] ?? 'easy'}',
      estimatedMinutes: (map['estimatedMinutes'] as num?)?.toInt() ?? 0,
      successCondition: '${map['successCondition'] ?? ''}',
      verificationMode: '${map['verificationMode'] ?? ''}',
      evidenceRule: '${map['evidenceRule'] ?? ''}',
      alternateProof: '${map['alternateProof'] ?? ''}',
      validationThreshold: '${map['validationThreshold'] ?? ''}',
      safetyNotes: '${map['safetyNotes'] ?? ''}',
      approvalStatus: enumValue(
        QuestApprovalStatus.values,
        map['approvalStatus'],
        QuestApprovalStatus.proposed,
      ),
      rules: (map['rules'] as List? ?? [])
          .map((x) => QuestRule.fromMap(Map<String, dynamic>.from(x as Map)))
          .toList(),
      pathwayType: '${map['pathwayType'] ?? ''}',
      progressionId: '${map['progressionId'] ?? ''}',
      learningStage: '${map['learningStage'] ?? ''}',
      theme: '${map['theme'] ?? ''}',
      goalTag: '${map['goalTag'] ?? ''}',
      validationMethod: '${map['validationMethod'] ?? ''}',
      completionWindowDays: (map['completionWindowDays'] as num?)?.toInt(),
      validationTokens: (map['validationTokens'] as List? ?? [])
          .map((x) => x.toString())
          .toList(),
    );
  }
  Map<String, dynamic> toMap() => {
    'id': id,
    'version': version,
    'category': category.name,
    'title': title,
    'description': description,
    'instructions': instructions,
    'difficulty': difficulty,
    'estimatedMinutes': estimatedMinutes,
    'successCondition': successCondition,
    'verificationMode': verificationMode,
    'evidenceRule': evidenceRule,
    'alternateProof': alternateProof,
    'validationThreshold': validationThreshold,
    'safetyNotes': safetyNotes,
    'approvalStatus': approvalStatus.name,
    'rules': rules.map((r) => r.toMap()).toList(),
    'pathwayType': pathwayType,
    'progressionId': progressionId,
    'learningStage': learningStage,
    'theme': theme,
    'goalTag': goalTag,
    'validationMethod': validationMethod,
    'completionWindowDays': completionWindowDays,
    'validationTokens': validationTokens,
  };
}
