import 'package:flutter/material.dart';

import '../models/running_quest.dart';
import '../storage/attempt_repository.dart';
import 'running_screen.dart';

class QuestListScreen extends StatelessWidget {
  const QuestListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PoGetIt • Running Quests'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Attempt history',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: runningQuests.length,
        itemBuilder: (context, index) {
          final quest = runningQuests[index];

          final description = switch (quest.kind) {
            QuestKind.timeDistance => '7 min • 400 m',
            QuestKind.loop => '12 min • 1 km • Finish within 150 m of start',
            QuestKind.stages => '400 m + 800 m + 400 m',
          };

          final difficulty = switch (quest.kind) {
            QuestKind.timeDistance => 'EASY',
            QuestKind.loop => 'MEDIUM',
            QuestKind.stages => 'HARD',
          };

          final color = switch (quest.kind) {
            QuestKind.timeDistance => Colors.green,
            QuestKind.loop => Colors.orange,
            QuestKind.stages => Colors.red,
          };

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(Icons.directions_run, color: color),
              ),
              title: Text(
                quest.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      difficulty,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(description),
                    const SizedBox(height: 6),
                    Text(
                      'Quest ID: ${quest.id}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => RunningScreen(quest: quest),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _attempts;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    _attempts = AttemptRepository().all();
  }

  void _refreshHistory() {
    setState(() {
      _loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Attempt Results'),
        actions: [
          IconButton(
            tooltip: 'Refresh history',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshHistory,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _attempts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load history:\n'
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refreshHistory,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No attempts yet.', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Complete or finish a quest to see results.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              final status = (item['status'] ?? 'unknown').toString();

              final isPassed = status.toLowerCase() == 'passed';

              final seconds = (item['seconds'] as num?)?.toInt() ?? 0;

              final metres = (item['metres'] as num?)?.toDouble() ?? 0;

              final minutes = seconds ~/ 60;
              final remainingSeconds = seconds % 60;

              final formattedTime =
                  '${minutes.toString().padLeft(2, '0')}:'
                  '${remainingSeconds.toString().padLeft(2, '0')}';

              final timestamp = (item['timestamp'] ?? 'Unknown').toString();

              final reason = (item['reason'] ?? 'No reason recorded')
                  .toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isPassed ? Icons.check_circle : Icons.cancel,
                            color: isPassed ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Quest: ${item['questId'] ?? 'Unknown'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: isPassed ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text('Time: $formattedTime'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.route, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Distance: '
                            '${metres.toStringAsFixed(1)} m',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Date: $timestamp')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Validation: $reason',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
