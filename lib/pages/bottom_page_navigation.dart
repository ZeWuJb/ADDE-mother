import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/appointmentPages/doctors_page.dart';
import 'package:adde/pages/community/community_screen.dart';
import 'package:adde/pages/education/Education_page.dart';
import 'package:adde/pages/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class BottomPageNavigation extends StatefulWidget {
  final String? email;
  final String user_id;

  const BottomPageNavigation({
    super.key,
    required this.email,
    required this.user_id,
  });

  @override
  State<BottomPageNavigation> createState() => _BottomPageNavigationState();
}

class _BottomPageNavigationState extends State<BottomPageNavigation>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  DateTime? pregnancyStartDate;
  String? fullName;
  String? gender;
  int? age;
  double? weight;
  double? height;
  String? weightUnit;
  String? bloodPressure;
  List<String>? healthConditions;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMotherInfo();
  }

  Future<void> fetchMotherInfo() async {
    try {
      if (widget.email == null) {
        throw Exception("Email is null, cannot fetch mother info.");
      }

      print("Fetching data for email: ${widget.email}");
      final response =
          await Supabase.instance.client
              .from('mothers')
              .select()
              .eq('email', widget.email!)
              .limit(1)
              .single();

      print("Supabase response: $response");

      setState(() {
        fullName = response['full_name'] as String? ?? 'Unknown';
        gender = response['gender']?.toString() ?? 'N/A';
        age = response['age'] as int? ?? 0;
        weight =
            (response['weight'] is double)
                ? response['weight']
                : double.tryParse(response['weight']?.toString() ?? '0') ?? 0.0;
        height =
            (response['height'] is double)
                ? response['height']
                : double.tryParse(response['height']?.toString() ?? '0') ?? 0.0;
        weightUnit = response['weight_unit']?.toString() ?? 'kg';
        bloodPressure = response['blood_pressure']?.toString() ?? 'N/A';
        healthConditions =
            (response['health_conditions'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        pregnancyStartDate =
            DateTime.tryParse(
              response['pregnancy_start_date']?.toString() ?? '',
            ) ??
            DateTime.now();
        isLoading = false;
      });
    } catch (error) {
      print("Error fetching mother info: $error");
      setState(() {
        isLoading = false;
      });
      showSnackBar(
        AppLocalizations.of(context)!.errorLoadingData(error.toString()),
        retry: () => fetchMotherInfo(),
      );
    }
  }

  void showSnackBar(String message, {VoidCallback? retry}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
            content: Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action:
                retry != null
                    ? SnackBarAction(
                      label: AppLocalizations.of(context)!.retryButton,
                      onPressed: retry,
                      textColor: Theme.of(context).colorScheme.onError,
                    )
                    : null,
          ).animate().fadeIn(duration: 200.ms)
          as SnackBar,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final pages = [
      isLoading
          ? Center(
            child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                )
                .animate()
                .fadeIn(duration: 250.ms)
                .scale(curve: Curves.easeOutQuad),
          )
          : (fullName != null &&
              weight != null &&
              weightUnit != null &&
              height != null &&
              pregnancyStartDate != null)
          ? HomeScreen(
            user_id: widget.user_id,
            fullName: fullName!,
            weight: weight!,
            weightUnit: weightUnit!,
            height: height!,
            pregnancyStartDate: pregnancyStartDate!,
          )
          : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.failedToLoadUserData,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOut),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: fetchMotherInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(l10n.retryButton),
                ).animate().scale(duration: 300.ms, curve: Curves.easeOutQuad),
              ],
            ),
          ),
      const CommunityScreen(),
      const EducationPage(),
      const DoctorsPage(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                    Theme.of(context).colorScheme.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder:
                (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
            child: IndexedStack(
              key: ValueKey<int>(_selectedIndex),
              index: _selectedIndex,
              children: pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withValues(alpha: 0.1),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[800]!,
              hoverColor: Colors.grey[700]!,
              haptic: true,
              tabBorderRadius: 15,
              tabActiveBorder: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 1,
              ),
              tabBorder: Border.all(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                width: 1,
              ),
              tabShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
              curve: Curves.easeOutExpo,
              duration: const Duration(milliseconds: 900),
              gap: 8,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              activeColor: Theme.of(context).colorScheme.primary,
              iconSize: 24,
              tabBackgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
              tabs: [
                GButton(
                  icon: _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
                  iconActiveColor:
                      _selectedIndex == 0
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                  textColor:
                      _selectedIndex == 0
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                  backgroundColor:
                      _selectedIndex == 0
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onPrimary,
                  text: l10n.bottomNavHome,
                ),
                GButton(
                  icon:
                      _selectedIndex == 1 ? Icons.people : Icons.people_outline,
                  iconActiveColor:
                      _selectedIndex == 1
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                  textColor:
                      _selectedIndex == 1
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                  backgroundColor:
                      _selectedIndex == 1
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onPrimary,
                  text: l10n.bottomNavCommunity,
                ),
                GButton(
                  icon:
                      _selectedIndex == 2
                          ? Icons.menu_book
                          : Icons.menu_book_outlined,
                  iconActiveColor:
                      _selectedIndex == 2
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                  textColor:
                      _selectedIndex == 2
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                  backgroundColor:
                      _selectedIndex == 2
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onPrimary,
                  text: l10n.bottomNavEducation,
                ),
                GButton(
                  icon:
                      _selectedIndex == 3
                          ? Icons.video_call
                          : Icons.video_call_outlined,
                  iconActiveColor:
                      _selectedIndex == 3
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                  textColor:
                      _selectedIndex == 3
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                  backgroundColor:
                      _selectedIndex == 3
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onPrimary,
                  text: l10n.bottomNavConsult,
                ),
              ],
            ),
          ),
        ),
      ).animate().slideY(
        begin: 0.1,
        end: 0,
        duration: 300.ms,
        curve: Curves.easeOutQuad,
      ),
    );
  }
}
