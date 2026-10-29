import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'location_service.dart';

enum TrackingState { idle, running, paused, finished }

class RunningTracker extends ChangeNotifier {
  RunningTracker(this.locationService);
  final LocationService locationService;
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
  double? get finishFromStartMetres => startPosition == null || lastPosition == null
      ? null : Geolocator.distanceBetween(startPosition!.latitude,
          startPosition!.longitude, lastPosition!.latitude, lastPosition!.longitude);

  Future<void> start() async {
    await locationService.ensurePermission();
    final first = await locationService.current();
    if (!locationService.reliable(first)) {
      throw StateError('Initial GPS accuracy too low (${first.accuracy.toStringAsFixed(0)}m). Try outdoors.');
    }
    startPosition = first;
    lastPosition = first;
    gpsValid = true;
    acceptedSamples = 1;
    gpsWarning = null;
    state = TrackingState.running;
    _watch.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
    _listen();
    notifyListeners();
  }

  void _listen() {
    _subscription = locationService.watch().listen((position) {
      if (state != TrackingState.running) return;
      if (!locationService.reliable(position)) {
        gpsWarning = 'Ignoring inaccurate GPS (${position.accuracy.toStringAsFixed(0)}m).';
        notifyListeners();
        return;
      }
      final previous = lastPosition;
      if (previous != null) {
        final seconds = position.timestamp.difference(previous.timestamp).inMilliseconds / 1000;
        final delta = Geolocator.distanceBetween(previous.latitude,
            previous.longitude, position.latitude, position.longitude);
        if (seconds <= 0 || delta / seconds > LocationService.maxPlausibleSpeedMetresPerSecond) {
          gpsWarning = 'GPS jump ignored; tracking may be incomplete.';
          notifyListeners();
          return;
        }
        distanceMetres += delta;
      }
      lastPosition = position;
      acceptedSamples++;
      gpsWarning = null;
      notifyListeners();
    }, onError: (Object error) {
      gpsValid = false;
      gpsWarning = 'GPS stream failed: $error';
      notifyListeners();
    });
  }

  Future<void> pause() async {
    if (state != TrackingState.running) return;
    _watch.stop();
    await _subscription?.cancel();
    _subscription = null;
    state = TrackingState.paused;
    notifyListeners();
  }

  Future<void> resume() async {
    if (state != TrackingState.paused) return;
    await locationService.ensurePermission();
    final fix = await locationService.current();
    if (!locationService.reliable(fix)) {
      throw StateError('GPS accuracy too low to resume.');
    }
    // Do not count travel while paused.
    lastPosition = fix;
    _watch.start();
    state = TrackingState.running;
    _listen();
    notifyListeners();
  }

  Future<void> finish() async {
    _watch.stop();
    _ticker?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    state = TrackingState.finished;
    notifyListeners();
  }

  @override
  void dispose() {
    _watch.stop();
    _ticker?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
