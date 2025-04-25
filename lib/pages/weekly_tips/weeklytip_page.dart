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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Weekly Tips"),
        backgroundColor:
            Theme.of(
              context,
            ).appBarTheme.backgroundColor, // #ff8fab (light), black (dark)
        foregroundColor:
            Theme.of(
              context,
            ).appBarTheme.foregroundColor, // black87 (light), white (dark)
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color:
                      Theme.of(
                        context,
                      ).colorScheme.primary, // #fb6f92 (light), white (dark)
                ),
              )
              : _allTips.isEmpty
              ? Center(
                child: Text(
                  "No tips available",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant, // black54 (light), white70 (dark)
                  ),
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
                    shape:
                        Theme.of(
                          context,
                        ).cardTheme.shape, // RoundedRectangleBorder
                    color:
                        Theme.of(
                          context,
                        ).cardTheme.color, // #FDE2E4 (light), black54 (dark)
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
                                  return Text(
                                    'Image failed to load',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.error, // redAccent
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 10),
                          Text(
                            "Week ${tip['week']}${isCurrentWeek ? ' (Current)' : ''}",
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color:
                                  isCurrentWeek
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primary // #fb6f92 (light), white (dark)
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant, // black54 (light), white70 (dark)
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            tip['title'] ?? 'No Title',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color:
                                  Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant, // black54 (light), white70 (dark)
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            tip['description'] ?? 'No Description',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant, // black54 (light), white70 (dark)
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
