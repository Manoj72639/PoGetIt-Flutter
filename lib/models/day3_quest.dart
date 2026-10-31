enum Day3Category { photography, mindfulness }

enum Day3Status { inProgress, passed, incomplete }

class Day3Quest {
  final String id;
  final String title;
  final String difficulty;
  final String instructions;
  final Day3Category category;
  final int requiredPhotos;
  final int requiredSessions;
  final List<String> checklist;

  const Day3Quest({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.instructions,
    required this.category,
    this.requiredPhotos = 0,
    this.requiredSessions = 0,
    this.checklist = const [],
  });
}

const day3Quests = <Day3Quest>[
  Day3Quest(
    id: 'PHOTO-E001',
    title: 'Bench Portrait',
    difficulty: 'Easy',
    instructions: 'Photograph an unoccupied public bench and submit one image.',
    category: Day3Category.photography,
    requiredPhotos: 1,
  ),
  Day3Quest(
    id: 'PHOTO-M001',
    title: 'One-Object Reinvention',
    difficulty: 'Medium',
    instructions:
        'Submit three photos of the same object from different angles or lighting.',
    category: Day3Category.photography,
    requiredPhotos: 3,
  ),
  Day3Quest(
    id: 'PHOTO-H001',
    title: 'Street Story in Five Frames',
    difficulty: 'Hard',
    instructions:
        'Submit five ordered photos that tell a simple story from one outing.',
    category: Day3Category.photography,
    requiredPhotos: 5,
  ),
  Day3Quest(
    id: 'RESET-E001',
    title: 'Bedside Reset',
    difficulty: 'Easy',
    instructions:
        'Put away three unrelated items near your sleeping area, then confirm completion.',
    category: Day3Category.mindfulness,
  ),
  Day3Quest(
    id: 'RESET-M001',
    title: 'Handwritten Words',
    difficulty: 'Medium',
    instructions:
        'Write a page of meaningful everyday words carefully and without rushing.',
    category: Day3Category.mindfulness,
    checklist: [
      'I wrote a page of words',
      'I completed the activity without rushing',
    ],
  ),
  Day3Quest(
    id: 'RESET-H001',
    title: 'Two-Option Pause',
    difficulty: 'Hard',
    instructions:
        'Create a four-option low-demand pause menu and test it over the week. Record each session date and duration.',
    category: Day3Category.mindfulness,
    // The Day 3 brief does not specify a number of sessions. Set this
    // configurable prototype default to the founder-approved number.
    requiredSessions: 3,
    checklist: [
      'I created my four-option pause menu',
      'I tested my pause options',
    ],
  ),
];
