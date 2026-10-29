enum CafeQuestKind { photo, dwell, expedition }

class CafeVenue {
  const CafeVenue(this.id, this.name, this.latitude, this.longitude);
  final String id, name;
  final double latitude, longitude;
}

class CafeQuest {
  const CafeQuest({
    required this.id,
    required this.title,
    required this.kind,
    this.radiusMetres = 150,
    this.dwellMinutes = 0,
    this.requiresPhoto = false,
  });
  final String id, title;
  final CafeQuestKind kind;
  final double radiusMetres;
  final int dwellMinutes;
  final bool requiresPhoto;
}

const cafeQuests = <CafeQuest>[
  CafeQuest(
    id: 'CE-E001',
    title: 'Coffee Break Outside',
    kind: CafeQuestKind.photo,
    requiresPhoto: true,
  ),
  CafeQuest(
    id: 'CE-E008',
    title: 'Quiet Corner',
    kind: CafeQuestKind.dwell,
    dwellMinutes: 10,
  ),
  CafeQuest(
    id: 'CE-H001',
    title: 'Three Cafe Expedition',
    kind: CafeQuestKind.expedition,
  ),
];

// The founder has not supplied real cafe coordinates. Replace with assigned cafe
// coordinates BEFORE real-device acceptance testing. These are fictional fixtures.
const testVenues = <CafeVenue>[
  CafeVenue('TEST-A', 'Test Cafe A (fixture)', 11.050770, 76.982462),
  CafeVenue('TEST-B', 'Test Cafe B (fixture)', 11.050705, 76.983755),
  CafeVenue('TEST-C', 'Test Cafe C (fixture)', 11.050785, 76.982486),
];
