enum QuestKind { timeDistance, loop, stages }

class RunningQuest {
  const RunningQuest({
    required this.id,
    required this.title,
    required this.kind,
    this.minSeconds = 0,
    this.minMetres = 0,
    this.finishRadiusMetres = 0,
    this.stages = const [],
  });
  final String id;
  final String title;
  final QuestKind kind;
  final int minSeconds;
  final double minMetres;
  final double finishRadiusMetres;
  final List<double> stages;
}

const runningQuests = <RunningQuest>[
  RunningQuest(
    id: 'RUN-01',
    title: 'The 7-Minute Escape',
    kind: QuestKind.timeDistance,
    minSeconds: 420,
    minMetres: 400,
  ),
  RunningQuest(
    id: 'RUN-02',
    title: "The Explorer's Loop",
    kind: QuestKind.loop,
    minSeconds: 720,
    minMetres: 1000,
    finishRadiusMetres: 150,
  ),
  RunningQuest(
    id: 'RUN-03',
    title: 'The Momentum Challenge',
    kind: QuestKind.stages,
    stages: [400, 800, 400],
  ),
];
