class QuestExecutionConfig {
  QuestExecutionConfig._();

  static const bool allowProposedForTesting = bool.fromEnvironment(
    'ALLOW_PROPOSED_QUESTS',
    defaultValue: false,
  );
}
