import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notification_service.dart'; // Adjust import path
import 'notification_detail.dart'; // Adjust import path

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
    if (_isMarkingAsSeen) return;

    setState(() => _isMarkingAsSeen = true);

    try {
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      await notificationService.markNotificationAsSeen(widget.userId, day);

      setState(() {
        _notifications =
            _notifications.map((n) {
              if (n['day'] == day) return {...n, 'seen': true};
              return n;
            }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error marking as seen: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isMarkingAsSeen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).brightness == Brightness.light
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onPrimary,
        elevation: Theme.of(context).appBarTheme.elevation,
        title: Text(
          'Notification History',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color:
                Theme.of(context).brightness == Brightness.light
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _notificationHistoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 16,
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off,
                      size: 60,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            _notifications = snapshot.data!;
            return Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final bool isSeen = notification['seen'] ?? false;
                    final deliveredAt = DateTime.parse(
                      notification['delivered_at'],
                    ).toLocal().toString().substring(0, 16);

                    return _buildNotificationCard(
                      notification,
                      isSeen,
                      deliveredAt,
                    );
                  },
                ),
                if (_isMarkingAsSeen)
                  Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.2),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
    bool isSeen,
    String deliveredAt,
  ) {
    return Card(
      elevation: Theme.of(context).cardTheme.elevation,
      margin: const EdgeInsets.only(bottom: 8),
      shape: Theme.of(context).cardTheme.shape,
      color:
          isSeen
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      NotificationDetailPage(notification: notification),
            ),
          ).then((_) {
            if (!isSeen) _markAsSeen(notification['day']);
          });
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color:
                  isSeen
                      ? Theme.of(context).colorScheme.outline
                      : Theme.of(context).colorScheme.primary,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isSeen
                          ? Theme.of(context).colorScheme.surface
                          : Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications,
                  color:
                      isSeen
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['title'] ?? 'No Title',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSeen ? FontWeight.normal : FontWeight.bold,
                        color:
                            isSeen
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['body'] ?? 'No Content',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification['relevance'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Relevance: ${notification['relevance']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          deliveredAt,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isSeen
                                    ? Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant
                                    : Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        if (isSeen)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check,
                                  size: 14,
                                  color:
                                      Theme.of(context).colorScheme.onSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Seen',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Tap to view',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onTertiary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
