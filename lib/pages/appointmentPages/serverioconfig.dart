// serverioconfig.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;
  bool isConnected = false;

  void connect(String doctorId) {
    // Make sure doctorId is not null or empty
    if (doctorId.isEmpty) {
      print('Error: doctorId is empty');
      return;
    }

    print('Connecting socket for doctor_id: $doctorId');

    socket = IO.io('http://192.168.127.180:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('Connected to socket server');
      isConnected = true;

      // Join the room with the doctorId
      socket.emit('join', doctorId);
      print('Joined room: $doctorId');
    });

    socket.onDisconnect((_) {
      print('Disconnected from socket server');
      isConnected = false;
    });

    socket.onConnectError((error) {
      print('Connection error: $error');
      isConnected = false;
    });
  }

  void acceptAppointment(String appointmentId) {
    print('Accepting appointment: $appointmentId');
    socket.emit('accept_appointment', {'appointmentId': appointmentId});
  }

  void declineAppointment(String appointmentId) {
    print('Declining appointment: $appointmentId');
    socket.emit('decline_appointment', {'appointmentId': appointmentId});
  }

  void disconnect() {
    socket.disconnect();
    isConnected = false;
    print('Socket disconnected');
  }
}