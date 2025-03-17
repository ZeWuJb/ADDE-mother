import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'booking_page.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> appointments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    try {
      final response = await supabase
          .from('appointments')
          .select('*')
          .eq('user_id', supabase.auth.currentUser!.id);
      setState(() {
        appointments = response;
        isLoading = false;
      });
    } catch (error) {
      print('Error fetching appointments: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          final status = appointment['status'];

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('Doctor: ${appointment['doctor_name']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${appointment['date']}'),
                  Text('Time: ${appointment['time']}'),
                  Text('Status: $status'),
                ],
              ),
              trailing: status == 'accepted'
                  ? ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentPage(appointmentId: appointment['id']),
                    ),
                  );
                },
                child: const Text('Pay'),
              )
                  : status == 'declined'
                  ? ElevatedButton(
                onPressed: () {
                  setState(() {
                    appointments.removeAt(index);
                  });
                },
                child: const Text('Dismiss'),
              )
                  : null,
            ),
          );
        },
      ),
    );
  }
}