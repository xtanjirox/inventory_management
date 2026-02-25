import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
// ignore: depend_on_referenced_packages
import 'package:timezone/data/latest_all.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int _lowStockId = 100;
  static const int _recapId = 200;
  static const int _reminderId = 300;
  static const String _channelId = 'inventory_alerts';
  static const String _channelName = 'Inventory Alerts';
  static const String _channelDesc = 'Alerts for low stock, daily recap and reminders';

  // Reusable details
  static const _androidHigh = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDesc,
    importance: Importance.high,
    priority: Priority.high,
    enableVibration: true,
  );
  static const _androidDefault = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDesc,
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    enableVibration: true,
  );
  static const _details = NotificationDetails(
    android: _androidHigh,
    iOS: DarwinNotificationDetails(),
  );
  static const _detailsDefault = NotificationDetails(
    android: _androidDefault,
    iOS: DarwinNotificationDetails(),
  );

  Future<void> initialize() async {
    if (_initialized) return;
    initializeTimeZones();

    // Set device local timezone so scheduled notifications fire at the right time
    final String deviceTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(deviceTz));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Create Android notification channel explicitly (required for Android 8+)
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
        enableVibration: true,
      ),
    );

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  // ── Low stock notification ────────────────────────────────────────────────

  // Show an immediate low-stock notification (call right after enabling the setting)
  Future<void> showLowStockNow({
    required int lowStockCount,
    required int totalProducts,
  }) async {
    if (lowStockCount == 0) return;
    await _plugin.show(
      _lowStockId,
      '⚠️ Low Stock Alert',
      '$lowStockCount of $totalProducts products are running low.',
      _details,
    );
  }

  Future<void> scheduleLowStockCheck({
    required int lowStockCount,
    required int totalProducts,
    Duration interval = const Duration(hours: 24),
  }) async {
    await _plugin.cancel(_lowStockId);
    if (lowStockCount == 0) return;

    await _plugin.zonedSchedule(
      _lowStockId,
      '⚠️ Low Stock Alert',
      '$lowStockCount of $totalProducts products are running low.',
      tz.TZDateTime.now(tz.local).add(interval),
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelLowStockNotification() async {
    await _plugin.cancel(_lowStockId);
  }

  // ── Daily recap notification ───────────────────────────────────────────────

  Future<void> scheduleRecap({
    required int totalProducts,
    required double totalValue,
    required int lowStockCount,
    required TimeOfDay time,
    required String currency,
    bool daily = true,
    int? customIntervalHours,
  }) async {
    await _plugin.cancel(_recapId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(
          Duration(hours: daily ? 24 : (customIntervalHours ?? 24)));
    }

    final body = '$totalProducts products · '
        '$currency ${totalValue.toStringAsFixed(0)} total value'
        '${lowStockCount > 0 ? ' · ⚠️ $lowStockCount low stock' : ''}';

    await _plugin.zonedSchedule(
      _recapId,
      '📦 Inventory Recap',
      body,
      scheduledDate,
      _detailsDefault,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: daily ? DateTimeComponents.time : null,
    );
  }

  Future<void> cancelRecapNotification() async {
    await _plugin.cancel(_recapId);
  }

  // ── Stock reminder notification ────────────────────────────────────────────

  Future<void> scheduleReminder({required TimeOfDay time}) async {
    await _plugin.cancel(_reminderId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(hours: 24));
    }

    await _plugin.zonedSchedule(
      _reminderId,
      '📋 Stock Review Reminder',
      'Time to check and adjust your inventory stock levels.',
      scheduledDate,
      _detailsDefault,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder() async {
    await _plugin.cancel(_reminderId);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
