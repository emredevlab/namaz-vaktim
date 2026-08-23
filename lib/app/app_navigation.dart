import 'package:flutter/material.dart';

/// Uygulama genelinde tek Navigator anahtarı; bildirim dokunuşları ve
/// benzeri widget ağacı dışındaki yönlendirmeler bunu kullanır.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Bildirim payload'u gibi dış kaynaklı rota isteklerini işleyen handler.
/// [_ConfiguredApp] yapılandırma yüklendiğinde atar.
void Function(String route)? notificationRouteHandler;

void handleNotificationPayload(String? payload) {
  if (payload == null || payload.isEmpty) return;
  const routePrefix = 'route:';
  final route = payload.startsWith(routePrefix)
      ? payload.substring(routePrefix.length)
      : payload;
  notificationRouteHandler?.call(route);
}
