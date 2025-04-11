import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  NotificationService() {
    _initNotification();
  }

  Future<void> _initNotification() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(tz.local.name));

      const AndroidInitializationSettings initSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(
        android: initSettingsAndroid,
      );

      await notificationPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (
          NotificationResponse response,
        ) async {
          if (response.payload != null) {
            final parts = response.payload!.split('|');
            if (parts.length == 4) {
              final userId = parts[0];
              final day = int.parse(parts[1]);
              final title = parts[2];
              final scheduledDate = DateTime.parse(parts[3]);
              await Future.wait([
                _saveDeliveredNotification(userId, day, title, scheduledDate),
                markNotificationAsSeen(userId, day),
              ]);
            }
          }
        },
      );

      final androidPlugin =
          notificationPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        if (granted != true) return;

        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'daily_channel_id',
          'Daily Tip',
          description: 'Health tips every 4 days',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }

      _isInitialized = true;
    } catch (e) {
      print('Error initializing notifications: $e');
      _isInitialized = false;
    }
  }

  NotificationDetails _notificationDetails() => const NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_channel_id',
      'Daily Tip',
      channelDescription: 'Health tips every 4 days',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    ),
  );

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _initNotification();
      await notificationPlugin.show(
        id,
        title,
        body,
        _notificationDetails(),
        payload: payload,
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  Future<void> scheduleDailyHealthTips(
    DateTime startDate,
    String userId,
  ) async {
    await _initNotification();
    if (!_isInitialized) return;

    final tips = await _fetchHealthTips();
    if (tips.isEmpty) return;

    await notificationPlugin.cancelAll();
    final now = DateTime.now();
    const interval = 4; // 4-day interval
    final maxTips = (280 / interval).ceil(); // 280 days / 4 = 70 tips max

    await Future.wait(
      List.generate(maxTips, (index) {
        final day = index * interval; // Day 0, 4, 8, ..., 276
        if (day >= 280 || day >= tips.length * interval) return Future.value();

        final scheduledDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day + day,
          8,
          0,
        );
        final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

        if (tzScheduledDate.isAfter(now)) {
          final tipIndex = (day / interval).floor(); // Map to tip index
          final tip = tips[tipIndex];
          final title = tip['title'];
          final body = tip['body'];

          return notificationPlugin.zonedSchedule(
            tip['id'],
            title,
            body,
            tzScheduledDate,
            _notificationDetails(),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: '$userId|$day|$title|${scheduledDate.toIso8601String()}',
          );
        }
        return Future.value();
      }),
    );
  }

  Future<void> checkAndShowTodaysTip(String userId, DateTime startDate) async {
    await _initNotification();
    if (!_isInitialized) return;

    final now = DateTime.now();
    final daysSinceStart = now.difference(startDate).inDays;
    if (daysSinceStart < 0 || daysSinceStart >= 280) return;

    final todayIntervalDay =
        (daysSinceStart ~/ 4) * 4; // Nearest lower 4-day mark
    final history = await getNotificationHistory(userId);
    final todayNotification = history.firstWhere(
      (n) => n['day'] == todayIntervalDay,
      orElse: () => {},
    );

    if (todayNotification.isEmpty || todayNotification['seen'] == false) {
      final tips = await _fetchHealthTips();
      final tipIndex = todayIntervalDay ~/ 4;
      if (tipIndex >= tips.length) return;

      final tip = tips[tipIndex];
      final title = tip['title'];
      final body = tip['body'];
      await showNotification(
        id: tip['id'],
        title: title,
        body: body,
        payload: '$userId|$todayIntervalDay|$title|${now.toIso8601String()}',
      );
      await _saveDeliveredNotification(userId, todayIntervalDay, title, now);
    }
  }

  Future<void> _saveDeliveredNotification(
    String userId,
    int day,
    String title,
    DateTime scheduledDate,
  ) async {
    try {
      final tips = await _fetchHealthTips();
      final tipIndex = day ~/ 4;
      if (tipIndex >= tips.length) return;

      final tip = tips[tipIndex];
      final body = tip['body'];
      final relevance = tip['relevance'];

      await Supabase.instance.client.from('notification_history').upsert({
        'user_id': userId,
        'day': day,
        'title': title,
        'body': body,
        if (relevance != null) 'relevance': relevance,
        'scheduled_date': scheduledDate.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'seen': false,
        'delivered_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,day');
    } catch (e) {
      print('Error saving delivered notification: $e');
    }
  }

  Future<void> markNotificationAsSeen(String userId, int day) async {
    try {
      await Supabase.instance.client
          .from('notification_history')
          .update({'seen': true})
          .eq('user_id', userId)
          .eq('day', day);
    } catch (e) {
      print('Error marking notification as seen: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNotificationHistory(
    String userId,
  ) async {
    try {
      final response = await Supabase.instance.client
          .from('notification_history')
          .select()
          .eq('user_id', userId)
          .order('delivered_at', ascending: false);
      return response;
    } catch (e) {
      print('Error fetching notification history: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchHealthTips() async {
    try {
      final response = await Supabase.instance.client
          .from('health_tips')
          .select('id, day, title, body, relevance')
          .order('day', ascending: true);
      return response;
    } catch (e) {
      print('Error fetching health tips: $e');
      return List.generate(
        70, // 280 days / 4 = 70 tips
        (index) => {
          'id': index,
          'day': index * 4,
          'title': 'Tip ${index + 1}',
          'body': 'Consult your doctor for advice.',
        },
      );
    }
  }
}
