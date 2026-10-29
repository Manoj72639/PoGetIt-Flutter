import 'package:geolocator/geolocator.dart';

class LocationService {
  static const double maxAccuracyMetres = 35;
  static const double maxPlausibleSpeedMetresPerSecond = 8;

  Future<void> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Enable location services in Android settings.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission denied. Enable it in app settings.');
    }
  }

  Stream<Position> watch() => Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ));

  Future<Position> current() => Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15)));

  bool reliable(Position position) =>
      position.accuracy.isFinite && position.accuracy >= 0 &&
      position.accuracy <= maxAccuracyMetres;
}
