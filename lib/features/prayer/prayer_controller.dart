import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/notification_service.dart';
import '../../core/prayer_backup_worker.dart';
import '../../shared/formatting.dart';
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

  /// Planlanmış yarın bildirimlerinin istekleri; synchronize() cancelAll
  /// yaptığından her senkrona bugünle birlikte dahil edilmek zorundalar.
  List<PrayerNotificationRequest>? _cachedTomorrowRequests;
  UserLocation _lastLocation = const UserLocation(
    city: 'Nevşehir',
    latitude: 38.6244,
    longitude: 34.7239,
  );
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
    await _synchronizeNotifications(_notificationRequestsFor(data));
    notifyListeners();
  }

  List<PrayerNotificationRequest> _notificationRequestsFor(
    DailyPrayerTimes data, {
    int idOffset = 0,
  }) =>
      [
        for (final prayerTime in data.times)
          PrayerNotificationRequest(
            id: prayerTime.type.index + idOffset,
            title: prayerTypeLabel(prayerTime.type),
            prayerTime: prayerTime.dateTime,
          ),
      ];

  /// Bugün + (varsa) yarının isteklerini birleştirip planlar.
  /// synchronize() cancelAll ile başladığından yarının istekleri her
  /// seferinde birlikte yeniden planlanmalı, aksi halde silinirler.
  Future<void> _synchronizeNotifications(
      List<PrayerNotificationRequest> todayRequests) async {
    try {
      await _notificationPlanner.synchronize(
        [
          ...todayRequests,
          if (_cachedTomorrowRequests != null) ..._cachedTomorrowRequests!,
        ],
        _notificationPreferences,
      );
    } catch (_) {
      // Bildirim kurulumu başarısız olsa da namaz vakitleri gösterilmelidir.
    }
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
      // copyWith kullanılır: fresh constructor tomorrow'ı sıfırlayıp
      // UI'da yarın bölümünün titremesine yol açıyordu.
      _state = _state.copyWith(data: data, isLoading: false);
      await _synchronizeNotifications(_notificationRequestsFor(data));
      try {
        // Önce bugün yüklensin; yarın gecikse/başarısız olsa bile bugünün
        // verisi etkilenmez.
        final previousTomorrowDate = _state.tomorrow?.date;
        final tomorrowData = await _repository.getDaily(
          effectiveLocation,
          DateTime.now().add(const Duration(days: 1)),
        );
        _state = _state.copyWith(tomorrow: tomorrowData);
        // Yedek görev (workmanager) bugünün vakitlerini buradan okur:
        // alarm katmanı engellenirse bile bildirim garantisi.
        unawaited(writeBackupData(data));
        // Yarının bildirimleri de planlanır: kullanıcı uygulamayı yarın
        // hiç açmasa bile vakit bildirimleri vaktinde gelir. Id çakışmasını
        // önlemek için yarın +200 ofsetiyle planlanır. Gün değişmedikçe
        // yeniden planlanmaz; cache sayesinde her senkrona zaten dahiller.
        if (previousTomorrowDate != tomorrowData.date) {
          _cachedTomorrowRequests =
              _notificationRequestsFor(tomorrowData, idOffset: 200);
          await _synchronizeNotifications(_notificationRequestsFor(data));
        }
      } catch (_) {
        // Yarının vakitleri alınamazsa sessizce geç; tomorrow null kalır.
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
