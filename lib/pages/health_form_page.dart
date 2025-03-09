import 'package:adde/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:supabase_flutter/supabase_flutter.dart';

class MotherFormPage extends StatefulWidget {
  final String? email;
  const MotherFormPage({super.key, required this.email});

  @override
  State<MotherFormPage> createState() => _MotherFormPageState();
}

class _MotherFormPageState extends State<MotherFormPage> {
  String selectedGender = "Female";
  double selectedAge = 18;
  String selectedWeightUnit = "kg";
  List<String> selectedHealthConditions = [];
  DateTime? pregnancyStartDate;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bloodPressureController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController healthInfoController = TextEditingController();

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
        selectedHealthConditions.isEmpty ||
        pregnancyStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all required fields!")),
      );
      return;
    }

    final pregnancyDuration = calculatePregnancyDuration(pregnancyStartDate!);

    final formData = {
      "email": widget.email,
      "full_name": nameController.text,
      "gender": selectedGender,
      "age": selectedAge.toInt(),
      "weight": double.tryParse(weightController.text) ?? 0.0,
      "weight_unit": selectedWeightUnit,
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
            builder: (context) => HomePage(email: widget.email),
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
            color: Colors.black87,
          ),
        ),
      ),
      body: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name Input Field
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 20),

                // Gender Selection Section
                Text(
                  "Select Gender",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                RadioListTile<String>(
                  title: Text("Male", style: TextStyle(color: Colors.black87)),
                  value: "Male",
                  groupValue: selectedGender,
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value!;
                    });
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                RadioListTile<String>(
                  title: Text(
                    "Female",
                    style: TextStyle(color: Colors.black87),
                  ),
                  value: "Female",
                  groupValue: selectedGender,
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value!;
                    });
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 5),
                Text(
                  "Selected Gender: $selectedGender",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                // Age Selection Section
                Text(
                  "Select Your Age",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Slider(
                  value: selectedAge,
                  min: 18,
                  max: 100,
                  divisions: 82,
                  label: selectedAge.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      selectedAge = value;
                    });
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveColor: Colors.white,
                ),
                const SizedBox(height: 5),
                Text(
                  "Selected Age: ${selectedAge.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                // Blood Pressure Section
                Text(
                  "Enter Your Blood Pressure",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bloodPressureController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: "Blood Pressure (e.g., 120/80)",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 20),

                // Weight Section
                Text(
                  "Enter Your Weight",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Weight",
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: selectedWeightUnit,
                      items:
                          ["kg", "lbs"].map<DropdownMenuItem<String>>((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedWeightUnit = newValue!;
                        });
                      },
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
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _selectPregnancyStartDate(context),
                  child: AbsorbPointer(
                    child: TextField(
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
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
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
                      color: Colors.black87,
                    ),
                  ),
                const SizedBox(height: 20),

                // Health Conditions Selection
                Text(
                  "Select Any Applicable Health Conditions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
                          selectedColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                        );
                      }).toList(),
                ),
                if (selectedHealthConditions.contains("Other"))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Describe Your Health Issue",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: healthInfoController,
                        maxLines: null, // Allows multi-line input
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText:
                              "Describe your health background or issues here...",
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
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
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
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
    );
  }
}
