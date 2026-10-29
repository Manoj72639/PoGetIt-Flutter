import 'package:flutter/material.dart';

import '../models/cafe_quest.dart';
import 'cafe_screen.dart';
import 'cafe_attempt_events_screen.dart';

class CafeListScreen extends StatelessWidget {
  const CafeListScreen({super.key});

  String _getDescription(String questId) {
    switch (questId) {
      case 'CE-E001':
        return 'Visit a cafe, check in within 150 m '
            'and attach a photo.';

      case 'CE-E008':
        return 'Check in at a cafe, stay for 10 minutes '
            'and check out.';

      case 'CE-H001':
        return 'Visit three different cafes and '
            'complete GPS check-ins.';

      default:
        return 'Complete the cafe exploration quest.';
    }
  }

  String _getDifficulty(String questId) {
    switch (questId) {
      case 'CE-E001':
        return 'Basic';

      case 'CE-E008':
        return 'Intermediate';

      case 'CE-H001':
        return 'Advanced';

      default:
        return 'Basic';
    }
  }

  Color _getDifficultyColor(String questId) {
    switch (questId) {
      case 'CE-E001':
        return Colors.green;

      case 'CE-E008':
        return Colors.orange;

      case 'CE-H001':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          'Cafe Exploration',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        actions: [
          IconButton(
            tooltip: 'Cafe Attempt History',
            icon: const Icon(Icons.history_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const CafeAttemptEventsScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Available Quests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          Text(
            'Choose a cafe quest to get started.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 20),

          ...cafeQuests.map((quest) {
            final difficulty = _getDifficulty(quest.id);

            final difficultyColor = _getDifficultyColor(quest.id);

            return Card(
              elevation: 0,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),

              child: InkWell(
                borderRadius: BorderRadius.circular(12),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => CafeScreen(quest: quest),
                    ),
                  );
                },

                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.local_cafe_outlined,
                            size: 22,
                            color: Colors.brown,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              quest.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        _getDescription(quest.id),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),

                            decoration: BoxDecoration(
                              color: difficultyColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),

                            child: Text(
                              difficulty,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: difficultyColor,
                              ),
                            ),
                          ),

                          const Spacer(),

                          Text(
                            quest.id,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
