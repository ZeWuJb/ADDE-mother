import 'package:flutter/material.dart';
import 'booking_page.dart';

class DoctorDetailsPage extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const DoctorDetailsPage({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(doctor['full_name']),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'id: ${doctor['id']}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Name: ${doctor['full_name']}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Email: ${doctor['email']}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'photo: ${doctor['profile_url']}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Specialty: ${doctor['speciality']}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'type: ${doctor['type']}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'payment: ${doctor['payment_required_amount']}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'consultation amount: ${doctor['consultations_given']}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'user_id: ${doctor['user_id']}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'Description: ${doctor['description'] ?? 'Not provided'}',
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingPage(doctorId: doctor['id']),
                  ),
                );
              },
              child: const Text('Book Appointment'),
            ),
          ],
        ),
      ),
    );
  }
}