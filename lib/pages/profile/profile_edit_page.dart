import 'dart:convert';
import 'dart:io';
import 'package:adde/l10n/arb/app_localizations.dart';
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
  String? selectedWeightUnit;
  String? selectedHeightUnit;
  DateTime? pregnancyStartDate;

  List<String> selectedHealthConditions = [];
  final List<String> healthConditionsKeys = [
    "diabetes",
    "hypertension",
    "asthma",
    "heartDisease",
    "thyroidIssues",
    "other",
  ];
  final List<String> genderOptions = [
    "female",
    "male",
    "other",
  ]; // For dropdown

  final supabase = Supabase.instance.client;
  final _picker = ImagePicker();
  bool _isLoading = false;
  bool _isImageLoading = false; // Separate loading state for image picking
  final _formKey = GlobalKey<FormState>(); // For form validation

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // Add this helper method inside _ProfileEditPageState
  String _getLocalizedGender(String gender, AppLocalizations l10n) {
    switch (gender) {
      case 'female':
        return l10n.genderFemale;
      case 'male':
        return l10n.genderMale;
      case 'other':
        return l10n.genderOther;
      default:
        return l10n.genderFemale; // Fallback to "Female"
    }
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
          healthInfoController.text =
              response['health_info'] ?? ''; // Load additional health info
          profileImageBase64 = response['profile_url'];
          selectedGender =
              genderOptions.contains(response['gender'])
                  ? response['gender']
                  : "female"; // Default to "female" if invalid
          selectedWeightUnit =
              ["kg", "lbs"].contains(response['weight_unit'])
                  ? response['weight_unit']
                  : "kg"; // Default to "kg" if invalid
          selectedHeightUnit =
              ["cm", "ft"].contains(response['height_unit'])
                  ? response['height_unit']
                  : "cm"; // Default to "cm" if invalid
          pregnancyStartDate = DateTime.tryParse(
            response['pregnancy_start_date'] ?? '',
          );

          final healthConditionsData = response['health_conditions'];
          if (healthConditionsData != null) {
            if (healthConditionsData is String) {
              selectedHealthConditions =
                  healthConditionsData
                      .split(',')
                      .where((condition) => condition.isNotEmpty)
                      .toList();
            } else if (healthConditionsData is List<dynamic>) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.failedToLoadProfile(e.toString()),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if form validation fails
    }

    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception(AppLocalizations.of(context)!.noUserLoggedIn);
      }

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
        'health_conditions': selectedHealthConditions,
        'health_info': healthInfoController.text, // Save additional health info
      };

      await supabase.from('mothers').upsert(updates);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.profileUpdatedSuccessfully,
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      String errorMessage;
      if (e is PostgrestException) {
        errorMessage = e.message; // More specific error from Supabase
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error: Please check your internet connection.';
      } else {
        errorMessage = e.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.failedToUpdateProfile(errorMessage),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> pickImage(ImageSource source) async {
    PermissionStatus status;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isImageLoading = true); // Show loading for image picking

    try {
      if (source == ImageSource.camera) {
        status = await Permission.camera.request();
      } else {
        final androidVersion =
            Platform.isAndroid ? await _getAndroidVersion() : 0;
        if (Platform.isAndroid && androidVersion >= 33) {
          status = await Permission.photos.request();
        } else {
          status = await Permission.storage.request();
        }
      }

      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              source == ImageSource.camera
                  ? l10n.cameraPermissionDenied
                  : l10n.galleryPermissionDenied,
            ),
          ),
        );
        if (status.isPermanentlyDenied) openAppSettings();
        return;
      }

      final pickedImage = await _picker.pickImage(
        source: source,
        maxHeight: 300, // Consider moving to theme or constant
        maxWidth: 300,
      );
      if (pickedImage == null) return;

      final file = File(pickedImage.path);
      final bytes = await file.readAsBytes();
      if (bytes.length > 500 * 1024) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.imageTooLarge)));
        return;
      }

      final base64Image = base64Encode(bytes);
      setState(() {
        profileImageBase64 = base64Image;
      });
    } catch (e) {
      String errorMessage = e.toString();
      if (e.toString().contains('camera_unavailable')) {
        errorMessage = 'Camera is not available on this device.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorPickingImage(errorMessage))),
      );
    } finally {
      setState(() => _isImageLoading = false);
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

  Future<void> _selectPregnancyStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: pregnancyStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != pregnancyStartDate) {
      setState(() {
        pregnancyStartDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final email = supabase.auth.currentUser?.email ?? '';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfileTitle),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            color: Theme.of(context).appBarTheme.foregroundColor,
            onPressed: () {},
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
              : Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              isDarkMode
                                  ? [
                                    Theme.of(context).colorScheme.surface,
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                  ]
                                  : [
                                    Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.2),
                                    Theme.of(context).colorScheme.surface,
                                  ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder:
                                          (context) => Wrap(
                                            children: [
                                              ListTile(
                                                leading: Icon(
                                                  Icons.photo_library,
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                ),
                                                title: Text(
                                                  l10n.chooseFromGallery,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .onSurface,
                                                      ),
                                                ),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  pickImage(
                                                    ImageSource.gallery,
                                                  );
                                                },
                                              ),
                                              ListTile(
                                                leading: Icon(
                                                  Icons.camera_alt,
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                ),
                                                title: Text(
                                                  l10n.takePhoto,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .onSurface,
                                                      ),
                                                ),
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
                                                  base64Decode(
                                                    profileImageBase64!,
                                                  ),
                                                )
                                                : const AssetImage(
                                                      'assets/user.png',
                                                    )
                                                    as ImageProvider,
                                        backgroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                        child:
                                            profileImageBase64 == null
                                                ? Icon(
                                                  Icons.person,
                                                  size: 80,
                                                  color:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                )
                                                : null,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.edit,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isImageLoading)
                                  CircularProgressIndicator(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              email,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.personalInformation,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: l10n.fullNameLabel,
                              border:
                                  Theme.of(context).inputDecorationTheme.border,
                              focusedBorder:
                                  Theme.of(
                                    context,
                                  ).inputDecorationTheme.focusedBorder,
                              filled: true,
                              fillColor:
                                  Theme.of(
                                    context,
                                  ).inputDecorationTheme.fillColor,
                              labelStyle: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                              prefixIcon: Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          DropdownButtonFormField<String>(
                            value: selectedGender,
                            items:
                                genderOptions.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      _getLocalizedGender(
                                        value,
                                        l10n,
                                      ), // Use the helper method
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                      ),
                                    ),
                                  );
                                }).toList(),
                            onChanged:
                                (newValue) =>
                                    setState(() => selectedGender = newValue!),
                            decoration: InputDecoration(
                              labelText:
                                  l10n.genderLabel, // Add a new localized label (to be added to lang_en.arb)
                              border:
                                  Theme.of(context).inputDecorationTheme.border,
                              focusedBorder:
                                  Theme.of(
                                    context,
                                  ).inputDecorationTheme.focusedBorder,
                              filled: true,
                              fillColor:
                                  Theme.of(
                                    context,
                                  ).inputDecorationTheme.fillColor,
                              labelStyle: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                              prefixIcon: Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            validator: (value) {
                              if (value == null) {
                                return l10n
                                    .genderSelectionError; // Add a new localized error message (to be added to lang_en.arb)
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.ageLabel,
                              border:
                                  Theme.of(context).inputDecorationTheme.border,
                              focusedBorder:
                                  Theme.of(
                                    context,
                                  ).inputDecorationTheme.focusedBorder,
                              filled: true,
                              fillColor:
                                  Theme.of(
                                    context,
                                  ).inputDecorationTheme.fillColor,
                              labelStyle: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                              prefixIcon: Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your age';
                              }
                              final age = int.tryParse(value);
                              if (age == null || age < 0 || age > 120) {
                                return 'Please enter a valid age (0-120)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: weightController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: l10n.weightLabel,
                                    border:
                                        Theme.of(
                                          context,
                                        ).inputDecorationTheme.border,
                                    focusedBorder:
                                        Theme.of(
                                          context,
                                        ).inputDecorationTheme.focusedBorder,
                                    filled: true,
                                    fillColor:
                                        Theme.of(
                                          context,
                                        ).inputDecorationTheme.fillColor,
                                    labelStyle: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.scale,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your weight';
                                    }
                                    final weight = double.tryParse(value);
                                    if (weight == null || weight <= 0) {
                                      return 'Please enter a valid weight';
                                    }
                                    return null;
                                  },
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
                                          l10n.weightUnit(value),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.copyWith(
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
                                underline: Container(
                                  height: 2,
                                  color: Theme.of(context).colorScheme.outline,
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
                                    labelText: l10n.heightLabel,
                                    border:
                                        Theme.of(
                                          context,
                                        ).inputDecorationTheme.border,
                                    focusedBorder:
                                        Theme.of(
                                          context,
                                        ).inputDecorationTheme.focusedBorder,
                                    filled: true,
                                    fillColor:
                                        Theme.of(
                                          context,
                                        ).inputDecorationTheme.fillColor,
                                    labelStyle: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.height,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your height';
                                    }
                                    final height = double.tryParse(value);
                                    if (height == null || height <= 0) {
                                      return 'Please enter a valid height';
                                    }
                                    return null;
                                  },
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
                                          l10n.heightUnit(value),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.copyWith(
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
                                underline: Container(
                                  height: 2,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: bloodPressureController,
                            decoration: InputDecoration(
                              labelText: l10n.bloodPressureLabel,
                              border:
                                  Theme.of(context).inputDecorationTheme.border,
                              focusedBorder:
                                  Theme.of(
                                    context,
                                  ).inputDecorationTheme.focusedBorder,
                              filled: true,
                              fillColor:
                                  Theme.of(
                                    context,
                                  ).inputDecorationTheme.fillColor,
                              labelStyle: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                              prefixIcon: Icon(
                                Icons.monitor_heart,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your blood pressure';
                              }
                              if (!RegExp(
                                r'^\d{2,3}/\d{2,3}$',
                              ).hasMatch(value)) {
                                return 'Please enter a valid blood pressure (e.g., 120/80)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Pregnancy Start Date',
                              border:
                                  Theme.of(context).inputDecorationTheme.border,
                              focusedBorder:
                                  Theme.of(
                                    context,
                                  ).inputDecorationTheme.focusedBorder,
                              filled: true,
                              fillColor:
                                  Theme.of(
                                    context,
                                  ).inputDecorationTheme.fillColor,
                              labelStyle: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                              prefixIcon: Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            controller: TextEditingController(
                              text:
                                  pregnancyStartDate != null
                                      ? DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(pregnancyStartDate!)
                                      : '',
                            ),
                            onTap: () => _selectPregnancyStartDate(context),
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            validator: (value) {
                              if (pregnancyStartDate == null) {
                                return 'Please select your pregnancy start date';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          Text(
                            l10n.selectHealthConditions,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children:
                                healthConditionsKeys.map((conditionKey) {
                                  return FilterChip(
                                    label: Text(
                                      l10n.healthCondition(conditionKey),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                      ),
                                    ),
                                    selected: selectedHealthConditions.contains(
                                      conditionKey,
                                    ),
                                    onSelected: (isSelected) {
                                      setState(() {
                                        if (isSelected) {
                                          selectedHealthConditions.add(
                                            conditionKey,
                                          );
                                        } else {
                                          selectedHealthConditions.remove(
                                            conditionKey,
                                          );
                                        }
                                      });
                                    },
                                    selectedColor: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.3),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.surface,
                                    checkmarkColor:
                                        Theme.of(context).colorScheme.onSurface,
                                  );
                                }).toList(),
                          ),
                          if (selectedHealthConditions.contains("other"))
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                Text(
                                  l10n.describeHealthIssue,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: healthInfoController,
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    border:
                                        Theme.of(
                                          context,
                                        ).inputDecorationTheme.border,
                                    focusedBorder:
                                        Theme.of(
                                          context,
                                        ).inputDecorationTheme.focusedBorder,
                                    hintText: l10n.healthIssueHint,
                                    filled: true,
                                    fillColor:
                                        Theme.of(
                                          context,
                                        ).inputDecorationTheme.fillColor,
                                    hintStyle: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.health_and_safety,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please describe your health issue';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _updateProfile,
                            style: Theme.of(
                              context,
                            ).elevatedButtonTheme.style?.copyWith(
                              minimumSize: WidgetStateProperty.all(
                                const Size(double.infinity, 50),
                              ),
                            ),
                            child: Text(
                              l10n.saveProfileButton,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    bloodPressureController.dispose();
    healthInfoController.dispose();
    super.dispose();
  }
}
