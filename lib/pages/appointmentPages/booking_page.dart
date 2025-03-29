import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'serverioconfig.dart';
import 'appointments_page.dart';

class BookingPage extends StatefulWidget {
  final String doctorId;

  const BookingPage({super.key, required this.doctorId});

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final supabase = Supabase.instance.client;
  final SocketService _socketService = SocketService();

  DateTime? _selectedDay;
  List<DateTime> _availableTimes = [];
  int? _currentTimeIndex;
  bool _timeSelected = false;
  bool _isLoading = false;
  String? _requestStatus;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Log the doctor ID for debugging
    print('BookingPage initialized with doctor_id: ${widget.doctorId}');

    // Initialize socket connection after widget is fully built
    Future.microtask(() {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        _socketService.connect(userId);

        // Set up callbacks for appointment responses
        _socketService.onAppointmentAccepted = (data) {
          if (!mounted) return;

          setState(() {
            _requestStatus = 'accepted';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Your appointment has been accepted!'),
              backgroundColor: Colors.green,
            ),
          );
        };

        _socketService.onAppointmentDeclined = (data) {
          if (!mounted) return;

          setState(() {
            _requestStatus = 'declined';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Your appointment was declined. Please try another time.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        };
        
        // Add error handler
        _socketService.onError = (error) {
          if (!mounted) return;
          
          setState(() {
            _errorMessage = error;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection error: $error'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        };
        
        // Add connection status handler
        _socketService.onConnectionChange = (connected) {
          if (!mounted) return;
          
          if (connected) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Connected to server'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        };
      }
    });
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  Future<void> _fetchAvailableTimes(DateTime selectedDate) async {
    final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);
    print(
      'Fetching availability for doctor_id: ${widget.doctorId} on date: $dateString',
    );

    final response =
        await supabase
            .from('doctor_availability')
            .select('availability')
            .eq('doctor_id', widget.doctorId)
            .maybeSingle();

    print('Response from Supabase: ${supabase.auth.currentUser?.id}');
    if (response == null || response['availability'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No availability found for this doctor.')),
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
      final motherRecord =
          await supabase
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
        'full_name':
            email.split(
              '@',
            )[0], // Use part of email as name if no name available
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
      _errorMessage = null;
    });

    try {
      // First ensure mother record exists
      final motherRecordExists = await _ensureMotherRecordExists();
      if (!motherRecordExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not create user profile. Please try again.'),
          ),
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
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get user name from Supabase
      final userData =
          await supabase
              .from('mothers')
              .select('full_name')
              .eq('user_id', userId)
              .single();

      final motherName = userData['full_name'] ?? 'Unknown Patient';

      // Check if socket is connected
      if (!_socketService.isConnected) {
        // Try to reconnect
        _socketService.connect(userId);
        
        // Show a message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trying to connect to server...'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Wait a moment for connection
        await Future.delayed(Duration(seconds: 2));
        
        // Check again
        if (!_socketService.isConnected) {
          throw Exception('Cannot connect to server. Please try again later.');
        }
      }

      // Send appointment request via socket
      _socketService.requestAppointment(
        doctorId: widget.doctorId,
        motherId: userId,
        motherName: motherName,
        requestedTime: requestedDateTime.toIso8601String(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Appointment request sent! Waiting for doctor approval.',
          ),
        ),
      );

      // Navigate to waiting page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SocketTestPage(doctorId: widget.doctorId),
        ),
      );

      setState(() {
        _selectedDay = null;
        _timeSelected = false;
        _currentTimeIndex = null;
        _availableTimes = [];
      });
    } catch (error) {
      print('Error sending appointment request: $error');
      setState(() {
        _errorMessage = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending request: ${error.toString()}')),
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
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Error message if any
                  if (_errorMessage != null)
                    Container(
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.all(8),
                      color: Colors.red[50],
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                  // Connection status indicator
                  Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    color: _socketService.isConnected ? Colors.green[50] : Colors.orange[50],
                    child: Row(
                      children: [
                        Icon(
                          _socketService.isConnected ? Icons.wifi : Icons.wifi_off,
                          color: _socketService.isConnected ? Colors.green : Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _socketService.isConnected 
                              ? 'Connected to server' 
                              : 'Not connected - appointments may not be sent',
                          style: TextStyle(
                            color: _socketService.isConnected ? Colors.green : Colors.orange,
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

