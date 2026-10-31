import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class HealthService {
  final Health _health = Health();

  Future<int?> getTodaySteps() async {
    await _health.configure();

    final sdkStatus = await _health.getHealthConnectSdkStatus();

    debugPrint('Health Connect status: $sdkStatus');

    final types = [HealthDataType.STEPS];
    final permissions = [HealthDataAccess.READ];

    final authorized = await _health.requestAuthorization(
      types,
      permissions: permissions,
    );

    debugPrint('Health Connect authorized: $authorized');

    if (!authorized) {
      throw Exception('Health Connect Steps permission denied');
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final steps = await _health.getTotalStepsInInterval(startOfDay, now);

    debugPrint('Today steps: $steps');

    return steps;
  }
}
