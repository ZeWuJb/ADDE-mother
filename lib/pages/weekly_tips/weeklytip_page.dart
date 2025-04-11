import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeeklyTipPage extends StatefulWidget {
  final Map<String, dynamic> initialTip;
  final DateTime pregnancyStartDate;

  const WeeklyTipPage({
    super.key,
    required this.initialTip,
    required this.pregnancyStartDate,
  });

  @override
  _WeeklyTipPageState createState() => _WeeklyTipPageState();
}

class _WeeklyTipPageState extends State<WeeklyTipPage> {
  List<Map<String, dynamic>> _allTips = [];
  bool _isLoading = true;
  int _currentWeek = 0;

  @override
  void initState() {
    super.initState();
    _calculateCurrentWeek();
    _loadAllTips();
  }

  void _calculateCurrentWeek() {
    final currentDate = DateTime.now();
    final difference = currentDate.difference(widget.pregnancyStartDate);
    final totalDays = difference.inDays;
    setState(() {
      _currentWeek = (totalDays / 7).floor();
    });
  }

  Future<void> _loadAllTips() async {
    try {
      final response = await Supabase.instance.client
          .from('weekly_tips')
          .select()
          .order('week', ascending: true);

      List<Map<String, dynamic>> tips = List<Map<String, dynamic>>.from(
        response,
      );

      // Reorder tips: put the current week's tip at the top
      final currentWeekTipIndex = tips.indexWhere(
        (tip) => tip['week'] == _currentWeek,
      );
      if (currentWeekTipIndex != -1) {
        final currentWeekTip = tips.removeAt(currentWeekTipIndex);
        tips.insert(0, currentWeekTip);
      }

      setState(() {
        _allTips = tips;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load tips: $e')));
      setState(() => _isLoading = false);
    }
  }

  String _cleanBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) return '';

    if (base64String.contains(',')) {
      return base64String.split(',')[1];
    }
    return base64String;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weekly Tips"),
        backgroundColor: Colors.pink.shade300,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _allTips.isEmpty
              ? const Center(
                child: Text(
                  "No tips available",
                  style: TextStyle(color: Colors.grey),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _allTips.length,
                itemBuilder: (context, index) {
                  final tip = _allTips[index];
                  final isCurrentWeek = tip['week'] == _currentWeek;

                  return Card(
                    elevation: isCurrentWeek ? 8 : 4,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (tip['image'] != null && tip['image'].isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                base64Decode(_cleanBase64(tip['image'])),
                                width: double.infinity,
                                height: 150,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Text(
                                    'Image failed to load',
                                    style: TextStyle(color: Colors.red),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 10),
                          Text(
                            "Week ${tip['week']}${isCurrentWeek ? ' (Current)' : ''}",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:
                                  isCurrentWeek
                                      ? Colors.pink
                                      : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            tip['title'] ?? 'No Title',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            tip['description'] ?? 'No Description',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
