import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
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

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('info1')
          .select('*')
          .eq('is_favorite', true)
          .order('created_at', ascending: false);

      setState(() {
        _favoriteEntries = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading favorites: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorite Entries',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchFavoriteEntries,
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
                    Colors.white,
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
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onSurface,
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No favorite entries yet.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
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
                                    entry['title'] ?? 'No Title',
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
                                    duration: const Duration(milliseconds: 300),
                                    child: Text(
                                      entry['text'] ?? 'No Content',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
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
                                        isExpanded ? "Less >>>" : "More >>>",
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Metadata
                                  Text(
                                    'Posted At: ${entry['created_at'].toString().split('T').first}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
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
    );
  }
}
