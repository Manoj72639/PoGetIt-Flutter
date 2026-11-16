import 'package:flutter/material.dart';

import '../models/onboarding_answers.dart';
import 'signup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;

  final _nameController = TextEditingController();

  final Set<String> _goals = {};
  String? _primaryInterest;
  String? _secondaryInterest;
  String? _activityLevel;
  String? _duration;
  String? _activityTime;
  int? _weeklyTarget;

  static const _questions = [
    'What should we call you?',
    'What would you like to do more in life?',
    'What are you interested in doing more of?',
    'How active are you with these interests?',
    'How much time would you normally like to spend on a quest?',
    'When are you most likely to try out your interests yourself?',
    'How many quests would you like to complete each week?',
  ];

  static const _goalOptions = [
    'Be more active',
    'Build consistency',
    'Explore more & try new things',
    'Peace and be mindful',
    'Spend less time scrolling',
    'Feel more productive with your free time',
  ];

  static const _interestOptions = [
    'Walking/Jogging',
    'Photography',
    'Cafe Exploration',
    'Mindfulness',
  ];

  static const _activityOptions = [
    'Just getting started',
    'Occasionally active',
    'Fairly consistent',
    'Very active',
  ];

  static const _durationOptions = [
    '10–15 minutes',
    '20–30 minutes',
    '30–60 minutes',
    '60+ minutes',
  ];

  static const _timeOptions = [
    'Morning',
    'Afternoon',
    'Evening',
    'Weekend',
    'Anytime',
  ];

  static const _weeklyOptions = [
    '2 Quests — Start easy',
    '3 Quests — Balanced (recommended)',
    '4 Quests — Build momentum',
    "5+ Quests — I'm ready for the challenge",
  ];

  bool get _valid {
    switch (_step) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _goals.isNotEmpty;
      case 2:
        return _primaryInterest != null &&
            _secondaryInterest != null &&
            _primaryInterest != _secondaryInterest;
      case 3:
        return _activityLevel != null;
      case 4:
        return _duration != null;
      case 5:
        return _activityTime != null;
      case 6:
        return _weeklyTarget != null;
      default:
        return false;
    }
  }

  int _minutesFromDuration(String duration) {
    switch (duration) {
      case '10–15 minutes':
        return 15;
      case '20–30 minutes':
        return 30;
      case '30–60 minutes':
        return 60;
      default:
        return 60;
    }
  }

  void _next() {
    if (!_valid) return;

    if (_step < 6) {
      setState(() => _step++);
      return;
    }

    final answers = OnboardingAnswers(
      name: _nameController.text.trim(),
      interests: [_primaryInterest!, _secondaryInterest!],
      goals: _goals.join(', '),
      activityLevel: _activityLevel!,
      preferredMinutes: _minutesFromDuration(_duration!),
      weeklyTarget: _weeklyTarget!,
      lifeGoals: _goals.toList(),
      primaryInterest: _primaryInterest!,
      secondaryInterest: _secondaryInterest!,
      preferredQuestDuration: _duration!,
      preferredActivityTime: _activityTime!,
    );

    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => SignupScreen(answers: answers)),
    );
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.pop(context);
    }
  }

  Widget _choice(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? Colors.teal.withValues(alpha: 0.10)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.teal : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? Colors.teal : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _questionContent() {
    switch (_step) {
      case 0:
        return TextField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Your name',
            hintText: 'Enter your name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
          ),
          onChanged: (_) => setState(() {}),
        );

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select all that apply'),
            const SizedBox(height: 16),
            ..._goalOptions.map(
              (goal) => _choice(goal, _goals.contains(goal), () {
                setState(() {
                  if (_goals.contains(goal)) {
                    _goals.remove(goal);
                  } else {
                    _goals.add(goal);
                  }
                });
              }),
            ),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose your primary interest',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._interestOptions.map(
              (interest) => _choice(interest, _primaryInterest == interest, () {
                setState(() {
                  _primaryInterest = interest;
                  if (_secondaryInterest == interest) {
                    _secondaryInterest = null;
                  }
                });
              }),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose a different secondary interest',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._interestOptions
                .where((v) => v != _primaryInterest)
                .map(
                  (interest) =>
                      _choice(interest, _secondaryInterest == interest, () {
                        setState(() {
                          _secondaryInterest = interest;
                        });
                      }),
                ),
          ],
        );

      case 3:
        return Column(
          children: _activityOptions
              .map(
                (value) => _choice(
                  value,
                  _activityLevel == value,
                  () => setState(() => _activityLevel = value),
                ),
              )
              .toList(),
        );

      case 4:
        return Column(
          children: _durationOptions
              .map(
                (value) => _choice(
                  value,
                  _duration == value,
                  () => setState(() => _duration = value),
                ),
              )
              .toList(),
        );

      case 5:
        return Column(
          children: _timeOptions
              .map(
                (value) => _choice(
                  value,
                  _activityTime == value,
                  () => setState(() => _activityTime = value),
                ),
              )
              .toList(),
        );

      case 6:
        return Column(
          children: List.generate(_weeklyOptions.length, (index) {
            final target = index + 2;
            return _choice(
              _weeklyOptions[index],
              _weeklyTarget == target,
              () => setState(() => _weeklyTarget = target),
            );
          }),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PoGetIt Onboarding'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Question ${_step + 1} of 7',
                    style: const TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  LinearProgressIndicator(
                    value: (_step + 1) / 7,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(10),
                  ),

                  const SizedBox(height: 30),

                  Text(
                    _questions[_step],
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  _questionContent(),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                children: [
                  if (_step > 0) ...[
                    OutlinedButton(onPressed: _back, child: const Text('Back')),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: _valid ? _next : null,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _step == 6 ? 'Continue to Sign Up' : 'Next',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
