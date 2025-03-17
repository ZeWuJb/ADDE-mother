import 'dart:convert';
import 'dart:typed_data';

import 'package:adde/auth/login_page.dart';
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
      final supabase = SupabaseClient(
        'https://hilkusrmkszlkttwgpso.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpbGt1c3Jta3N6bGt0dHdncHNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA1NjI0OTksImV4cCI6MjA1NjEzODQ5OX0.T9s-UiT8-FDVBD6Oy5l0icSzbD5Dmyu1rlexWgMbNaU',
      );
      final response = await supabase
          .from('info')
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

  /// Function to delete a diary entry
  Future<void> _deleteDiaryEntry(String entryId) async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase.from('info').delete().eq('id', entryId);

      if (response == null) {
        throw Exception('No response from Supabase');
      }

      _fetchDiaryEntries(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting entry: $e')));
    }
  }

  /// Show delete confirmation dialog
  void _showDeleteDialog(String entryId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Entry'),
            content: Text('Are you sure you want to delete this entry?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteDiaryEntry(entryId);
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Day',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchDiaryEntries,
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => LoginPage()));
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
                          SizedBox(height: 10),
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
                      padding: EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
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
                          margin: EdgeInsets.symmetric(vertical: 8),
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
                            onLongPress:
                                () => _showDeleteDialog(entry['id'].toString()),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        entry['day'] ?? 'No Date',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        entry['time'] ?? 'No Time',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),

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

                                  SizedBox(height: 10),
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
                                  SizedBox(height: 5),

                                  // Expandable Text Section
                                  AnimatedSize(
                                    duration: Duration(milliseconds: 300),
                                    child: Text(
                                      entry['text'] ?? 'No Content',
                                      style: TextStyle(
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
                                    'Created At: ${entry['created_at'].toString().split('T').first}',
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
