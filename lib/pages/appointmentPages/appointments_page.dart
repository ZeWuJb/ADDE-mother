import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'tele-conseltation_page.dart'; // Import the video consultation page

class SocketTestPage extends StatefulWidget {
  // Make doctorId optional since we don't need it for the main appointments page
  final String? doctorId;

  const SocketTestPage({super.key, this.doctorId});

  @override
  State<SocketTestPage> createState() => _SocketTestPageState();
}

class _SocketTestPageState extends State<SocketTestPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  // Appointment lists by status
  List<Map<String, dynamic>> pendingAppointments = [];
  List<Map<String, dynamic>> acceptedAppointments = [];
  List<Map<String, dynamic>> rejectedAppointments = [];

  String connectionStatus = 'Connected';
  String errorMessage = '';
  bool isLoading = true;
  bool isReconnecting = false;

  // Subscription channels
  RealtimeChannel? tempAppointmentsChannel;
  RealtimeChannel? appointmentsChannel;

  // Tab controller for the different appointment categories
  late TabController _tabController;

  // Keep track of appointments we've already processed
  final Set<String> _processedAppointments = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize data and subscriptions
    Future.microtask(() {
      _setupRealtimeSubscriptions();
      _loadAppointments();

      // Set up a timer to periodically check for new appointments
      Timer.periodic(const Duration(seconds: 30), (timer) {
        if (mounted) {
          _fetchAppointmentsFromDatabase();
        }
      });
    });
  }

  void _setupRealtimeSubscriptions() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        errorMessage = 'User not authenticated';
        connectionStatus = 'Authentication Error';
      });
      return;
    }

    // Subscribe to temporary appointments
    tempAppointmentsChannel =
        supabase
            .channel('temp-appointments-mother-$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.delete,
              schema: 'public',
              table: 'temporary_appointments',
              callback: (payload) {
                if (mounted) {
                  // Refresh appointments when a temporary appointment is deleted
                  _fetchAppointmentsFromDatabase();
                }
              },
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'temporary_appointments',
              callback: (payload) {
                if (mounted) {
                  // Refresh appointments when a new temporary appointment is created
                  _fetchAppointmentsFromDatabase();
                }
              },
            )
            .subscribe();

    // Subscribe to regular appointments
    appointmentsChannel =
        supabase
            .channel('appointments-mother-$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'appointments',
              callback: (payload) {
                if (mounted) {
                  // Refresh appointments when a new appointment is created
                  _fetchAppointmentsFromDatabase();

                  // Show notification for accepted appointment
                  _showStatusDialog(
                    'Appointment Accepted',
                    'Your appointment has been accepted! The video consultation will open shortly.',
                    Colors.green,
                  );
                }
              },
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'appointments',
              callback: (payload) {
                if (mounted) {
                  // Refresh appointments when an appointment is updated
                  _fetchAppointmentsFromDatabase();
                }
              },
            )
            .subscribe();
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

      // Fetch appointments directly from database
      await _fetchAppointmentsFromDatabase();
    } catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load appointments: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Fetch appointments directly from Supabase
  Future<void> _fetchAppointmentsFromDatabase() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch temporary appointments
      final tempResponse = await supabase
          .from('temporary_appointments')
          .select('''
            id, 
            doctor_id,
            requested_time, 
            created_at,
            doctors:doctor_id (
              id, 
              full_name, 
              speciality,
              profile_url
            )
          ''')
          .eq('mother_id', userId)
          .order('created_at', ascending: false);

      // Fetch regular appointments
      final appResponse = await supabase
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

      // Process temporary appointments (all are pending)
      List<Map<String, dynamic>> pending = [];
      for (var appointment in tempResponse) {
        // Convert to Map<String, dynamic> if it's not already
        final appointmentMap = Map<String, dynamic>.from(appointment);
        appointmentMap['status'] = 'pending';
        appointmentMap['appointmentId'] = appointmentMap['id'];
        pending.add(appointmentMap);
      }

      // Process regular appointments by status
      List<Map<String, dynamic>> accepted = [];
      List<Map<String, dynamic>> declined = [];

      for (var appointment in appResponse) {
        // Convert to Map<String, dynamic> if it's not already
        final appointmentMap = Map<String, dynamic>.from(appointment);

        String status = appointmentMap['status'] ?? 'pending';

        if (status == 'accepted') {
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
      if (mounted) {
        setState(() {
          pendingAppointments = pending;
          acceptedAppointments = accepted;
          rejectedAppointments = declined;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error fetching appointments: $error';
        });
      }
    }
  }

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

  void _showStatusDialog(String title, String message, Color color) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          backgroundColor: color.withAlpha(25),
          actions: [
            TextButton(
              child: const Text('OK'),
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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(50),
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
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(appointment['requested_time']),
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            if (status == 'accepted') ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  _navigateToVideoCall(appointment);
                },
                icon: const Icon(Icons.video_call),
                label: const Text('Join Video Call'),
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
          const SizedBox(height: 16),
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
    // Clean up subscriptions
    tempAppointmentsChannel?.unsubscribe();
    appointmentsChannel?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.hourglass_empty),
              text: 'Pending (${pendingAppointments.length})',
            ),
            Tab(
              icon: const Icon(Icons.check_circle),
              text: 'Accepted (${acceptedAppointments.length})',
            ),
            Tab(
              icon: const Icon(Icons.cancel),
              text: 'Rejected (${rejectedAppointments.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadAppointments();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status indicator (only show when disconnected)
          if (connectionStatus != 'Connected')
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red[50],
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Status: $connectionStatus',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isReconnecting)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isReconnecting = true;
                      });
                      _fetchAppointmentsFromDatabase();
                      setState(() {
                        isReconnecting = false;
                        connectionStatus = 'Connected';
                      });
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // Error message if any
          if (errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red[50],
              width: double.infinity,
              child: Text(
                'Error: $errorMessage',
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // Main content
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
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
                              padding: const EdgeInsets.all(8),
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
                              padding: const EdgeInsets.all(8),
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
                              padding: const EdgeInsets.all(8),
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
