import 'package:flutter_test/flutter_test.dart';
import 'package:pogetit_quests/validators/cafe_validator.dart';
void main() {
  test('photo needs both checkin and photo', () {
    expect(CafeValidator.photoQuest(checkedIn: true, photoAttached: false).status, CafeStatus.rejected);
    expect(CafeValidator.photoQuest(checkedIn: true, photoAttached: true).status, CafeStatus.accepted);
  });
  test('radius boundary and rejection', () {
    expect(CafeValidator.checkLocation(distance: 150, radius: 150, gpsReliable: true).status, CafeStatus.accepted);
    expect(CafeValidator.checkLocation(distance: 151, radius: 150, gpsReliable: true).status, CafeStatus.rejected);
    expect(CafeValidator.checkLocation(distance: 0, radius: 150, gpsReliable: false).status, CafeStatus.rejected);
  });
  test('dwell time and checkout location', () {
    final start = DateTime.utc(2026, 10, 28, 10);
    expect(CafeValidator.dwellQuest(start: start, end: start.add(const Duration(minutes: 9)), checkoutInRadius: true, requiredMinutes: 10).status, CafeStatus.rejected);
    expect(CafeValidator.dwellQuest(start: start, end: start.add(const Duration(minutes: 10)), checkoutInRadius: false, requiredMinutes: 10).status, CafeStatus.rejected);
    expect(CafeValidator.dwellQuest(start: start, end: start.add(const Duration(minutes: 10)), checkoutInRadius: true, requiredMinutes: 10).status, CafeStatus.accepted);
  });
  test('expedition needs three distinct venues', () {
    final t = DateTime.utc(2026);
    CafeCheckin v(String id) => CafeCheckin(venueId: id, at: t, distanceMetres: 50);
    expect(CafeValidator.expedition([v('A')]).status, CafeStatus.inProgress);
    expect(CafeValidator.expedition([v('A'), v('A')]).status, CafeStatus.rejected);
    expect(CafeValidator.expedition([v('A'), v('B'), v('C')]).status, CafeStatus.accepted);
  });
}
