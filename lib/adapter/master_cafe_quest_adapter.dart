import '../models/master_quest.dart';

class UnsupportedCafeRule implements Exception {
  const UnsupportedCafeRule(this.message);
  final String message;
  @override
  String toString() => message;
}

class MasterCafeQuestConfig {
  const MasterCafeQuestConfig({
    required this.id,
    required this.title,
    required this.instructions,
    required this.requiresVenueVisit,
    required this.requiredCheckins,
    required this.requiredDistinctVenues,
    required this.sameVenueSeparateOccasions,
    required this.requiresReview,
  });
  final String id, title, instructions;
  final bool requiresVenueVisit, sameVenueSeparateOccasions, requiresReview;
  final int requiredCheckins, requiredDistinctVenues;
}

class MasterCafeQuestAdapter {
  static const _flags = <String>{
    'VENUE_VISIT',
    'GPS_CHECKIN_OR_PARTNER_QR',
    'TASK_SELF_DECLARATION_OR_PHOTO',
    'SELF_REPORT_FALLBACK_UNVERIFIED',
    'OFFSITE_OR_OPTIONAL_VISIT',
    'GPS_OR_PARTNER_QR_OPTIONAL_CONTEXT',
    'QUEST_STEPS_OPTIONAL_IF_WALKING',
    'SAME_VENUE_SEPARATE_OCCASIONS',
  };
  static const _counts = <String>{'CHECKINS_MIN', 'DISTINCT_VENUES_MIN'};

  static MasterCafeQuestConfig parse(MasterQuest quest) {
    if (quest.category != MasterQuestCategory.cafeExploration) {
      throw const UnsupportedCafeRule('Not a Café Exploration quest.');
    }
    if (quest.rules.length != 1 ||
        quest.rules.single.type.trim().toLowerCase() !=
            'source_validation_method') {
      throw const UnsupportedCafeRule('Unsupported Café rule structure.');
    }
    final rule = quest.rules.single;
    final p = rule.parameters;
    final tokens =
        <String>{
              ...quest.validationTokens,
              ...quest.verificationMode.split(';'),
            }
            .expand((e) => e.split(';'))
            .map((e) => e.trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toSet();

    for (final token in tokens) {
      if (!_flags.contains(token) &&
          !_counts.any((key) => token.startsWith('$key='))) {
        throw UnsupportedCafeRule('Unsupported token: $token');
      }
    }
    for (final key in p.keys) {
      if (!_flags.contains(key) && !_counts.contains(key)) {
        throw UnsupportedCafeRule('Unsupported parameter: $key');
      }
    }
    for (final flag in _flags) {
      final raw = p[flag];
      if (raw != null && raw is! bool) {
        throw UnsupportedCafeRule('Invalid flag: $flag');
      }
      if ((raw == true) != tokens.contains(flag)) {
        throw UnsupportedCafeRule('Flag mismatch: $flag');
      }
    }
    int count(String key) {
      final found = tokens.where((e) => e.startsWith('$key=')).toList();
      if (found.isEmpty) {
        if (p.containsKey(key)) throw UnsupportedCafeRule('Unexpected $key');
        return 0;
      }
      if (found.length != 1) throw UnsupportedCafeRule('Duplicate $key');
      final n = int.tryParse(found.single.substring(key.length + 1));
      if (n == null || n <= 0 || p[key] is! num || p[key] != n) {
        throw UnsupportedCafeRule('Invalid or mismatched $key');
      }
      return n;
    }

    final venue = tokens.contains('VENUE_VISIT');
    final offsite = tokens.contains('OFFSITE_OR_OPTIONAL_VISIT');
    final checkins = count('CHECKINS_MIN');
    final distinct = count('DISTINCT_VENUES_MIN');
    if (venue == offsite ||
        !tokens.contains('TASK_SELF_DECLARATION_OR_PHOTO') ||
        distinct > checkins) {
      throw const UnsupportedCafeRule('Inconsistent Café requirements.');
    }
    if (venue &&
        (checkins < 1 ||
            !tokens.contains('GPS_CHECKIN_OR_PARTNER_QR') ||
            !tokens.contains('SELF_REPORT_FALLBACK_UNVERIFIED'))) {
      throw const UnsupportedCafeRule('Venue evidence requirements missing.');
    }
    if (offsite &&
        (checkins != 0 ||
            distinct != 0 ||
            !tokens.contains('GPS_OR_PARTNER_QR_OPTIONAL_CONTEXT'))) {
      throw const UnsupportedCafeRule('Off-site requirements inconsistent.');
    }
    final occasions = tokens.contains('SAME_VENUE_SEPARATE_OCCASIONS');
    if (occasions && checkins < 2) {
      throw const UnsupportedCafeRule(
        'Separate occasions require two check-ins.',
      );
    }
    return MasterCafeQuestConfig(
      id: quest.id,
      title: quest.title,
      instructions: quest.instructions,
      requiresVenueVisit: venue,
      requiredCheckins: checkins,
      requiredDistinctVenues: distinct,
      sameVenueSeparateOccasions: occasions,
      requiresReview: rule.requiresReview,
    );
  }
}
