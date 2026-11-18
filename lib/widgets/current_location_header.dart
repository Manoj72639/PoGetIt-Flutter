import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class CurrentLocationHeader extends StatefulWidget {
  const CurrentLocationHeader({super.key});

  @override
  State<CurrentLocationHeader> createState() => _CurrentLocationHeaderState();
}

class _CurrentLocationHeaderState extends State<CurrentLocationHeader> {
  static const MethodChannel _channel = MethodChannel('pogetit/location');

  String _location = 'Detecting your location...';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _location = 'Detecting your location...';
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _location = 'Please turn on GPS');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() => _location = 'Location permission denied');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _location = 'Enable location in app settings');
        return;
      }
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 20),
          ),
        );
      } catch (e) {
        debugPrint('Fresh GPS failed: $e');
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition == null) rethrow;
        position = lastPosition;
      }
      debugPrint(
        'GPS coordinates: ${position.latitude}, ${position.longitude}',
      );
      if (!mounted) return;
      setState(() {
        _location =
            '${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}';
      });
      try {
        final address = await _channel
            .invokeMethod<String>('getAddress', {
              'latitude': position.latitude,
              'longitude': position.longitude,
            })
            .timeout(const Duration(seconds: 15));
        if (!mounted) return;
        if (address != null && address.trim().isNotEmpty) {
          setState(() => _location = address);
        }
      } catch (e) {
        debugPrint('Reverse geocoding failed: $e');
      }
    } catch (e, stackTrace) {
      debugPrint('LOCATION ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _location = 'Unable to detect location');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: Colors.black,
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _location,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh location',
              onPressed: _loading ? null : _loadCurrentLocation,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_outlined, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
