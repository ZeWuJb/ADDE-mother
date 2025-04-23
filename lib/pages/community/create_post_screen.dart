import 'dart:io';
import 'package:adde/pages/community/post_model.dart';
import 'package:adde/pages/community/post_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key, this.post});

  final Post? post;

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  String? motherId;
  String? fullName;
  bool _isLoading = true;
  File? _imageFile;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _contentController.text = widget.post!.content;
    }
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please log in')));
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final response =
          await Supabase.instance.client
              .from('mothers')
              .select('full_name')
              .eq('user_id', user.id)
              .single();
      setState(() {
        motherId = user.id;
        fullName = response['full_name']?.toString() ?? 'Unknown';
        _isLoading = false;
        print('CreatePostScreen motherId: $motherId');
      });
    } catch (e) {
      print('Error fetching user data: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching user data: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final size = await File(pickedFile.path).length();
        if (size > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image must be under 5MB')),
          );
          return;
        }
        setState(() {
          _imageFile = File(pickedFile.path);
          print('Picked image: ${pickedFile.path}');
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _submit() async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);

    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter content')));
      return;
    }

    if (motherId == null || fullName == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User data not loaded')));
      return;
    }

    try {
      if (widget.post == null) {
        await postProvider.createPost(
          motherId!,
          fullName!,
          '', // Title removed
          _contentController.text,
          imageFile: _imageFile,
        );
        print('Created post for motherId: $motherId');
      } else {
        await postProvider.updatePost(
          widget.post!.id,
          '', // Title removed
          _contentController.text,
          imageFile: _imageFile,
        );
        print('Updated post ID: ${widget.post!.id}');
      }
      Navigator.pop(context);
    } catch (e) {
      print('Error saving post: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving post: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder:
          (_, controller) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Text(
                                widget.post == null
                                    ? 'Create Post'
                                    : 'Edit Post',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: Colors.black),
                              ),
                              TextButton(
                                onPressed: _submit,
                                child: Text(
                                  widget.post == null ? 'Post' : 'Update',
                                  style: GoogleFonts.poppins(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            controller: controller,
                            padding: const EdgeInsets.all(16),
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.secondary,
                                    child: Text(
                                      fullName?.isNotEmpty == true
                                          ? fullName![0]
                                          : '?',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    fullName ?? 'Unknown',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(color: Colors.black),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _contentController,
                                decoration: InputDecoration(
                                  hintText: "What's on your mind?",
                                  hintStyle: GoogleFonts.roboto(
                                    color: Colors.grey[500],
                                  ),
                                  border: InputBorder.none,
                                ),
                                maxLines: null,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.black87),
                              ),
                              const SizedBox(height: 16),
                              if (_imageFile != null)
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _imageFile!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.cancel,
                                          color: Colors.white,
                                        ),
                                        onPressed:
                                            () => setState(
                                              () => _imageFile = null,
                                            ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else if (widget.post?.imageUrl != null)
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        widget.post!.imageUrl!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) =>
                                                const Icon(Icons.broken_image),
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.cancel,
                                          color: Colors.white,
                                        ),
                                        onPressed:
                                            () => setState(
                                              () => _imageFile = null,
                                            ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.image,
                                      color: Color(0xFFa1c4f7),
                                    ),
                                    onPressed: _pickImage,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
          ),
    );
  }
}
