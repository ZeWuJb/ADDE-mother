import 'dart:convert';
import 'dart:io';
import 'package:adde/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart';

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

  String? profileImageBase64;
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response =
            await supabase
                .from('mothers')
                .select()
                .eq('user_id', user.id)
                .single();

        setState(() {
          nameController.text = response['full_name'] ?? '';
          ageController.text = response['age']?.toString() ?? '';
          weightController.text = response['weight']?.toString() ?? '';
          heightController.text = response['height']?.toString() ?? '';
          bloodPressureController.text = response['blood_pressure'] ?? '';
          profileImageBase64 = response['profile_url'];
          selectedGender = response['gender'] ?? "female";
          selectedAge = response['age'];
          selectedWeightUnit = response['weight_unit'];
          selectedHeightUnit = response['height_unit'];
          pregnancyStartDate = DateTime.tryParse(
            response['pregnancy_start_date'] ?? '',
          );

          // Handle health_conditions dynamically
          final healthConditionsData = response['health_conditions'];
          if (healthConditionsData != null) {
            if (healthConditionsData is String) {
              // If it's a comma-separated string
              selectedHealthConditions =
                  healthConditionsData
                      .split(',')
                      .where((condition) => condition.isNotEmpty)
                      .toList();
            } else if (healthConditionsData is List<dynamic>) {
              // If it's a list/array from Supabase
              selectedHealthConditions =
                  healthConditionsData
                      .map((condition) => condition.toString())
                      .where((condition) => condition.isNotEmpty)
                      .toList();
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final updates = {
        "email": user.email,
        'user_id': user.id,
        'full_name': nameController.text,
        'gender': selectedGender,
        'age': int.tryParse(ageController.text) ?? 0,
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
        'health_conditions': selectedHealthConditions, // Save as List
      };

      await supabase.from('mothers').upsert(updates);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Updated Successfully!")),
      );
      Navigator.pop(context);
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
      if (status.isPermanentlyDenied) openAppSettings();
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
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final email = supabase.auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.2),
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
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder:
                                    (context) => Wrap(
                                      children: [
                                        ListTile(
                                          leading: const Icon(
                                            Icons.photo_library,
                                          ),
                                          title: const Text(
                                            "Choose from Gallery",
                                          ),
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
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
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
                                  child:
                                      profileImageBase64 == null
                                          ? const Icon(
                                            Icons.person,
                                            size: 80,
                                            color: Colors.grey,
                                          )
                                          : null,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            email,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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
                                  fillColor:
                                      Theme.of(context).colorScheme.surface,
                                  prefixIcon: Icon(
                                    Icons.scale,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged:
                                  (newValue) => setState(
                                    () => selectedWeightUnit = newValue!,
                                  ),
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
                                  fillColor:
                                      Theme.of(context).colorScheme.surface,
                                  prefixIcon: Icon(
                                    Icons.height,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged:
                                  (newValue) => setState(
                                    () => selectedHeightUnit = newValue!,
                                  ),
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
                                        selectedHealthConditions.remove(
                                          condition,
                                        );
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
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
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
                                  fillColor:
                                      Theme.of(context).colorScheme.surface,
                                  prefixIcon: Icon(
                                    Icons.health_and_safety,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
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
