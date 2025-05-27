import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeleConsultationPage extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final String doctorName;

  const TeleConsultationPage({
    super.key,
    required this.appointment,
    required this.doctorName,
  });

  @override
  TeleConsultationPageState createState() => TeleConsultationPageState();
}

class TeleConsultationPageState extends State<TeleConsultationPage> {
  final JitsiMeet jitsiMeet = JitsiMeet();
  final supabase = Supabase.instance.client;
  bool isCallActive = false;
  String callStatus = 'Ready to join';
  late String roomName;
  late String meetingUrl;
  bool isJoining = false;
  String? errorMessage;
  Timer? _refreshTimer;
  bool _paymentVerified = false;

  @override
  void initState() {
    super.initState();
    _verifyPaymentAndInitialize();

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _refreshAppointmentData();
      }
    });
  }

  Future<void> _verifyPaymentAndInitialize() async {
    try {
      // Check if appointment is paid
      final appointmentId =
          widget.appointment['id']?.toString() ??
          widget.appointment['appointmentId']?.toString();

      if (appointmentId == null) {
        setState(() {
          errorMessage = 'Invalid appointment data';
        });
        return;
      }

      // Fetch latest appointment data
      final response =
          await supabase
              .from('appointments')
              .select('payment_status, video_conference_link, status')
              .eq('id', appointmentId)
              .single();

      final paymentStatus = response['payment_status'];
      final status = response['status'];

      if (status != 'accepted') {
        setState(() {
          errorMessage = 'Appointment not accepted yet';
        });
        return;
      }

      if (paymentStatus != 'paid') {
        setState(() {
          errorMessage = 'Payment required for video call';
        });
        return;
      }

      _paymentVerified = true;
      await _initializeJitsiMeet();
    } catch (e) {
      debugPrint("Error verifying payment: $e");
      setState(() {
        errorMessage = 'Error verifying payment status';
      });
    }
  }

  Future<void> _refreshAppointmentData() async {
    if (!_paymentVerified) return;

    try {
      final appointmentId =
          widget.appointment['id']?.toString() ??
          widget.appointment['appointmentId']?.toString();
      if (appointmentId == null) return;

      final response =
          await supabase
              .from('appointments')
              .select('video_conference_link, status, payment_status')
              .eq('id', appointmentId)
              .single();

      if (mounted) {
        final newVideoLink = response['video_conference_link'];
        final status = response['status'];
        final paymentStatus = response['payment_status'];

        // Check if payment status changed
        if (paymentStatus != 'paid') {
          _showPaymentIssueDialog();
          return;
        }

        // Check if appointment was cancelled
        if (status == 'cancelled') {
          _showAppointmentCancelledDialog();
          return;
        }

        // Update video link if changed
        if (newVideoLink != null &&
            newVideoLink.isNotEmpty &&
            newVideoLink != meetingUrl) {
          setState(() {
            meetingUrl = newVideoLink;
            roomName = _extractRoomNameFromUrl(meetingUrl);
          });

          if (!isCallActive) {
            _showNewLinkDialog();
          }
        }
      }
    } catch (e) {
      debugPrint("Error refreshing appointment data: $e");
    }
  }

  String _extractRoomNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : 'default_room';
    } catch (e) {
      return 'default_room';
    }
  }

  void _showPaymentIssueDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Payment Issue'),
            content: const Text(
              'There seems to be an issue with your payment. Please contact support.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showNewLinkDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              l10n?.newMeetingLinkAvailable ?? 'New Meeting Link Available',
            ),
            content: Text(
              l10n?.newMeetingLinkMessage ??
                  'A new meeting link is available. Would you like to join now?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(l10n?.later ?? 'Later'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _joinMeeting();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: Text(l10n?.joinNow ?? 'Join Now'),
              ),
            ],
          ),
    );
  }

  void _showAppointmentCancelledDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(l10n?.appointmentCancelled ?? 'Appointment Cancelled'),
            content: Text(
              l10n?.appointmentCancelledMessage ??
                  'This appointment has been cancelled.',
            ),
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
      debugPrint("Appointment data: ${widget.appointment}");
      meetingUrl =
          widget.appointment['video_conference_link']?.toString() ?? '';
      debugPrint("Meeting URL from appointment: $meetingUrl");

      if (meetingUrl.isNotEmpty) {
        roomName = _extractRoomNameFromUrl(meetingUrl);
        debugPrint("Room name extracted from URL: $roomName");
      } else {
        // Generate fallback room name
        final appointmentId =
            widget.appointment['id']?.toString() ??
            widget.appointment['appointmentId']?.toString() ??
            'default_room';
        roomName = 'caresync_appointment_$appointmentId';
        meetingUrl = 'https://meet.jit.si/$roomName';
        debugPrint("Generated room name: $roomName");
        debugPrint("Generated meeting URL: $meetingUrl");

        // Update video link in database if we generated one
        await _updateVideoLinkInDatabase(appointmentId, meetingUrl);
      }

      setState(() {
        callStatus = 'Ready to join';
      });

      // Auto-join after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _paymentVerified) {
          _joinMeeting();
        }
      });
    } catch (e) {
      debugPrint("Error in initializeJitsiMeet: $e");
      setState(() {
        errorMessage = 'Error initializing video call';
      });
    }
  }

  Future<void> _updateVideoLinkInDatabase(
    String appointmentId,
    String videoLink,
  ) async {
    try {
      if (appointmentId.isNotEmpty && appointmentId != 'default_room') {
        await supabase
            .from('appointments')
            .update({'video_conference_link': videoLink})
            .eq('id', appointmentId);
        debugPrint(
          "Updated video link in database for appointment $appointmentId",
        );
      }
    } catch (e) {
      debugPrint("Error updating video link in database: $e");
    }
  }

  Future<Map<String, String>> _getUserDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'Patient';
      debugPrint("User name for meeting: $userName");
      return {'name': userName};
    } catch (e) {
      debugPrint("Error getting user details: $e");
      return {'name': 'Patient'};
    }
  }

  Future<void> _joinMeeting() async {
    final l10n = AppLocalizations.of(context);

    if (!_paymentVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment required for video call'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isJoining) {
      debugPrint("Already attempting to join a meeting");
      return;
    }

    setState(() {
      isJoining = true;
      callStatus = l10n?.joiningCall ?? 'Joining call...';
      errorMessage = null;
    });

    try {
      debugPrint("Starting to join meeting with room: $roomName");
      final userDetails = await _getUserDetails();

      var options = JitsiMeetConferenceOptions(
        serverURL: "https://meet.jit.si",
        room: roomName,
        configOverrides: {
          "startWithAudioMuted": false,
          "startWithVideoMuted": false,
          "subject": "Appointment with Dr. ${widget.doctorName}",
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

      debugPrint("Jitsi options configured: ${options.room}");

      var listener = JitsiMeetEventListener(
        conferenceJoined: (url) {
          debugPrint("Conference joined: $url");
          if (mounted) {
            setState(() {
              isCallActive = true;
              callStatus = l10n?.connectedToCall ?? 'Connected to call';
              isJoining = false;
            });
          }
          _logCallEvent('joined');
        },
        conferenceTerminated: (url, error) {
          debugPrint("Conference terminated: $url, error: $error");
          if (mounted) {
            setState(() {
              isCallActive = false;
              callStatus = 'Call ended';
              isJoining = false;
            });
          }
          _logCallEvent('terminated');
        },
        conferenceWillJoin: (url) {
          debugPrint("Conference will join: $url");
          if (mounted) {
            setState(() {
              callStatus = l10n?.connectingToCall ?? 'Connecting to call...';
            });
          }
        },
        participantJoined: (email, name, role, participantId) {
          debugPrint("Participant joined: $name ($participantId)");
        },
        participantLeft: (participantId) {
          debugPrint("Participant left: $participantId");
        },
        audioMutedChanged: (muted) {
          debugPrint("Audio muted changed: $muted");
        },
        videoMutedChanged: (muted) {
          debugPrint("Video muted changed: $muted");
        },
      );

      debugPrint("Attempting to join meeting now...");
      await jitsiMeet.join(options, listener);
      debugPrint("Join method completed");
    } catch (error) {
      debugPrint("Error joining meeting: $error");
      if (mounted) {
        setState(() {
          callStatus = l10n?.errorJoiningCall ?? 'Error joining call';
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

      debugPrint(
        'Call event: $event for appointment $appointmentId at $timestamp',
      );
    } catch (e) {
      debugPrint('Error logging call event: $e');
    }
  }

  String _formatAppointmentDate() {
    final l10n = AppLocalizations.of(context);
    try {
      final dateString =
          widget.appointment['appointmentDate'] ??
          widget.appointment['requested_time'] ??
          widget.appointment['requestedTime'];
      if (dateString == null) {
        return l10n?.noDateAvailable ?? 'No date available';
      }

      final date = DateTime.parse(dateString);
      return DateFormat('EEEE, MMMM d, yyyy - h:mm a').format(date);
    } catch (e) {
      debugPrint("Error formatting date: $e");
      return l10n?.invalidDateFormat ?? 'Invalid date format';
    }
  }

  void _copyToClipboard(String text) {
    final l10n = AppLocalizations.of(context);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n?.copiedToClipboard ?? 'Copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final existingLink = widget.appointment['video_conference_link'];
    final hasExistingLink = existingLink != null && existingLink.isNotEmpty;
    final displayUrl = hasExistingLink ? existingLink : meetingUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.videoConsultationTitle ?? 'Video Consultation'),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment verification status
            if (!_paymentVerified)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payment, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Verifying payment status...',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointment with Dr. ${widget.doctorName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scheduled for ${_formatAppointmentDate()}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _paymentVerified
                              ? Icons.check_circle
                              : Icons.hourglass_empty,
                          color:
                              _paymentVerified ? Colors.green : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _paymentVerified
                              ? 'Payment verified'
                              : 'Verifying payment...',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                _paymentVerified ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_paymentVerified) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.meetingInformation ?? 'Meeting Information',
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
                            tooltip: l10n?.copyLinkTooltip ?? 'Copy link',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Room: $roomName',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n?.yourDoctorWillJoin ??
                            'Your doctor will join this meeting',
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
            ],

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
                      'Error:',
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
                          : _paymentVerified
                          ? Colors.blue.shade100
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  callStatus,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        isCallActive
                            ? Colors.green.shade800
                            : _paymentVerified
                            ? Colors.blue.shade800
                            : Colors.grey.shade800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            if (_paymentVerified) ...[
              Center(
                child: ElevatedButton.icon(
                  onPressed: isCallActive || isJoining ? null : _joinMeeting,
                  icon: const Icon(Icons.video_call),
                  label: Text(
                    isJoining
                        ? l10n?.joining ?? 'Joining...'
                        : isCallActive
                        ? l10n?.inCall ?? 'In Call'
                        : l10n?.joinVideoCall ?? 'Join Video Call',
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
            ],

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.beforeJoining ?? 'Before joining:',
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
                      title: Text(
                        l10n?.ensureStableConnection ??
                            'Ensure stable internet connection',
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: Text(l10n?.findQuietSpace ?? 'Find a quiet space'),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: Text(
                        l10n?.testCameraMic ??
                            'Test your camera and microphone',
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: Text(
                        l10n?.haveQuestionsReady ?? 'Have your questions ready',
                      ),
                    ),
                    if (!_paymentVerified)
                      const ListTile(
                        leading: Icon(Icons.payment, color: Colors.orange),
                        title: Text('Payment must be completed before joining'),
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
        debugPrint("Error hanging up: $e");
      }
    }
    super.dispose();
  }
}
