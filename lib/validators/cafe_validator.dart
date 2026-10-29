import 'dart:math' as math;

enum CafeStatus { accepted, rejected, inProgress }

class CafeResult {
  const CafeResult(this.status, this.reason);
  final CafeStatus status;
  final String reason;
}

class CafeCheckin {
  const CafeCheckin({
    required this.venueId,
    required this.at,
    required this.distanceMetres,
  });
  final String venueId;
  final DateTime at;
  final double distanceMetres;
  Map<String, dynamic> toJson() => {
    'venueId': venueId,
    'timestamp': at.toIso8601String(),
    'distanceMetres': distanceMetres,
  };
}

class CafeValidator {
  static double distanceMetres(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const radius = 6371000.0;
    final a1 = lat1 * math.pi / 180, a2 = lat2 * math.pi / 180;
    final da = (lat2 - lat1) * math.pi / 180;
    final dl = (lon2 - lon1) * math.pi / 180;
    final a =
        math.pow(math.sin(da / 2), 2) +
        math.cos(a1) * math.cos(a2) * math.pow(math.sin(dl / 2), 2);
    return 2 * radius * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
  }

  static CafeResult checkLocation({
    required double distance,
    required double radius,
    required bool gpsReliable,
  }) {
    if (!gpsReliable || !distance.isFinite || distance < 0) {
      return const CafeResult(
        CafeStatus.rejected,
        'Reliable GPS location unavailable.',
      );
    }
    if (distance > radius)
      return CafeResult(
        CafeStatus.rejected,
        'Outside radius: ${distance.toStringAsFixed(1)} m > ${radius.toStringAsFixed(0)} m.',
      );
    return const CafeResult(
      CafeStatus.accepted,
      'Location within allowed radius.',
    );
  }

  static CafeResult photoQuest({
    required bool checkedIn,
    required bool photoAttached,
  }) {
    if (!checkedIn)
      return const CafeResult(
        CafeStatus.rejected,
        'A valid cafe check-in is required.',
      );
    if (!photoAttached)
      return const CafeResult(
        CafeStatus.rejected,
        'Required photo is missing.',
      );
    return const CafeResult(
      CafeStatus.accepted,
      'Valid cafe check-in and photo submitted.',
    );
  }

  static CafeResult dwellQuest({
    required DateTime? start,
    required DateTime end,
    required bool checkoutInRadius,
    required int requiredMinutes,
  }) {
    if (start == null)
      return const CafeResult(
        CafeStatus.rejected,
        'Check in before checking out.',
      );
    if (!checkoutInRadius)
      return const CafeResult(
        CafeStatus.rejected,
        'Checkout outside cafe radius.',
      );
    if (end.isBefore(start) ||
        end.difference(start) < Duration(minutes: requiredMinutes)) {
      return CafeResult(
        CafeStatus.rejected,
        'Stay shorter than $requiredMinutes minutes.',
      );
    }
    return const CafeResult(
      CafeStatus.accepted,
      'Dwell time and checkout location accepted.',
    );
  }

  static CafeResult expedition(List<CafeCheckin> visits) {
    if (visits.map((e) => e.venueId).toSet().length != visits.length) {
      return const CafeResult(CafeStatus.rejected, 'Duplicate cafe check-in.');
    }
    if (visits.length < 3)
      return CafeResult(
        CafeStatus.inProgress,
        '${visits.length}/3 distinct cafe visits recorded.',
      );
    return const CafeResult(
      CafeStatus.accepted,
      'Three distinct cafes visited.',
    );
  }
}
