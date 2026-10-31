import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/day3_quest.dart';
import '../models/day3_validator.dart';
import '../storage/day3_repository.dart';

class Day3PhotographyScreen extends StatefulWidget {
  final Day3Quest quest;
  const Day3PhotographyScreen({super.key, required this.quest});
  @override
  State<Day3PhotographyScreen> createState() => _Day3PhotographyScreenState();
}

class _Day3PhotographyScreenState extends State<Day3PhotographyScreen> {
  final _picker = ImagePicker();
  final _photos = <String>[];
  late final String _attemptId;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _attemptId = DateTime.now().microsecondsSinceEpoch.toString();
  }

  Future<void> _addPhoto() async {
    if (_busy || _photos.length >= widget.quest.requiredPhotos) return;
    setState(() => _busy = true);
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (picked == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/day3_photos/$_attemptId');
      await folder.create(recursive: true);
      final destination = '${folder.path}/${_photos.length + 1}.jpg';
      await File(picked.path).copy(destination);
      if (mounted) setState(() => _photos.add(destination));
    } catch (e) {
      if (mounted) setState(() => _message = 'Could not save photo: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = Day3Validator.photography(widget.quest, _photos.length);
      await Day3Repository().save({
        'attemptId': _attemptId,
        'questId': widget.quest.id,
        'title': widget.quest.title,
        'category': 'Photography',
        'status': result.status.name,
        'reason': result.reason,
        'timestamp': DateTime.now().toIso8601String(),
        'photoPaths': List<String>.from(_photos),
      });
      if (mounted) setState(() => _message = result.reason);
    } catch (e) {
      if (mounted) setState(() => _message = 'Could not save attempt: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.quest.title)),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Text(widget.quest.instructions),
      const SizedBox(height: 16),
      Text('${_photos.length} / ${widget.quest.requiredPhotos} photos added',
        style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      ..._photos.asMap().entries.map((entry) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(6),
            child: Image.file(File(entry.value), width: 64, height: 64, fit: BoxFit.cover)),
          const SizedBox(width: 12),
          Expanded(child: Text('Photo ${entry.key + 1}')),
          IconButton(tooltip: 'Remove photo', icon: const Icon(Icons.close),
            onPressed: _busy ? null : () => setState(() => _photos.removeAt(entry.key))),
        ]),
      )),
      OutlinedButton.icon(
        onPressed: _busy || _photos.length >= widget.quest.requiredPhotos ? null : _addPhoto,
        icon: const Icon(Icons.add_a_photo_outlined), label: const Text('Take Photo'),
      ),
      const SizedBox(height: 8),
      FilledButton(onPressed: _busy ? null : _submit, child: const Text('Submit Photos')),
      if (_message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!)),
      const SizedBox(height: 12),
      const Text('Validation checks photo count only, not the photo subject or artistic quality.',
        style: TextStyle(fontSize: 12, color: Colors.grey)),
    ]),
  );
}
