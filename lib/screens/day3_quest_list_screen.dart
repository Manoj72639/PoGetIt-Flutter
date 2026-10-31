import 'package:flutter/material.dart';
import '../models/day3_quest.dart';
import 'day3_photography_screen.dart';
import 'day3_reset_screen.dart';
import 'day3_history_screen.dart';

class Day3QuestListScreen extends StatelessWidget {
  final Day3Category category;
  const Day3QuestListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final quests = day3Quests.where((q) => q.category == category).toList();
    final title = category == Day3Category.photography ? 'Photography' : 'Mindfulness / Reset';
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [
        IconButton(tooltip: 'Attempt history', icon: const Icon(Icons.history),
          onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
            builder: (_) => const Day3HistoryScreen()))),
      ]),
      body: ListView.builder(
        padding: const EdgeInsets.all(12), itemCount: quests.length,
        itemBuilder: (context, index) {
          final quest = quests[index];
          return Card(
            elevation: 0, margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.shade300)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              title: Text(quest.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Padding(padding: const EdgeInsets.only(top: 6),
                child: Text('${quest.difficulty} • ${quest.instructions}')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute<void>(
                builder: (_) => category == Day3Category.photography
                    ? Day3PhotographyScreen(quest: quest)
                    : Day3ResetScreen(quest: quest))),
            ),
          );
        },
      ),
    );
  }
}
