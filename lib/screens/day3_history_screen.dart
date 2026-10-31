import 'dart:io';
import 'package:flutter/material.dart';
import '../storage/day3_repository.dart';

class Day3HistoryScreen extends StatefulWidget {
  const Day3HistoryScreen({super.key});
  @override
  State<Day3HistoryScreen> createState() => _Day3HistoryScreenState();
}

class _Day3HistoryScreenState extends State<Day3HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() {
    super.initState();
    _reload();
  }
  void _reload() => _future = Day3Repository().all();
  Future<void> _refresh() async {
    setState(_reload);
    try { await _future; } catch (_) { /* Shown by FutureBuilder. */ }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Day 3 Attempt History')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: TextButton(onPressed: _refresh, child: const Text('Retry')));
        }
        final records = snapshot.data ?? [];
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: records.isEmpty ? 1 : records.length,
            itemBuilder: (context, index) {
              if (records.isEmpty) return const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: Text('No attempts yet')));
              final r = records[index];
              final photos = (r['photoPaths'] as List<dynamic>? ?? [])
                  .map((e) => e.toString()).toList();
              final passed = r['status'] == 'passed';
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300)),
                child: ExpansionTile(
                  leading: Icon(passed ? Icons.check_circle_outline : Icons.access_time,
                    color: passed ? Colors.green : Colors.orange),
                  title: Text((r['title'] ?? 'Quest').toString(), maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                  subtitle: Text('${r['status']} • ${r['timestamp']}', maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                  childrenPadding: const EdgeInsets.all(12),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((r['reason'] ?? '').toString()),
                    if (photos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('${photos.length} submitted photos'),
                      ...photos.asMap().entries.map((entry) => TextButton.icon(
                        onPressed: () => Navigator.push(context,
                          MaterialPageRoute<void>(builder: (_) => _PhotoView(path: entry.value))),
                        icon: const Icon(Icons.visibility_outlined),
                        label: Text('View photo ${entry.key + 1}'),
                      )),
                    ],
                    if (r['sessions'] is List) Text('Sessions logged: ${(r['sessions'] as List).length}'),
                  ],
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

class _PhotoView extends StatelessWidget {
  final String path;
  const _PhotoView({required this.path});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(title: const Text('Submitted Photo'),
      backgroundColor: Colors.black, foregroundColor: Colors.white),
    body: SafeArea(child: Center(child: InteractiveViewer(
      child: Image.file(File(path), fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Text('Photo unavailable',
          style: TextStyle(color: Colors.white))),
    ))),
  );
}
