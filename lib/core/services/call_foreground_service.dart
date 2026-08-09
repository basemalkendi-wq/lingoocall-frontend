import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class CallForegroundService {
  static void initService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'lingoocall_active_call',
        channelName: 'LingooCall Active Call',
        channelDescription: 'Ongoing AI Translated Call Notification',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 1000,
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> startCallNotification({
    required String contactName,
    required String durationText,
  }) async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: '📞 مكالمة جارِية مع $contactName',
        notificationText: 'المدة: $durationText • LingooCall AI',
      );
    } else {
      await FlutterForegroundTask.startService(
        notificationTitle: '📞 مكالمة جارِية مع $contactName',
        notificationText: 'المدة: $durationText • LingooCall AI',
      );
    }
  }

  static Future<void> stopCallNotification() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}
