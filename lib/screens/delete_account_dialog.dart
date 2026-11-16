import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final TextEditingController _likedController = TextEditingController();

  final TextEditingController _leavingController = TextEditingController();

  bool _submitting = false;
  String? _error;

  Future<void> _submitRequest() async {
    if (_submitting) return;

    final liked = _likedController.text.trim();
    final leaving = _leavingController.text.trim();

    if (liked.isEmpty || leaving.isEmpty) {
      setState(() {
        _error = 'Please answer both questions.';
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (confirmContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion Request'),
          content: const Text(
            'Do you want to submit a request '
            'to delete your PoGetIt account?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(confirmContext).pop(false);
              },
              child: const Text('Keep Account'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(confirmContext).pop(true);
              },
              child: const Text('Confirm Request'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final requestRef = FirebaseFirestore.instance
          .collection('account_deletion_requests')
          .doc(user.uid);

      // Check whether a deletion request already exists.
      final existing = await requestRef.get();

      if (!mounted) return;

      if (existing.exists) {
        setState(() {
          _error =
              'A deletion request already exists for '
              'this account. Please contact support '
              'if you need an update.';
          _submitting = false;
        });
        return;
      }

      // Create a new request.
      await requestRef.set({
        'userId': user.uid,
        'likedAboutApp': liked,
        'reasonForLeaving': leaving,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      String message = 'Unable to submit request: ${e.message}';

      if (e.code == 'permission-denied') {
        message =
            'Permission denied. Check the Firestore '
            'security rules for account_deletion_requests.';
      }

      setState(() {
        _submitting = false;
        _error = message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
        _error = 'Unable to submit request: $e';
      });
    }
  }

  @override
  void dispose() {
    _likedController.dispose();
    _leavingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Account'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Before requesting account deletion, '
              'please answer these questions.',
            ),
            const SizedBox(height: 18),

            const Text('What did you like about this app?'),
            const SizedBox(height: 8),

            TextField(
              controller: _likedController,
              maxLines: 3,
              maxLength: 500,
              enabled: !_submitting,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Your answer',
              ),
            ),

            const SizedBox(height: 14),

            const Text('Why are you leaving the app?'),
            const SizedBox(height: 8),

            TextField(
              controller: _leavingController,
              maxLines: 3,
              maxLength: 500,
              enabled: !_submitting,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Your answer',
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Your request will be submitted '
              'for secure account deletion processing. '
              'Your account is not deleted immediately.',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
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
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _submitting ? null : _submitRequest,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Request Deletion'),
        ),
      ],
    );
  }
}
