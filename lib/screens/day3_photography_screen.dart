import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../adapter/master_photography_quest_adapter.dart';
import '../models/day3_quest.dart';
import '../models/day3_validator.dart';
import '../storage/day3_repository.dart';

class Day3PhotographyScreen extends StatefulWidget {
  final Day3Quest quest;
  final PhotographyQuestConfig? masterConfig;
  const Day3PhotographyScreen({
    super.key,
    required this.quest,
    this.masterConfig,
  });
  @override
  State<Day3PhotographyScreen> createState() => _Day3PhotographyScreenState();
}

class _Day3PhotographyScreenState extends State<Day3PhotographyScreen> {
  final _picker = ImagePicker();
  final _photos = <String>[];
  late final String _attemptId;
  bool _busy = false;
  bool _submitted = false;
  String? _message;
  String? _status;

  @override
  void initState() {
    super.initState();
    _attemptId = DateTime.now().microsecondsSinceEpoch.toString();
  }

  Future<void> _addPhoto(ImageSource source) async {
    if (_busy || _submitted) return;
    final required = widget.quest.requiredPhotos;
    if (required > 0 && _photos.length >= required) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/day3_photos/$_attemptId');
      await folder.create(recursive: true);
      final destination =
          '${folder.path}/${DateTime.now().microsecondsSinceEpoch}.jpg';
      await File(picked.path).copy(destination);
      if (mounted) setState(() => _photos.add(destination));
    } catch (e) {
      if (mounted) setState(() => _message = 'Could not add photo: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removePhoto(int index) async {
    if (_busy || _submitted) return;
    final path = _photos[index];
    setState(() => _photos.removeAt(index));
    try {
      await File(path).delete();
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_busy || _submitted || _photos.isEmpty) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = Day3Validator.photography(widget.quest, _photos.length);
      final config = widget.masterConfig;
      final countSatisfied =
          widget.quest.requiredPhotos > 0 &&
          _photos.length >= widget.quest.requiredPhotos;
      // A Master Quest can only be passed when its structured photo-count
      // requirement is known and there are no additional review requirements.
      final needsReview =
          config != null && (!config.countConfigured || config.requiresReview);
      final status =
          (needsReview && countSatisfied ||
              config != null && !config.countConfigured)
          ? Day3Status.incomplete
          : result.status;
      final reason = needsReview
          ? (countSatisfied || !config!.countConfigured
                ? 'Photos saved. Master Quest conditions require manual review or are not fully configured.'
                : result.reason)
          : result.reason;
      await Day3Repository().save({
        'attemptId': _attemptId,
        'questId': widget.quest.id,
        'title': widget.quest.title,
        'category': 'Photography',
        'status': status.name,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
        'photoPaths': List<String>.from(_photos),
        if (config != null) 'masterQuestVersion': config.master.version,
        if (config != null) 'requiresReview': needsReview,
      });
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _status = status.name;
        _message = reason;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photography attempt saved')),
      );
    } catch (e) {
      if (mounted) setState(() => _message = 'Could not save attempt: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _preview(String path) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Unable to open image',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final required = widget.quest.requiredPhotos;
    final canAdd =
        !_busy && !_submitted && (required <= 0 || _photos.length < required);
    final master = widget.masterConfig?.master;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Photography Quest'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.photo_camera_outlined,
                      size: 32,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.quest.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.quest.difficulty} · ${widget.quest.id}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Text(widget.quest.instructions),
                    if (master != null &&
                        master.successCondition.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Success condition',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(master.successCondition),
                    ],
                    if (master != null && master.evidenceRule.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Evidence rule',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(master.evidenceRule),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Photo evidence',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        required > 0
                            ? '${_photos.length} / $required photos'
                            : '${_photos.length} photos · Count not configured',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (required > 0) ...[
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: (_photos.length / required)
                            .clamp(0.0, 1.0)
                            .toDouble(),
                        color: Colors.black,
                        backgroundColor: Colors.black12,
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: canAdd
                            ? () => _addPhoto(ImageSource.camera)
                            : null,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Take Photo'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: canAdd
                            ? () => _addPhoto(ImageSource.gallery)
                            : null,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Choose from Gallery'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_photos.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Added photos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (final entry in _photos.asMap().entries)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => _preview(entry.value),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(entry.value),
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                width: 64,
                                height: 64,
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Photo ${entry.key + 1}')),
                        IconButton(
                          tooltip: 'Preview',
                          onPressed: () => _preview(entry.value),
                          icon: const Icon(Icons.visibility_outlined),
                        ),
                        if (!_submitted)
                          IconButton(
                            tooltip: 'Remove',
                            onPressed: _busy
                                ? null
                                : () => _removePhoto(entry.key),
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy || _submitted || _photos.isEmpty
                    ? null
                    : _submit,
                child: Text(
                  _busy
                      ? 'Saving...'
                      : _submitted
                      ? 'Attempt Saved'
                      : 'Submit Photos',
                ),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_status != null)
                        Text(
                          'Validation: $_status',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      Text(_message!),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'Photo count is checked automatically. Image subject, artistic quality, and any additional Master Quest conditions are not automatically verified.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
