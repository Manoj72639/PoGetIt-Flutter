import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/day3_quest.dart';
import 'day3_quest_list_screen.dart';

/// Use as the entry point before the category list. This is a prototype
/// preferences gate; it does not yet personalize quest recommendations.
class Day3PreferencesScreen extends StatefulWidget {
  const Day3PreferencesScreen({super.key});
  @override
  State<Day3PreferencesScreen> createState() => _Day3PreferencesScreenState();
}

class _Day3PreferencesScreenState extends State<Day3PreferencesScreen> {
  final _interests = <String>{};
  String _activityLevel = 'Beginner';
  int _minutes = 15;
  bool _busy = false;

  Future<void> _continue() async {
    if (_interests.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('pogetit_interests', _interests.toList());
      await prefs.setString('pogetit_activity_level', _activityLevel);
      await prefs.setInt('pogetit_preferred_minutes', _minutes);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute<void>(
        builder: (_) => const Day3CategoryHomeScreen()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save preferences: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your Preferences')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Choose your interests', style: TextStyle(fontWeight: FontWeight.w600)),
      ...['Running', 'Café Exploration', 'Photography', 'Mindfulness / Reset'].map(
        (interest) => CheckboxListTile(
          contentPadding: EdgeInsets.zero, title: Text(interest),
          value: _interests.contains(interest),
          onChanged: (value) => setState(() {
            if (value == true) {
              _interests.add(interest);
            } else {
              _interests.remove(interest);
            }
          }),
        )),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: _activityLevel,
        decoration: const InputDecoration(labelText: 'Activity level', border: OutlineInputBorder()),
        items: ['Beginner', 'Intermediate', 'Advanced']
            .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (value) => setState(() => _activityLevel = value ?? 'Beginner'),
      ),
      const SizedBox(height: 16),
      Text('Preferred duration: $_minutes minutes'),
      Slider(value: _minutes.toDouble(), min: 5, max: 60, divisions: 11,
        label: '$_minutes min', onChanged: (v) => setState(() => _minutes = v.round())),
      FilledButton(onPressed: _busy || _interests.isEmpty ? null : _continue,
        child: const Text('Continue to Quests')),
    ]),
  );
}

class Day3CategoryHomeScreen extends StatelessWidget {
  const Day3CategoryHomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PoGetIt Quests')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Choose a category', style: TextStyle(fontSize: 18,
        fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      // Day 1 and Day 2 buttons are added in your existing home screen;
      // keep their existing routes rather than creating a second app.
      _tile(context, 'Photography', Icons.camera_alt_outlined,
        const Day3QuestListScreen(category: Day3Category.photography)),
      _tile(context, 'Mindfulness / Reset', Icons.self_improvement,
        const Day3QuestListScreen(category: Day3Category.mindfulness)),
    ]),
  );

  Widget _tile(BuildContext context, String label, IconData icon, Widget screen) =>
    Card(elevation: 0, child: ListTile(
      leading: Icon(icon), title: Text(label), trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(context,
        MaterialPageRoute<void>(builder: (_) => screen)),
    ));
}
