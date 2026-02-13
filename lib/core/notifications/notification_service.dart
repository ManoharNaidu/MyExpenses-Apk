import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../storage/secure_storage.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const _enabledKey = 'notifications_enabled';

  static bool _initialized = false;
  static bool _enabled = true;

  static bool get enabled => _enabled;

  static Future<void> initialize() async {
    if (_initialized) return;

    final saved = await SecureStorage.readString(_enabledKey);
    _enabled = saved == null ? true : saved == 'true';

    if (kIsWeb) {
      _initialized = true;
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  static Future<void> setEnabled(bool value) async {
    _enabled = value;
    await SecureStorage.writeString(_enabledKey, value ? 'true' : 'false');
  }

  static Future<bool> isEnabled() async {
    if (!_initialized) {
      await initialize();
    }
    return _enabled;
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    if (kIsWeb) return;
    if (!_enabled) return;

    const androidDetails = AndroidNotificationDetails(
      'transactions_channel',
      'Transactions',
      channelDescription: 'Transaction updates and reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details);
  }
}
