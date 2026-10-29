import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/cafe_quest.dart';
import '../services/location_service.dart';
import '../storage/cafe_attempt_repository.dart';
import '../validators/cafe_validator.dart';

class CafeScreen extends StatefulWidget {
  const CafeScreen({super.key, required this.quest});
  final CafeQuest quest;
  @override
  State<CafeScreen> createState() => _CafeScreenState();
}

class _CafeScreenState extends State<CafeScreen> {
  final _location = LocationService();
  final _repository = CafeAttemptRepository();
  final _picker = ImagePicker();
  bool _started = false, _busy = false, _done = false;
  String? _photoPath;
  DateTime? _startTime;
  double? _checkinDistance, _checkoutDistance;
  String? _checkedInVenue;
  final List<CafeCheckin> _visits = [];
  CafeResult _result = const CafeResult(
    CafeStatus.inProgress,
    'Tap Start to begin.',
  );
  CafeVenue _venue = testVenues.first;

  Future<void> _begin() async {
    setState(() {
      _started = true;
      _done = false;
      _photoPath = null;
      _startTime = null;
      _checkinDistance = null;
      _checkoutDistance = null;
      _checkedInVenue = null;
      _visits.clear();
      _result = const CafeResult(
        CafeStatus.inProgress,
        'Ready for cafe check-in.',
      );
    });
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy || _done) return;
    setState(() => _busy = true);
    try {
      await operation();
    } catch (e) {
      if (mounted)
        setState(
          () => _result = CafeResult(CafeStatus.rejected, 'Action failed: $e'),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<double> _distanceTo(CafeVenue venue) async {
    await _location.ensurePermission();
    final Position position = await _location.current();
    if (!_location.reliable(position))
      throw StateError(
        'GPS accuracy is insufficient. Move outdoors and retry.',
      );
    return CafeValidator.distanceMetres(
      position.latitude,
      position.longitude,
      venue.latitude,
      venue.longitude,
    );
  }

  Future<void> _record(
    String action,
    CafeResult result, {
    double? distance,
  }) async {
    // Store a snapshot of every action, including rejected attempts and progress.
    final record = <String, dynamic>{
      'questId': widget.quest.id,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
      'venueId': _venue.id,
      'distanceMetres': distance,
      'checkinDistanceMetres': _checkinDistance,
      'checkoutDistanceMetres': _checkoutDistance,
      'startTime': _startTime?.toIso8601String(),
      'elapsedSeconds': _startTime == null
          ? null
          : DateTime.now().difference(_startTime!).inSeconds,
      'photoPath': _photoPath,
      'checkins': _visits.map((v) => v.toJson()).toList(),
      'status': result.status.name,
      'reason': result.reason,
    };
    await _repository.save(record);
    if (!mounted) return;
    setState(() {
      _result = result;
      if (result.status == CafeStatus.accepted) _done = true;
    });
  }

  Future<void> _checkin() => _run(() async {
    final distance = await _distanceTo(_venue);
    final check = CafeValidator.checkLocation(
      distance: distance,
      radius: widget.quest.radiusMetres,
      gpsReliable: true,
    );
    if (check.status == CafeStatus.rejected) {
      await _record('checkin', check, distance: distance);
      return;
    }
    if (widget.quest.kind == CafeQuestKind.expedition) {
      if (_visits.any((v) => v.venueId == _venue.id)) {
        await _record(
          'checkin',
          const CafeResult(
            CafeStatus.rejected,
            'This cafe was already checked in.',
          ),
          distance: distance,
        );
        return;
      }
      _visits.add(
        CafeCheckin(
          venueId: _venue.id,
          at: DateTime.now(),
          distanceMetres: distance,
        ),
      );
      await _record(
        'checkin',
        CafeValidator.expedition(_visits),
        distance: distance,
      );
    } else {
      if (_checkedInVenue != null) {
        await _record(
          'checkin',
          const CafeResult(
            CafeStatus.rejected,
            'Already checked in for this attempt.',
          ),
          distance: distance,
        );
        return;
      }
      _checkedInVenue = _venue.id;
      _checkinDistance = distance;
      _startTime = DateTime.now();
      await _record(
        'checkin',
        const CafeResult(
          CafeStatus.inProgress,
          'Check-in accepted; complete remaining requirements.',
        ),
        distance: distance,
      );
    }
  });
  Future<void> _attachPhoto() => _run(() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (image == null) return;
    // ImagePicker's cache path is temporary; copy it to app documents for persistence.
    final directory = await _photoDirectory();
    final saved = await File(
      image.path,
    ).copy('${directory.path}/${DateTime.now().microsecondsSinceEpoch}.jpg');
    _photoPath = saved.path;
    if (mounted) setState(() {});
    await _record(
      'photo',
      const CafeResult(
        CafeStatus.inProgress,
        'Photo attached; submit evidence to validate.',
      ),
    );
  });
  Future<Directory> _photoDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/cafe_evidence');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _submitPhoto() => _run(() async {
    final result = CafeValidator.photoQuest(
      checkedIn: _checkedInVenue != null,
      photoAttached: _photoPath != null,
    );
    await _record('submit', result, distance: _checkinDistance);
  });
  Future<void> _checkout() => _run(() async {
    if (_checkedInVenue == null || _startTime == null) {
      await _record(
        'checkout',
        const CafeResult(CafeStatus.rejected, 'Check in first.'),
      );
      return;
    }
    if (_checkedInVenue != _venue.id) {
      await _record(
        'checkout',
        const CafeResult(
          CafeStatus.rejected,
          'Checkout must use the same cafe.',
        ),
      );
      return;
    }
    final distance = await _distanceTo(_venue);
    _checkoutDistance = distance;
    final check = CafeValidator.checkLocation(
      distance: distance,
      radius: widget.quest.radiusMetres,
      gpsReliable: true,
    );
    final result = CafeValidator.dwellQuest(
      start: _startTime,
      end: DateTime.now(),
      checkoutInRadius: check.status == CafeStatus.accepted,
      requiredMinutes: widget.quest.dwellMinutes,
    );
    await _record('checkout', result, distance: distance);
  });
  @override
  Widget build(BuildContext context) {
    final q = widget.quest;
    return Scaffold(
      appBar: AppBar(title: Text(q.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(q.id, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Text('Allowed radius: ${q.radiusMetres.toStringAsFixed(0)} m'),
          if (q.kind == CafeQuestKind.dwell)
            Text('Required stay: ${q.dwellMinutes} minutes'),
          if (q.requiresPhoto)
            const Text('Required evidence: one photo from this attempt'),
          if (q.kind == CafeQuestKind.expedition)
            const Text('Visit three different assigned cafes.'),
          const SizedBox(height: 12),
          const Text('', style: TextStyle(color: Colors.deepOrange)),
          DropdownButtonFormField<String>(
            value: _venue.id,
            decoration: const InputDecoration(labelText: 'Target cafe'),
            items: testVenues
                .map((v) => DropdownMenuItem(value: v.id, child: Text(v.name)))
                .toList(),
            onChanged: (!_started || _done || _busy)
                ? null
                : (id) => setState(
                    () => _venue = testVenues.firstWhere((v) => v.id == id),
                  ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _begin,
            child: const Text('Start / New Attempt'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: !_started || _done || _busy ? null : _checkin,
            child: const Text('GPS Check-in'),
          ),
          if (q.kind == CafeQuestKind.photo) ...[
            OutlinedButton(
              onPressed: !_started || _done || _busy ? null : _attachPhoto,
              child: const Text('Capture Photo'),
            ),
            if (_photoPath != null)
              Text(
                'Attached: ${_photoPath!.split(Platform.pathSeparator).last}',
              ),
            FilledButton(
              onPressed: !_started || _done || _busy ? null : _submitPhoto,
              child: const Text('Submit Evidence'),
            ),
          ],
          if (q.kind == CafeQuestKind.dwell)
            FilledButton(
              onPressed: !_started || _done || _busy ? null : _checkout,
              child: const Text('GPS Check-out'),
            ),
          if (q.kind == CafeQuestKind.expedition)
            Text('Valid distinct visits: ${_visits.length}/3'),
          if (_startTime != null)
            Text('Check-in time: ${_startTime!.toLocal()}'),
          if (_checkinDistance != null)
            Text(
              'Check-in distance: ${_checkinDistance!.toStringAsFixed(1)} m',
            ),
          if (_checkoutDistance != null)
            Text(
              'Check-out distance: ${_checkoutDistance!.toStringAsFixed(1)} m',
            ),
          const Divider(height: 32),
          if (_busy) const LinearProgressIndicator(),
          Text(
            'Status: ${_result.status.name.toUpperCase()}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(_result.reason),
          const SizedBox(height: 12),
          const Text(
            'Location checks verify proximity at check-in/out, not continuous presence or purchase. Photo submission does not verify photo content.',
          ),
        ],
      ),
    );
  }
}
