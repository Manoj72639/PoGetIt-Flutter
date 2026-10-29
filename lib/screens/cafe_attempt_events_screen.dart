import 'dart:io';

import 'package:flutter/material.dart';
import '../storage/cafe_attempt_repository.dart';

class CafeAttemptEventsScreen extends StatefulWidget {
  const CafeAttemptEventsScreen({super.key});

  @override
  State<CafeAttemptEventsScreen> createState() =>
      _CafeAttemptEventsScreenState();
}

class _CafeAttemptEventsScreenState extends State<CafeAttemptEventsScreen> {
  late Future<List<Map<String, dynamic>>> _attemptsFuture;

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  void _loadAttempts() {
    _attemptsFuture = CafeAttemptRepository().all();
  }

  Future<void> _refresh() async {
    setState(_loadAttempts);
    try {
      await _attemptsFuture;
    } catch (_) {
      // The FutureBuilder displays the error.
    }
  }

  String _questTitle(String id) {
    switch (id) {
      case 'CE-E001':
        return 'Coffee Break Outside';
      case 'CE-E008':
        return 'Quiet Corner';
      case 'CE-H001':
        return 'Three Cafe Expedition';
      default:
        return 'Cafe Quest';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Cafe Attempt History',
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _attemptsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: TextButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry loading attempts'),
                ),
              );
            }

            final attempts = snapshot.data ?? [];

            if (attempts.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  children: const [
                    SizedBox(height: 140),
                    Center(child: Text('No cafe attempts yet')),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: attempts.length,
                itemBuilder: (context, index) {
                  return _attemptCard(attempts[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _attemptCard(Map<String, dynamic> item) {
    final questId = (item['questId'] ?? '').toString();

    final status = (item['status'] ?? 'in_progress').toString().toLowerCase();

    final reason = (item['reason'] ?? '').toString();

    final timestamp = (item['timestamp'] ?? '').toString();

    final photoPath = (item['photoPath'] ?? item['photoRef'] ?? '').toString();

    final distance = item['distanceMetres'];

    final accepted = status == 'accepted' || status == 'passed';

    final rejected = status == 'rejected' || status == 'failed';

    final color = accepted
        ? Colors.green
        : rejected
        ? Colors.red
        : Colors.orange;

    final icon = accepted
        ? Icons.check_circle_outline
        : rejected
        ? Icons.cancel_outlined
        : Icons.access_time;

    final statusLabel = accepted
        ? 'Accepted'
        : rejected
        ? 'Rejected'
        : 'In progress';

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          _questTitle(questId),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$questId • $statusLabel',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        children: [
          const Divider(height: 16),

          _detailRow('Status', statusLabel),

          _detailRow('Time', timestamp.isEmpty ? 'N/A' : timestamp),

          if (distance != null) _detailRow('Distance', '$distance m'),

          _detailRow('Reason', reason.isEmpty ? 'No details' : reason),

          if (photoPath.isNotEmpty) ...[
            const SizedBox(height: 12),
            FutureBuilder<bool>(
              future: File(photoPath).exists(),
              builder: (context, snapshot) {
                if (snapshot.data != true) {
                  return const Text(
                    'Photo unavailable',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  );
                }

                return OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => CafePhotoViewer(photoPath: photoPath),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View Photo'),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// Keep this class only if it is not already
// defined elsewhere in your project.
class CafePhotoViewer extends StatelessWidget {
  final String photoPath;

  const CafePhotoViewer({super.key, required this.photoPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Uploaded Photo'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Image.file(
              File(photoPath),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return const Text(
                  'Unable to load photo',
                  style: TextStyle(color: Colors.white),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
