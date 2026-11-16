import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'location_picker_screen.dart';
import 'general_feedback_dialog.dart';
import 'delete_account_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _signingOut = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  String _displayValue(dynamic value) {
    if (value == null) return 'Not provided';

    if (value is List) {
      return value.isEmpty ? 'Not provided' : value.join(', ');
    }

    final text = value.toString().trim();
    return text.isEmpty ? 'Not provided' : text;
  }

  Future<void> _signOut() async {
    if (_signingOut) return;

    setState(() => _signingOut = true);

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _signingOut = false);
      }
    }
  }

  Future<void> _openLocationPicker() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LocationPickerScreen()),
    );
  }

  Future<void> _showGeneralFeedback() async {
    final submitted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const GeneralFeedbackDialog(),
    );

    if (!mounted) return;

    if (submitted == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showDeleteAccount() async {
    final submitted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DeleteAccountDialog(),
    );

    if (!mounted) return;

    if (submitted == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deletion request submitted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view your profile.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile'), centerTitle: true),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to load profile: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() ?? <String, dynamic>{};

            final name = _displayValue(data['name'] ?? user.displayName);

            final email = _displayValue(data['email'] ?? user.email);

            final pinnedLocation = data['pinnedLocation'];
            String locationText = 'Not selected';

            if (pinnedLocation is Map) {
              locationText =
                  '${pinnedLocation['latitude']}, '
                  '${pinnedLocation['longitude']}';
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.all(constraints.maxWidth < 360 ? 12 : 18),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const CircleAvatar(
                            radius: 40,
                            child: Icon(Icons.person, size: 42),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(email, textAlign: TextAlign.center),
                          const SizedBox(height: 22),

                          _section('Your Location', [
                            _infoRow(
                              Icons.location_on_outlined,
                              'Selected Location',
                              locationText,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _openLocationPicker,
                                icon: const Icon(Icons.map_outlined),
                                label: const Text('Choose My Location'),
                              ),
                            ),
                          ]),

                          const SizedBox(height: 16),

                          _section('Account Information', [
                            _infoRow(Icons.person_outline, 'Name', name),
                            _infoRow(Icons.email_outlined, 'Email', email),
                            _infoRow(
                              Icons.phone_outlined,
                              'Phone',
                              _displayValue(data['phone'] ?? user.phoneNumber),
                            ),
                          ]),

                          const SizedBox(height: 16),

                          _section('My Quest Preferences', [
                            _infoRow(
                              Icons.flag_outlined,
                              'Goals',
                              _displayValue(data['lifeGoals'] ?? data['goals']),
                            ),
                            _infoRow(
                              Icons.favorite_outline,
                              'Interests',
                              _displayValue(data['interests']),
                            ),
                            _infoRow(
                              Icons.directions_run,
                              'Activity Level',
                              _displayValue(data['activityLevel']),
                            ),
                            _infoRow(
                              Icons.timer_outlined,
                              'Preferred Duration',
                              _displayValue(
                                data['preferredQuestDuration'] ??
                                    data['preferredMinutes'],
                              ),
                            ),
                            _infoRow(
                              Icons.calendar_month_outlined,
                              'Weekly Quest Target',
                              _displayValue(data['weeklyTarget']),
                            ),
                          ]),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _showGeneralFeedback,
                              icon: const Icon(Icons.feedback_outlined),
                              label: const Text('General Feedback'),
                            ),
                          ),

                          const SizedBox(height: 10),

                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _showDeleteAccount,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete Account'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _signingOut ? null : _signOut,
                              icon: _signingOut
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.logout),
                              label: Text(
                                _signingOut ? 'Signing Out...' : 'Sign Out',
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
