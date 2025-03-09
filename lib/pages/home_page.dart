import 'package:adde/component/tool_card.dart';
import 'package:adde/pages/Community_page.dart';
import 'package:adde/pages/Education_page.dart';
import 'package:adde/pages/calander_page.dart';
import 'package:adde/pages/calculator_page.dart';
import 'package:adde/pages/journal_page.dart';
import 'package:adde/pages/name_suggation_page.dart';
import 'package:adde/pages/notification_page.dart';
import 'package:adde/pages/setting_page.dart';
import 'package:adde/pages/tele-conseltation_page.dart';
import 'package:flutter/material.dart';
import 'package:adde/pages/diary_form_page.dart';
import 'package:adde/pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  final email;
  const HomePage({super.key, required this.email});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    int? pregnancyWeeks;
    String? pregnancyDays;

    Future<void> fetchPregnancyData() async {
      try {
        final response = await Supabase.instance.client
            .from('mothers')
            .select('pregnancy_weeks, pregnancy_days')
            .eq('email', widget.email)
            .limit(1);

        if (response.isNotEmpty) {
          setState(() {
            pregnancyWeeks = response[0]['pregnancy_weeks'];
            pregnancyDays = response[0]['pregnancy_days'];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to load pregnancy data.")),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("An error occurred: $error")));
      }
    }

    List box = [
      {
        "icon": "assets/calendar.png",
        "name": "Calender",
        "description": "Calender To Appoint Health Profftional",
        "navigation": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CalendarPage()),
          );
        },
      },
      {
        "icon": "assets/bmi.png",
        "name": "Calculate",
        "description": "Health Matrics Calculator",
        "navigation": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CalculatorPage()),
          );
        },
      },
      {
        "icon": "assets/diary.png",
        "name": "Journal",
        "description": "Jurnal Yor Pregnancy Time",
        "navigation": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => JournalPage()),
          );
        },
      },
      {
        "icon": "assets/label.png",
        "name": "Name Sugation",
        "description": "Name Suggetion and Meaning For Child",
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
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        actionsPadding: EdgeInsets.only(right: 15),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => NotificationPage()),
                );
              },
              child: Icon(Icons.notification_add),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => LoginPage()));
            },
            child: Icon(Icons.logout),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => DiaryFormPage()));
        },
        child: Center(child: Image.asset("assets/chatbot.png")),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    Text(
                      "Adde",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Text(
                              pregnancyWeeks.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 24,
                              ),
                            ),
                            Text(
                              "Weeks",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),

                        CircleAvatar(
                          radius: 70,
                          child: Image.asset("assets/embryo.gif"),
                        ),
                        Column(
                          children: [
                            Text(
                              pregnancyDays.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 24,
                              ),
                            ),
                            Text(
                              "Days",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    TextButton(
                      style: ButtonStyle(),
                      onPressed: () {},
                      child: Text(
                        "More >>>",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onTertiary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: double.infinity,
                height: 70,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Center(child: Text("Health Tips")),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Health Tools",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ),

            // Container(
            //   child: Row(
            //     children: [
            //       Column(
            //         children: [
            //           Text("Health Profetional Appointment Calender"),
            //           TextButton(onPressed: () {}, child: Text("Calendar Now")),
            //         ],
            //       ),
            //       Image.asset(box[index]["icon"]),
            //     ],
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 250, // Set an explicit height for GridView
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    return ToolCard(
                      iconPath: box[index]["icon"],
                      name: box[index]["name"],
                      description: box[index]["description"],
                      onTap: box[index]["navigation"],
                    );
                  },
                ),
              ),
            ),

            /*
              Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 250, // Set an explicit height for GridView
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    return ToolCard(
                      iconPath: box[index]["icon"],
                      name: box[index]["name"],
                      onTap: box[index]["navigation"],
                    );
                  },
                ),
              ),
            ),
            
             */
          ],
        ),
      ),

      drawer: Drawer(
        child: Container(
          color: Theme.of(context).colorScheme.surfaceDim,
          child: ListView(
            children: [
              DrawerHeader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      child: Image.asset("assets/user.png"),
                    ),
                    Text(widget.email),
                  ],
                ),
              ),

              ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EducationPage()),
                  );
                },
                leading: Image.asset("assets/medical-book.png", width: 25),
                title: Text("Education"),
              ),
              ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CommunityPage()),
                  );
                },
                leading: Image.asset("assets/community.png", width: 25),
                title: Text("Community"),
              ),
              ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeleConseltationPage(),
                    ),
                  );
                },
                leading: Image.asset("assets/video-call.png", width: 25),
                title: Text("Tele Conseltation"),
              ),
              Container(
                color: Theme.of(context).colorScheme.onSurface,
                width: double.infinity,
                height: 1,
              ),
              ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingPage()),
                  );
                },
                leading: Icon(Icons.settings),
                title: Text("Settings"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
