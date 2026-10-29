import 'package:flutter/material.dart';
import 'quest_list_screen.dart';
import 'cafe_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PoGetIt • Quest Prototypes')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.directions_run),
            title: const Text('Day 1 — Running/Jogging'),
            subtitle: const Text('3 running quests • timer and GPS'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const QuestListScreen()),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.local_cafe),
            title: const Text('Day 2 — Cafe Exploration'),
            subtitle: const Text(
              '3 cafe quests • GPS, photo, dwell and expedition',
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const CafeListScreen()),
            ),
          ),
        ),
      ],
    ),
  );
}
