// SocketTestPage.dart

import 'package:adde/pages/appointmentPages/serverioconfig.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SocketTestPage extends StatefulWidget {
  final String doctorId;

  const SocketTestPage({Key? key, required this.doctorId}) : super(key: key);

  @override
  _SocketTestPageState createState() => _SocketTestPageState();
}

class _SocketTestPageState extends State<SocketTestPage> {
  final SocketService _socketService = SocketService();
  final supabase = Supabase.instance.client;
  List<String> notifications = [];
  List<Map<String, dynamic>> pendingAppointments = [];
  String connectionStatus = 'Disconnected';
  String errorMessage = '';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('SocketTestPage initialized with doctor_id: ${widget.doctorId}');
    _connectSocket();
  }

  void _connectSocket() {
    // Validate doctor_id before connecting
    if (widget.doctorId.isEmpty) {
      setState(() {
        errorMessage = 'Invalid doctor ID';
        connectionStatus = 'Connection Error';
      });
      return;
    }

    _socketService.connect(widget.doctorId);

    _socketService.socket.on('connect', (_) {
      print('Socket connected for doctor_id: ${widget.doctorId}');
      setState(() {
        connectionStatus = 'Connected';
        errorMessage = '';
      });
    });

    _socketService.socket.on('disconnect', (_) {
      print('Socket disconnected');
      setState(() {
        connectionStatus = 'Disconnected';
      });
    });

    _socketService.socket.on('connect_error', (error) {
      print('Socket connection error: $error');
      setState(() {
        connectionStatus = 'Connection Error';
        errorMessage = error.toString();
      });
    });

    _socketService.socket.on('new_appointment', (data) {
      print('Received new appointment: $data');
      setState(() {
        notifications.add('New appointment request from ${data['mother_name']}');
        pendingAppointments.add(data);
      });
    });

    _socketService.socket.on('appointment_accepted', (data) {
      print('Appointment accepted: $data');
      setState(() {
        notifications.add('Appointment accepted for ${data['mother_name']}');
        pendingAppointments.removeWhere((appointment) => appointment['appointmentId'] == data['appointmentId']);
      });
    });

    _socketService.socket.on('appointment_declined', (data) {
      print('Appointment declined: $data');
      setState(() {
        notifications.add('Appointment declined for ${data['mother_name']}');
        pendingAppointments.removeWhere((appointment) => appointment['appointmentId'] == data['appointmentId']);
      });
    });
  }

  void _sendAppointmentRequest() {
    final String motherName = _nameController.text.trim();
    final String requestedTime = _timeController.text.trim();

    if (motherName.isEmpty || requestedTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Format the date properly for the server
    DateTime now = DateTime.now();
    // Try to parse the time input or use a default format
    DateTime requestedDateTime;
    try {
      // Attempt to parse the time string
      List<String> timeParts = requestedTime.split(':');
      if (timeParts.length >= 2) {
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        requestedDateTime = DateTime(now.year, now.month, now.day, hour, minute);
      } else {
        // Fallback to current time if parsing fails
        requestedDateTime = now;
      }
    } catch (e) {
      // If parsing fails, use current time
      requestedDateTime = now;
    }

    // Get the current user ID or use a test ID
    final userId = supabase.auth.currentUser?.id ?? 'test-mother-id';

    print('Sending appointment request:');
    print('doctor_id: ${widget.doctorId}');
    print('mother_id: $userId');
    print('mother_name: $motherName');
    print('requested_time: ${requestedDateTime.toIso8601String()}');

    _socketService.socket.emit('request_appointment', {
      'doctor_id': widget.doctorId,
      'mother_id': userId,
      'mother_name': motherName,
      'requested_time': requestedDateTime.toIso8601String(),
    });

    _nameController.clear();
    _timeController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Appointment request sent!')),
    );
  }

  @override
  void dispose() {
    _socketService.disconnect();
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Socket.IO Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Status: $connectionStatus',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Doctor ID: ${widget.doctorId}',
              style: TextStyle(fontSize: 16),
            ),
            if (errorMessage.isNotEmpty)
              Text(
                'Error: $errorMessage',
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 20),
            Text(
              'Send Appointment Request:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Patient Name'),
            ),
            TextField(
              controller: _timeController,
              decoration: InputDecoration(labelText: 'Requested Time (e.g., 10:00)'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _sendAppointmentRequest,
              child: Text('Send Request'),
            ),
            SizedBox(height: 20),
            Text(
              'Notifications:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(notifications[index]),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Pending Appointments:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: pendingAppointments.length,
                itemBuilder: (context, index) {
                  final appointment = pendingAppointments[index];
                  return ListTile(
                    title: Text(appointment['mother_name'] ?? 'Unknown'),
                    subtitle: Text('Time: ${appointment['requested_time'] ?? 'Not specified'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () => _socketService.acceptAppointment(appointment['appointmentId']),
                          child: Text('Accept'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _socketService.declineAppointment(appointment['appointmentId']),
                          child: Text('Decline'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}