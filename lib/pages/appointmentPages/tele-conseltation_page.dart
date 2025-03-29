import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class TeleConseltationPage extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final String doctorName;

  const TeleConseltationPage({
    Key? key,
    required this.appointment,
    required this.doctorName,
  }) : super(key: key);

  @override
  _TeleConseltationPageState createState() => _TeleConseltationPageState();
}

class _TeleConseltationPageState extends State<TeleConseltationPage> {
  final JitsiMeet jitsiMeet = JitsiMeet();
  bool isCallActive = false;
  String callStatus = 'Ready to join';
  late String roomName;
  late String meetingUrl;

  @override
  void initState() {
    super.initState();
    // Generate room name and URL
    final appointmentId = widget.appointment['appointmentId'] ?? widget.appointment['id'];
    roomName = 'caresync_appointment_$appointmentId';
    meetingUrl = 'https://meet.jit.si/$roomName';
  }

  // Get user details with minimal data
  Future<Map<String, String>> _getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? 'Patient';
    // Only get essential data
    return {
      'name': userName,
    };
  }

  // Join meeting with optimized options
  Future<void> _joinMeeting() async {
    try {
      setState(() {
        callStatus = 'Joining call...';
      });

      final userDetails = await _getUserDetails();

      // Configure meeting options with minimal data
      var options = JitsiMeetConferenceOptions(
        serverURL: "https://meet.jit.si",
        room: roomName,
        configOverrides: {
          "startWithAudioMuted": false,
          "startWithVideoMuted": false,
          "subject": "Appointment with ${widget.doctorName}",
        },
        featureFlags: {
          "ios.recording.enabled": false,
          "live-streaming.enabled": false,
          // Disable features that might add headers
          "invite.enabled": false,
          "chat.enabled": true,
          "calendar.enabled": false,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: userDetails['name'],
          // Don't include email unless necessary
        ),
      );

      // Set up listeners for call events
      jitsiMeet.onConferenceJoined(() {
        setState(() {
          isCallActive = true;
          callStatus = 'Connected to call';
        });
        // Log the join event locally
        _logCallEvent('joined');
      });

      jitsiMeet.onConferenceTerminated((message) {
        setState(() {
          isCallActive = false;
          callStatus = 'Call ended: $message';
        });
        // Log the termination event locally
        _logCallEvent('terminated');
      });

      // Join the meeting
      await jitsiMeet.join(options);

    } catch (error) {
      setState(() {
        callStatus = 'Error joining call: $error';
      });
      print('Error joining meeting: $error');
    }
  }

  // Log call events locally to avoid server requests
  Future<void> _logCallEvent(String event) async {
    try {
      final appointmentId = widget.appointment['appointmentId'] ?? widget.appointment['id'];
      final timestamp = DateTime.now().toIso8601String();

      // Store locally
      final prefs = await SharedPreferences.getInstance();
      final callLogs = prefs.getStringList('call_logs') ?? [];
      callLogs.add('$appointmentId|$event|$timestamp');
      await prefs.setStringList('call_logs', callLogs);

      print('Call event: $event for appointment $appointmentId at $timestamp');
    } catch (e) {
      print('Error logging call event: $e');
    }
  }

  // Format appointment date for display
  String _formatAppointmentDate() {
    try {
      final dateString = widget.appointment['appointmentDate'] ??
          widget.appointment['requested_time'];
      if (dateString == null) return 'No date available';

      final date = DateTime.parse(dateString);
      return DateFormat('EEEE, MMMM d, yyyy - h:mm a').format(date);
    } catch (e) {
      return 'Invalid date format';
    }
  }

  // Copy text to clipboard
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if there's a video_conference_link in the appointment data
    final existingLink = widget.appointment['video_conference_link'];
    final hasExistingLink = existingLink != null && existingLink.isNotEmpty;

    // If there's an existing link, use it instead of our generated one
    final displayUrl = hasExistingLink ? existingLink : meetingUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text('Video Consultation'),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appointment details card
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointment with ${widget.doctorName}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Scheduled for: ${_formatAppointmentDate()}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Status: ${widget.appointment['status'] ?? 'Confirmed'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Meeting link card
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meeting Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayUrl,
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy),
                          onPressed: () => _copyToClipboard(displayUrl),
                          tooltip: 'Copy link',
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your doctor will use this same link to join the meeting.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // Call status
            Center(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCallActive ? Colors.green.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  callStatus,
                  style: TextStyle(
                    fontSize: 16,
                    color: isCallActive ? Colors.green.shade800 : Colors.black87,
                  ),
                ),
              ),
            ),

            SizedBox(height: 30),

            // Join call button
            Center(
              child: ElevatedButton.icon(
                onPressed: isCallActive ? null : _joinMeeting,
                icon: Icon(Icons.video_call),
                label: Text(isCallActive ? 'In Call' : 'Join Video Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Instructions
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Before joining:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Ensure you have a stable internet connection'),
                    ),
                    ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Find a quiet, private space for your consultation'),
                    ),
                    ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Test your camera and microphone'),
                    ),
                    ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Have your questions ready for the doctor'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up resources
    if (isCallActive) {
      jitsiMeet.hangUp();
    }
    super.dispose();
  }
}

extension on JitsiMeet {
  void onConferenceJoined(Null Function() param0) {}

  void onConferenceTerminated(Null Function(dynamic message) param0) {}
}

