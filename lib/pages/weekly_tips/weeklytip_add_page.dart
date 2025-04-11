import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeeklyTipAddPage extends StatefulWidget {
  const WeeklyTipAddPage({super.key});

  @override
  _WeeklyTipAddPageState createState() => _WeeklyTipAddPageState();
}

class _WeeklyTipAddPageState extends State<WeeklyTipAddPage> {
  final TextEditingController _weekController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final supabase = Supabase.instance.client;
  final _picker = ImagePicker();
  String? _imageBase64;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
      maxHeight: 300,
      maxWidth: 300,
    );
    if (pickedImage != null) {
      final file = File(pickedImage.path);
      final bytes = await file.readAsBytes();
      if (bytes.length > 500 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image too large, please select a smaller one'),
          ),
        );
        return;
      }
      setState(() {
        _imageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _addWeeklyTip() async {
    setState(() => _isLoading = true);
    try {
      final week = int.tryParse(_weekController.text) ?? 0;
      final title = _titleController.text;
      final description = _descriptionController.text;

      if (week <= 0 || title.isEmpty || description.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields correctly')),
        );
        return;
      }

      await supabase.from('weekly_tips').insert({
        'week': week,
        'title': title,
        'description': description,
        'image': _imageBase64,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weekly tip added successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add tip: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Weekly Tip"),
        backgroundColor: Colors.pink.shade300,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                          image:
                              _imageBase64 != null
                                  ? DecorationImage(
                                    image: MemoryImage(
                                      base64Decode(_imageBase64!),
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                        ),
                        child:
                            _imageBase64 == null
                                ? const Center(
                                  child: Icon(
                                    Icons.add_a_photo,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _weekController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Week Number",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: "Title",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _addWeeklyTip,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.pink.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Add Tip",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
