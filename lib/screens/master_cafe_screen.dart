import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../adapter/master_cafe_quest_adapter.dart';
import '../models/cafe_quest.dart';
import '../services/location_service.dart';

/// Only supply venues with verified, real coordinates. Never pass testVenues.
class MasterCafeScreen extends StatefulWidget {
  const MasterCafeScreen({
    super.key,
    required this.config,
    this.venues = const <CafeVenue>[],
    this.radiusMetres = 100,
  });

  final MasterCafeQuestConfig config;
  final List<CafeVenue> venues;
  final double radiusMetres;

  @override
  State<MasterCafeScreen> createState() => _MasterCafeScreenState();
}

class _MasterCafeScreenState extends State<MasterCafeScreen> {
  final _location = LocationService();
  final _picker = ImagePicker();
  final List<_Visit> _visits = [];
  String? _selectedVenueId;
  String? _photoPath;
  bool _declared = false;
  bool _busy = false;
  bool _finished = false;
  bool _started = false;
  DateTime? _startedAt;
  String _message = 'Tap Start Quest to begin.';
  String _status = 'Not started';

  CafeVenue? get _selectedVenue {
    for (final venue in widget.venues) {
      if (venue.id == _selectedVenueId) return venue;
    }
    return null;
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy || _finished) return;
    setState(() => _busy = true);
    try {
      await operation();
    } catch (e) {
      if (mounted) setState(() => _message = 'Action failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _start() {
    setState(() {
      _started = true;
      _startedAt = DateTime.now();
      _message = 'Complete the quest task and provide evidence.';
      _status = 'In progress';
    });
  }

  Future<void> _checkIn() => _run(() async {
    if (!_started) return;
    final venue = _selectedVenue;
    if (venue == null) {
      throw StateError('Choose a verified café. No venues are configured.');
    }
    if (!venue.latitude.isFinite ||
        !venue.longitude.isFinite ||
        venue.latitude < -90 ||
        venue.latitude > 90 ||
        venue.longitude < -180 ||
        venue.longitude > 180 ||
        widget.radiusMetres <= 0) {
      throw StateError('Invalid verified venue configuration.');
    }
    await _location.ensurePermission();
    final position = await _location.current();
    if (!_location.reliable(position)) {
      throw StateError('Reliable GPS is unavailable. Try outdoors.');
    }
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      venue.latitude,
      venue.longitude,
    );
    if (distance > widget.radiusMetres) {
      throw StateError(
        'Outside the allowed radius: ${distance.toStringAsFixed(0)} m '
        '(limit ${widget.radiusMetres.toStringAsFixed(0)} m).',
      );
    }
    if (widget.config.requiredDistinctVenues > 0 &&
        _visits.any((v) => v.venueId == venue.id)) {
      throw StateError('This quest requires a different café.');
    }
    if (widget.config.sameVenueSeparateOccasions && _visits.isNotEmpty) {
      // The catalog does not specify a minimum interval. A second
      // same-session tap must not count as a separate occasion.
      throw StateError(
        'Separate occasions cannot be verified in this session. '
        'This quest needs a future session-aware workflow.',
      );
    }
    setState(() {
      _visits.add(_Visit(venue.id, DateTime.now(), distance));
      _message =
          'GPS check-in recorded at ${venue.name} '
          '(${distance.toStringAsFixed(0)} m from venue).';
    });
  });

  Future<void> _takePhoto() => _run(() async {
    if (!_started) return;
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (image == null) return;
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/cafe_evidence');
    await dir.create(recursive: true);
    final file = await File(
      image.path,
    ).copy('${dir.path}/${DateTime.now().microsecondsSinceEpoch}.jpg');
    if (mounted) {
      setState(() {
        _photoPath = file.path;
        _message =
            'Photo attached. Photo contents are not automatically verified.';
      });
    }
  });

  Future<void> _finish() => _run(() async {
    if (!_started) return;
    final config = widget.config;
    final distinct = _visits.map((v) => v.venueId).toSet().length;
    final hasEvidence = _declared || _photoPath != null;
    String status;
    String reason;

    if (!hasEvidence) {
      status = 'Incomplete';
      reason = 'Provide a task declaration or photo.';
    } else if (config.requiresVenueVisit &&
        (_visits.length < config.requiredCheckins ||
            distinct < config.requiredDistinctVenues)) {
      status = 'Incomplete';
      reason =
          'Verified GPS check-ins: ${_visits.length}/${config.requiredCheckins}; '
          'distinct cafés: $distinct/${config.requiredDistinctVenues}. '
          'A self-declared visit cannot count as verified attendance.';
    } else if (config.sameVenueSeparateOccasions) {
      status = 'Incomplete';
      reason = 'Separate-occasion attendance requires a session-aware review.';
    } else {
      // Imported rules require review. Even if not, GPS only proves
      // proximity; the task observation/photo content is not verified.
      status = 'Incomplete';
      reason = config.requiresReview
          ? 'Evidence recorded; awaiting review. Not yet passed.'
          : 'Evidence recorded; task content needs verification.';
    }

    final record = <String, dynamic>{
      'category': 'cafeExploration',
      'questId': config.id,
      'timestamp': DateTime.now().toIso8601String(),
      'startedAt': _startedAt?.toIso8601String(),
      'status': status.toLowerCase(),
      'reason': reason,
      'requiredCheckins': config.requiredCheckins,
      'requiredDistinctVenues': config.requiredDistinctVenues,
      'requiresReview': config.requiresReview,
      'taskDeclared': _declared,
      'photoPath': _photoPath,
      'checkins': _visits.map((v) => v.toJson()).toList(),
    };
    final prefs = await SharedPreferences.getInstance();
    const key = 'pogetit_master_cafe_attempts_v1';
    final entries = prefs.getStringList(key) ?? <String>[];
    entries.add(jsonEncode(record));
    if (!await prefs.setStringList(key, entries)) {
      throw StateError('Unable to save attempt. Please retry.');
    }
    if (mounted) {
      setState(() {
        _status = status;
        _message = reason;
        _finished = true;
      });
    }
  });

  @override
  Widget build(BuildContext context) {
    final q = widget.config;
    return Scaffold(
      appBar: AppBar(title: Text(q.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(q.id, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(q.instructions),
            const SizedBox(height: 12),
            Text(
              q.requiresVenueVisit
                  ? 'Venue visit: ${q.requiredCheckins} GPS check-in(s); '
                        '${q.requiredDistinctVenues} distinct café(s) required.'
                  : 'Off-site task: no café check-in required.',
            ),
            if (q.sameVenueSeparateOccasions)
              const Text(
                'Separate occasions required; not auto-verifiable yet.',
              ),
            if (q.requiresVenueVisit && widget.venues.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'No verified café locations configured. GPS check-in '
                  'is disabled until real venues are supplied.',
                  style: TextStyle(color: Colors.deepOrange),
                ),
              ),
            const SizedBox(height: 12),
            if (!_started)
              FilledButton(onPressed: _start, child: const Text('Start Quest')),
            if (_started && !_finished) ...[
              if (q.requiresVenueVisit) ...[
                DropdownButtonFormField<String>(
                  value: widget.venues.any((v) => v.id == _selectedVenueId)
                      ? _selectedVenueId
                      : null,
                  decoration: const InputDecoration(labelText: 'Verified café'),
                  items: widget.venues
                      .map(
                        (v) =>
                            DropdownMenuItem(value: v.id, child: Text(v.name)),
                      )
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (id) => setState(() => _selectedVenueId = id),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: _busy || widget.venues.isEmpty ? null : _checkIn,
                  child: const Text('GPS Check-in'),
                ),
                Text('Check-ins: ${_visits.length}/${q.requiredCheckins}'),
              ],
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _declared,
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _declared = v ?? false),
                title: const Text('I completed the task described above.'),
                subtitle: const Text(
                  'Self-declaration is not independently verified.',
                ),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _takePhoto,
                child: const Text('Capture Optional Photo'),
              ),
              if (_photoPath != null) ...[
                const SizedBox(height: 8),
                Image.file(
                  File(_photoPath!),
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Text('Photo preview unavailable.'),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy ? null : _finish,
                child: const Text('Finish and Save Evidence'),
              ),
            ],
            if (_busy) const LinearProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Status: $_status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(_message),
            const SizedBox(height: 12),
            const Text(
              'GPS confirms proximity, not a purchase or continuous presence. '
              'Partner QR verification and reviewer approval are not implemented.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Visit {
  const _Visit(this.venueId, this.timestamp, this.distanceMetres);
  final String venueId;
  final DateTime timestamp;
  final double distanceMetres;
  Map<String, dynamic> toJson() => {
    'venueId': venueId,
    'timestamp': timestamp.toIso8601String(),
    'distanceMetres': distanceMetres,
    'verificationMethod': 'gps',
  };
}
