import 'package:flutter/material.dart';

import 'appointments_page.dart';
import 'booking_page.dart';
import 'doctors_page.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mother App'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Navigation Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DoctorsPage(),
                      ),
                    );
                  },
                  child: const Text('Doctors'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BookingPage(doctorId: ''),
                      ),
                    );
                  },
                  child: const Text('Booking'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SocketTestPage(doctorId: ''),
                      ),
                    );
                  },
                  child: const Text('Appointments'),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Welcome to the Mother App!',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
