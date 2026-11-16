abstract class QuestEvidence {
  const QuestEvidence();

  String get evidenceType;

  Map<String, dynamic> toMap();
}

class WalkingJoggingEvidence extends QuestEvidence {
  final int activeSeconds;
  final double distanceMeters;
  final bool gpsAvailable;
  final String taskNote;
  final bool selfReported;

  const WalkingJoggingEvidence({
    required this.activeSeconds,
    required this.distanceMeters,
    required this.gpsAvailable,
    this.taskNote = '',
    this.selfReported = false,
  });

  @override
  String get evidenceType => 'walking_jogging';

  @override
  Map<String, dynamic> toMap() => {
    'type': evidenceType,
    'activeSeconds': activeSeconds,
    'distanceMeters': distanceMeters,
    'gpsAvailable': gpsAvailable,
    'taskNote': taskNote,
    'selfReported': selfReported,
  };
}

class CafeEvidence extends QuestEvidence {
  final String cafeName;
  final DateTime visitedAt;
  final double? distanceMeters;
  final int? dwellSeconds;
  final bool gpsAvailable;
  final String observation;
  final List<String> photoUrls;

  const CafeEvidence({
    required this.cafeName,
    required this.visitedAt,
    required this.gpsAvailable,
    this.distanceMeters,
    this.dwellSeconds,
    this.observation = '',
    this.photoUrls = const [],
  });

  @override
  String get evidenceType => 'cafe_exploration';

  @override
  Map<String, dynamic> toMap() => {
    'type': evidenceType,
    'cafeName': cafeName,
    'visitedAt': visitedAt.toIso8601String(),
    'distanceMeters': distanceMeters,
    'dwellSeconds': dwellSeconds,
    'gpsAvailable': gpsAvailable,
    'observation': observation,
    'photoUrls': photoUrls,
  };
}

class PhotographyEvidence extends QuestEvidence {
  final List<String> photoUrls;
  final List<String> captions;
  final Map<String, bool> checklist;

  const PhotographyEvidence({
    required this.photoUrls,
    this.captions = const [],
    this.checklist = const {},
  });

  @override
  String get evidenceType => 'photography';

  @override
  Map<String, dynamic> toMap() => {
    'type': evidenceType,
    'photoUrls': photoUrls,
    'captions': captions,
    'checklist': checklist,
  };
}

class ResetEvidence extends QuestEvidence {
  final int sessionSeconds;
  final Map<String, bool> checklist;
  final String completionNote;
  final bool selfReported;

  const ResetEvidence({
    required this.sessionSeconds,
    this.checklist = const {},
    this.completionNote = '',
    this.selfReported = false,
  });

  @override
  String get evidenceType => 'reset';

  @override
  Map<String, dynamic> toMap() => {
    'type': evidenceType,
    'sessionSeconds': sessionSeconds,
    'checklist': checklist,
    'completionNote': completionNote,
    'selfReported': selfReported,
  };
}
