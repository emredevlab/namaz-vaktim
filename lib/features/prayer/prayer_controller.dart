import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/notification_service.dart';
import 'prayer_models.dart';
import 'prayer_repository.dart';

final class PrayerController extends ChangeNotifier {
  PrayerController({
    PrayerTimesRepository? repository,
    LocalNotificationScheduler? notificationScheduler,
    NotificationPreferences preferences = const NotificationPreferences(),
    Future<void> Function(NotificationPreferences preferences)?
        onPreferencesChanged,
  })  : _repository = repository ?? const DemoPrayerTimesRepository(),
        _notificationPlanner = PrayerNotificationPlanner(
          scheduler: notificationScheduler ?? const NoopNotificationScheduler(),
        ),
        _notificationPreferences = preferences,
        _onPreferencesChanged = onPreferencesChanged;
  final PrayerTimesRepository _repository;
  final PrayerNotificationPlanner _notificationPlanner;
  NotificationPreferences _notificationPreferences;
  final Future<void> Function(NotificationPreferences preferences)?
      _onPreferencesChanged;
  Timer? _refreshTimer;
  bool _requestInFlight = false;
  UserLocation _lastLocation = const UserLocation(city: 'Nevşehir');
  PrayerHomeState _state = const PrayerHomeState(isLoading: true);

  PrayerHomeState get state => _state;

  NotificationPreferences get notificationPreferences =>
      _notificationPreferences;

  Future<void> updateNotificationPreferences(
      NotificationPreferences preferences) async {
    _notificationPreferences = preferences;
    await _onPreferencesChanged?.call(preferences);
    final data = _state.data;
    if (data == null) return;
    await _notificationPlanner.synchronize(
      [
        for (final prayerTime in data.times)
          PrayerNotificationRequest(
            id: prayerTime.type.index,
            title: prayerTime.type.name,
            prayerTime: prayerTime.dateTime,
          ),
      ],
      preferences,
    );
    notifyListeners();
  }

  /// [location] verilmezse en son kullanılan konum yeniden kullanılır;
  /// böylece periyodik yenileme ve hata sonrası retry, kullanıcının
  /// seçtiği şehri/GPS konumunu üzerine yazmaz.
  Future<void> load({UserLocation? location}) async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    final effectiveLocation = location ?? _lastLocation;
    _lastLocation = effectiveLocation;
    final hasExistingData = _state.data != null;
    _state =
        _state.copyWith(isLoading: !hasExistingData, error: null);
    notifyListeners();
    try {
      final data = await _repository.getDaily(effectiveLocation, DateTime.now());
      _state = PrayerHomeState(data: data);
      try {
        await _notificationPlanner.synchronize(
          [
            for (final prayerTime in data.times)
              PrayerNotificationRequest(
                id: prayerTime.type.index,
                title: prayerTime.type.name,
                prayerTime: prayerTime.dateTime,
              ),
          ],
          _notificationPreferences,
        );
      } catch (_) {
        // Bildirim kurulumu başarısız olsa da namaz vakitleri gösterilmelidir.
      }
    } catch (_) {
      if (!hasExistingData) {
        _state = const PrayerHomeState(
            error: 'Namaz vakitleri yüklenemedi. Lütfen tekrar deneyin.');
      }
    }
    _requestInFlight = false;
    notifyListeners();
    _refreshTimer ??= Timer.periodic(const Duration(minutes: 1), (_) {
      load();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    super.dispose();
  }
}
