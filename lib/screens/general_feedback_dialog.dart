import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GeneralFeedbackDialog extends StatefulWidget {
  const GeneralFeedbackDialog({super.key});

  @override
  State<GeneralFeedbackDialog> createState() => _GeneralFeedbackDialogState();
}

class _GeneralFeedbackDialogState extends State<GeneralFeedbackDialog> {
  final TextEditingController _controller = TextEditingController();

  bool _submitting = false;
  String? _error;

  Future<void> _submitFeedback() async {
    if (_submitting) return;

    final message = _controller.text.trim();

    if (message.isEmpty) {
      setState(() {
        _error = 'Please enter your feedback.';
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _error = 'Please sign in again.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await FirebaseFirestore.instance.collection('general_feedback').add({
        'userId': user.uid,
        'feedback': message,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'new',
      });

      if (!mounted) return;

      // Return true to the ProfileScreen.
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
        _error = 'Unable to submit feedback: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('General Feedback'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              maxLines: 5,
              maxLength: 1000,
              enabled: !_submitting,
              decoration: const InputDecoration(
                hintText: 'Tell us what you think about PoGetIt...',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submitFeedback,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
