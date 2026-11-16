import 'quest_evidence.dart';

enum MasterQuestStatus { inProgress, passed, failed, incomplete, needsReview }

class MasterQuestAttempt {
  final String attemptId;
  final String userId;
  final String questId;
  final String questVersion;
  final MasterQuestStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final QuestEvidence evidence;
  final String validationReason;

  const MasterQuestAttempt({
    required this.attemptId,
    required this.userId,
    required this.questId,
    required this.questVersion,
    required this.status,
    required this.startedAt,
    required this.evidence,
    this.completedAt,
    this.validationReason = '',
  });

  Map<String, dynamic> toMap() => {
    'attemptId': attemptId,
    'userId': userId,
    'questId': questId,
    'questVersion': questVersion,
    'status': status.name,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'evidence': evidence.toMap(),
    'validationReason': validationReason,
  };
}

class MasterQuestValidationResult {
  final MasterQuestStatus status;
  final String reason;
  final List<String> missingRequirements;

  const MasterQuestValidationResult({
    required this.status,
    required this.reason,
    this.missingRequirements = const [],
  });

  bool get isPassed => status == MasterQuestStatus.passed;
}
