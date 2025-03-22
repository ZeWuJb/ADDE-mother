import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  late IO.Socket socket;
  bool isConnected = false;
  int reconnectAttempts = 0;
  final int maxReconnectAttempts = 5;
  Timer? pingTimer;
  Timer? reconnectTimer;

  // Add a set to track processed appointment IDs
  final Set<String> processedAppointments = {};

  // Callback functions for appointment status updates
  Function(Map<String, dynamic>)? onAppointmentAccepted;
  Function(Map<String, dynamic>)? onAppointmentDeclined;
  Function(bool)? onConnectionChange;
  Function(String)? onError;
  Function(List<Map<String, dynamic>>)? onAppointmentHistoryReceived;

  // Constants for storage
  static const String PENDING_APPOINTMENTS_KEY = 'pending_appointments';
  static const String ACCEPTED_APPOINTMENTS_KEY = 'accepted_appointments';
  static const String DECLINED_APPOINTMENTS_KEY = 'declined_appointments';

  // Update the connect method to improve connection persistence
  void connect(String userId) {
    // Make sure userId is not null or empty
    if (userId.isEmpty) {
      print('Error: userId is empty');
      if (onError != null) {
        onError!('User ID is empty');
      }
      return;
    }

    print('Connecting socket for user_id: $userId');

    try {
      // Disconnect any existing connection
      disconnect();

      // Create new socket with improved options for persistence
      socket = IO.io('http://192.168.127.180:3000', <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 10, // Increased from 5
        'reconnectionDelay': 1000, // Start with shorter delay
        'reconnectionDelayMax': 5000, // Maximum delay
        'timeout': 30000, // Increased timeout
        'query': {'userId': userId},
        'forceNew': true, // Force a new connection to prevent duplicates
      });

      // Set up connection event handlers
      socket.onConnect((_) {
        print('Connected to socket server with ID: ${socket.id}');
        isConnected = true;
        reconnectAttempts = 0;

        if (onConnectionChange != null) {
          onConnectionChange!(true);
        }

        // Join the room with the userId
        socket.emit('join', userId);
        print('Joined room: $userId');

        // Start ping timer
        startPingTimer();

        // Request appointment history
        requestAppointmentHistory(userId, 'mother');
      });

      socket.onDisconnect((reason) {
        print('Disconnected from socket server: $reason');
        isConnected = false;

        if (onConnectionChange != null) {
          onConnectionChange!(false);
        }

        // Try to reconnect manually
        attemptReconnect(userId);
      });

      socket.onConnectError((error) {
        print('Connection error: $error');
        isConnected = false;

        if (onConnectionChange != null) {
          onConnectionChange!(false);
        }

        if (onError != null) {
          onError!('Connection error: $error');
        }

        // Try to reconnect manually
        attemptReconnect(userId);
      });

      // Set up all other event handlers
      _setupEventHandlers(userId);
    } catch (e) {
      print('Exception during socket connection: $e');
      if (onError != null) {
        onError!('Failed to connect: $e');
      }
    }
  }

  // Update the event handlers to handle heartbeat and deduplication
  void _setupEventHandlers(String userId) {
    // Confirmation events
    socket.on('connection_established', (data) {
      print('Connection confirmed by server: $data');
    });

    socket.on('joined_room', (data) {
      print('Successfully joined room: $data');
    });

    socket.on('pong', (data) {
      print('Received pong from server: ${data['timestamp']}');
    });

    // Handle server heartbeat
    socket.on('heartbeat', (data) {
      print('Received heartbeat from server: ${data['timestamp']}');
      // Respond to heartbeat to confirm client is still alive
      socket.emit('heartbeat_response', {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });

    // Set up listeners for appointment status updates with deduplication
    socket.on('appointment_accepted', (data) async {
      print('Appointment accepted: $data');

      // Check if we've already processed this appointment
      final appointmentId = data['appointmentId']?.toString() ?? '';
      if (appointmentId.isNotEmpty) {
        if (processedAppointments.contains('accepted-$appointmentId')) {
          print('Skipping duplicate accepted appointment: $appointmentId');
          return;
        }

        // Add to processed set
        processedAppointments.add('accepted-$appointmentId');
      }

      // Save to persistent storage
      await _saveAppointmentToStorage(data, 'accepted');

      if (onAppointmentAccepted != null) {
        onAppointmentAccepted!(data);
      }
    });

    socket.on('appointment_declined', (data) async {
      print('Appointment declined: $data');

      // Check if we've already processed this appointment
      final appointmentId = data['appointmentId']?.toString() ?? '';
      if (appointmentId.isNotEmpty) {
        if (processedAppointments.contains('declined-$appointmentId')) {
          print('Skipping duplicate declined appointment: $appointmentId');
          return;
        }

        // Add to processed set
        processedAppointments.add('declined-$appointmentId');
      }

      // Save to persistent storage
      await _saveAppointmentToStorage(data, 'declined');

      if (onAppointmentDeclined != null) {
        onAppointmentDeclined!(data);
      }
    });

    // Error handling
    socket.on('error', (data) {
      print('Server error: $data');
      if (onError != null) {
        onError!(data['message'] ?? 'Unknown server error');
      }
    });

    // Confirmation events
    socket.on('appointment_requested', (data) async {
      print('Appointment request confirmation: $data');

      // If the request was successful and not a duplicate, save it
      if (data['success'] == true && data['duplicate'] != true) {
        // Create appointment data structure
        final appointmentData = {
          'appointmentId': data['appointmentId'],
          'status': 'pending',
          'requested_time':
              DateTime.now()
                  .toIso8601String(), // This should come from the server
          'doctor_id': '', // This should be filled with actual data
          'mother_id': userId,
          'mother_name': '', // This should be filled with actual data
          'payment_status': 'unpaid',
        };

        // Save to persistent storage
        await _saveAppointmentToStorage(appointmentData, 'pending');
      }
    });

    // Handle appointment history response
    socket.on('appointment_history', (data) {
      print('Received appointment history: $data');

      if (data != null && data['appointments'] != null) {
        List<dynamic> appointments = data['appointments'];
        List<Map<String, dynamic>> typedAppointments =
            appointments
                .map((appt) => Map<String, dynamic>.from(appt))
                .toList();

        // Process and save appointments by status
        _processAppointmentHistory(typedAppointments);

        // Notify listeners
        if (onAppointmentHistoryReceived != null) {
          onAppointmentHistoryReceived!(typedAppointments);
        }
      }
    });
  }

  // Process and save appointment history by status
  void _processAppointmentHistory(
    List<Map<String, dynamic>> appointments,
  ) async {
    List<Map<String, dynamic>> pendingAppointments = [];
    List<Map<String, dynamic>> acceptedAppointments = [];
    List<Map<String, dynamic>> declinedAppointments = [];

    for (var appointment in appointments) {
      String status = appointment['status'] ?? 'pending';

      if (status == 'pending') {
        pendingAppointments.add(appointment);
      } else if (status == 'accepted') {
        acceptedAppointments.add(appointment);
      } else if (status == 'declined') {
        declinedAppointments.add(appointment);
      }
    }

    // Save to storage by status
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (pendingAppointments.isNotEmpty) {
      await prefs.setString(
        PENDING_APPOINTMENTS_KEY,
        jsonEncode(pendingAppointments),
      );
    }

    if (acceptedAppointments.isNotEmpty) {
      await prefs.setString(
        ACCEPTED_APPOINTMENTS_KEY,
        jsonEncode(acceptedAppointments),
      );
    }

    if (declinedAppointments.isNotEmpty) {
      await prefs.setString(
        DECLINED_APPOINTMENTS_KEY,
        jsonEncode(declinedAppointments),
      );
    }
  }

  // Save appointment to SharedPreferences
  Future<void> _saveAppointmentToStorage(
    Map<String, dynamic> appointment,
    String status,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String storageKey;

      // Determine which storage key to use based on status
      if (status == 'pending') {
        storageKey = PENDING_APPOINTMENTS_KEY;
      } else if (status == 'accepted') {
        storageKey = ACCEPTED_APPOINTMENTS_KEY;
      } else if (status == 'declined') {
        storageKey = DECLINED_APPOINTMENTS_KEY;
      } else {
        print('Invalid status: $status');
        return;
      }

      // Get existing appointments
      List<Map<String, dynamic>> appointments = [];
      String? existingData = prefs.getString(storageKey);

      if (existingData != null && existingData.isNotEmpty) {
        List<dynamic> decoded = jsonDecode(existingData);
        appointments =
            decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      // Check if appointment already exists
      bool exists = appointments.any(
        (a) => a['appointmentId'] == appointment['appointmentId'],
      );

      if (!exists) {
        // Add new appointment
        appointments.add(appointment);

        // Save back to storage
        await prefs.setString(storageKey, jsonEncode(appointments));
        print(
          'Saved appointment to $storageKey: ${appointment['appointmentId']}',
        );
      }
    } catch (e) {
      print('Error saving appointment to storage: $e');
    }
  }

  // Load appointments from SharedPreferences
  Future<Map<String, List<Map<String, dynamic>>>>
  loadAppointmentsFromStorage() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Initialize result map
      Map<String, List<Map<String, dynamic>>> result = {
        'pending': [],
        'accepted': [],
        'declined': [],
      };

      // Load pending appointments
      String? pendingData = prefs.getString(PENDING_APPOINTMENTS_KEY);
      if (pendingData != null && pendingData.isNotEmpty) {
        List<dynamic> decoded = jsonDecode(pendingData);
        result['pending'] =
            decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      // Load accepted appointments
      String? acceptedData = prefs.getString(ACCEPTED_APPOINTMENTS_KEY);
      if (acceptedData != null && acceptedData.isNotEmpty) {
        List<dynamic> decoded = jsonDecode(acceptedData);
        result['accepted'] =
            decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      // Load declined appointments
      String? declinedData = prefs.getString(DECLINED_APPOINTMENTS_KEY);
      if (declinedData != null && declinedData.isNotEmpty) {
        List<dynamic> decoded = jsonDecode(declinedData);
        result['declined'] =
            decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      print(
        'Loaded appointments from storage: ${result['pending']!.length} pending, ${result['accepted']!.length} accepted, ${result['declined']!.length} declined',
      );
      return result;
    } catch (e) {
      print('Error loading appointments from storage: $e');
      return {'pending': [], 'accepted': [], 'declined': []};
    }
  }

  // Remove appointment from storage
  Future<void> removeAppointmentFromStorage(
    String appointmentId,
    String status,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String storageKey;

      // Determine which storage key to use based on status
      if (status == 'pending') {
        storageKey = PENDING_APPOINTMENTS_KEY;
      } else if (status == 'accepted') {
        storageKey = ACCEPTED_APPOINTMENTS_KEY;
      } else if (status == 'declined') {
        storageKey = DECLINED_APPOINTMENTS_KEY;
      } else {
        print('Invalid status: $status');
        return;
      }

      // Get existing appointments
      String? existingData = prefs.getString(storageKey);
      if (existingData != null && existingData.isNotEmpty) {
        List<dynamic> decoded = jsonDecode(existingData);
        List<Map<String, dynamic>> appointments =
            decoded.map((item) => Map<String, dynamic>.from(item)).toList();

        // Remove the appointment
        appointments.removeWhere((a) => a['appointmentId'] == appointmentId);

        // Save back to storage
        await prefs.setString(storageKey, jsonEncode(appointments));
        print('Removed appointment from $storageKey: $appointmentId');
      }
    } catch (e) {
      print('Error removing appointment from storage: $e');
    }
  }

  // Update the ping timer to be more frequent
  void startPingTimer() {
    // Cancel any existing timer
    pingTimer?.cancel();

    // Start a new ping timer - more frequent to keep connection alive
    pingTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (isConnected) {
        print('Sending ping to keep connection alive');
        socket.emit('ping', {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        print('Not connected, attempting to reconnect in ping timer');
        socket.connect();
      }
    });
  }

  // Improve the reconnection logic with exponential backoff
  void attemptReconnect(String userId) {
    // Cancel any existing reconnect timer
    reconnectTimer?.cancel();

    if (reconnectAttempts >= maxReconnectAttempts) {
      print('Maximum reconnection attempts reached, creating new connection');
      // Instead of giving up, try to create a completely new connection
      connect(userId);
      return;
    }

    reconnectAttempts++;
    print(
      'Attempting to reconnect ($reconnectAttempts/$maxReconnectAttempts)...',
    );

    // Use exponential backoff with a maximum delay
    final delay = min(1000 * pow(1.5, reconnectAttempts), 10000);

    // Set up reconnect timer with increasing backoff
    reconnectTimer = Timer(Duration(milliseconds: delay.toInt()), () {
      if (!isConnected) {
        print('Trying to reconnect...');
        socket.connect();
      }
    });
  }

  // Request appointment history from server
  void requestAppointmentHistory(String userId, String userType) {
    if (!isConnected) {
      print('Cannot request history: Socket not connected');
      return;
    }

    print('Requesting appointment history for $userType: $userId');
    // Fix: Pass the data as a single Map instead of multiple arguments
    socket.emit('get_appointment_history', {
      'userId': userId,
      'userType': userType,
    });
  }

  // Send appointment request via socket with deduplication
  void requestAppointment({
    required String doctorId,
    required String motherId,
    required String motherName,
    required String requestedTime,
  }) {
    if (!isConnected) {
      print('Cannot send request: Socket not connected');
      if (onError != null) {
        onError!('Cannot send request: Socket not connected');
      }
      return;
    }

    // Create a unique key for this request to prevent duplicates
    final requestKey = '$doctorId-$motherId-$requestedTime';

    // Check if we've already sent this request
    if (processedAppointments.contains(requestKey)) {
      print('Skipping duplicate appointment request: $requestKey');
      return;
    }

    // Add to processed set
    processedAppointments.add(requestKey);

    print('Sending appointment request:');
    print('doctor_id: $doctorId');
    print('mother_id: $motherId');
    print('mother_name: $motherName');
    print('requested_time: $requestedTime');

    socket.emit('request_appointment', {
      'doctor_id': doctorId,
      'mother_id': motherId,
      'mother_name': motherName,
      'requested_time': requestedTime,
    });
  }

  void acceptAppointment(String appointmentId) {
    if (!isConnected) {
      print('Cannot accept: Socket not connected');
      return;
    }

    print('Accepting appointment: $appointmentId');
    socket.emit('accept_appointment', {'appointmentId': appointmentId});
  }

  void declineAppointment(String appointmentId) {
    if (!isConnected) {
      print('Cannot decline: Socket not connected');
      return;
    }

    print('Declining appointment: $appointmentId');
    socket.emit('decline_appointment', {'appointmentId': appointmentId});
  }

  // Update the disconnect method to be more robust
  void disconnect() {
    pingTimer?.cancel();
    reconnectTimer?.cancel();

    try {
      socket.disconnect();
      socket.dispose();
      isConnected = false;
      print('Socket disconnected and disposed');
    } catch (e) {
      print('Error during socket disconnect: $e');
    }

    // Clear the processed appointments set when disconnecting
    processedAppointments.clear();
  }
}
