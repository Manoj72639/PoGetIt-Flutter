import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;

  LatLng? _selectedLocation;
  bool _loadingLocation = false;
  bool _saving = false;
  String? _errorMessage;

  static const LatLng _initialPosition = LatLng(11.0168, 76.9558);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (_loadingLocation) return;

    setState(() {
      _loadingLocation = true;
      _errorMessage = null;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        throw Exception('GPS is disabled. Enable Location Services and retry.');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission denied. Please allow access and retry.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission permanently denied. Enable it in app settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;

      final location = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = location;
      });

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(location, 16),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
      }
    }
  }

  Future<void> _saveLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    final location = _selectedLocation;

    if (user == null || location == null) return;

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'pinnedLocation': {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.pop(context, location);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save location: $e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Location')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _initialPosition,
              zoom: 13,
            ),
            onMapCreated: (controller) {
              _mapController = controller;

              if (_selectedLocation != null) {
                controller.moveCamera(
                  CameraUpdate.newLatLngZoom(_selectedLocation!, 16),
                );
              }
            },
            onCameraMove: (position) {
              _selectedLocation = position.target;
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 36),
              child: Icon(Icons.location_pin, color: Colors.red, size: 48),
            ),
          ),

          Positioned(
            right: 16,
            top: 16,
            child: FloatingActionButton.small(
              heroTag: 'currentLocation',
              onPressed: _loadingLocation ? null : _getCurrentLocation,
              child: _loadingLocation
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),

          if (_errorMessage != null)
            Positioned(
              top: 72,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      TextButton(
                        onPressed: _getCurrentLocation,
                        child: const Text('Retry'),
                      ),
                      TextButton(
                        onPressed: Geolocator.openAppSettings,
                        child: const Text('Open App Settings'),
                      ),
                      TextButton(
                        onPressed: Geolocator.openLocationSettings,
                        child: const Text('Open Location Settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Move the map to select a location',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedLocation == null
                          ? 'Select a location'
                          : '${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                                '${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving || _selectedLocation == null
                            ? null
                            : _saveLocation,
                        icon: const Icon(Icons.check),
                        label: Text(_saving ? 'Saving...' : 'Confirm Location'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
