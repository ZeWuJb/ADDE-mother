import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'appointments_page.dart';
import 'tele-conseltation_page.dart';

class BookingPage extends StatefulWidget {
  final String doctorId;

  const BookingPage({super.key, required this.doctorId});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final supabase = Supabase.instance.client;

  DateTime? _selectedDay;
  List<DateTime> _availableTimes = [];
  int? _currentTimeIndex;
  bool _timeSelected = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    // Check connection status
    _checkConnectionStatus();
  }

  Future<void> _checkConnectionStatus() async {
    try {
      // Simple query to check if Supabase is connected
      await supabase.from('doctors').select('id').limit(1);
      if (mounted) {
        setState(() {
          _isConnected = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
        });
      }
    }
  }

  Future<void> _fetchAvailableTimes(DateTime selectedDate) async {
    final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      final response =
          await supabase
              .from('doctor_availability')
              .select('availability')
              .eq('doctor_id', widget.doctorId)
              .maybeSingle();

      if (!mounted) return;

      if (response == null || response['availability'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No availability found for this doctor.'),
          ),
        );
        return;
      }

      final availability = response['availability'];
      final dateEntry = (availability['dates'] as List?)?.firstWhere(
        (entry) => entry['date'] == dateString,
        orElse: () => null,
      );

      if (dateEntry != null) {
        setState(() {
          _availableTimes =
              (dateEntry['slots'] as List)
                  .map<DateTime>((slot) => DateFormat('HH:mm').parse(slot))
                  .toList();
        });
      } else {
        setState(() {
          _availableTimes = [];
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching availability: $error')),
        );
      }
    }
  }

  // Check if mother record exists and create if needed
  Future<bool> _ensureMotherRecordExists() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return false;
    }

    try {
      // Check if mother record exists - IMPORTANT: use user_id, not id
      final motherRecord =
          await supabase
              .from('mothers')
              .select()
              .eq('user_id', userId)
              .maybeSingle();

      if (motherRecord != null) {
        return true;
      }

      // Get user details from auth
      final user = supabase.auth.currentUser!;
      final email = user.email ?? '';

      // Create mother record with user_id as the primary key
      await supabase.from('mothers').insert({
        'user_id': userId, // This is the primary key
        'full_name':
            email.split(
              '@',
            )[0], // Use part of email as name if no name available
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
        });
      }
      return false;
    }
  }

  Future<void> sendRequest() async {
    if (_selectedDay == null || _currentTimeIndex == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date and time')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First ensure mother record exists
      final motherRecordExists = await _ensureMotherRecordExists();
      if (!motherRecordExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not create user profile. Please try again.'),
            ),
          );
        }
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
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Calculate expires_at (20 minutes from now)
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: 20));

      // Create temporary appointment request
      final result =
          await supabase
              .from('temporary_appointments')
              .insert({
                'doctor_id': widget.doctorId,
                'mother_id': userId,
                'requested_time': requestedDateTime.toIso8601String(),
                'expires_at': expiresAt.toIso8601String(),
                'status': 'pending',
              })
              .select()
              .single();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Appointment request sent! Waiting for doctor approval.',
            ),
          ),
        );

        // Navigate to appointments page - pass the doctorId
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SocketTestPage(doctorId: widget.doctorId),
          ),
        );
      }

      setState(() {
        _selectedDay = null;
        _timeSelected = false;
        _currentTimeIndex = null;
        _availableTimes = [];
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending request: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Error message if any
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.all(8),
                      color: Colors.red[50],
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Connection status indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: _isConnected ? Colors.green[50] : Colors.orange[50],
                    child: Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.wifi : Icons.wifi_off,
                          color: _isConnected ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isConnected
                              ? 'Connected to server'
                              : 'Not connected - appointments may not be sent',
                          style: TextStyle(
                            color: _isConnected ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

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
                    const Text(
                      'Available Time Slots:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Wrap(
                      children: List.generate(_availableTimes.length, (index) {
                        final time = DateFormat(
                          'HH:mm',
                        ).format(_availableTimes[index]);
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
                    onPressed:
                        _selectedDay != null && _timeSelected
                            ? sendRequest
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                    child: const Text('Request Appointment'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
    );
  }
}
