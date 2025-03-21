import 'dart:convert';
import 'package:adde/pages/notification/notificatio_history_page.dart'
    show NotificationHistoryPage;
import 'package:adde/pages/notification/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adde/auth/login_page.dart';
import 'package:adde/pages/appointmentPages/calander_page.dart';
import 'package:adde/pages/health_matrics_page.dart';
import 'package:adde/pages/journal_page.dart';
import 'package:adde/pages/name_suggation_page.dart';
import 'package:adde/pages/profile/profile_page.dart';

class HomeScreen extends StatefulWidget {
  final String user_id;
  final String fullName;
  final double weight;
  final String weightUnit;
  final double height;
  final DateTime pregnancyStartDate;

  const HomeScreen({
    super.key,
    required this.fullName,
    required this.weight,
    required this.weightUnit,
    required this.height,
    required this.pregnancyStartDate,
    required this.user_id,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ScrollController _scrollController;
  bool _hasUnreadNotifications = false;
  int _pregnancyWeeks = 0;
  int _pregnancyDays = 0;
  String? _profileImageBase64;

  @override
  void initState() {
    super.initState();
    _updatePregnancyProgress();
    _checkUnreadNotifications();
    _loadProfileImage();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _pregnancyWeeks * 54.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      _scheduleHealthTips();
      _checkAndShowTodaysTip();
    });

    Future.delayed(const Duration(days: 1), () {
      if (mounted) _updatePregnancyProgress();
    });
  }

  void _updatePregnancyProgress() {
    final currentDate = DateTime.now();
    final difference = currentDate.difference(widget.pregnancyStartDate);
    final totalDays = difference.inDays;
    print('Total days since pregnancy start: $totalDays');
    setState(() {
      _pregnancyWeeks = (totalDays / 7).floor();
      _pregnancyDays = totalDays % 7;
    });
  }

  Future<void> _loadProfileImage() async {
    try {
      final response =
          await Supabase.instance.client
              .from('mothers')
              .select('profile_url')
              .eq('user_id', widget.user_id)
              .single();
      setState(() {
        _profileImageBase64 = response['profile_url'];
      });
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

  Future<void> _checkUnreadNotifications() async {
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );
    final history = await notificationService.getNotificationHistory(
      widget.user_id,
    );
    setState(() {
      _hasUnreadNotifications = history.any((n) => n['seen'] == false);
    });
  }

  Future<void> _scheduleHealthTips() async {
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );
    await notificationService.scheduleDailyHealthTips(
      widget.pregnancyStartDate,
      widget.user_id,
    );
  }

  Future<void> _checkAndShowTodaysTip() async {
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );
    await notificationService.checkAndShowTodaysTip(
      widget.user_id,
      widget.pregnancyStartDate,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> features = [
      {
        "icon": "assets/calendar.png",
        "name": "Calendar",
        "description": "Schedule Appointments",
        "navigation": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CalendarPage()),
          );
        },
      },
      {
        "icon": "assets/bmi.png",
        "name": "Health Metrics",
        "description": "Check your health",
        "navigation": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HealthMetricsPage(userId: widget.user_id),
            ),
          );
        },
      },
      {
        "icon": "assets/diary.png",
        "name": "Journal",
        "description": "Write your thoughts",
        "navigation": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => JournalPage()),
          );
        },
      },
      {
        "icon": "assets/label.png",
        "name": "Name Suggestion",
        "description": "Find baby names",
        "navigation": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NameSuggationPage()),
          );
        },
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                ).then((_) => _loadProfileImage()); // Refresh image on return
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage:
                    _profileImageBase64 != null
                        ? MemoryImage(base64Decode(_profileImageBase64!))
                        : const AssetImage('assets/user.png') as ImageProvider,
                radius: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "Welcome, ${widget.fullName.toUpperCase()}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _hasUnreadNotifications
                  ? Icons.notifications_active
                  : Icons.notifications_none,
              color: _hasUnreadNotifications ? Colors.red : Colors.grey,
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          NotificationHistoryPage(userId: widget.user_id),
                ),
              );
              await _checkUnreadNotifications();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.pink),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => JournalPage()),
          );
        },
        backgroundColor: Colors.pink,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pinkAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 250,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Pregnancy Tracker",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              "$_pregnancyWeeks",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              "Weeks",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        const CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.white24,
                          backgroundImage: AssetImage("assets/embryo.gif"),
                        ),
                        Column(
                          children: [
                            Text(
                              "$_pregnancyDays",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              "Days",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: LinearProgressIndicator(
                        value: _pregnancyWeeks / 40,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      features.map<Widget>((item) {
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: item["navigation"],
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Image.asset(
                                    item["icon"],
                                    width: 50,
                                    height: 50,
                                    color: Colors.pink,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item["name"],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item["description"],
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
