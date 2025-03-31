import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class TeleConseltationPage extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final String doctorName;

  const TeleConseltationPage({
    super.key,
    required this.appointment,
    required this.doctorName,
  });

  @override
  _TeleConseltationPageState createState() => _TeleConseltationPageState();
}

class _TeleConseltationPageState extends State<TeleConseltationPage> {
  final JitsiMeet jitsiMeet = JitsiMeet();
  bool isCallActive = false;
  String callStatus = 'Ready to join';
  late String roomName;
  late String meetingUrl;
  bool isJoining = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeJitsiMeet();
  }

  Future<void> _initializeJitsiMeet() async {
    try {
      // Extract the meeting URL from the appointment
      print("Appointment data: ${widget.appointment}");
      meetingUrl = widget.appointment['video_conference_link'] ?? '';
      print("Meeting URL from appointment: $meetingUrl");

      // Extract room name from the URL
      if (meetingUrl.isNotEmpty) {
        roomName = meetingUrl.split('/').last;
        print("Room name extracted from URL: $roomName");
      } else {
        // Fallback to using appointment ID if no URL is available
        final appointmentId =
            widget.appointment['appointmentId'] ??
            widget.appointment['id'] ??
            'default_room';
        roomName = 'caresync_appointment_$appointmentId';
        meetingUrl = 'https://meet.jit.si/$roomName';
        print("Generated room name: $roomName");
        print("Generated meeting URL: $meetingUrl");
      }

      // Auto-join the meeting after a short delay
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          _joinMeeting();
        }
      });
    } catch (e) {
      print("Error in initializeJitsiMeet: $e");
      setState(() {
        errorMessage = "Error initializing: $e";
      });
    }
  }

  // Get user details with minimal data
  Future<Map<String, String>> _getUserDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'Patient';
      print("User name for meeting: $userName");
      return {'name': userName};
    } catch (e) {
      print("Error getting user details: $e");
      return {'name': 'Patient'};
    }
  }

  // Join meeting with optimized options
  Future<void> _joinMeeting() async {
    if (isJoining) {
      print("Already attempting to join a meeting");
      return;
    }

    setState(() {
      isJoining = true;
      callStatus = 'Joining call...';
      errorMessage = null;
    });

    try {
      print("Starting to join meeting with room: $roomName");
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
          "invite.enabled": false,
          "chat.enabled": true,
          "calendar.enabled": false,
          "call-integration.enabled": true,
          "pip.enabled": true,
        },
        userInfo: JitsiMeetUserInfo(displayName: userDetails['name']),
      );

      print("Jitsi options configured: ${options.room}");

      // Create event listener
      var listener = JitsiMeetEventListener(
        conferenceJoined: (url) {
          print("Conference joined: $url");
          if (mounted) {
            setState(() {
              isCallActive = true;
              callStatus = 'Connected to call';
              isJoining = false;
            });
          }
          _logCallEvent('joined');
        },
        conferenceTerminated: (url, error) {
          print("Conference terminated: $url, error: $error");
          if (mounted) {
            setState(() {
              isCallActive = false;
              callStatus = 'Call ended: ${error ?? ""}';
              isJoining = false;
            });
          }
          _logCallEvent('terminated');
        },
        conferenceWillJoin: (url) {
          print("Conference will join: $url");
          if (mounted) {
            setState(() {
              callStatus = 'Connecting to call...';
            });
          }
        },
        participantJoined: (email, name, role, participantId) {
          print("Participant joined: $name ($participantId)");
        },
        participantLeft: (participantId) {
          print("Participant left: $participantId");
        },
        audioMutedChanged: (muted) {
          print("Audio muted changed: $muted");
        },
        videoMutedChanged: (muted) {
          print("Video muted changed: $muted");
        },
      );

      print("Attempting to join meeting now...");
      // Join the meeting with the listener
      await jitsiMeet.join(options, listener);
      print("Join method completed");
    } catch (error) {
      print("Error joining meeting: $error");
      if (mounted) {
        setState(() {
          callStatus = 'Error joining call';
          errorMessage = error.toString();
          isJoining = false;
        });
      }
    }
  }

  // Log call events locally to avoid server requests
  Future<void> _logCallEvent(String event) async {
    try {
      final appointmentId =
          widget.appointment['appointmentId'] ??
          widget.appointment['id'] ??
          'unknown';
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
      final dateString =
          widget.appointment['appointmentDate'] ??
          widget.appointment['requested_time'];
      if (dateString == null) return 'No date available';

      final date = DateTime.parse(dateString);
      return DateFormat('EEEE, MMMM d, yyyy - h:mm a').format(date);
    } catch (e) {
      print("Error formatting date: $e");
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
                      style: TextStyle(fontSize: 16, color: Colors.green),
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
                      'Room name: $roomName',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
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

            SizedBox(height: 20),

            // Error message if any
            if (errorMessage != null)
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Error:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ],
                ),
              ),

            // Call status
            Center(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isCallActive
                          ? Colors.green.shade100
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  callStatus,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        isCallActive ? Colors.green.shade800 : Colors.black87,
                  ),
                ),
              ),
            ),

            SizedBox(height: 30),

            // Join call button
            Center(
              child: ElevatedButton.icon(
                onPressed: isCallActive || isJoining ? null : _joinMeeting,
                icon: Icon(Icons.video_call),
                label: Text(
                  isJoining
                      ? 'Joining...'
                      : isCallActive
                      ? 'In Call'
                      : 'Join Video Call',
                ),
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
                      title: Text(
                        'Ensure you have a stable internet connection',
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text(
                        'Find a quiet, private space for your consultation',
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Test your camera and microphone'),
                    ),
                    ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Have your questions ready for the doctor'),
                    ),
                    // Debug information
                    SizedBox(height: 20),
                    Text(
                      'Debug Information:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Room: $roomName'),
                    Text('URL: $meetingUrl'),
                    Text('Call active: $isCallActive'),
                    Text('Joining: $isJoining'),
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
      try {
        jitsiMeet.hangUp();
      } catch (e) {
        print("Error hanging up: $e");
      }
    }
    super.dispose();
  }
}
