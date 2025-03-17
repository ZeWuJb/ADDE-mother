import 'dart:convert';
import 'dart:io';
import 'package:adde/pages/profile/profile_edit_page.dart';
import 'package:adde/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController healthInfoController = TextEditingController();
  String? profileImageBase64; // Store Base64 encoded image
  final supabase = Supabase.instance.client;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // Load the profile data from Supabase (assuming user is logged in)
  Future<void> _loadProfileData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        // Retrieve profile data from Supabase
        final response = await Supabase.instance.client
            .from('mothers')
            .select()
            .eq('user_id', user.id)
            .limit(1);

        if (response.isNotEmpty) {
          final profile = response[0]; // Access the first element of the list
          setState(() {
            nameController.text = profile['name'] ?? '';
            ageController.text = profile['age']?.toString() ?? '';
            healthInfoController.text = profile['health_info'] ?? '';
            profileImageBase64 = profile['profile_image']; // Load Base64 image
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    }
  }

  // Update profile in Supabase
  Future<void> _updateProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        await Supabase.instance.client.from('mothers').upsert({
          'user_id': user.id,
          'name': nameController.text,
          'age': int.tryParse(ageController.text),
          'health_info': healthInfoController.text,
          'profile_image': profileImageBase64, // Save Base64 image
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    }
  }

  Future<void> pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      var status = await Permission.camera.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Camera permission denied')));
        return;
      }
    } else if (source == ImageSource.gallery) {
      var status = await Permission.photos.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gallery access denied')));
        return;
      }
    }

    final pickedImage = await _picker.pickImage(source: source);
    if (pickedImage != null) {
      final file = File(pickedImage.path);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      setState(() {
        profileImageBase64 = base64Image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final email = supabase.auth.currentUser?.email.toString();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings page
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap:
                          () => showModalBottomSheet(
                            context: context,
                            builder:
                                (context) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.photo_library),
                                      title: const Text("Choose from Gallery"),
                                      onTap: () {
                                        pickImage(ImageSource.gallery);
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.camera_alt),
                                      title: const Text("Take a Photo"),
                                      onTap: () {
                                        pickImage(ImageSource.camera);
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                          ),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundImage:
                            profileImageBase64 != null
                                ? MemoryImage(base64Decode(profileImageBase64!))
                                    as ImageProvider
                                : AssetImage('assets/user.png'),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProfileEditPage(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 16),
                        Text(
                          "Edit Profile",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 2,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(
                  themeProvider.themeMode == ThemeMode.light
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: Text(
                  "Theme Mode",
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                trailing: Switch(
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
