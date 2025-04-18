import 'dart:convert';
import 'dart:typed_data';

import 'package:adde/pages/education/favorite_edu_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EducationPage extends StatefulWidget {
  const EducationPage({super.key});

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = false;
  Set<int> expandedEntries = {}; // Track expanded items

  @override
  void initState() {
    super.initState();
    _fetchDiaryEntries();
  }

  /// Function to fetch diary entries
  Future<void> _fetchDiaryEntries() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('info1')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _entries = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading entries: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  
  Future<void> _toggleFavorite(String entryId, bool currentStatus) async {
    try {
      final supabase = Supabase.instance.client;
      final newStatus = !currentStatus;

      await supabase
          .from('info1')
          .update({'is_favorite': newStatus})
          .eq('id', entryId);

     
      setState(() {
        final entryIndex = _entries.indexWhere(
          (entry) => entry['id'] == entryId,
        );
        if (entryIndex != -1) {
          _entries[entryIndex]['is_favorite'] = newStatus;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating favorite: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Day',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchDiaryEntries,
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesPage()),
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
            onRefresh: _fetchDiaryEntries,
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onSurface,
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No diary entries yet.',
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
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
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
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color:
                                              isFavorite
                                                  ? Colors.red
                                                  : Colors.grey,
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
