enum BrowserNotificationResult { sent, denied, unsupported, failed }

class BrowserNotificationService {
  Future<BrowserNotificationResult> sendTestNotification() async {
    return BrowserNotificationResult.unsupported;
  }
}
