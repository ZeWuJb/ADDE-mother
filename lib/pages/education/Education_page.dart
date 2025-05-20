import 'dart:convert';
import 'dart:typed_data';
import 'package:adde/pages/education/favorite_edu_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:intl/intl.dart';

class EducationPage extends StatefulWidget {
  const EducationPage({super.key});

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = false;
  bool _hasError = false;
  Set<int> expandedEntries = {};

  @override
  void initState() {
    super.initState();
    // Fetch will be triggered in didChangeDependencies to ensure context is ready
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch entries only if not already loading or fetched
    if (!_isLoading && _entries.isEmpty && !_hasError) {
      _fetchDiaryEntries();
    }
  }

  /// Function to fetch diary entries with timeout and improved error handling
  Future<void> _fetchDiaryEntries() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).languageCode;
    final titleField = currentLocale == 'am' ? 'title_am' : 'title_en';
    final textField = currentLocale == 'am' ? 'text_am' : 'text_en';

    try {
      final supabase = Supabase.instance.client;

      // Check authentication status
      if (supabase.auth.currentUser == null) {
        throw Exception('User is not authenticated');
      }

      print('Fetching entries from info1 for locale: $currentLocale');
      final response = await supabase
          .from('info1')
          .select('id, $titleField, $textField, image, is_favorite, created_at')
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));

      print('Supabase response: $response');

      if (!mounted) return;

      setState(() {
        _entries =
            List<Map<String, dynamic>>.from(response).map((entry) {
              return {
                'id': entry['id'],
                'title': entry[titleField] ?? l10n.noTitle,
                'text': entry[textField] ?? l10n.noContent,
                'image': entry['image'],
                'is_favorite': entry['is_favorite'] ?? false,
                'created_at':
                    entry['created_at'] ?? DateTime.now().toIso8601String(),
              };
            }).toList();
      });
    } catch (e) {
      print('Error fetching entries: $e');
      if (!mounted) return;

      setState(() {
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorLoadingEntries(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: l10n.retryButton,
            onPressed: _fetchDiaryEntries,
            textColor: Theme.of(context).colorScheme.onError,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Toggle favorite status for an entry
  Future<void> _toggleFavorite(String entryId, bool currentStatus) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final supabase = Supabase.instance.client;
      final newStatus = !currentStatus;

      print('Toggling favorite for entry $entryId to $newStatus');
      await supabase
          .from('info1')
          .update({'is_favorite': newStatus})
          .eq('id', entryId)
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;

      setState(() {
        final entryIndex = _entries.indexWhere(
          (entry) => entry['id'] == entryId,
        );
        if (entryIndex != -1) {
          _entries[entryIndex]['is_favorite'] = newStatus;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus ? l10n.addedToFavorites : l10n.removedFromFavorites,
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      print('Error toggling favorite: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorUpdatingFavorite(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text(
            l10n.pageTitleHealthArticle,
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
              onPressed: _fetchDiaryEntries,
            ),
            IconButton(
              icon: Icon(
                Icons.favorite,
                color:
                    Theme.of(context).brightness == Brightness.light
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FavoritesPage(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            // Gradient Background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      Theme.of(context).colorScheme.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Main Content
            RefreshIndicator(
              onRefresh: _fetchDiaryEntries,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                      : _hasError
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.errorLoadingEntries(
                                'Failed to load articles',
                              ),
                              style: TextStyle(
                                fontSize: 18,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _fetchDiaryEntries,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              ),
                              child: Text(l10n.retryButton),
                            ),
                          ],
                        ),
                      )
                      : _entries.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 60,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.noDiaryEntries,
                              style: TextStyle(
                                fontSize: 18,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: _entries.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          bool isExpanded = expandedEntries.contains(index);
                          bool isFavorite = entry['is_favorite'] ?? false;

                          Uint8List? imageBytes;
                          if (entry['image'] != null &&
                              entry['image'].isNotEmpty) {
                            String imageStr = entry['image'];
                            if (imageStr.startsWith('data:image')) {
                              final base64Str = imageStr.split(',').last;
                              try {
                                imageBytes = base64Decode(base64Str);
                              } catch (e) {
                                print("Image decoding error: $e");
                              }
                            }
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: Theme.of(context).cardTheme.shape,
                            elevation: Theme.of(context).cardTheme.elevation,
                            color: Theme.of(context).cardTheme.color,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    expandedEntries.remove(index);
                                  } else {
                                    expandedEntries.add(index);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 10),
                                    // Image Section
                                    if (imageBytes != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          imageBytes,
                                          width: double.infinity,
                                          height: 200,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            entry['title'] ?? l10n.noTitle,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isFavorite
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color:
                                                isFavorite
                                                    ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                          ),
                                          onPressed:
                                              () => _toggleFavorite(
                                                entry['id'].toString(),
                                                isFavorite,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    // Expandable Text Section
                                    AnimatedSize(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: Text(
                                        entry['text'] ?? l10n.noContent,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: isExpanded ? null : 3,
                                        overflow:
                                            isExpanded
                                                ? TextOverflow.visible
                                                : TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // "More" Button
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          setState(() {
                                            if (isExpanded) {
                                              expandedEntries.remove(index);
                                            } else {
                                              expandedEntries.add(index);
                                            }
                                          });
                                        },
                                        child: Text(
                                          isExpanded
                                              ? l10n.lessButton
                                              : l10n.moreButton,
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Metadata
                                    Text(
                                      l10n.postedAt(
                                        DateFormat.yMMMd(
                                          Localizations.localeOf(
                                            context,
                                          ).languageCode,
                                        ).format(
                                          DateTime.parse(entry['created_at']),
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
