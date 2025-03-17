import 'package:flutter/material.dart';
import 'package:adde/auth/login_page.dart';
import 'package:adde/pages/appointmentPages/calander_page.dart';
import 'package:adde/pages/health_matrics_page.dart';
import 'package:adde/pages/journal_page.dart';
import 'package:adde/pages/name_suggation_page.dart';
import 'package:adde/pages/notification_page.dart';
import 'package:adde/pages/profile/profile_page.dart';

class HomeScreen extends StatelessWidget {
  final ScrollController _scrollController = ScrollController();
  final String user_id;
  final String fullName;
  final int pregnancyWeeks;
  final int pregnancyDays;
  final double weight;
  final String weightUnit;
  final double height;
  final DateTime pregnancyStartDate;

  HomeScreen({
    super.key,
    required this.fullName,
    required this.pregnancyWeeks,
    required this.pregnancyDays,
    required this.weight,
    required this.weightUnit,
    required this.height,
    required this.pregnancyStartDate,
    required this.user_id,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        pregnancyWeeks * 54.0, // Adjust scroll position
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });

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
              builder: (context) => HealthMetricsPage(userId: user_id),
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
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 30, color: Colors.pink),
              ),
            ),
            SizedBox(width: 8),
            Text(
              "Welcome, ${fullName.toUpperCase()}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.pink),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.pink),
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
        child: Icon(Icons.chat, color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade100, Colors.purple.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
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
                    Text(
                      "Pregnancy Tracker",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              "$pregnancyWeeks",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "Weeks",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Image.asset("assets/embryo.gif"),
                        ),
                        Column(
                          children: [
                            Text(
                              "$pregnancyDays",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text("Days", style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: LinearProgressIndicator(
                        value: pregnancyWeeks / 40,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // Feature Boxes Section
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
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item["name"],
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          item["description"],
                                          style: TextStyle(fontSize: 14),
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
