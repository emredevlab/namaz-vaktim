import 'package:permission_handler/permission_handler.dart' as platform;

enum AppPermission { location, notification }

enum PermissionStatus { granted, denied, permanentlyDenied, restricted }

abstract interface class PermissionManager {
  Future<PermissionStatus> status(AppPermission permission);
  Future<PermissionStatus> request(AppPermission permission);
  Future<bool> openSettings();
}

final class PermissionRationale {
  const PermissionRationale({
    required this.title,
    required this.message,
    required this.actionLabel,
  });

  final String title;
  final String message;
  final String actionLabel;
}

final class PermissionRationalePolicy {
  const PermissionRationalePolicy();

  PermissionRationale forPermission(AppPermission permission) =>
      switch (permission) {
        AppPermission.location => const PermissionRationale(
            title: 'Konum izni gerekli',
            message:
                'Bulunduğunuz şehre göre doğru namaz vakitlerini göstermek için konum izni kullanılabilir.',
            actionLabel: 'Konuma izin ver',
          ),
        AppPermission.notification => const PermissionRationale(
            title: 'Bildirim izni gerekli',
            message:
                'Namaz vakitlerinden önce hatırlatma gönderebilmek için bildirim izni gerekir.',
            actionLabel: 'Bildirimlere izin ver',
          ),
      };

  String permanentlyDeniedMessage(AppPermission permission) =>
      '${forPermission(permission).title} kalıcı olarak reddedildi. Android ayarlarından izni etkinleştirin.';
}

final class PermissionHandlerManager implements PermissionManager {
  const PermissionHandlerManager();

  platform.Permission _permission(AppPermission permission) =>
      switch (permission) {
        AppPermission.location => platform.Permission.location,
        AppPermission.notification => platform.Permission.notification,
      };

  PermissionStatus _status(platform.PermissionStatus status) =>
      switch (status) {
        platform.PermissionStatus.granted => PermissionStatus.granted,
        platform.PermissionStatus.restricted => PermissionStatus.restricted,
        platform.PermissionStatus.permanentlyDenied =>
          PermissionStatus.permanentlyDenied,
        _ => PermissionStatus.denied,
      };

  @override
  Future<PermissionStatus> status(AppPermission permission) async =>
      _status(await _permission(permission).status);

  @override
  Future<PermissionStatus> request(AppPermission permission) async =>
      _status(await _permission(permission).request());

  @override
  Future<bool> openSettings() => platform.openAppSettings();
}

final class NoopPermissionManager implements PermissionManager {
  const NoopPermissionManager();
  @override
  Future<PermissionStatus> status(AppPermission permission) async =>
      PermissionStatus.denied;
  @override
  Future<PermissionStatus> request(AppPermission permission) async =>
      PermissionStatus.denied;
  @override
  Future<bool> openSettings() async => false;
}
