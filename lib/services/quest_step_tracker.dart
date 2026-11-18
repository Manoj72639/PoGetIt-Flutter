import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

enum StepTrackingState { idle, running, paused, finished }

class QuestStepTracker extends ChangeNotifier {
  StreamSubscription<StepCount>? _subscription;

  StepTrackingState state = StepTrackingState.idle;

  int steps = 0;

  int? _lastSensorCount;
  DateTime? _lastSampleTime;
  DateTime? _activeStart;

  bool reliable = false;
  String? warning;

  bool _hasBaseline = false;
  bool _sensorError = false;
  bool _disposed = false;

  // Indicates whether some steps around a tracking
  // boundary could not be attributed precisely.
  bool _boundaryUncertain = false;

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> start() async {
    if (state != StepTrackingState.idle) {
      throw StateError('Step tracking already started.');
    }

    final permission = await Permission.activityRecognition.request();

    if (!permission.isGranted) {
      throw StateError('Activity recognition permission denied.');
    }

    steps = 0;
    _lastSensorCount = null;
    _lastSampleTime = null;
    _activeStart = DateTime.now();

    reliable = false;
    warning = 'Waiting for step sensor baseline.';

    _hasBaseline = false;
    _sensorError = false;
    _boundaryUncertain = false;

    state = StepTrackingState.running;

    _subscribe();
    _notify();
  }

  void _subscribe() {
    _subscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: (Object error) {
        _sensorError = true;
        reliable = false;
        warning = 'Step sensor error: $error';
        _notify();
      },
      cancelOnError: false,
    );
  }

  void _onStepCount(StepCount event) {
    if (state != StepTrackingState.running) {
      return;
    }

    final count = event.steps;
    final timestamp = event.timeStamp;

    if (_activeStart != null && timestamp.isBefore(_activeStart!)) {
      return;
    }

    if (!_hasBaseline) {
      _lastSensorCount = count;
      _lastSampleTime = timestamp;
      _hasBaseline = true;

      reliable = false;
      warning = 'Waiting for step updates.';
      _notify();
      return;
    }

    final previous = _lastSensorCount;
    final previousTime = _lastSampleTime;

    if (previous == null || previousTime == null) {
      _sensorError = true;
      reliable = false;
      warning = 'Missing previous step sample.';
      _notify();
      return;
    }

    if (timestamp.isBefore(previousTime)) {
      _sensorError = true;
      reliable = false;
      warning = 'Out-of-order step sensor reading.';
      _notify();
      return;
    }

    if (count < previous) {
      _sensorError = true;
      reliable = false;
      warning = 'Step counter reset detected.';
      _notify();
      return;
    }

    // Ignore exact duplicate sensor readings.
    if (count == previous) {
      _lastSampleTime = timestamp;
      _notify();
      return;
    }

    // Both samples must belong to the active interval.
    if (_activeStart != null && previousTime.isBefore(_activeStart!)) {
      _boundaryUncertain = true;

      _lastSensorCount = count;
      _lastSampleTime = timestamp;

      reliable = false;
      warning = 'Step interval crossed tracking boundary.';
      _notify();
      return;
    }

    final delta = count - previous;

    steps += delta;

    _lastSensorCount = count;
    _lastSampleTime = timestamp;

    reliable = !_sensorError && !_boundaryUncertain && _hasBaseline;

    warning = reliable ? null : 'Some step evidence is incomplete.';

    _notify();
  }

  Future<void> pause() async {
    if (state != StepTrackingState.running) {
      return;
    }

    state = StepTrackingState.paused;

    // The sensor may have unreported steps since
    // the last accepted reading.
    _boundaryUncertain = true;
    reliable = false;

    warning =
        'Steps near the pause boundary '
        'could not be verified.';

    await _subscription?.cancel();
    _subscription = null;

    _notify();
  }

  Future<void> resume() async {
    if (state != StepTrackingState.paused) {
      return;
    }

    _activeStart = DateTime.now();

    _lastSensorCount = null;
    _lastSampleTime = null;
    _hasBaseline = false;

    state = StepTrackingState.running;

    warning = 'Waiting for new step baseline.';

    _subscribe();
    _notify();
  }

  Future<void> finish() async {
    if (state == StepTrackingState.finished) {
      return;
    }

    if (state == StepTrackingState.running) {
      // A final sensor delta may not have arrived.
      _boundaryUncertain = true;
    }

    state = StepTrackingState.finished;

    await _subscription?.cancel();
    _subscription = null;

    reliable = _hasBaseline && !_sensorError && !_boundaryUncertain;

    if (!reliable) {
      warning =
          'Quest step evidence is incomplete. '
          'The sensor did not confirm all '
          'tracking boundaries.';
    } else {
      warning = null;
    }

    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
