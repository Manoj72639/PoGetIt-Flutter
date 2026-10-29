import 'package:flutter/material.dart';
import '../models/running_quest.dart';
import '../services/location_service.dart';
import '../services/running_tracker.dart';
import '../storage/attempt_repository.dart';
import '../validators/running_validator.dart';

class RunningScreen extends StatefulWidget {
  const RunningScreen({super.key, required this.quest});
  final RunningQuest quest;
  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  late final RunningTracker tracker = RunningTracker(LocationService())
    ..addListener(_refresh);
  bool busy = false;
  ValidationResult? result;

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _finish() async {
    await tracker.finish();
    final validation = RunningValidator.validate(
      quest: widget.quest,
      elapsedSeconds: tracker.elapsedSeconds,
      distanceMetres: tracker.distanceMetres,
      gpsValid: tracker.gpsValid && tracker.acceptedSamples >= 2,
      finishFromStartMetres: tracker.finishFromStartMetres,
    );
    setState(() => result = validation);
    await AttemptRepository().save(
      questId: widget.quest.id,
      seconds: tracker.elapsedSeconds,
      metres: tracker.distanceMetres,
      result: validation,
      finishFromStartMetres: tracker.finishFromStartMetres,
    );
  }

  @override
  void dispose() {
    tracker.removeListener(_refresh);
    tracker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = tracker.state;
    final minutes = (tracker.elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (tracker.elapsedSeconds % 60).toString().padLeft(2, '0');
    final stages = widget.quest.stages;
    var accumulated = 0.0;
    return PopScope(
      canPop: state == TrackingState.idle || state == TrackingState.finished,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.quest.title)),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Text(
                widget.quest.id,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              Text(
                '$minutes:$seconds',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge,
              ),
              Text(
                '${tracker.distanceMetres.toStringAsFixed(1)} metres',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'State: ${state.name} • GPS samples: ${tracker.acceptedSamples}',
              ),
              if (tracker.finishFromStartMetres != null)
                Text(
                  'From start: ${tracker.finishFromStartMetres!.toStringAsFixed(0)} m',
                ),
              if (tracker.gpsWarning != null)
                Text(
                  tracker.gpsWarning!,
                  style: const TextStyle(color: Colors.deepOrange),
                ),
              if (stages.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (var i = 0; i < stages.length; i++)
                  Builder(
                    builder: (context) {
                      final stageStart = accumulated;
                      accumulated += stages[i];
                      final stageProgress =
                          (tracker.distanceMetres - stageStart).clamp(
                            0.0,
                            stages[i],
                          ) /
                          stages[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stage ${i + 1}: ${stages[i].toStringAsFixed(0)} m',
                          ),
                          LinearProgressIndicator(value: stageProgress),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
              ],
              const SizedBox(height: 24),
              if (state == TrackingState.idle)
                ElevatedButton(
                  onPressed: busy ? null : () => _perform(tracker.start),
                  child: const Text('Start'),
                ),
              if (state == TrackingState.running)
                ElevatedButton(
                  onPressed: busy ? null : () => _perform(tracker.pause),
                  child: const Text('Pause'),
                ),
              if (state == TrackingState.paused)
                ElevatedButton(
                  onPressed: busy ? null : () => _perform(tracker.resume),
                  child: const Text('Resume'),
                ),
              if (state == TrackingState.running ||
                  state == TrackingState.paused)
                OutlinedButton(
                  onPressed: busy ? null : () => _perform(_finish),
                  child: const Text('Finish and validate'),
                ),
              if (result != null) ...[
                const SizedBox(height: 20),
                Text(
                  'Result: ${result!.status.name.toUpperCase()}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(result!.reason),
                const Text('Attempt saved locally.'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
