import 'package:flutter/material.dart';

import '../models/running_quest.dart';
import '../services/location_service.dart';
import '../services/running_tracker.dart';
import '../storage/attempt_repository.dart';
import '../validators/running_validator.dart';

class RunningScreen extends StatefulWidget {
  const RunningScreen({
    super.key,
    required this.quest,
    this.requiredSteps,
    this.requiresTaskDeclaration = false,
    this.requiresReview = false,
  });

  final RunningQuest quest;

  final int? requiredSteps;

  final bool requiresTaskDeclaration;

  // Indicates whether additional evidence review
  // is required before confirming completion.
  final bool requiresReview;

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  late final RunningTracker tracker = RunningTracker(LocationService())
    ..addListener(_refresh);

  bool busy = false;
  bool taskDeclared = false;

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
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _finish() async {
    await tracker.finish();

    final gpsReliable = tracker.gpsValid && tracker.acceptedSamples >= 2;

    final ValidationResult validation;

    if (widget.requiredSteps != null) {
      validation = RunningValidator.validateGpsAndSteps(
        distanceMetres: tracker.distanceMetres,
        questSteps: tracker.questSteps,
        requiredGpsMetres: widget.quest.minMetres,
        requiredSteps: widget.requiredSteps!,
        gpsReliable: gpsReliable,
        stepsReliable: tracker.stepsReliable,
        taskDeclared: !widget.requiresTaskDeclaration || taskDeclared,
      );
    } else {
      validation = RunningValidator.validate(
        quest: widget.quest,
        elapsedSeconds: tracker.elapsedSeconds,
        distanceMetres: tracker.distanceMetres,
        gpsValid: gpsReliable,
        finishFromStartMetres: tracker.finishFromStartMetres,
      );
    }

    if (mounted) {
      setState(() => result = validation);
    }

    await AttemptRepository().save(
      questId: widget.quest.id,
      seconds: tracker.elapsedSeconds,
      metres: tracker.distanceMetres,
      result: validation,
      finishFromStartMetres: tracker.finishFromStartMetres,

      // GPS + Steps evidence.
      questSteps: widget.requiredSteps == null ? null : tracker.questSteps,

      requiredGpsMetres: widget.requiredSteps == null
          ? null
          : widget.quest.minMetres,

      requiredSteps: widget.requiredSteps,

      taskDeclared: widget.requiresTaskDeclaration ? taskDeclared : null,

      gpsReliable: gpsReliable,

      stepsReliable: widget.requiredSteps == null
          ? null
          : tracker.stepsReliable,

      requiresReview: widget.requiresReview,
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
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.quest.id,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),

              Text(
                '$minutes:$seconds',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge,
              ),

              const SizedBox(height: 8),

              Text(
                '${tracker.distanceMetres.toStringAsFixed(1)} metres',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              const SizedBox(height: 8),

              Text(
                '${tracker.questSteps} quest steps',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),

              if (widget.requiredSteps != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Required distance: '
                  '${widget.quest.minMetres.toStringAsFixed(0)} m',
                ),
                Text('Required steps: ${widget.requiredSteps}'),
              ],

              const SizedBox(height: 12),

              Text(
                'State: ${state.name} '
                '• GPS samples: ${tracker.acceptedSamples}',
              ),

              if (tracker.finishFromStartMetres != null)
                Text(
                  'From start: '
                  '${tracker.finishFromStartMetres!.toStringAsFixed(0)} m',
                ),

              if (tracker.gpsWarning != null)
                Text(
                  tracker.gpsWarning!,
                  style: const TextStyle(color: Colors.deepOrange),
                ),

              if (tracker.stepsWarning != null)
                Text(
                  tracker.stepsWarning!,
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

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stage ${i + 1}: '
                              '${stages[i].toStringAsFixed(0)} m',
                            ),
                            LinearProgressIndicator(value: stageProgress),
                          ],
                        ),
                      );
                    },
                  ),
              ],

              if (widget.requiresTaskDeclaration) ...[
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: taskDeclared,
                  onChanged: state == TrackingState.finished
                      ? null
                      : (value) {
                          setState(() {
                            taskDeclared = value ?? false;
                          });
                        },
                  title: const Text('I completed the required quest task.'),
                ),
              ],

              const SizedBox(height: 20),

              if (state == TrackingState.idle)
                FilledButton(
                  onPressed: busy ? null : () => _perform(tracker.start),
                  child: const Text('Start'),
                ),

              if (state == TrackingState.running)
                FilledButton.tonal(
                  onPressed: busy ? null : () => _perform(tracker.pause),
                  child: const Text('Pause'),
                ),

              if (state == TrackingState.paused)
                FilledButton(
                  onPressed: busy ? null : () => _perform(tracker.resume),
                  child: const Text('Resume'),
                ),

              if (state == TrackingState.running ||
                  state == TrackingState.paused)
                OutlinedButton(
                  onPressed: busy ? null : () => _perform(_finish),
                  child: const Text('Finish and Validate'),
                ),

              if (result != null) ...[
                const SizedBox(height: 20),
                Text(
                  'Result: ${result!.status.name.toUpperCase()}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(result!.reason),
                const SizedBox(height: 6),
                const Text('Attempt saved locally.'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
