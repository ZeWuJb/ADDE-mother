import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'serverioconfig.dart';
import 'tele-conseltation_page.dart'; // Import the video consultation page

class SocketTestPage extends StatefulWidget {
  final String doctorId;

  const SocketTestPage({super.key, required this.doctorId});

  @override
  _SocketTestPageState createState() => _SocketTestPageState();
}

class _SocketTestPageState extends State<SocketTestPage>
    with SingleTickerProviderStateMixin {
  final SocketService _socketService = SocketService();
  final supabase = Supabase.instance.client;

  // Appointment lists by status
  List<Map<String, dynamic>> pendingAppointments = [];
  List<Map<String, dynamic>> acceptedAppointments = [];
  List<Map<String, dynamic>> rejectedAppointments = [];

  String connectionStatus = 'Disconnected';
  String errorMessage = '';
  bool isLoading = true;
  bool isReconnecting = false;

  // Tab controller for the different appointment categories
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    print('SocketTestPage initialized with doctor_id: ${widget.doctorId}');

    // Set up connection status callback
    _socketService.onConnectionChange = (connected) {
      if (!mounted) return;

      setState(() {
        connectionStatus = connected ? 'Connected' : 'Disconnected';
        isReconnecting = !connected;
      });

      // If connection was established, refresh data
      if (connected) {
        _loadAppointments();
      }
    };

    // Set up error callback
    _socketService.onError = (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error;
      });

      // Show a snackbar for connection errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: $error'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              final userId = supabase.auth.currentUser?.id;
              if (userId != null) {
                setState(() {
                  isReconnecting = true;
                });
                _socketService.connect(userId);
              }
            },
          ),
        ),
      );
    };

    // Set up appointment history callback
    _socketService.onAppointmentHistoryReceived = (appointments) {
      if (!mounted) return;

      // Process appointments by status
      List<Map<String, dynamic>> pending = [];
      List<Map<String, dynamic>> accepted = [];
      List<Map<String, dynamic>> declined = [];

      for (var appointment in appointments) {
        String status = appointment['status'] ?? 'pending';

        if (status == 'pending') {
          pending.add(appointment);
        } else if (status == 'accepted') {
          accepted.add(appointment);
        } else if (status == 'declined') {
          declined.add(appointment);
        }
      }

      setState(() {
        pendingAppointments = pending;
        acceptedAppointments = accepted;
        rejectedAppointments = declined;
        isLoading = false;
      });
    };

    // Connect socket and load data after widget is fully initialized
    Future.microtask(() {
      _connectSocket();
      _loadAppointments();

      // Set up a timer to periodically check for new appointments in the database
      Timer.periodic(Duration(seconds: 10), (timer) {
        if (mounted) {
          _fetchAppointmentsFromDatabase();
        }
      });
    });
  }

  Future<void> _loadAppointments() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          errorMessage = 'User not authenticated';
          isLoading = false;
        });
        return;
      }

      // First try to load from local storage
      final storedAppointments =
          await _socketService.loadAppointmentsFromStorage();

      setState(() {
        pendingAppointments = storedAppointments['pending'] ?? [];
        acceptedAppointments = storedAppointments['accepted'] ?? [];
        rejectedAppointments = storedAppointments['declined'] ?? [];
      });

      // Then request fresh data from server
      if (_socketService.isConnected) {
        _socketService.requestAppointmentHistory(userId, 'mother');
      }

      // Also fetch appointments directly from database
      _fetchAppointmentsFromDatabase();
    } catch (error) {
      print('Error loading appointments: $error');
      setState(() {
        errorMessage = 'Failed to load appointments: $error';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch appointments directly from Supabase
  Future<void> _fetchAppointmentsFromDatabase() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // IMPORTANT: Use userId directly since it's the primary key in mothers table
      // No need to query the mothers table first

      // Fetch appointments from the database
      final response = await supabase
          .from('appointments')
          .select('''
            id, 
            requested_time, 
            status, 
            payment_status, 
            video_conference_link,
            created_at,
            updated_at,
            doctors:doctor_id (
              id, 
              full_name, 
              speciality,
              profile_url
            )
          ''')
          .eq('mother_id', userId) // Use userId directly as mother_id
          .order('requested_time', ascending: true);

      if (response == null || response.isEmpty) {
        print('No appointments found in database');
        return;
      }

      print('Fetched ${response.length} appointments from database');

      // Process appointments by status
      List<Map<String, dynamic>> pending = [];
      List<Map<String, dynamic>> accepted = [];
      List<Map<String, dynamic>> declined = [];

      for (var appointment in response) {
        // Convert to Map<String, dynamic> if it's not already
        final appointmentMap = Map<String, dynamic>.from(appointment);

        String status = appointmentMap['status'] ?? 'pending';

        if (status == 'pending') {
          pending.add(appointmentMap);
        } else if (status == 'accepted') {
          accepted.add(appointmentMap);

          // Check if this is a newly accepted appointment with a video link
          if (appointmentMap['video_conference_link'] != null &&
              appointmentMap['video_conference_link'].toString().isNotEmpty) {
            // Check if we've already processed this appointment
            if (!_processedAppointments.contains(appointmentMap['id'])) {
              _processedAppointments.add(appointmentMap['id']);

              // Navigate to video call immediately
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _navigateToVideoCall(appointmentMap);
              });
            }
          }
        } else if (status == 'declined' || status == 'cancelled') {
          declined.add(appointmentMap);
        }
      }

      // Update state with database appointments
      setState(() {
        pendingAppointments = pending;
        acceptedAppointments = accepted;
        rejectedAppointments = declined;
      });
    } catch (error) {
      print('Error fetching appointments from database: $error');
    }
  }

  // Keep track of appointments we've already processed
  Set<String> _processedAppointments = {};

  void _navigateToVideoCall(Map<String, dynamic> appointment) {
    final doctorName =
        appointment['doctors'] != null
            ? appointment['doctors']['full_name']
            : 'Doctor';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TeleConseltationPage(
              appointment: appointment,
              doctorName: doctorName,
            ),
      ),
    );
  }

  void _connectSocket() {
    // Get the current user ID
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        errorMessage = 'User not authenticated';
        connectionStatus = 'Authentication Error';
      });
      return;
    }

    // Connect using the user's ID
    _socketService.connect(userId);

    // Set up callbacks for appointment responses
    _socketService.onAppointmentAccepted = (data) {
      print('Appointment accepted: $data');

      // Move appointment from pending to accepted
      setState(() {
        final appointmentId = data['appointmentId'];
        final appointmentIndex = pendingAppointments.indexWhere(
          (appointment) => appointment['appointmentId'] == appointmentId,
        );

        if (appointmentIndex != -1) {
          final appointment = pendingAppointments[appointmentIndex];
          appointment['status'] = 'accepted';
          acceptedAppointments.add(appointment);
          pendingAppointments.removeAt(appointmentIndex);
        }
      });

      // Show notification
      _showStatusDialog(
        'Appointment Accepted',
        'Your appointment has been accepted! The video consultation will open shortly.',
        Colors.green,
      );

      // Immediately fetch from database to get the video conference link
      _fetchAppointmentsFromDatabase();
    };

    _socketService.onAppointmentDeclined = (data) {
      print('Appointment declined: $data');

      // Move appointment from pending to rejected
      setState(() {
        final appointmentId = data['appointmentId'];
        final appointmentIndex = pendingAppointments.indexWhere(
          (appointment) => appointment['appointmentId'] == appointmentId,
        );

        if (appointmentIndex != -1) {
          final appointment = pendingAppointments[appointmentIndex];
          appointment['status'] = 'declined';
          rejectedAppointments.add(appointment);
          pendingAppointments.removeAt(appointmentIndex);
        }
      });

      // Show notification
      _showStatusDialog(
        'Appointment Declined',
        'Your appointment was declined. Please try another time or doctor.',
        Colors.red,
      );
    };
  }

  void _showStatusDialog(String title, String message, Color color) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          backgroundColor: color.withOpacity(0.1),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'Not specified';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('MMM d, yyyy - h:mm a').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['status'] ?? 'unknown';
    final Color statusColor =
        status == 'pending'
            ? Colors.amber
            : status == 'accepted'
            ? Colors.green
            : Colors.red;

    // Check if this appointment has a video conference link
    final hasVideoLink =
        appointment['video_conference_link'] != null &&
        appointment['video_conference_link'].toString().isNotEmpty;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    appointment['doctor_name'] ??
                        (appointment['doctors'] != null
                            ? appointment['doctors']['full_name']
                            : 'Unknown Doctor'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  _formatDateTime(appointment['requested_time']),
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            if (status == 'accepted') ...[
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  _navigateToVideoCall(appointment);
                },
                icon: Icon(Icons.video_call),
                label: Text('Join Video Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasVideoLink ? Colors.blue : Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _socketService.disconnect();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Appointments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.hourglass_empty),
              text: 'Pending (${pendingAppointments.length})',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: 'Accepted (${acceptedAppointments.length})',
            ),
            Tab(
              icon: Icon(Icons.cancel),
              text: 'Rejected (${rejectedAppointments.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _loadAppointments();
              // Also attempt to reconnect if disconnected
              if (connectionStatus != 'Connected') {
                final userId = supabase.auth.currentUser?.id;
                if (userId != null) {
                  _socketService.connect(userId);
                }
              }
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status indicator
          Container(
            padding: EdgeInsets.all(8),
            color:
                connectionStatus == 'Connected'
                    ? Colors.green[50]
                    : Colors.red[50],
            child: Row(
              children: [
                Icon(
                  connectionStatus == 'Connected' ? Icons.wifi : Icons.wifi_off,
                  color:
                      connectionStatus == 'Connected'
                          ? Colors.green
                          : Colors.red,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Status: $connectionStatus',
                  style: TextStyle(
                    color:
                        connectionStatus == 'Connected'
                            ? Colors.green
                            : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isReconnecting)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    ),
                  ),
                Spacer(),
                if (connectionStatus != 'Connected')
                  TextButton(
                    onPressed: () {
                      final userId = supabase.auth.currentUser?.id;
                      if (userId != null) {
                        setState(() {
                          isReconnecting = true;
                        });
                        _socketService.connect(userId);
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: Text('Reconnect'),
                  ),
              ],
            ),
          ),

          // Error message if any
          if (errorMessage.isNotEmpty)
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.red[50],
              width: double.infinity,
              child: Text(
                'Error: $errorMessage',
                style: TextStyle(color: Colors.red),
              ),
            ),

          // Main content
          Expanded(
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : TabBarView(
                      controller: _tabController,
                      children: [
                        // Pending Appointments Tab
                        pendingAppointments.isEmpty
                            ? _buildEmptyState(
                              'No pending appointments.\nRequests you send will appear here.',
                              Icons.hourglass_empty,
                            )
                            : ListView.builder(
                              itemCount: pendingAppointments.length,
                              padding: EdgeInsets.all(8),
                              itemBuilder: (context, index) {
                                return _buildAppointmentCard(
                                  pendingAppointments[index],
                                );
                              },
                            ),

                        // Accepted Appointments Tab
                        acceptedAppointments.isEmpty
                            ? _buildEmptyState(
                              'No accepted appointments.\nAccepted appointments will appear here.',
                              Icons.check_circle,
                            )
                            : ListView.builder(
                              itemCount: acceptedAppointments.length,
                              padding: EdgeInsets.all(8),
                              itemBuilder: (context, index) {
                                return _buildAppointmentCard(
                                  acceptedAppointments[index],
                                );
                              },
                            ),

                        // Rejected Appointments Tab
                        rejectedAppointments.isEmpty
                            ? _buildEmptyState(
                              'No rejected appointments.\nRejected appointments will appear here.',
                              Icons.cancel,
                            )
                            : ListView.builder(
                              itemCount: rejectedAppointments.length,
                              padding: EdgeInsets.all(8),
                              itemBuilder: (context, index) {
                                return _buildAppointmentCard(
                                  rejectedAppointments[index],
                                );
                              },
                            ),
                      ],
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate back to booking page
          Navigator.pop(context);
        },
        tooltip: 'Book New Appointment',
        child: Icon(Icons.add),
      ),
    );
  }
}
