import '../config/quest_execution_config.dart';
import '../models/master_quest.dart';

class QuestExecutionPolicy {
  QuestExecutionPolicy._();

  static String? approvalIssue(MasterQuest quest) {
    switch (quest.approvalStatus) {
      case QuestApprovalStatus.approved:
        return null;

      case QuestApprovalStatus.proposed:
        if (QuestExecutionConfig.allowProposedForTesting) {
          return null;
        }
        return 'This quest is not yet approved for execution.';

      case QuestApprovalStatus.rejected:
        return 'This quest has been rejected.';

      case QuestApprovalStatus.retired:
        return 'This quest has been retired.';
    }
  }

  static bool canExecute(MasterQuest quest) {
    return approvalIssue(quest) == null;
  }
}
