import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingPage extends StatefulWidget {
  final String doctorId;
  const BookingPage({super.key, required this.doctorId});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _dateSelected = false;
  bool _timeSelected = false;
  List<DateTime> _availableTimes = [];
  Set<DateTime> _availableDates = {};
  final supabase = Supabase.instance.client;
  int? _currentTimeIndex;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialAvailability();
  }

  Future<void> _fetchInitialAvailability() async {
    final firstDay = DateTime.now();
    final lastDay = DateTime(firstDay.year + 10, 12, 31);
    await _fetchAvailableDates(firstDay, lastDay);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: Colors.teal,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildTableCalendar(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 35),
                  child: Center(
                    child: Text(
                      'Select Consultation Time',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_availableTimes.isEmpty && _dateSelected)
            SliverToBoxAdapter(
              child: _buildMessage('No available times for this date.'),
            )
          else
            SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final time = _availableTimes[index];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _currentTimeIndex = index;
                      _timeSelected = true;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            _currentTimeIndex == index
                                ? Colors.teal
                                : Colors.black,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      color: _currentTimeIndex == index ? Colors.teal : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      DateFormat('h:mm a').format(time),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _currentTimeIndex == index ? Colors.white : null,
                      ),
                    ),
                  ),
                );
              }, childCount: _availableTimes.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.7,
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed:
                        _dateSelected && _timeSelected ? sendRequest : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: const Text(
                      'Make Appointment',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const PaymentPage(appointmentId: null),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: const Text(
                      'Pay',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCalendar() {
    return TableCalendar(
      focusedDay: _focusedDay,
      firstDay: DateTime.now(),
      lastDay: DateTime.now().add(const Duration(days: 3650)),
      calendarFormat: _calendarFormat,
      currentDay: _selectedDay,
      rowHeight: 48,
      calendarStyle: const CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.teal,
          shape: BoxShape.circle,
        ),
      ),
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
      enabledDayPredicate: (day) => _availableDates.contains(day),
      onDaySelected: _onDaySelected,
      onPageChanged: (focusedDay) {
        setState(() => _focusedDay = focusedDay);
        final start = DateTime(focusedDay.year, focusedDay.month, 1);
        final end = DateTime(focusedDay.year, focusedDay.month + 1, 0);
        _fetchAvailableDates(start, end);
      },
    );
  }

  Widget _buildMessage(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
      alignment: Alignment.center,
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Future<void> _fetchAvailableDates(DateTime start, DateTime end) async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('doctor_availability')
          .select('availability')
          .eq('doctor_id', widget.doctorId);

      final dates = <DateTime>{};
      for (var entry in response) {
        final availability = Map<String, dynamic>.from(entry['availability']);
        final dateList = List<Map<String, dynamic>>.from(
          availability['dates'] ?? [],
        );

        for (var dateEntry in dateList) {
          final dateString = dateEntry['date'] as String?;
          if (dateString != null) {
            final date = DateFormat('yyyy-MM-dd').parse(dateString);
            if (date.isAfter(start.subtract(const Duration(days: 1))) &&
                date.isBefore(end.add(const Duration(days: 1)))) {
              dates.add(date);
            }
          }
        }
      }
      setState(() => _availableDates = dates);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching availability: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    if (!mounted) return;
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _dateSelected = true;
      _availableTimes = [];
      _currentTimeIndex = null;
      _timeSelected = false;
    });
    await _fetchAvailableTimes(selectedDay);
  }

  Future<void> _fetchAvailableTimes(DateTime date) async {
    setState(() => _isLoading = true);
    try {
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      final response = await supabase
          .from('doctor_availability')
          .select('availability')
          .eq('doctor_id', widget.doctorId);

      final timeSet = <DateTime>{};
      for (var entry in response) {
        final availability = Map<String, dynamic>.from(entry['availability']);
        final dateList = List<Map<String, dynamic>>.from(
          availability['dates'] ?? [],
        );

        for (var dateEntry in dateList) {
          if (dateEntry['date'] == dateString) {
            final slots = List<String>.from(dateEntry['slots'] ?? []);

            for (var slot in slots) {
              final time = _parseTime(slot);
              if (time != null) {
                timeSet.add(
                  DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  ),
                );
              }
            }
          }
        }
      }
      setState(() => _availableTimes = timeSet.toList()..sort());
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching available times: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  TimeOfDay? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      debugPrint('Invalid time format: $timeStr');
    }
    return null;
  }

  Future<void> sendRequest() async {
    if (!_dateSelected || !_timeSelected) return;
    setState(() => _isLoading = true);
    try {
      final selectedTime = _availableTimes[_currentTimeIndex!];
      await supabase.from('appointments').insert({
        'doctor_id': widget.doctorId,
        'user_id': supabase.auth.currentUser!.id,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDay),
        'time': DateFormat('h:mm a').format(selectedTime),
        'status': 'pending',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent successfully')),
      );
      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $error')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key, required appointmentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.teal,
      ),
      body: const Center(child: Text('Payment Page')),
    );
  }
}
