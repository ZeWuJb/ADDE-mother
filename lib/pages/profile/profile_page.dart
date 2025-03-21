import 'dart:convert';
import 'dart:io';
import 'package:adde/pages/profile/profile_edit_page.dart';
import 'package:adde/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  String? profileImageBase64;
  final supabase = Supabase.instance.client;
  final _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No user logged in')));
        return;
      }

      final response =
          await supabase
              .from('mothers')
              .select()
              .eq('user_id', user.id)
              .single();

      setState(() {
        nameController.text = response['full_name'] ?? '';
        ageController.text = response['age']?.toString() ?? '';
        profileImageBase64 = response['profile_image'];
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final updates = {
        'email': user.email,
        'user_id': user.id,
        'full_name': nameController.text,
        'age': int.tryParse(ageController.text) ?? 0,
        if (profileImageBase64 != null) 'profile_url': profileImageBase64,
      };

      await supabase.from('mothers').upsert(updates);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> pickImage(ImageSource source) async {
    PermissionStatus status;

    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
    } else {
      // Handle gallery permissions based on Android version
      final androidVersion =
          Platform.isAndroid ? await _getAndroidVersion() : 0;
      if (Platform.isAndroid && androidVersion >= 33) {
        status = await Permission.photos.request(); // Android 13+
      } else {
        status = await Permission.storage.request(); // Older Android
      }
    }

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${source == ImageSource.camera ? 'Camera' : 'Gallery'} permission denied',
          ),
        ),
      );
      if (status.isPermanentlyDenied) {
        openAppSettings(); // Guide user to settings if permanently denied
      }
      return;
    }

    try {
      final pickedImage = await _picker.pickImage(
        source: source,
        maxHeight: 300,
        maxWidth: 300,
      );
      if (pickedImage == null) return;

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

      final base64Image = base64Encode(bytes);
      setState(() {
        profileImageBase64 = base64Image;
      });
      await _updateProfile();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<int> _getAndroidVersion() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.version.sdkInt ?? 0;
      }
    } catch (e) {
      print('Error getting Android version: $e');
    }
    return 0; // Default to 0 for non-Android or error cases
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final email = supabase.auth.currentUser?.email ?? 'No email';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
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
                                              leading: const Icon(
                                                Icons.photo_library,
                                              ),
                                              title: const Text(
                                                'Choose from Gallery',
                                              ),
                                              onTap: () {
                                                pickImage(ImageSource.gallery);
                                                Navigator.pop(context);
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(
                                                Icons.camera_alt,
                                              ),
                                              title: const Text('Take a Photo'),
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
                                        ? MemoryImage(
                                          base64Decode(profileImageBase64!),
                                        )
                                        : const AssetImage('assets/user.png')
                                            as ImageProvider,
                                backgroundColor:
                                    Theme.of(context).colorScheme.surface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              email,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium!.copyWith(
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
                                Icon(
                                  Icons.edit,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
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
                          'Theme Mode',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        trailing: Switch(
                          value: themeProvider.themeMode == ThemeMode.dark,
                          onChanged:
                              (value) => themeProvider.toggleTheme(value),
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
