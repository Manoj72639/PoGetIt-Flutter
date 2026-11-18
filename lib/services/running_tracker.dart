import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'location_service.dart';
import 'quest_step_tracker.dart';

enum TrackingState { idle, running, paused, finished }

class RunningTracker extends ChangeNotifier {
  RunningTracker(this.locationService) {
    stepTracker.addListener(_onStepsChanged);
  }

  final LocationService locationService;

  final QuestStepTracker stepTracker = QuestStepTracker();

  final Stopwatch _watch = Stopwatch();

  Timer? _ticker;
  StreamSubscription<Position>? _subscription;

  TrackingState state = TrackingState.idle;

  double distanceMetres = 0;

  Position? startPosition;
  Position? lastPosition;

  String? gpsWarning;

  bool gpsValid = false;

  int acceptedSamples = 0;

  int get elapsedSeconds => _watch.elapsed.inSeconds;

  int get questSteps => stepTracker.steps;

  bool get stepsReliable => stepTracker.reliable;

  String? get stepsWarning => stepTracker.warning;

  double? get finishFromStartMetres {
    if (startPosition == null || lastPosition == null) {
      return null;
    }

    return Geolocator.distanceBetween(
      startPosition!.latitude,
      startPosition!.longitude,
      lastPosition!.latitude,
      lastPosition!.longitude,
    );
  }

  void _onStepsChanged() {
    notifyListeners();
  }

  Future<void> start() async {
    if (state != TrackingState.idle) {
      throw StateError('Quest already started.');
    }

    await locationService.ensurePermission();

    final first = await locationService.current();

    if (!locationService.reliable(first)) {
      throw StateError(
        'Initial GPS accuracy too low '
        '(${first.accuracy.toStringAsFixed(0)}m).',
      );
    }

    await stepTracker.start();

    startPosition = first;
    lastPosition = first;

    distanceMetres = 0;
    acceptedSamples = 1;

    gpsValid = true;
    gpsWarning = null;

    state = TrackingState.running;

    _watch.start();

    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => notifyListeners(),
    );

    _listen();
    notifyListeners();
  }

  void _listen() {
    _subscription = locationService.watch().listen(
      (position) {
        if (state != TrackingState.running) return;

        if (!locationService.reliable(position)) {
          gpsWarning =
              'Ignoring inaccurate GPS '
              '(${position.accuracy.toStringAsFixed(0)}m).';
          notifyListeners();
          return;
        }

        final previous = lastPosition;

        if (previous != null) {
          final seconds =
              position.timestamp.difference(previous.timestamp).inMilliseconds /
              1000;

          final delta = Geolocator.distanceBetween(
            previous.latitude,
            previous.longitude,
            position.latitude,
            position.longitude,
          );

          if (seconds <= 0 ||
              delta / seconds >
                  LocationService.maxPlausibleSpeedMetresPerSecond) {
            gpsWarning = 'GPS jump ignored.';
            notifyListeners();
            return;
          }

          distanceMetres += delta;
        }

        lastPosition = position;
        acceptedSamples++;

        gpsWarning = null;
        notifyListeners();
      },
      onError: (Object error) {
        gpsValid = false;
        gpsWarning = 'GPS stream failed: $error';
        notifyListeners();
      },
    );
  }

  Future<void> pause() async {
    if (state != TrackingState.running) return;

    state = TrackingState.paused;
    _watch.stop();

    await _subscription?.cancel();
    _subscription = null;

    await stepTracker.pause();

    notifyListeners();
  }

  Future<void> resume() async {
    if (state != TrackingState.paused) return;

    await locationService.ensurePermission();

    final fix = await locationService.current();

    if (!locationService.reliable(fix)) {
      throw StateError('GPS accuracy too low to resume.');
    }

    // Reset the GPS baseline.
    // Do not count movement during the pause.
    lastPosition = fix;

    await stepTracker.resume();

    state = TrackingState.running;
    _watch.start();

    _listen();
    notifyListeners();
  }

  Future<void> finish() async {
    if (state == TrackingState.finished) return;

    // Stop accepting new GPS samples immediately.
    state = TrackingState.finished;

    _watch.stop();

    _ticker?.cancel();
    _ticker = null;

    await _subscription?.cancel();
    _subscription = null;

    await stepTracker.finish();

    notifyListeners();
  }

  @override
  void dispose() {
    _watch.stop();
    _ticker?.cancel();
    _subscription?.cancel();

    stepTracker.removeListener(_onStepsChanged);
    stepTracker.dispose();

    super.dispose();
  }
}
