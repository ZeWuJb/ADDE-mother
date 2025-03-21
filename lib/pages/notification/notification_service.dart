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

  // Initialize the notification plugin
  Future<void> _initNotification() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      final String timeZoneName = tz.local.name;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print('Step 1: Timezone initialized: $timeZoneName');

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
              await _saveDeliveredNotification(
                userId,
                day,
                title,
                scheduledDate,
              );
              await markNotificationAsSeen(
                userId,
                day,
              ); // Mark as seen when tapped
            }
          }
        },
      );
      print('Step 2: Notification plugin initialized with callback');

      final androidPlugin =
          notificationPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        if (granted != true) {
          print('Step 3: Notification permission not granted');
          return; // Exit if permission is denied
        }
        print('Step 3: Notification permission granted');
      }

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'daily_channel_id',
        'Daily Tip',
        description: 'Daily health tips for pregnancy',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin?.createNotificationChannel(channel);
      print('Step 4: Notification channel created');

      _isInitialized = true;
    } catch (e) {
      print('Error initializing notifications: $e');
      _isInitialized = false;
    }
  }

  // Notification details for consistent styling
  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id',
        'Daily Tip',
        channelDescription: 'Daily health tips for pregnancy',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  // Show an immediate notification
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
      print('Notification shown - ID: $id, Title: $title, Body: $body');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  // Schedule daily health tips for 280 days
  Future<void> scheduleDailyHealthTips(
    DateTime startDate,
    String userId,
  ) async {
    await _initNotification();
    if (!_isInitialized) {
      print('Notification service not initialized, aborting scheduling');
      return;
    }

    print('Scheduling daily health tips for user: $userId');
    final tips = await _fetchHealthTips();
    if (tips.length < 280) {
      print('Error: Not enough tips in Supabase (${tips.length}/280)');
      return;
    }

    await notificationPlugin.cancelAll(); // Clear old schedules
    print('Cancelled all previous notifications');

    final now = DateTime.now();
    for (int day = 0; day < 280; day++) {
      final scheduledDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day + day,
        8, // 8:00 AM daily
        0,
      );
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      if (tzScheduledDate.isAfter(now)) {
        final title = 'Day ${day + 1} Health Tip';
        final body = tips[day]['tip'];

        await notificationPlugin.zonedSchedule(
          day,
          title,
          body,
          tzScheduledDate,
          _notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: '$userId|$day|$title|${scheduledDate.toIso8601String()}',
        );
        print('Scheduled tip for Day ${day + 1} at $tzScheduledDate');
      } else {
        print('Skipped past tip for Day ${day + 1} at $tzScheduledDate');
      }
    }
    print('All notifications scheduled');
  }

  // Check and show today's tip if not seen when app opens
  Future<void> checkAndShowTodaysTip(String userId, DateTime startDate) async {
    await _initNotification();
    if (!_isInitialized) {
      print('Notification service not initialized, skipping today\'s tip');
      return;
    }

    final now = DateTime.now();
    final daysSinceStart = now.difference(startDate).inDays;
    if (daysSinceStart < 0 || daysSinceStart >= 280) {
      print('Day $daysSinceStart is out of pregnancy range (0-279)');
      return;
    }

    final todayDay = daysSinceStart;
    final history = await getNotificationHistory(userId);
    final todayNotification = history.firstWhere(
      (n) => n['day'] == todayDay,
      orElse: () => {},
    );

    if (todayNotification.isEmpty || todayNotification['seen'] == false) {
      final tips = await _fetchHealthTips();
      if (tips.length <= todayDay) {
        print('No tip available for Day ${todayDay + 1}');
        return;
      }

      final title = 'Day ${todayDay + 1} Health Tip';
      final body = tips[todayDay]['tip'];
      await showNotification(
        id: todayDay,
        title: title,
        body: body,
        payload: '$userId|$todayDay|$title|${now.toIso8601String()}',
      );
      print('Showed today\'s tip for Day ${todayDay + 1}');
      _saveDeliveredNotification(userId, todayDay, title, now);
    } else {
      print('Today\'s tip for Day ${todayDay + 1} already seen');
    }
  }

  // Save delivered notification to Supabase
  Future<void> _saveDeliveredNotification(
    String userId,
    int day,
    String title,
    DateTime scheduledDate,
  ) async {
    try {
      final tips = await _fetchHealthTips();
      final body = tips[day]['tip'];
      await Supabase.instance.client.from('notification_history').insert({
        'user_id': userId,
        'day': day,
        'title': title,
        'body': body,
        'scheduled_date': scheduledDate.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'seen': false,
        'delivered_at': DateTime.now().toIso8601String(),
      });
      print('Saved delivered notification for user: $userId, day: $day');
    } catch (e) {
      print('Error saving delivered notification: $e');
    }
  }

  // Mark notification as seen
  Future<void> markNotificationAsSeen(String userId, int day) async {
    try {
      await Supabase.instance.client
          .from('notification_history')
          .update({'seen': true})
          .eq('user_id', userId)
          .eq('day', day);
      print('Marked notification as seen for user: $userId, day: $day');
    } catch (e) {
      print('Error marking notification as seen: $e');
    }
  }

  // Fetch notification history
  Future<List<Map<String, dynamic>>> getNotificationHistory(
    String userId,
  ) async {
    try {
      final response = await Supabase.instance.client
          .from('notification_history')
          .select()
          .eq('user_id', userId)
          .order('delivered_at', ascending: false);
      print('Fetched notification history for user: $userId');
      return response;
    } catch (e) {
      print('Error fetching notification history: $e');
      return [];
    }
  }

  // Fetch health tips from Supabase
  Future<List<Map<String, dynamic>>> _fetchHealthTips() async {
    try {
      final response = await Supabase.instance.client
          .from('health_tips')
          .select()
          .order('day', ascending: true);
      print('Fetched ${response.length} health tips');
      return response;
    } catch (e) {
      print('Error fetching health tips: $e');
      return List.generate(
        280,
        (index) => {
          'day': index,
          'tip': 'Day ${index + 1}: Consult your doctor for advice.',
        },
      );
    }
  }
}
