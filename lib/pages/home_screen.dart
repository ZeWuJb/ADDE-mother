import 'dart:convert';
import 'package:adde/pages/chatbot/chat_screen.dart';
import 'package:adde/pages/name_suggestion/name_suggestion_page.dart';
import 'package:adde/pages/note/journal_screen.dart';
import 'package:adde/pages/notification/notificatio_history_page.dart';
import 'package:adde/pages/notification/notification_service.dart';
import 'package:adde/pages/weekly_tips/weeklytip_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adde/auth/login_page.dart';
import 'package:adde/pages/appointmentPages/calander_page.dart';
import 'package:adde/pages/health_matrics_page.dart';
import 'package:adde/pages/profile/profile_page.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  late Future<void> _notificationCheckFuture;
  List<Map<String, dynamic>> _weeklyTips = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _updatePregnancyProgress();
    _loadProfileImage();
    _notificationCheckFuture = _checkUnreadNotifications();
    _loadWeeklyTips();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0); // Ensure top is visible on load
      }
      _scheduleHealthTips();
      _checkAndShowTodaysTip();
    });

    // Periodic update for pregnancy progress (once a day)
    Future.delayed(const Duration(days: 1), () {
      if (mounted) _updatePregnancyProgress();
    });
  }

  void _updatePregnancyProgress() {
    final currentDate = DateTime.now();
    final difference = currentDate.difference(widget.pregnancyStartDate);
    final totalDays = difference.inDays;
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

  Future<void> _loadWeeklyTips() async {
    try {
      final response = await Supabase.instance.client
          .from('weekly_tips')
          .select()
          .order('week', ascending: true)
          .limit(3);
      setState(() {
        _weeklyTips = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading weekly tips: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      floatingActionButton: _buildFloatingActionButton(context),
      body: Container(
        decoration: _buildBackgroundGradient(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: _buildPregnancyJourneySection()),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: _buildWeeklyTipsSection(context),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverToBoxAdapter(child: _buildFeaturesSection(context)),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                ).then((_) => _loadProfileImage()),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withOpacity(0.3),
              backgroundImage:
                  _profileImageBase64 != null
                      ? MemoryImage(base64Decode(_profileImageBase64!))
                      : const AssetImage('assets/user.png') as ImageProvider,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Hi, ${widget.fullName}!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
                shadows: [
                  Shadow(
                    color: Theme.of(context).colorScheme.shadow,
                    blurRadius: 4,
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        FutureBuilder<void>(
          future: _notificationCheckFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.onSurface,
                  strokeWidth: 2,
                ),
              );
            }
            return Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 28,
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                NotificationHistoryPage(userId: widget.user_id),
                      ),
                    );
                    _notificationCheckFuture = _checkUnreadNotifications();
                    setState(() {});
                  },
                ),
                if (_hasUnreadNotifications)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.shadow,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          icon: Icon(
            Icons.logout,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 28,
          ),
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
              ),
        ),
      ],
    );
  }

  Animate _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen()),
          ),
      backgroundColor: Colors.white,
      elevation: 6,
      child: const Icon(Icons.chat, color: Colors.pink, size: 28),
    ).animate().fadeIn(duration: 600.ms).scale(delay: 400.ms);
  }

  BoxDecoration _buildBackgroundGradient() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.pink.shade100, Colors.purple.shade50],
      ),
    );
  }

  Widget _buildPregnancyJourneySection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.pink.shade400, Colors.purple.shade400],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Pregnancy Journey",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ).animate().fadeIn(duration: 800.ms),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCounterBox(_pregnancyWeeks, "Weeks"),
              const SizedBox(width: 20),
              CircleAvatar(
                radius: 70,
                backgroundColor: Colors.white.withOpacity(0.9),
                child: ClipOval(
                  child: Image.asset(
                    "assets/embryo.gif",
                    fit: BoxFit.cover,
                    width: 120,
                    height: 120,
                  ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOut),
              const SizedBox(width: 20),
              _buildCounterBox(_pregnancyDays, "Days"),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (_pregnancyWeeks / 40).clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.pink.shade200],
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ).animate().fadeIn(duration: 1000.ms),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTipsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Weekly Tips",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child:
              _weeklyTips.isEmpty
                  ? Center(
                    child: Text(
                      "No tips yet—add some!",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _weeklyTips.length,
                    itemBuilder: (context, index) {
                      final tip = _weeklyTips[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => WeeklyTipPage(
                                        initialTip: tip,
                                        pregnancyStartDate:
                                            widget.pregnancyStartDate,
                                      ),
                                ),
                              ),
                          child: Container(
                            width: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  child:
                                      tip['image'] != null
                                          ? Image.memory(
                                            base64Decode(tip['image']),
                                            height: 100,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                          : Container(
                                            height: 100,
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                              Icons.image,
                                              size: 40,
                                              color: Colors.grey,
                                            ),
                                          ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Week ${tip['week']}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.pink,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        tip['title'] ?? 'No Title',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: (index * 200).ms),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    final features = [
      {
        "icon": "assets/calendar.png",
        "name": "Calendar",
        "description": "Schedule Appointments",
        "navigation":
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CalendarPage()),
            ),
      },
      {
        "icon": "assets/bmi.png",
        "name": "Health Metrics",
        "description": "Check your health",
        "navigation":
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HealthMetricsPage(userId: widget.user_id),
              ),
            ),
      },
      {
        "icon": "assets/diary.png",
        "name": "Journal",
        "description": "Write your thoughts",
        "navigation":
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => JournalScreen()),
            ),
      },
      {
        "icon": "assets/label.png",
        "name": "Name Suggestion",
        "description": "Find baby names",
        "navigation":
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NameSuggestionPage()),
            ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Explore Features",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        const SizedBox(height: 12),
        ...features.map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildFeatureCard(feature),
          ),
        ),
      ],
    );
  }

  Widget _buildCounterBox(int value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
            ],
          ),
          child: Text(
            "$value",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: feature["navigation"],
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  feature["icon"],
                  width: 40,
                  height: 40,
                  color: Colors.pink.shade400,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature["name"],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature["description"],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.pink),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
