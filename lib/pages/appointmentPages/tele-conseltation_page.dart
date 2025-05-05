import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final supabase = Supabase.instance.client;
  bool isCallActive = false;
  String callStatus = 'Ready to join';
  late String roomName;
  late String meetingUrl;
  bool isJoining = false;
  String? errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeJitsiMeet();

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _refreshAppointmentData();
      }
    });
  }

  Future<void> _refreshAppointmentData() async {
    try {
      final appointmentId = widget.appointment['id']?.toString();
      if (appointmentId == null) return;

      final response =
          await supabase
              .from('appointments')
              .select('video_conference_link, status')
              .eq('id', appointmentId)
              .single();

      if (mounted) {
        final newVideoLink = response['video_conference_link'];
        if (newVideoLink != null &&
            newVideoLink.isNotEmpty &&
            newVideoLink != meetingUrl) {
          setState(() {
            meetingUrl = newVideoLink;
            roomName = meetingUrl.split('/').last;
          });

          if (!isCallActive) {
            _showNewLinkDialog();
          }
        }

        final status = response['status'];
        if (status == 'cancelled' && isCallActive) {
          _showAppointmentCancelledDialog();
        }
      }
    } catch (e) {
      print("Error refreshing appointment data: $e");
    }
  }

  void _showNewLinkDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.newMeetingLinkAvailable),
            content: Text(l10n.newMeetingLinkMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(l10n.later),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _joinMeeting();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: Text(l10n.joinNow),
              ),
            ],
          ),
    );
  }

  void _showAppointmentCancelledDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.appointmentCancelled),
            content: Text(l10n.appointmentCancelledMessage),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  jitsiMeet.hangUp();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _initializeJitsiMeet() async {
    try {
      print("Appointment data: ${widget.appointment}");
      meetingUrl =
          widget.appointment['video_conference_link']?.toString() ?? '';
      print("Meeting URL from appointment: $meetingUrl");

      if (meetingUrl.isNotEmpty) {
        roomName = meetingUrl.split('/').last;
        print("Room name extracted from URL: $roomName");
      } else {
        final appointmentId =
            widget.appointment['id']?.toString() ??
            widget.appointment['appointmentId']?.toString() ??
            'default_room';
        roomName = 'caresync_appointment_$appointmentId';
        meetingUrl = 'https://meet.jit.si/$roomName';
        print("Generated room name: $roomName");
        print("Generated meeting URL: $meetingUrl");

        _updateVideoLinkInDatabase(appointmentId, meetingUrl);
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _joinMeeting();
        }
      });
    } catch (e) {
      print("Error in initializeJitsiMeet: $e");
      setState(() {
        errorMessage = AppLocalizations.of(context)!.errorLabel(e.toString());
      });
    }
  }

  Future<void> _updateVideoLinkInDatabase(
    String appointmentId,
    String videoLink,
  ) async {
    try {
      if (appointmentId.contains('-')) {
        await supabase
            .from('appointments')
            .update({'video_conference_link': videoLink})
            .eq('id', appointmentId);
        print("Updated video link in database for appointment $appointmentId");
      }
    } catch (e) {
      print("Error updating video link in database: $e");
    }
  }

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

  Future<void> _joinMeeting() async {
    final l10n = AppLocalizations.of(context)!;
    if (isJoining) {
      print("Already attempting to join a meeting");
      return;
    }

    setState(() {
      isJoining = true;
      callStatus = l10n.joiningCall;
      errorMessage = null;
    });

    try {
      print("Starting to join meeting with room: $roomName");
      final userDetails = await _getUserDetails();

      var options = JitsiMeetConferenceOptions(
        serverURL: "https://meet.jit.si",
        room: roomName,
        configOverrides: {
          "startWithAudioMuted": false,
          "startWithVideoMuted": false,
          "subject": l10n.appointmentWithDoctor(widget.doctorName),
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

      var listener = JitsiMeetEventListener(
        conferenceJoined: (url) {
          print("Conference joined: $url");
          if (mounted) {
            setState(() {
              isCallActive = true;
              callStatus = l10n.connectedToCall;
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
              callStatus = l10n.callEnded(
                error?.toString() ?? l10n.notAvailable,
              );
              isJoining = false;
            });
          }
          _logCallEvent('terminated');
        },
        conferenceWillJoin: (url) {
          print("Conference will join: $url");
          if (mounted) {
            setState(() {
              callStatus = l10n.connectingToCall;
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
      await jitsiMeet.join(options, listener);
      print("Join method completed");
    } catch (error) {
      print("Error joining meeting: $error");
      if (mounted) {
        setState(() {
          callStatus = l10n.errorJoiningCall;
          errorMessage = error.toString();
          isJoining = false;
        });
      }
    }
  }

  Future<void> _logCallEvent(String event) async {
    try {
      final appointmentId =
          widget.appointment['id']?.toString() ??
          widget.appointment['appointmentId']?.toString() ??
          'unknown';
      final timestamp = DateTime.now().toIso8601String();

      final prefs = await SharedPreferences.getInstance();
      final callLogs = prefs.getStringList('call_logs') ?? [];
      callLogs.add('$appointmentId|$event|$timestamp');
      await prefs.setStringList('call_logs', callLogs);

      print('Call event: $event for appointment $appointmentId at $timestamp');
    } catch (e) {
      print('Error logging call event: $e');
    }
  }

  String _formatAppointmentDate() {
    try {
      final dateString =
          widget.appointment['appointmentDate'] ??
          widget.appointment['requested_time'];
      if (dateString == null) {
        return AppLocalizations.of(context)!.noDateAvailable;
      }

      final date = DateTime.parse(dateString);
      return DateFormat('EEEE, MMMM d, yyyy - h:mm a').format(date);
    } catch (e) {
      print("Error formatting date: $e");
      return AppLocalizations.of(context)!.invalidDateFormat;
    }
  }

  void _copyToClipboard(String text) {
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.copiedToClipboard),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final existingLink = widget.appointment['video_conference_link'];
    final hasExistingLink = existingLink != null && existingLink.isNotEmpty;
    final displayUrl = hasExistingLink ? existingLink : meetingUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.videoConsultationTitle),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appointmentWithDoctor(widget.doctorName),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.scheduledFor(_formatAppointmentDate()),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.statusLabel(
                        widget.appointment['status']?.toString() ?? 'Confirmed',
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.meetingInformation,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayUrl,
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () => _copyToClipboard(displayUrl),
                          tooltip: l10n.copyLinkTooltip,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.roomName(roomName),
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.yourDoctorWillJoin,
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
            const SizedBox(height: 20),
            if (errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.errorPrefix,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ],
                ),
              ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
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
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: isCallActive || isJoining ? null : _joinMeeting,
                icon: const Icon(Icons.video_call),
                label: Text(
                  isJoining
                      ? l10n.joining
                      : isCallActive
                      ? l10n.inCall
                      : l10n.joinVideoCall,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.beforeJoining,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: Text(l10n.ensureStableConnection),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: Text(l10n.findQuietSpace),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: Text(l10n.testCameraMic),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: Text(l10n.haveQuestionsReady),
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
    _refreshTimer?.cancel();
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
