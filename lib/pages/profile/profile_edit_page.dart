import 'dart:convert';
import 'dart:io';
import 'package:adde/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

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
  final TextEditingController healthInfoController = TextEditingController();

  String? profileImageBase64; // Store Base64 encoded image
  String? selectedGender;
  int? selectedAge;
  String? selectedWeightUnit;
  String? selectedHeightUnit;
  DateTime? pregnancyStartDate;

  List<String> selectedHealthConditions = [];
  final List<String> healthConditions = [
    "Diabetes",
    "Hypertension",
    "Asthma",
    "Heart Disease",
    "Thyroid Issues",
    "Other",
  ];

  final supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  /// Load the profile data from Supabase (assuming user is logged in)
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
            profileImageBase64 = profile['profile_image']; // Load Base64 image
            selectedGender = profile['gender'] ?? "female";
            selectedAge = profile['age'];
            selectedWeightUnit = profile['weight_unit'];
            selectedHeightUnit = profile['height_unit'];
            pregnancyStartDate = DateTime.tryParse(
              profile['pregnancy_start_date'] ?? '',
            );

            // Split health_conditions into a list
            if (profile['health_conditions'] != null &&
                profile['health_conditions'].isNotEmpty) {
              selectedHealthConditions =
                  profile['health_conditions']
                      .split(',')
                      .where((condition) => condition.isNotEmpty)
                      .toList();
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    }
  }

  /// Update profile in Supabase
  Future<void> _updateProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Convert health conditions back to a comma-separated string
        final healthConditionsString = selectedHealthConditions;

        final int? parsedAge = int.tryParse(ageController.text);

        await Supabase.instance.client
            .from('mothers')
            .update({
              'user_id': user.id,
              'full_name': nameController.text,
              'gender': selectedGender,
              'age': parsedAge,
              'weight': double.tryParse(weightController.text) ?? 0.0,
              'weight_unit': selectedWeightUnit,
              'height': double.tryParse(heightController.text) ?? 0.0,
              'height_unit': selectedHeightUnit,
              'blood_pressure': bloodPressureController.text,
              'profile_url': profileImageBase64,
              'pregnancy_start_date':
                  pregnancyStartDate != null
                      ? DateFormat('yyyy-MM-dd').format(pregnancyStartDate!)
                      : null,
              'health_conditions':
                  healthConditionsString, // Save as comma-separated string
            })
            .eq("user_id", user.id);
        print(selectedAge);
        print(ageController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    }
  }

  /// Pick an image from the camera or gallery
  Future<void> pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      var status = await Permission.camera.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied')),
        );
        return;
      }
    } else if (source == ImageSource.gallery) {
      var status = await Permission.photos.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gallery access denied')));
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
        title: Text(
          "Edit Profile",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Navigate to settings page
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
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture Section
                Center(
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder:
                            (context) => Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text("Choose from Gallery"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    pickImage(ImageSource.gallery);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text("Take a Photo"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    pickImage(ImageSource.camera);
                                  },
                                ),
                              ],
                            ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 70,
                      backgroundImage:
                          profileImageBase64 != null
                              ? MemoryImage(base64Decode(profileImageBase64!))
                                  as ImageProvider
                              : const AssetImage('assets/user.png'),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      child:
                          profileImageBase64 == null
                              ? const Icon(
                                Icons.person,
                                size: 80,
                                color: Colors.grey,
                              )
                              : null,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    email ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Input Fields
                Text(
                  "Personal Information",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    prefixIcon: Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Age",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    prefixIcon: Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Weight",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          prefixIcon: Icon(
                            Icons.scale,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: selectedWeightUnit,
                      items:
                          ["kg", "lbs"].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            );
                          }).toList(),
                      onChanged:
                          (newValue) =>
                              setState(() => selectedWeightUnit = newValue!),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: heightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Height",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          prefixIcon: Icon(
                            Icons.height,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: selectedHeightUnit,
                      items:
                          ["cm", "ft"].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            );
                          }).toList(),
                      onChanged:
                          (newValue) =>
                              setState(() => selectedHeightUnit = newValue!),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: bloodPressureController,
                  decoration: InputDecoration(
                    labelText: "Blood Pressure (e.g., 120/80)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    prefixIcon: Icon(
                      Icons.monitor_heart,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Health Conditions Selection
                Text(
                  "Select Applicable Health Conditions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      healthConditions.map((condition) {
                        return FilterChip(
                          label: Text(condition),
                          selected: selectedHealthConditions.contains(
                            condition,
                          ),
                          onSelected: (isSelected) {
                            setState(() {
                              if (isSelected) {
                                selectedHealthConditions.add(condition);
                              } else {
                                selectedHealthConditions.remove(condition);
                              }
                            });
                          },
                          selectedColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                        );
                      }).toList(),
                ),
                if (selectedHealthConditions.contains("Other"))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        "Describe Your Health Issue",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: healthInfoController,
                        maxLines: null,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          hintText:
                              "Describe your health background or issues here...",
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          prefixIcon: Icon(
                            Icons.health_and_safety,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                // Save Button
                ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Save Profile",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
