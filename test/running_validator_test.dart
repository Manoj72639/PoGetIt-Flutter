import 'package:flutter_test/flutter_test.dart';
import 'package:pogetit_quests/models/running_quest.dart';
import 'package:pogetit_quests/validators/running_validator.dart';

void main() {
  test('RUN-01 passes both thresholds', () {
    expect(RunningValidator.validate(quest: runningQuests[0], elapsedSeconds: 420,
        distanceMetres: 400, gpsValid: true).status, ValidationStatus.passed);
  });
  test('RUN-01 fails if time is short', () {
    expect(RunningValidator.validate(quest: runningQuests[0], elapsedSeconds: 419,
        distanceMetres: 500, gpsValid: true).status, ValidationStatus.failed);
  });
  test('RUN-02 fails outside finish radius', () {
    expect(RunningValidator.validate(quest: runningQuests[1], elapsedSeconds: 800,
        distanceMetres: 1200, gpsValid: true,
        finishFromStartMetres: 151).status, ValidationStatus.failed);
  });
  test('RUN-02 passes inside finish radius', () {
    expect(RunningValidator.validate(quest: runningQuests[1], elapsedSeconds: 720,
        distanceMetres: 1000, gpsValid: true,
        finishFromStartMetres: 150).status, ValidationStatus.passed);
  });
  test('RUN-03 needs 1600 metres', () {
    expect(RunningValidator.validate(quest: runningQuests[2], elapsedSeconds: 0,
        distanceMetres: 1599, gpsValid: true).status, ValidationStatus.failed);
    expect(RunningValidator.validate(quest: runningQuests[2], elapsedSeconds: 0,
        distanceMetres: 1600, gpsValid: true).status, ValidationStatus.passed);
  });
  test('unavailable GPS cannot pass', () {
    expect(RunningValidator.validate(quest: runningQuests[0], elapsedSeconds: 800,
        distanceMetres: 1000, gpsValid: false).status, ValidationStatus.incomplete);
  });
}
