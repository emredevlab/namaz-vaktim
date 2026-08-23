import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notification_service.dart';
import '../core/permission_manager.dart';
import '../features/prayer/prayer_controller.dart';
import '../features/prayer/prayer_repository.dart';
import 'app_navigation.dart';

final permissionManagerProvider =
    Provider<PermissionManager>((ref) => const PermissionHandlerManager());
final notificationSchedulerProvider = Provider<LocalNotificationScheduler>(
  (ref) => AndroidNotificationScheduler(
    onNotificationTap: handleNotificationPayload,
  ),
);
final notificationPreferencesStoreProvider =
    Provider<NotificationPreferencesStore>(
  (ref) => NotificationPreferencesStore.memory(),
);
final prayerRepositoryProvider =
    Provider<PrayerTimesRepository>((ref) => const DemoPrayerTimesRepository());

final prayerControllerProvider = ChangeNotifierProvider<PrayerController>(
  (ref) {
    return PrayerController(
      repository: ref.watch(prayerRepositoryProvider),
      notificationScheduler: ref.watch(notificationSchedulerProvider),
      preferences: ref.watch(notificationPreferencesStoreProvider).read(),
      onPreferencesChanged:
          ref.watch(notificationPreferencesStoreProvider).write,
    );
  },
  dependencies: [
    prayerRepositoryProvider,
    notificationSchedulerProvider,
    notificationPreferencesStoreProvider,
  ],
);
