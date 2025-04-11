import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notification_service.dart'; // Adjust import path
import 'tification_detail.dart'; // Adjust import path

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error marking as seen: $e')));
      }
    } finally {
      if (mounted) setState(() => _isMarkingAsSeen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink.shade300,
        elevation: 0,
        title: const Text(
          'Notification History',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.pink.shade300, Colors.purple.shade200],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink.shade50, Colors.white],
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _notificationHistoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.pink),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
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
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
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
                    color: Colors.black.withOpacity(0.2),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
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
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: isSeen ? Colors.white : Colors.white.withOpacity(0.95),
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
              color: isSeen ? Colors.grey.shade200 : Colors.pink.shade200,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSeen ? Colors.grey.shade100 : Colors.pink.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications,
                  color: isSeen ? Colors.grey.shade600 : Colors.pink.shade600,
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
                        color: isSeen ? Colors.grey.shade700 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['body'] ?? 'No Content',
                      style: TextStyle(
                        fontSize: 14,
                        color: isSeen ? Colors.grey.shade600 : Colors.black54,
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
                          color: Colors.grey.shade500,
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
                                    ? Colors.grey.shade500
                                    : Colors.blue.shade600,
                          ),
                        ),
                        if (isSeen)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Seen',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
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
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Tap to view',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
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
