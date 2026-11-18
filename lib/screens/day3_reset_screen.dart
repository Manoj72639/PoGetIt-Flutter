import 'dart:ui' show FontFeature;
import 'dart:async';

import 'package:flutter/material.dart';

import '../adapter/master_mindfulness_quest_adapter.dart';
import '../models/day3_quest.dart';
import '../models/day3_validator.dart';
import '../storage/day3_repository.dart';

class Day3ResetScreen extends StatefulWidget {
  final Day3Quest quest;
  final MindfulnessQuestConfig? masterConfig;

  const Day3ResetScreen({super.key, required this.quest, this.masterConfig});

  @override
  State<Day3ResetScreen> createState() => _Day3ResetScreenState();
}

class _Day3ResetScreenState extends State<Day3ResetScreen> {
  late final List<bool> _checks;
  final List<Map<String, dynamic>> _sessions = [];
  late final String _attemptId;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  bool _confirmed = false;
  bool _busy = false;
  bool _submitted = false;
  String? _message;
  String? _status;

  @override
  void initState() {
    super.initState();
    _checks = List<bool>.filled(widget.quest.checklist.length, false);
    _attemptId = DateTime.now().microsecondsSinceEpoch.toString();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _startOrResume() {
    if (_busy || _submitted || _stopwatch.isRunning) return;
    _stopwatch.start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) setState(() => _elapsed = _stopwatch.elapsed);
    });
    setState(() => _message = null);
  }

  void _pause() {
    _stopwatch.stop();
    _ticker?.cancel();
    setState(() => _elapsed = _stopwatch.elapsed);
  }

  void _finishSession() {
    if (_busy || _submitted) return;
    _stopwatch.stop();
    _ticker?.cancel();
    final elapsed = _stopwatch.elapsed;
    if (elapsed < const Duration(minutes: 1)) {
      setState(() {
        _elapsed = elapsed;
        _message = 'A session must last at least one minute to be logged.';
      });
      return;
    }
    final now = DateTime.now();
    setState(() {
      _sessions.add({
        'date': now.toIso8601String(),
        'minutes': elapsed.inMinutes,
        'durationSeconds': elapsed.inSeconds,
      });
      _stopwatch.reset();
      _elapsed = Duration.zero;
      _message =
          'Session saved locally. Submit the quest to save your attempt.';
    });
  }

  void _removeSession(int index) {
    if (_busy || _submitted) return;
    setState(() => _sessions.removeAt(index));
  }

  Future<void> _submit() async {
    if (_busy || _submitted || _stopwatch.isRunning) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = Day3Validator.reset(
        widget.quest,
        confirmed: _confirmed,
        checklistComplete: _checks.every((value) => value),
        sessions: _sessions.length,
      );
      final masterConfig = widget.masterConfig;
      final needsReview = masterConfig?.requiresReview ?? false;
      final status = needsReview && result.status == Day3Status.passed
          ? Day3Status.incomplete
          : result.status;
      final reason = needsReview && result.status == Day3Status.passed
          ? 'Activity recorded. Master Quest conditions require review before approval.'
          : result.reason;
      await Day3Repository().save({
        'attemptId': _attemptId,
        'questId': widget.quest.id,
        'title': widget.quest.title,
        'category': 'Mindfulness / Reset',
        'status': status.name,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
        'checklist': List<bool>.from(_checks),
        'sessions': _sessions.map((e) => Map<String, dynamic>.from(e)).toList(),
        'confirmed': _confirmed,
        if (masterConfig != null)
          'masterQuestVersion': masterConfig.master.version,
        if (masterConfig != null) 'requiresReview': needsReview,
      });
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _status = status.name;
        _message = reason;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mindfulness attempt saved')),
      );
    } catch (e) {
      if (mounted) setState(() => _message = 'Could not save attempt: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final running = _stopwatch.isRunning;
    final locked = _busy || _submitted;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mindfulness Quest'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.masterConfig != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Master Quest requirements',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (widget
                          .masterConfig!
                          .master
                          .successCondition
                          .isNotEmpty)
                        Text(widget.masterConfig!.master.successCondition),
                      if (widget
                          .masterConfig!
                          .master
                          .evidenceRule
                          .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(widget.masterConfig!.master.evidenceRule),
                      ],
                      const SizedBox(height: 8),
                      const Text(
                        'Session count and duration are not inferred from quest text. Master Quest completion requires review.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.self_improvement_outlined, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      widget.quest.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(widget.quest.instructions),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Session timer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _formatDuration(_elapsed),
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: locked
                                ? null
                                : (running ? _pause : _startOrResume),
                            icon: Icon(
                              running ? Icons.pause : Icons.play_arrow,
                            ),
                            label: Text(
                              running
                                  ? 'Pause'
                                  : (_elapsed > Duration.zero
                                        ? 'Resume'
                                        : 'Start'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: locked || _elapsed == Duration.zero
                                ? null
                                : _finishSession,
                            icon: const Icon(Icons.stop_outlined),
                            label: const Text('Finish'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Only completed sessions lasting at least one minute are logged.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Sessions: ${_sessions.length} / ${widget.quest.requiredSessions}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (final entry in _sessions.asMap().entries)
              Card(
                child: ListTile(
                  title: Text('Session ${entry.key + 1}'),
                  subtitle: Text(
                    '${entry.value['minutes']} minute(s) • ${entry.value['date']}',
                  ),
                  trailing: _submitted
                      ? null
                      : IconButton(
                          tooltip: 'Remove session',
                          onPressed: _busy
                              ? null
                              : () => _removeSession(entry.key),
                          icon: const Icon(Icons.delete_outline),
                        ),
                ),
              ),
            if (widget.quest.checklist.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                'Checklist',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              for (final entry in widget.quest.checklist.asMap().entries)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.black,
                  title: Text(entry.value),
                  value: _checks[entry.key],
                  onChanged: locked
                      ? null
                      : (value) =>
                            setState(() => _checks[entry.key] = value ?? false),
                ),
            ],
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.black,
              title: const Text('I completed this activity'),
              value: _confirmed,
              onChanged: locked
                  ? null
                  : (value) => setState(() => _confirmed = value ?? false),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: locked || running ? null : _submit,
              child: Text(
                _busy
                    ? 'Saving...'
                    : (_submitted ? 'Attempt Saved' : 'Submit Completion'),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_status != null) ...[
                        Text(
                          'Validation: $_status',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(_message!),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'No journal text, mood details, or private photos are collected. '
              'The timer records elapsed time; other quest conditions are not automatically verified.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
