import 'dart:convert';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/chatbot/chat_screen.dart';
import 'package:adde/pages/health_matrics_page.dart';
import 'package:adde/pages/name_suggestion/name_suggestion_page.dart';
import 'package:adde/pages/note/journal_screen.dart';
import 'package:adde/pages/notification/NotificationSettingsProvider.dart';
import 'package:adde/pages/notification/notificatio_history_page.dart';
import 'package:adde/pages/notification/notification_service.dart';
import 'package:adde/pages/weekly_tips/weeklytip_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adde/auth/login_page.dart';
import 'package:adde/pages/profile/profile_page.dart';
import 'package:adde/pages/profile/locale_provider.dart';
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  bool _hasUnreadNotifications = false;
  int _pregnancyWeeks = 0;
  int _pregnancyDays = 0;
  String? _profileImageBase64;
  List<Map<String, dynamic>> _weeklyTips = [];
  bool _hasLoadedWeeklyTips = false;
  bool _hasShownTodaysTip = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _updatePregnancyProgress();
    _loadProfileImage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkUnreadNotifications();
        _scheduleHealthTips();
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && !_hasShownTodaysTip) {
            _checkAndShowTodaysTip();
            _hasShownTodaysTip = true;
          }
        });
      }
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });

    // Schedule periodic pregnancy progress updates
    Future.delayed(const Duration(days: 1), () {
      if (mounted) _updatePregnancyProgress();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeProvider = Provider.of<LocaleProvider>(context);
    if (localeProvider.locale != Localizations.localeOf(context)) {
      _hasLoadedWeeklyTips = false;
    }
    if (!_hasLoadedWeeklyTips) {
      _hasLoadedWeeklyTips = true;
      _loadWeeklyTips();
    }
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
    try {
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      final locale = AppLocalizations.of(context)!.localeName;
      final history = await notificationService.getNotificationHistory(
        widget.user_id,
        locale,
      );
      setState(() {
        _hasUnreadNotifications = history.any((n) => n['seen'] == false);
      });
    } catch (e) {
      print('Error checking unread notifications: $e');
    }
  }

  Future<void> _scheduleHealthTips() async {
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    await notificationService.scheduleDailyHealthTips(
      widget.pregnancyStartDate,
      widget.user_id,
      locale,
      l10n.notificationChannelName,
      l10n.notificationChannelDescription,
    );
  }

  Future<void> _checkAndShowTodaysTip() async {
    try {
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      final notificationSettingsProvider =
          Provider.of<NotificationSettingsProvider>(context, listen: false);
      final l10n = AppLocalizations.of(context)!;
      final locale = l10n.localeName;

      await notificationService.checkAndShowTodaysTip(
        widget.user_id,
        widget.pregnancyStartDate,
        locale,
        l10n.notificationChannelName,
        l10n.notificationChannelDescription,
        showPopup: notificationSettingsProvider.showPopupNotifications,
      );
    } catch (e) {
      print('Error showing today\'s tip: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorLoadingEntries(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: l10n.retryButton,
              onPressed: _checkAndShowTodaysTip,
              textColor: Theme.of(context).colorScheme.onError,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadWeeklyTips() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final response = await Supabase.instance.client
          .from('weekly_tips')
          .select('id, week, title_en, title_am, image')
          .order('week', ascending: true)
          .limit(3);

      setState(() {
        _weeklyTips =
            List<Map<String, dynamic>>.from(response).map((tip) {
              return {
                'id': tip['id'],
                'week': tip['week'],
                'title_en': tip['title_en'] ?? l10n.noTitle,
                'title_am': tip['title_am'] ?? l10n.noTitle,
                'image': tip['image'],
              };
            }).toList();
      });
    } catch (e) {
      print('Error loading weekly tips: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorLoadingEntries(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: l10n.retryButton,
            onPressed: _loadWeeklyTips,
            textColor: Theme.of(context).colorScheme.onError,
          ),
        ),
      );
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
          physics: const BouncingScrollPhysics(), // Smoother scrolling
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
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  _buildFeaturesSection(
                    context,
                  ).map((widget) => widget).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppBar(
      backgroundColor:
          Theme.of(context).brightness == Brightness.light
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onPrimary,
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
              backgroundColor: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
              backgroundImage:
                  _profileImageBase64 != null
                      ? MemoryImage(base64Decode(_profileImageBase64!))
                      : const AssetImage('assets/user.png') as ImageProvider,
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutQuad),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.greeting(widget.fullName),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color:
                    Theme.of(context).brightness == Brightness.light
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.primary,
                shadows: [
                  Shadow(
                    color: Theme.of(context).colorScheme.shadow,
                    blurRadius: 4,
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ).animate().fadeIn(duration: 600.ms, curve: Curves.easeOut),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications,
                color:
                    Theme.of(context).brightness == Brightness.light
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => NotificationHistoryPage(userId: widget.user_id),
                  ),
                );
                await _checkUnreadNotifications();
              },
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutQuad),
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
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              ),
          ],
        ),
        IconButton(
          icon: Icon(
            Icons.logout,
            color:
                Theme.of(context).brightness == Brightness.light
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          onPressed: () async {
            try {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              }
            } catch (e) {
              print('Error during logout: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.errorLoggingOut(e.toString())),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    action: SnackBarAction(
                      label: l10n.retryButton,
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        }
                      },
                      textColor: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                );
              }
            }
          },
        ).animate().scale(duration: 500.ms, curve: Curves.easeOutQuad),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              ),
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          elevation: 6,
          child: Icon(
            Icons.chat,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
        )
        .animate()
        .scale(duration: 600.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 600.ms);
  }

  BoxDecoration _buildBackgroundGradient() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          Theme.of(context).colorScheme.surface,
        ],
      ),
    );
  }

  Widget _buildPregnancyJourneySection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).brightness == Brightness.light
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onPrimary,
            Theme.of(context).brightness == Brightness.light
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.onSecondary,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            l10n.pregnancyJourney,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color:
                  Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ).animate().fadeIn(duration: 800.ms, curve: Curves.easeOutQuad),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCounterBox(_pregnancyWeeks, l10n.weeksLabel),
              const SizedBox(width: 20),
              CircleAvatar(
                radius: 70,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.9),
                child: ClipOval(
                  child: Image.asset(
                    "assets/embryo.gif",
                    fit: BoxFit.cover,
                    width: 120,
                    height: 120,
                  ),
                ),
              ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
              const SizedBox(width: 20),
              _buildCounterBox(_pregnancyDays, l10n.daysLabel),
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
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (_pregnancyWeeks / 40).clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onPrimary,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ).animate().slideX(
                    duration: 1000.ms,
                    curve: Curves.easeInOut,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms);
  }

  Widget _buildWeeklyTipsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.weeklyTips,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ).animate().fadeIn(duration: 600.ms, curve: Curves.easeOutQuad),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child:
              _weeklyTips.isEmpty
                  ? Center(
                    child: Text(
                      l10n.noTipsYet,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _weeklyTips.length,
                    itemBuilder: (context, index) {
                      final tip = _weeklyTips[index];
                      final title =
                          currentLocale == 'am'
                              ? tip['title_am']
                              : tip['title_en'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => WeeklyTipPage(
                                      initialTip: tip,
                                      pregnancyStartDate:
                                          widget.pregnancyStartDate,
                                    ),
                              ),
                            );
                          },
                          child: Container(
                            width: 200,
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.shadow.withValues(alpha: 0.2),
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
                                            frameBuilder: (
                                              context,
                                              child,
                                              frame,
                                              wasSynchronouslyLoaded,
                                            ) {
                                              return child.animate().fadeIn(
                                                duration: 400.ms,
                                                delay: (index * 200).ms,
                                              );
                                            },
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Container(
                                                  height: 100,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.1),
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 40,
                                                    color:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                  ),
                                                ),
                                          )
                                          : Container(
                                            height: 100,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.1),
                                            child: Icon(
                                              Icons.image,
                                              size: 40,
                                              color:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
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
                                        l10n.weekLabel(tip['week']),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        title ?? l10n.noTitle,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
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
                        ).animate().slideX(
                          begin: 0.2,
                          end: 0,
                          duration: 600.ms,
                          delay: (index * 200).ms,
                          curve: Curves.easeOutQuad,
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  List<Widget> _buildFeaturesSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final features = [
      {
        "icon": "assets/bmi.png",
        "name": l10n.featureHealthMetrics,
        "description": l10n.featureHealthMetricsDescription,
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
        "name": l10n.featureJournal,
        "description": l10n.featureJournalDescription,
        "navigation":
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JournalScreen()),
            ),
      },
      {
        "icon": "assets/label.png",
        "name": l10n.featureNameSuggestion,
        "description": l10n.featureNameSuggestionDescription,
        "navigation":
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NameSuggestionPage()),
            ),
      },
    ];

    return features.asMap().entries.map((entry) {
      final index = entry.key;
      final feature = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildFeatureCard(feature).animate().slideY(
          begin: 0.2,
          end: 0,
          duration: 400.ms,
          delay: (index * 150).ms,
          curve: Curves.easeOutQuad,
        ),
      );
    }).toList();
  }

  Widget _buildCounterBox(int value, String label) {
    return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                "$value",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color:
                      Theme.of(context).brightness == Brightness.light
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color:
                    Theme.of(context).brightness == Brightness.light
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 600.ms, curve: Curves.easeOutQuad)
        .scale(duration: 600.ms, curve: Curves.easeOutBack);
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  feature["icon"],
                  width: 40,
                  height: 40,
                  color: Theme.of(context).colorScheme.primary,
                ).animate().fadeIn(duration: 500.ms, curve: Curves.easeOut),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature["name"],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature["description"],
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
