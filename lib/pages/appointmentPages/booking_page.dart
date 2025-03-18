// BookingPage.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'appointments_page.dart';

class BookingPage extends StatefulWidget {
  final String doctorId;

  const BookingPage({Key? key, required this.doctorId}) : super(key: key);

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final supabase = Supabase.instance.client;

  DateTime? _selectedDay;
  List<DateTime> _availableTimes = [];
  int? _currentTimeIndex;
  bool _timeSelected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Log the doctor ID for debugging
    print('BookingPage initialized with doctor_id: ${widget.doctorId}');
  }

  Future<void> _fetchAvailableTimes(DateTime selectedDate) async {
    final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);
    print('Fetching availability for doctor_id: ${widget.doctorId} on date: $dateString');

    final response = await supabase
        .from('doctor_availability')
        .select('availability')
        .eq('doctor_id', widget.doctorId)
        .maybeSingle();

    print('Response from Supabase: ${ supabase.auth.currentUser?.id}');
    if (response == null || response['availability'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No availability found for this doctor.')),
      );
      return;
    }

    final availability = response['availability'];
    final dateEntry = (availability['dates'] as List?)
        ?.firstWhere((entry) => entry['date'] == dateString, orElse: () => null);

    if (dateEntry != null) {
      setState(() {
        _availableTimes = (dateEntry['slots'] as List)
            .map<DateTime>((slot) => DateFormat('HH:mm').parse(slot))
            .toList();
      });
    } else {
      setState(() {
        _availableTimes = [];
      });
    }
  }

  // Check if mother record exists and create if needed
  Future<bool> _ensureMotherRecordExists() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      print('No authenticated user found');
      return false;
    }

    try {
      // Check if mother record exists
      final motherRecord = await supabase
          .from('mothers')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (motherRecord != null) {
        print('Mother record exists with ID: $userId');
        return true;
      }

      // Get user details from auth
      final user = supabase.auth.currentUser!;
      final email = user.email ?? '';

      // Create mother record without doctor_id
      print('Creating mother record for user: $userId');
      await supabase.from('mothers').insert({
        'id': userId,
        'full_name': email.split('@')[0], // Use part of email as name if no name available
        'email': email,
        // Remove doctor_id field as it's not part of the mothers table
        'created_at': DateTime.now().toIso8601String(),
      });

      print('Mother record created successfully');
      return true;
    } catch (error) {
      print('Error ensuring mother record exists: $error');
      return false;
    }
  }
  Future<void> sendRequest() async {
    if (_selectedDay == null || _currentTimeIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // First ensure mother record exists
      final motherRecordExists = await _ensureMotherRecordExists();
      if (!motherRecordExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create user profile. Please try again.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final selectedTime = _availableTimes[_currentTimeIndex!];

      // Create a proper DateTime object for the requested time
      final requestedDateTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      final userId = supabase.auth.currentUser?.id;
      print('Creating appointment with doctor_id: ${widget.doctorId}');
      print('Requested time: ${requestedDateTime.toIso8601String()}');
      print('Current user ID: $userId');

      // Create appointment data matching database schema
      final appointmentData = {
        'doctor_id': widget.doctorId,
        'mother_id': userId,
        // Convert DateTime to ISO8601 string for proper serialization
        'requested_time': requestedDateTime.toIso8601String(),
        'status': 'pending',
        'payment_status': 'unpaid',
        'video_conference_link': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase.from('appointments').insert([appointmentData]);

      print('Appointment created successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment booked successfully!')),
      );

      // Navigate to SocketTestPage after successful booking
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SocketTestPage(doctorId: widget.doctorId)),
      );

      setState(() {
        _selectedDay = null;
        _timeSelected = false;
        _currentTimeIndex = null;
        _availableTimes = [];
      });
    } catch (error) {
      print('Error creating appointment: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking appointment: ${error.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CalendarDatePicker(
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              onDateChanged: (date) {
                setState(() {
                  _selectedDay = date;
                  _availableTimes = [];
                  _currentTimeIndex = null;
                  _timeSelected = false;
                });
                _fetchAvailableTimes(date);
              },
            ),
          ),
          if (_selectedDay != null) ...[
            const Text('Available Time Slots:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Wrap(
              children: List.generate(_availableTimes.length, (index) {
                final time = DateFormat('HH:mm').format(_availableTimes[index]);
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ChoiceChip(
                    label: Text(time),
                    selected: _currentTimeIndex == index,
                    onSelected: (selected) {
                      setState(() {
                        _currentTimeIndex = selected ? index : null;
                        _timeSelected = selected;
                      });
                    },
                  ),
                );
              }),
            ),
          ],
          const Spacer(),
          ElevatedButton(
            onPressed: _selectedDay != null && _timeSelected ? sendRequest : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Make Appointment'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}