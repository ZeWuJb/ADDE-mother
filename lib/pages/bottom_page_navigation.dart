import 'package:flutter/material.dart';
import 'package:adde/pages/home_screen.dart';
import 'package:adde/pages/Community_page.dart';
import 'package:adde/pages/education/Education_page.dart';
import 'package:adde/pages/appointmentPages/tele-conseltation_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  final String? email;
  final String user_id;

  const HomePage({super.key, required this.email, required this.user_id});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  late DateTime pregnancyStartDate;
  late int pregnancyWeeks;
  late int pregnancyDays;
  late String fullName;
  late String gender;
  late int age;
  late double weight;
  late double height;
  late String weightUnit;
  late String bloodPressure;
  late List<String> healthConditions;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMotherInfo();
  }

  Future<void> fetchMotherInfo() async {
    try {
      final response =
          await Supabase.instance.client
              .from('mothers')
              .select()
              .eq('email', widget.email as Object)
              .limit(1)
              .single();

      setState(() {
        fullName = response['full_name'];
        gender = response['gender'].toString();
        age = response['age'];
        weight =
            (response['weight'] is double)
                ? response['weight']
                : double.tryParse(response['weight'].toString()) ?? 0.0;

        height =
            (response['height'] is double)
                ? response['height']
                : double.tryParse(response['height'].toString()) ?? 0.0;
        weightUnit = response['weight_unit'].toString();
        bloodPressure = response['blood_pressure'].toString();
        healthConditions = List<String>.from(response['health_conditions']);
        pregnancyStartDate = DateTime.parse(response['pregnancy_start_date']);
        pregnancyWeeks = response['pregnancy_weeks'];
        pregnancyDays = response['pregnancy_days'];
        isLoading = false;
      });
    } catch (error) {
      showSnackBar("An Error occurred: $error");
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
    List<Widget> pages = [
      isLoading
          ? Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          )
          : HomeScreen(
            user_id: widget.user_id,
            fullName: fullName,
            pregnancyWeeks: pregnancyWeeks,
            pregnancyDays: pregnancyDays,
            weight: weight,
            weightUnit: weightUnit,
            height: height,
            pregnancyStartDate: pregnancyStartDate,
          ),
      CommunityPage(),
      EducationPage(),
      TeleConseltationPage(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    Colors.white,
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
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: Colors.white,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: "Community",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: "Education",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_call_outlined),
            activeIcon: Icon(Icons.video_call),
            label: "Consult",
          ),
        ],
      ),
    );
  }
}
