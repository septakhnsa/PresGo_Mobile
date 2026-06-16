import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import '../models/jadwal_model.dart';
import '../main.dart' show navigatorKey;
import '../screens/main_navigation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Stores the last logged-in user data so we can navigate properly
  /// when a notification is tapped from background/terminated state.
  static Map<String, dynamic>? _lastUser;

  /// Call this after a successful login to store the user reference.
  static void setCurrentUser(Map<String, dynamic> user) {
    _lastUser = user;
  }

  Future<void> init() async {
    tz.initializeTimeZones();
    // Use local timezone if needed, assuming Jakarta
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (e) {
      debugPrint("Failed to set timezone: $e");
    }

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap (foreground + background)
        _handleNotificationTap(response.payload);
      },
    );

    // Request permissions for Android 13+
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();

    // Check if app was launched by tapping a notification (terminated state)
    final launchDetails = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails != null &&
        launchDetails.didNotificationLaunchApp &&
        launchDetails.notificationResponse != null) {
      // Delay to allow the widget tree to build first
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationTap(launchDetails.notificationResponse!.payload);
      });
    }
  }

  /// Central handler for notification taps.
  /// Navigates to the MainNavigation with the notification page open.
  void _handleNotificationTap(String? payload) {
    debugPrint('Notification tapped with payload: $payload');

    final user = _lastUser;
    if (user == null) {
      // User hasn't logged in yet — the app will open to the login screen.
      // We can't navigate to notifications without user data.
      debugPrint('No user data available, skipping notification navigation.');
      return;
    }

    // Use a small delay to ensure the navigator is ready
    Future.delayed(const Duration(milliseconds: 300), () {
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        // Push the MainNavigation with showNotification flag
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => MainNavigation(
              user: user,
              initialShowNotification: true,
            ),
          ),
          (route) => false,
        );
      }
    });
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'presensi_channel',
      'Presensi Notifications',
      channelDescription: 'Notifications for attendance status',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF14532D), // Tosca
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload ?? 'notification',
    );
  }

  Future<void> scheduleClassReminders(List<JadwalModel> jadwalList) async {
    // Cancel all previously scheduled class reminders to avoid duplicates
    await flutterLocalNotificationsPlugin.cancelAll();

    final now = DateTime.now();
    int notifIdCounter = 100;

    for (var jadwal in jadwalList) {
      if (jadwal.status == 'Sudah Absen') continue;

      final parts = jadwal.jamMulai.split(':');
      if (parts.length != 2) continue;

      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      // Find the next occurrence of this class day
      int targetWeekday = _getWeekdayNumber(jadwal.hari);
      DateTime scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

      // Adjust date to the correct weekday
      while (scheduledDate.weekday != targetWeekday) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // We want to remind 15 minutes before the class
      DateTime reminderTime = scheduledDate.subtract(const Duration(minutes: 15));

      // If the reminder time is already passed for this week, schedule for next week
      if (reminderTime.isBefore(now)) {
        reminderTime = reminderTime.add(const Duration(days: 7));
      }

      final tz.TZDateTime tzReminderTime = tz.TZDateTime.from(reminderTime, tz.local);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notifIdCounter++,
        'Pengingat Presensi',
        'Kelas ${jadwal.mataKuliah} akan dimulai dalam 15 Menit. Persiapkan kehadiran Anda.',
        tzReminderTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'class_reminders',
            'Class Reminders',
            channelDescription: 'Alarm reminders before class starts',
            importance: Importance.max,
            priority: Priority.high,
            color: Color(0xFF14532D),
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // Repeats weekly
        payload: jadwal.mataKuliah,
      );
    }
  }

  int _getWeekdayNumber(String hari) {
    switch (hari.toLowerCase()) {
      case 'senin': return 1;
      case 'selasa': return 2;
      case 'rabu': return 3;
      case 'kamis': return 4;
      case 'jumat': return 5;
      case 'sabtu': return 6;
      case 'minggu': return 7;
      default: return 1;
    }
  }
}
