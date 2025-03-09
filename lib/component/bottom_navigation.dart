import 'package:adde/pages/diary_form_page.dart';

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class BottomNavigation extends StatefulWidget {
  final int initialIndex;

  const BottomNavigation({super.key, this.initialIndex = 0});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  // int _current_index = 0;
  // List pages = [HomePage(), EducationPage(), CommunityPage(), CommunityPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: pages[_current_index],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: GNav(
          padding: EdgeInsets.all(8),
          // selectedIndex: _current_index,
          // onTabChange: (int newindex) {
          //   setState(() {
          //     _current_index = newindex;
          //   });
          // },
          activeColor: Theme.of(context).colorScheme.tertiary,
          tabActiveBorder: Border.all(width: 1, style: BorderStyle.solid),
          gap: 8,
          tabs: [
            GButton(icon: Icons.home, text: "Home"),
            GButton(icon: Icons.cast_for_education, text: "Education"),
            GButton(icon: Icons.group, text: "Community"),
            GButton(icon: Icons.group, text: "Community"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => DiaryFormPage()));
        },
        child: Center(child: Image.asset("assets/chatbot.png")),
      ),
    );
  }
}
