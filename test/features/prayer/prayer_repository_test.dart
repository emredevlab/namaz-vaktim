import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_vaktim/features/prayer/prayer_models.dart';
import 'package:namaz_vaktim/features/prayer/prayer_repository.dart';

void main() {
  test('demo repository returns six prayer times', () async {
    final result = await const DemoPrayerTimesRepository().getDaily(
      const UserLocation(city: 'Nevşehir'),
      DateTime(2026, 8, 6),
    );
    expect(result.times, hasLength(6));
    expect(result.location.city, 'Nevşehir');
  });
}
