import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'user_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static Future<void>? _pluginReady;
  static bool _timeZonesInitialized = false;

  static Future<void> initialize() async {
    await _ensurePluginReady();

    final bool notificationsEnabled =
        await UserService.getNotificationsEnabled();
    if (!notificationsEnabled) {
      await cancelDailyReminders();
      return;
    }

    await scheduleDailyMoodPrompt();
    await scheduleMorningMotivation();
  }

  static Future<void> _ensurePluginReady() {
    return _pluginReady ??= _initializePlugin();
  }

  static Future<void> _initializePlugin() async {
    if (!_timeZonesInitialized) {
      tz.initializeTimeZones();
      _timeZonesInitialized = true;
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle payload routing if needed
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidImplementation?.requestNotificationsPermission();
    if (Platform.isAndroid) {
      await androidImplementation?.requestExactAlarmsPermission();
    }

    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> cancelDailyReminders() async {
    await _ensurePluginReady();
    await _notificationsPlugin.cancel(id: 0);
    await _notificationsPlugin.cancel(id: 2);
  }

  static Future<void> scheduleMorningMotivation() async {
    await _ensurePluginReady();
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'morning_motivation',
          'Morning Motivation',
          channelDescription: 'Get your day started with a quick win',
          importance: Importance.high,
          priority: Priority.high,
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      id: 2,
      title: "Rise and Build 🏗️",
      body: "What's the one thing you're going to ship today? Log your plan early.",
      scheduledDate: _nextInstanceOf9AM(),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOf9AM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> scheduleDailyMoodPrompt() async {
    await _ensurePluginReady();
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'daily_mood_prompt',
          'Daily Mood Check-in',
          channelDescription: 'Reminds you to log your daily mood and energy',
          importance: Importance.max,
          priority: Priority.high,
        );
    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await _notificationsPlugin.zonedSchedule(
      id: 0,
      title: 'How was your day?',
      body: 'Take 5 seconds to log your mood and energy to keep your streak alive!',
      scheduledDate: _nextInstanceOf8PM(),
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOf8PM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Schedules a weekly recap notification for Sunday at 7 PM.
  static Future<void> scheduleWeeklyRecap({
    required int weeklyScore,
    required double avgSleep,
    required int avgSteps,
  }) async {
    await _ensurePluginReady();
    final String sleepStr = avgSleep.toStringAsFixed(1);
    final String stepsStr = '${(avgSteps / 1000).toStringAsFixed(1)}k';

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'weekly_recap',
          'Weekly Recap',
          channelDescription: 'Sunday summary of your LifeScore week',
          importance: Importance.high,
          priority: Priority.high,
        );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id: 1,
      title: 'Your week in review 📊',
      body: 'LifeScore: $weeklyScore  •  Sleep: ${sleepStr}h avg  •  Steps: $stepsStr avg. Tap to share!',
      scheduledDate: _nextSunday7PM(),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static tz.TZDateTime _nextSunday7PM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    int daysUntilSunday = DateTime.sunday - now.weekday;
    if (daysUntilSunday <= 0) {
      daysUntilSunday += 7;
    }
    final tz.TZDateTime sunday = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysUntilSunday,
      19,
    );
    return sunday;
  }

  /// Shows an immediate motivational nudge based on user activity.
  static Future<void> showMotivationalNudge({
    required String title,
    required String body,
    String? channelId,
  }) async {
    await _ensurePluginReady();
    final bool notificationsEnabled =
        await UserService.getNotificationsEnabled();
    if (!notificationsEnabled) {
      return;
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId ?? 'motivational_nudges',
          'Motivational Nudges',
          channelDescription:
              'Dynamic nudges to keep you focused and motivated',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFFF0FF00),
        );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// Analyzes the current score or input and triggers a nudge if appropriate.
  static Future<void> checkAndNudge({
    required String type, // 'build', 'self', or 'needle'
    required dynamic value,
    int? previousValue,
  }) async {
    try {
      if (type == 'needle' && value == true) {
        await showMotivationalNudge(
          title: "Needle Moved! 🎯",
          body:
              "Huge win. You just did something most people find excuses for. Keep going!",
        );
      } else if (type == 'build') {
        final int score = value as int;
        if (score >= 90) {
          await showMotivationalNudge(
            title: "Elite Performance 🏆",
            body:
                "Your Build Score is at $score. You are in deep flow. Don't stop now!",
          );
        } else if (score < 30 && (previousValue ?? 100) >= 30) {
          await showMotivationalNudge(
            title: "Reality Check ⚡",
            body:
                "The numbers don't lie. Your Build Score is low. Ship one small task to reset the energy.",
          );
        }
      } else if (type == 'self') {
        final int score = value as int;
        if (score < 40) {
          await showMotivationalNudge(
            title: "Foundation Warning ⚠️",
            body:
                "Your Self Score is low. You can't build a skyscraper on a swamp. Sleep or recover first.",
          );
        }
      }
    } catch (e) {
      debugPrint('NOTIFICATION ERROR: $e');
    }
  }
}
