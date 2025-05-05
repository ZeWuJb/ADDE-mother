import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:adde/l10n/arb/app_localizations.dart'; // Import AppLocalizations
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>> _favoriteEntries = [];
  bool _isLoading = false;
  Set<int> expandedEntries = {};

  @override
  void initState() {
    super.initState();
    _fetchFavoriteEntries();
  }

  /// Function to fetch favorite diary entries
  Future<void> _fetchFavoriteEntries() async {
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!; // Access AppLocalizations
    final currentLocale = Localizations.localeOf(context).languageCode;
    final titleField = currentLocale == 'am' ? 'title_am' : 'title_en';
    final textField = currentLocale == 'am' ? 'text_am' : 'text_en';

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('info1')
          .select(
            'id, created_at, image, day, time, is_favorite, type, $titleField, $textField',
          )
          .eq('is_favorite', true)
          .order('created_at', ascending: false);

      setState(() {
        _favoriteEntries =
            List<Map<String, dynamic>>.from(response).map((entry) {
              return {
                'id': entry['id'],
                'created_at': entry['created_at'],
                'image': entry['image'],
                'day': entry['day'],
                'time': entry['time'],
                'is_favorite': entry['is_favorite'],
                'type': entry['type'],
                'title': entry[titleField] ?? l10n.noTitle,
                'text': entry[textField] ?? l10n.noContent,
              };
            }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorLoadingEntries(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Access AppLocalizations

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text(
            l10n.favoriteEntriesTitle, // Localized AppBar title
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
              onPressed: _fetchFavoriteEntries,
              tooltip: l10n.refreshButton, // Localized tooltip
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
              onRefresh: _fetchFavoriteEntries,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                      : _favoriteEntries.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 60,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.noFavoriteEntries, // Localized empty state message
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
                        itemCount: _favoriteEntries.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final entry = _favoriteEntries[index];
                          bool isExpanded = expandedEntries.contains(index);

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
                                    Text(
                                      entry['title'], // Already localized in _fetchFavoriteEntries
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    // Expandable Text Section
                                    AnimatedSize(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: Text(
                                        entry['text'], // Already localized in _fetchFavoriteEntries
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
                                              ? l10n.showLess
                                              : l10n
                                                  .showMore, // Localized button text
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
                                      '${l10n.postedAtLabel}: ${entry['created_at'].toString().split('T').first}', // Localized label
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
}
