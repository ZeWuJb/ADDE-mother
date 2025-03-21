import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adde/pages/notification/notification_service.dart';

class NotificationHistoryPage extends StatefulWidget {
  final String userId;

  const NotificationHistoryPage({super.key, required this.userId});

  @override
  State<NotificationHistoryPage> createState() =>
      _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage> {
  late Future<List<Map<String, dynamic>>> _notificationHistoryFuture;
  List<Map<String, dynamic>> _notifications = [];
  bool _isMarkingAsSeen = false;

  @override
  void initState() {
    super.initState();
    _notificationHistoryFuture = _fetchNotificationHistory();
  }

  Future<List<Map<String, dynamic>>> _fetchNotificationHistory() async {
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );
    return await notificationService.getNotificationHistory(widget.userId);
  }

  Future<void> _markAsSeen(int day) async {
    if (_isMarkingAsSeen) return; // Prevent multiple simultaneous taps

    setState(() {
      _isMarkingAsSeen = true;
    });

    try {
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      await notificationService.markNotificationAsSeen(widget.userId, day);

      // Update local data instead of refetching
      setState(() {
        _notifications =
            _notifications.map((n) {
              if (n['day'] == day) {
                return {...n, 'seen': true};
              }
              return n;
            }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error marking as seen: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingAsSeen = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Delivered Notifications')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notificationHistoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No delivered notifications yet'));
          }

          _notifications = snapshot.data!; // Store locally for updates
          return Stack(
            children: [
              ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  final bool isSeen = notification['seen'] ?? false;
                  final deliveredAt = DateTime.parse(
                    notification['delivered_at'],
                  ).toLocal().toString().substring(0, 16);

                  return ListTile(
                    title: Text(
                      notification['title'] ?? 'No Title',
                      style: TextStyle(
                        fontWeight:
                            isSeen ? FontWeight.normal : FontWeight.bold,
                        color: isSeen ? Colors.grey : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      notification['body'] ?? 'No Content',
                      style: TextStyle(
                        color: isSeen ? Colors.grey : Colors.black,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          deliveredAt,
                          style: TextStyle(
                            color: isSeen ? Colors.grey : Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isSeen)
                          const Icon(
                            Icons.check,
                            color: Colors.green,
                            size: 20,
                          ),
                      ],
                    ),
                    onTap:
                        isSeen
                            ? null // Disable tap if already seen
                            : () async {
                              await _markAsSeen(notification['day']);
                            },
                  );
                },
              ),
              if (_isMarkingAsSeen)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
    );
  }
}
