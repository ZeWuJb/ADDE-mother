import 'dart:convert';
import 'dart:io';
import 'package:adde/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart'; // for formatting the date

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController bloodPressureController = TextEditingController();
  final TextEditingController healthConditionsController =
      TextEditingController();
  String? profileImageBase64; // Store Base64 encoded image
  String? selectedGender;
  int? selectedAge;
  String? selectedWeightUnit;
  String? selectedHeightUnit;
  DateTime? pregnancyStartDate;
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
            nameController.text = profile['full_name'] ?? '';
            ageController.text = profile['age']?.toString() ?? '';
            weightController.text = profile['weight']?.toString() ?? '';
            heightController.text = profile['height']?.toString() ?? '';
            bloodPressureController.text = profile['blood_pressure'] ?? '';
            // healthConditionsController.text =
            //     profile['health_conditions'] ?? '';
            profileImageBase64 = profile['profile_image']; // Load Base64 image
            selectedGender = profile['gender'] ?? "female";
            selectedAge = profile['age'];
            selectedWeightUnit = profile['weight_unit'];
            selectedHeightUnit = profile['height_unit'];
            pregnancyStartDate = DateTime.tryParse(
              profile['pregnancy_start_date'] ?? '',
            );
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
    print(selectedGender);
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        await Supabase.instance.client
            .from('mothers')
            .update({
              'user_id': user.id,
              'full_name': nameController.text,
              'gender': selectedGender,
              'age': selectedAge,
              'weight': double.tryParse(weightController.text) ?? 0.0,
              'weight_unit': selectedWeightUnit,
              'height': double.tryParse(heightController.text) ?? 0.0,
              'height_unit': selectedHeightUnit,
              'blood_pressure': bloodPressureController.text,
              //'health_conditions': healthConditionsController.text,
              'pregnancy_start_date':
                  pregnancyStartDate != null
                      ? DateFormat('yyyy-MM-dd').format(pregnancyStartDate!)
                      : null,
            })
            .eq("id", user.id);

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
        backgroundColor: Theme.of(context).colorScheme.tertiary,
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
                      onTap: () => pickImage(ImageSource.gallery),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundImage:
                            profileImageBase64 != null
                                ? MemoryImage(base64Decode(profileImageBase64!))
                                    as ImageProvider
                                : AssetImage('assets/user.png'),
                      ),
                    ),
                    Text(
                      email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit Profile"),
              ),
              Container(
                width: double.infinity,
                height: 2,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(labelText: "Age"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(labelText: "Weight (kg)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: heightController,
                decoration: const InputDecoration(labelText: "Height (cm)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: bloodPressureController,
                decoration: const InputDecoration(labelText: "Blood Pressure"),
              ),
              TextField(
                controller: healthConditionsController,
                decoration: const InputDecoration(
                  labelText: "Health Conditions",
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile, // Save profile data
                child: const Text("Save Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
