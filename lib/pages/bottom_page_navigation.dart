import 'package:adde/l10n/arb/app_localizations.dart'; // Import AppLocalizations
import 'package:adde/pages/appointmentPages/doctors_page.dart';
import 'package:adde/pages/community/community_screen.dart';
import 'package:flutter/material.dart';
import 'package:adde/pages/home_screen.dart';
import 'package:adde/pages/education/Education_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class _BottomPageNavigationState extends State<BottomPageNavigation> {
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

      print("Fetching data for email: ${widget.email}"); // Debug log
      final response =
          await Supabase.instance.client
              .from('mothers')
              .select()
              .eq('email', widget.email!)
              .limit(1)
              .single();

      print("Supabase response: $response"); // Debug log

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
      print("Error fetching mother info: $error"); // Debug log
      showSnackBar(
        AppLocalizations.of(context)!.errorLoadingData(error.toString()),
      );
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onError),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Access AppLocalizations

    List<Widget> pages = [
      isLoading
          ? Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
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
            child: Text(
              l10n.failedToLoadUserData, // Localized error message
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
          ),
      const CommunityScreen(),
      const EducationPage(),
      const DoctorsPage(), // Localized placeholder
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // Gradient Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    Theme.of(context).colorScheme.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Main Content
          pages[_selectedIndex],
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: Theme.of(context).bottomNavigationBarTheme.elevation ?? 8,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        selectedLabelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
        unselectedLabelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l10n.bottomNavHome, // Localized label
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            activeIcon: const Icon(Icons.people),
            label: l10n.bottomNavCommunity, // Localized label
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_book_outlined),
            activeIcon: const Icon(Icons.menu_book),
            label: l10n.bottomNavEducation, // Localized label
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.video_call_outlined),
            activeIcon: const Icon(Icons.video_call),
            label: l10n.bottomNavConsult, // Localized label
          ),
        ],
      ),
    );
  }
}
