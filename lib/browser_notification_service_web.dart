import 'dart:js_interop';

import 'package:web/web.dart' as web;

enum BrowserNotificationResult { sent, denied, unsupported, failed }

class BrowserNotificationService {
  Future<BrowserNotificationResult> sendTestNotification() async {
    try {
      var permission = web.Notification.permission;
      if (permission == 'default') {
        final permissionResult =
            await web.Notification.requestPermission().toDart;
        permission = permissionResult.toDart;
      }

      if (permission == 'denied') {
        return BrowserNotificationResult.denied;
      }
      if (permission != 'granted') {
        return BrowserNotificationResult.unsupported;
      }

      web.Notification(
        'Mindful Moments',
        web.NotificationOptions(body: 'Time for your meditation session!'),
      );
      return BrowserNotificationResult.sent;
    } catch (_) {
      return BrowserNotificationResult.failed;
    }
  }
}
