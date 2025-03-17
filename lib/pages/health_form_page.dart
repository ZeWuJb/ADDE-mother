import 'package:adde/pages/bottom_page_navigation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MotherFormPage extends StatefulWidget {
  final String? email;
  final String? user_id;
  const MotherFormPage({super.key, required this.email, required this.user_id});

  @override
  State<MotherFormPage> createState() => _MotherFormPageState();
}

class _MotherFormPageState extends State<MotherFormPage> {
  String selectedGender = "Female";
  String selectedHeightUnit = "cm";
  int selectedAge = 18;
  String selectedWeightUnit = "kg";
  List<String> selectedHealthConditions = [];
  DateTime? pregnancyStartDate;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bloodPressureController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController healthInfoController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  // Predefined list of common health conditions
  final List<String> healthConditions = [
    "Diabetes",
    "Hypertension",
    "Asthma",
    "Heart Disease",
    "Thyroid Issues",
    "Other",
  ];

  Map<String, int> calculatePregnancyDuration(DateTime startDate) {
    final now = DateTime.now();
    final difference = now.difference(startDate);
    final weeks = (difference.inDays / 7).floor();
    final days = difference.inDays % 7;
    return {"weeks": weeks, "days": days};
  }

  Future<void> _selectPregnancyStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 280)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != pregnancyStartDate) {
      setState(() {
        pregnancyStartDate = picked;
      });
    }
  }

  formSubmit() async {
    if (nameController.text.isEmpty ||
        bloodPressureController.text.isEmpty ||
        weightController.text.isEmpty ||
        heightController.text.isEmpty ||
        pregnancyStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all required fields!")),
      );
      return;
    }
    final pregnancyDuration = calculatePregnancyDuration(pregnancyStartDate!);
    final formData = {
      "user_id": widget.user_id,
      "email": widget.email,
      "full_name": nameController.text,
      "gender": selectedGender,
      "age": selectedAge.toInt(),
      "weight": double.tryParse(weightController.text) ?? 0.0,
      "weight_unit": selectedWeightUnit,
      "height": double.tryParse(heightController.text) ?? 0.0,
      "height_unit": selectedHeightUnit,
      "blood_pressure": bloodPressureController.text,
      "health_conditions": selectedHealthConditions,
      "pregnancy_start_date": DateFormat(
        'yyyy-MM-dd',
      ).format(pregnancyStartDate!),
      "pregnancy_weeks": pregnancyDuration["weeks"],
      "pregnancy_days": pregnancyDuration["days"],
    };
    try {
      final response =
          await Supabase.instance.client
              .from('mothers')
              .insert(formData)
              .select();
      if (response.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Form Submitted Successfully!")));
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) =>
                    HomePage(email: widget.email, user_id: widget.user_id!),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to submit form. Please try again.")),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("An error occurred: $error")));
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    bloodPressureController.dispose();
    weightController.dispose();
    heightController.dispose();
    healthInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Welcome, Please Fill Below Form!",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
      ),
      body: Container(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Input Field
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
                  const SizedBox(height: 20),

                  // Gender Selection Section
                  Text(
                    "Select Gender",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text(
                            "Male",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          value: "Male",
                          groupValue: selectedGender,
                          onChanged:
                              (value) =>
                                  setState(() => selectedGender = value!),
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text(
                            "Female",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          value: "Female",
                          groupValue: selectedGender,
                          onChanged:
                              (value) =>
                                  setState(() => selectedGender = value!),
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Age Selection Section
                  Text(
                    "Select Your Age",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: selectedAge.toDouble(),
                    min: 18,
                    max: 100,
                    divisions: 82,
                    label: selectedAge.round().toString(),
                    onChanged:
                        (value) => setState(() => selectedAge = value as int),
                    activeColor: Theme.of(context).colorScheme.primary,
                    inactiveColor: Colors.grey[300],
                  ),
                  Text(
                    "Selected Age: ${selectedAge.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Height Section
                  Text(
                    "Enter Your Height",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 20),

                  // Blood Pressure Section
                  Text(
                    "Enter Your Blood Pressure",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: bloodPressureController,
                    keyboardType: TextInputType.text,
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
                  const SizedBox(height: 20),

                  // Weight Section
                  Text(
                    "Enter Your Weight",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 20),

                  // Pregnancy Start Date Section
                  Text(
                    "When Did You Become Pregnant?",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _selectPregnancyStartDate(context),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: TextEditingController(
                          text:
                              pregnancyStartDate != null
                                  ? DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(pregnancyStartDate!)
                                  : "Not set",
                        ),
                        decoration: InputDecoration(
                          labelText: "Pregnancy Start Date",
                          suffixIcon: Icon(
                            Icons.calendar_today,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (pregnancyStartDate != null)
                    Text(
                      "Pregnancy Duration: ${calculatePregnancyDuration(pregnancyStartDate!)['weeks']} weeks and ${calculatePregnancyDuration(pregnancyStartDate!)['days']} days",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Health Conditions Selection
                  Text(
                    "Select Any Applicable Health Conditions",
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
                            label: Text(
                              condition,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
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

                  // Submit Button
                  ElevatedButton(
                    onPressed: formSubmit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Submit",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
