import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/profile_service.dart';
import 'delete_account_dialog.dart';
import 'general_feedback_dialog.dart';
import 'location_picker_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _service = ProfileService();
  bool _signingOut = false;

  String _value(dynamic value) {
    if (value == null) return 'Not provided';
    if (value is List) return value.isEmpty ? 'Not provided' : value.join(', ');
    final result = value.toString().trim();
    return result.isEmpty ? 'Not provided' : result;
  }

  Future<void> _edit(Map<String, dynamic> data) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: (data['name'] ?? '').toString());
    final goals = TextEditingController(
      text: (data['goals'] ?? data['lifeGoals'] ?? '').toString(),
    );
    final interests = TextEditingController(
      text: (data['interests'] is List)
          ? (data['interests'] as List).join(', ')
          : (data['interests'] ?? '').toString(),
    );
    final activity = TextEditingController(
      text: (data['activityLevel'] ?? '').toString(),
    );
    final duration = TextEditingController(
      text: (data['preferredMinutes'] ?? data['preferredQuestDuration'] ?? 20)
          .toString(),
    );
    final weekly = TextEditingController(
      text: (data['weeklyTarget'] ?? 3).toString(),
    );
    bool saving = false;
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
            title: const Text('Edit Profile'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: name,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter your name'
                            : null,
                      ),
                      TextFormField(
                        controller: goals,
                        decoration: const InputDecoration(labelText: 'Goals'),
                      ),
                      TextFormField(
                        controller: interests,
                        decoration: const InputDecoration(
                          labelText: 'Interests (comma separated)',
                        ),
                      ),
                      TextFormField(
                        controller: activity,
                        decoration: const InputDecoration(
                          labelText: 'Activity level',
                        ),
                      ),
                      TextFormField(
                        controller: duration,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Preferred duration (minutes)',
                        ),
                        validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                            ? 'Enter minutes greater than zero'
                            : null,
                      ),
                      TextFormField(
                        controller: weekly,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Weekly quest target',
                        ),
                        validator: (v) => (int.tryParse(v ?? '') ?? -1) < 0
                            ? 'Enter zero or more'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        update(() => saving = true);
                        try {
                          await _service.saveProfile(
                            name: name.text,
                            interests: interests.text
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList(),
                            goals: goals.text,
                            activityLevel: activity.text,
                            preferredMinutes: int.parse(duration.text),
                            weeklyTarget: int.parse(weekly.text),
                          );
                          if (dialogContext.mounted)
                            Navigator.pop(dialogContext);
                          if (mounted)
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(content: Text('Profile updated')),
                            );
                        } catch (e) {
                          if (dialogContext.mounted)
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text('Unable to save profile: $e'),
                              ),
                            );
                        } finally {
                          if (dialogContext.mounted)
                            update(() => saving = false);
                        }
                      },
                child: Text(saving ? 'Saving...' : 'Save'),
              ),
            ],
          ),
        ),
      );
    } finally {
      // Allow the closing dialog transition to finish before disposal.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      name.dispose();
      goals.dispose();
      interests.dispose();
      activity.dispose();
      duration.dispose();
      weekly.dispose();
    }
  }

  Future<void> _feedback() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const GeneralFeedbackDialog(),
    );
    if (mounted && result == true)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted successfully')),
      );
  }

  Future<void> _deleteAccount() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DeleteAccountDialog(),
    );
    if (mounted && result == true)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deletion request submitted')),
      );
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await _service.signOut();
      // AuthGate handles navigation automatically.
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Widget _section(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...children,
        ],
      ),
    ),
  );

  Widget _detail(IconData icon, String title, String value) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    leading: Icon(icon, color: Colors.black),
    title: Text(
      title,
      style: const TextStyle(fontSize: 13, color: Colors.black54),
    ),
    subtitle: Text(
      value,
      style: const TextStyle(
        fontSize: 15,
        color: Colors.black,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(
        body: Center(child: Text('Please sign in to view your profile.')),
      );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _service.watchProfile(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(
              child: Text('Unable to load profile: ${snapshot.error}'),
            );
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() ?? <String, dynamic>{};
          final pinned = data['pinnedLocation'];
          final location = pinned is Map
              ? '${pinned['latitude'] ?? '-'}, ${pinned['longitude'] ?? '-'}'
              : 'Not selected';
          final name = _value(data['name'] ?? user.displayName);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.black,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _value(data['email'] ?? user.email),
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _edit(data),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit Profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _section('Your Location', [
                _detail(
                  Icons.location_on_outlined,
                  'Selected Location',
                  location,
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LocationPickerScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Choose My Location'),
                  ),
                ),
              ]),
              _section('Account Information', [
                _detail(Icons.person_outline, 'Name', name),
                _detail(
                  Icons.email_outlined,
                  'Email',
                  _value(data['email'] ?? user.email),
                ),
                _detail(
                  Icons.phone_outlined,
                  'Phone',
                  _value(data['phone'] ?? user.phoneNumber),
                ),
              ]),
              _section('My Quest Preferences', [
                _detail(
                  Icons.flag_outlined,
                  'Goals',
                  _value(data['goals'] ?? data['lifeGoals']),
                ),
                _detail(
                  Icons.favorite_outline,
                  'Interests',
                  _value(data['interests']),
                ),
                _detail(
                  Icons.directions_run,
                  'Activity Level',
                  _value(data['activityLevel']),
                ),
                _detail(
                  Icons.timer_outlined,
                  'Preferred Duration',
                  '${_value(data['preferredMinutes'] ?? data['preferredQuestDuration'])} minutes',
                ),
                _detail(
                  Icons.calendar_month_outlined,
                  'Weekly Quest Target',
                  _value(data['weeklyTarget']),
                ),
              ]),
              _section('Account Settings', [
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: const Text('General Feedback'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _feedback,
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Delete Account'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _deleteAccount,
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(_signingOut ? 'Signing out...' : 'Sign Out'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _signingOut ? null : _signOut,
                ),
              ]),
            ],
          );
        },
      ),
    );
  }
}
