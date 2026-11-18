import 'package:geolocator/geolocator.dart';

class LocationService {
  // Maximum accepted GPS accuracy.
  static const double maxAccuracyMetres = 35;

  // Maximum plausible walking/jogging speed.
  static const double maxPlausibleSpeedMetresPerSecond = 8;

  Future<void> ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      throw StateError(
        'Please enable GPS/location services '
        'in your device settings.',
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location permission permanently denied. '
        'Enable it from Android app settings.',
      );
    }

    if (permission == LocationPermission.denied) {
      throw StateError(
        'Location permission is required '
        'to start this quest.',
      );
    }

    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw StateError('Location permission is unavailable.');
    }
  }

  Stream<Position> watch() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    );
  }

  Future<Position> current() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!reliable(position)) {
        throw StateError(
          'GPS accuracy is too low '
          '(${position.accuracy.toStringAsFixed(0)} m). '
          'Please move to an open area.',
        );
      }

      return position;
    } catch (e) {
      if (e is StateError) rethrow;

      throw StateError('Unable to get current GPS location: $e');
    }
  }

  bool reliable(Position position) {
    if (!position.latitude.isFinite || !position.longitude.isFinite) {
      return false;
    }

    if (!position.accuracy.isFinite ||
        position.accuracy < 0 ||
        position.accuracy > maxAccuracyMetres) {
      return false;
    }

    if (position.latitude < -90 ||
        position.latitude > 90 ||
        position.longitude < -180 ||
        position.longitude > 180) {
      return false;
    }

    final age = DateTime.now().difference(position.timestamp);

    // Reject stale or future-dated GPS readings.
    if (age > const Duration(seconds: 15) ||
        age < const Duration(seconds: -5)) {
      return false;
    }

    return true;
  }
}
