import 'package:flutter/material.dart';
import '../models/day3_quest.dart';
import '../models/day3_validator.dart';
import '../storage/day3_repository.dart';

class Day3ResetScreen extends StatefulWidget {
  final Day3Quest quest;
  const Day3ResetScreen({super.key, required this.quest});
  @override
  State<Day3ResetScreen> createState() => _Day3ResetScreenState();
}

class _Day3ResetScreenState extends State<Day3ResetScreen> {
  late final List<bool> _checks;
  final _sessions = <Map<String, dynamic>>[];
  final _minutes = TextEditingController(text: '5');
  late final String _attemptId;
  bool _confirmed = false;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _checks = List<bool>.filled(widget.quest.checklist.length, false);
    _attemptId = DateTime.now().microsecondsSinceEpoch.toString();
  }

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  void _addSession() {
    final value = int.tryParse(_minutes.text.trim());
    if (value == null || value <= 0 || value > 1440) {
      setState(() => _message = 'Enter a duration between 1 and 1440 minutes.');
      return;
    }
    setState(() {
      _sessions.add({'date': DateTime.now().toIso8601String(), 'minutes': value});
      _message = null;
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = Day3Validator.reset(widget.quest,
        confirmed: _confirmed,
        checklistComplete: _checks.every((value) => value),
        sessions: _sessions.length);
      await Day3Repository().save({
        'attemptId': _attemptId,
        'questId': widget.quest.id,
        'title': widget.quest.title,
        'category': 'Mindfulness / Reset',
        'status': result.status.name,
        'reason': result.reason,
        'timestamp': DateTime.now().toIso8601String(),
        'checklist': List<bool>.from(_checks),
        'sessions': List<Map<String, dynamic>>.from(_sessions),
        'confirmed': _confirmed,
      });
      if (mounted) setState(() => _message = result.reason);
    } catch (e) {
      if (mounted) setState(() => _message = 'Could not save attempt: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.quest.title)),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Text(widget.quest.instructions),
      const SizedBox(height: 16),
      ...widget.quest.checklist.asMap().entries.map((entry) => CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(entry.value),
        value: _checks[entry.key],
        onChanged: (value) => setState(() => _checks[entry.key] = value ?? false),
      )),
      if (widget.quest.requiredSessions > 0) ...[
        Text('Sessions: ${_sessions.length} / ${widget.quest.requiredSessions}',
          style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(controller: _minutes, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Session duration (minutes)',
            border: OutlineInputBorder())),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: _addSession,
          icon: const Icon(Icons.add), label: const Text('Log Session Now')),
        ..._sessions.asMap().entries.map((entry) => ListTile(
          dense: true, title: Text('Session ${entry.key + 1} • ${entry.value['minutes']} min'),
          subtitle: Text(entry.value['date'].toString()),
          trailing: IconButton(icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => _sessions.removeAt(entry.key))),
        )),
      ],
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('I completed this activity'),
        value: _confirmed,
        onChanged: (value) => setState(() => _confirmed = value ?? false),
      ),
      const SizedBox(height: 8),
      FilledButton(onPressed: _busy ? null : _submit,
        child: const Text('Submit Completion')),
      if (_message != null) Padding(padding: const EdgeInsets.only(top: 12),
        child: Text(_message!)),
      const SizedBox(height: 12),
      const Text('No journal text, mood details, or private photos are collected.',
        style: TextStyle(fontSize: 12, color: Colors.grey)),
    ]),
  );
}
