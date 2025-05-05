import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
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
  State<WeeklyTipPage> createState() => _WeeklyTipPageState();
}

class _WeeklyTipPageState extends State<WeeklyTipPage> {
  List<Map<String, dynamic>> _tips = [];
  bool _isLoading = true;
  int _currentWeek = 0;

  @override
  void initState() {
    super.initState();
    print('Initial Tip on Init: ${widget.initialTip}');
    _calculateCurrentWeek();
    _loadTips();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-fetch tips if the locale changes
    final currentLocale = Localizations.localeOf(context).languageCode;
    if (_tips.isNotEmpty && _tips[0]['locale'] != currentLocale) {
      _loadTips();
    }
  }

  void _calculateCurrentWeek() {
    final currentDate = DateTime.now();
    final difference = currentDate.difference(widget.pregnancyStartDate);
    final totalDays = difference.inDays;
    setState(() {
      _currentWeek = (totalDays / 7).floor();
    });
  }

  Future<void> _loadTips() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    final currentLocale = Localizations.localeOf(context).languageCode;
    final titleField = currentLocale == 'am' ? 'title_am' : 'title_en';
    final descriptionField =
        currentLocale == 'am' ? 'description_am' : 'description_en';
    print(
      'Locale: $currentLocale, Title Field: $titleField, Description Field: $descriptionField',
    );

    try {
      print('Fetching all tips from database');
      final response = await Supabase.instance.client
          .from('weekly_tips')
          .select('id, week, $titleField, $descriptionField, image')
          .order('week', ascending: true);
      print('Supabase response: $response');

      final initialTipId = widget.initialTip['id'];
      final allTips =
          List<Map<String, dynamic>>.from(response).map((tip) {
            return {
              'id': tip['id'],
              'week': tip['week'] ?? 0,
              'title': tip[titleField] ?? tip['title_en'] ?? l10n.noTitle,
              'description':
                  tip[descriptionField] ??
                  tip['description_en'] ??
                  l10n.noContent,
              'image': tip['image'],
              'locale': currentLocale,
            };
          }).toList();

      setState(() {
        if (initialTipId != null) {
          // Find the tip matching the initialTip's id
          final matchedTip = allTips.firstWhere(
            (tip) => tip['id'] == initialTipId,
            orElse:
                () =>
                    Map<String, dynamic>.from(widget.initialTip)
                      ..['title'] ??= l10n.noTitle
                      ..['week'] ??= 0
                      ..['locale'] = currentLocale,
          );
          // Create the tips list with the matched tip first, followed by others
          _tips = [
            matchedTip,
            ...allTips.where((tip) => tip['id'] != initialTipId),
          ];
        } else {
          // If no initialTip id, just use all tips
          _tips = allTips;
        }
        print('Set _tips: $_tips');
      });
    } catch (e) {
      print('Error loading tips: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorLoadingEntries(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: l10n.retryButton,
            onPressed: _loadTips,
            textColor: Theme.of(context).colorScheme.onError,
          ),
        ),
      );
      // Fallback to initialTip if provided
      setState(() {
        final initialTip = Map<String, dynamic>.from(widget.initialTip);
        initialTip['title'] ??= l10n.noTitle;
        initialTip['week'] ??= 0;
        initialTip['locale'] = currentLocale;
        _tips = [initialTip];
        print('Fell back to initialTip: $_tips');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.pageTitleWeeklyTip,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color:
                Theme.of(context).brightness == Brightness.light
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor:
            Theme.of(context).brightness == Brightness.light
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onPrimary,
        elevation: Theme.of(context).appBarTheme.elevation,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color:
                  Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary,
            ),
            onPressed: _loadTips,
            tooltip: l10n.retryButton,
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
              : _tips.isEmpty
              ? Center(
                child: Text(
                  l10n.noTipsYet,
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _tips.length,
                itemBuilder: (context, index) {
                  final tip = _tips[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation:
                        index == 0
                            ? 4
                            : 2, // Slightly higher elevation for the first tip
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (tip['image'] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                base64Decode(tip['image']),
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: 200,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.1),
                                    child: Icon(
                                      Icons.image,
                                      size: 60,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (tip['image'] != null) const SizedBox(height: 16),
                          Text(
                            l10n.weekLabel(tip['week'] ?? 0),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tip['title'] ?? l10n.noTitle,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            tip['description'] ?? l10n.noContent,
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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
