import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  Future<void> initialize() async {
    if (_initialized) return;
    initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
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
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.defaultImportance,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          daily ? DateTimeComponents.time : null,
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
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
