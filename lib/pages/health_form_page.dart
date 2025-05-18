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
  final TextEditingController heightController = TextEditingController();
  final TextEditingController healthInfoController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _bloodPressureFocus = FocusNode();
  final FocusNode _weightFocus = FocusNode();
  final FocusNode _heightFocus = FocusNode();
  final FocusNode _healthInfoFocus = FocusNode();

  // Predefined list of common health conditions
  static const List<String> healthConditions = [
    "Diabetes",
    "Hypertension",
    "Asthma",
    "Heart Disease",
    "Thyroid Issues",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0); // Ensure top is visible on load
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    bloodPressureController.dispose();
    weightController.dispose();
    heightController.dispose();
    healthInfoController.dispose();
    _scrollController.dispose();
    _nameFocus.dispose();
    _bloodPressureFocus.dispose();
    _weightFocus.dispose();
    _heightFocus.dispose();
    _healthInfoFocus.dispose();
    super.dispose();
  }

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
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).colorScheme.primary,
                onPrimary: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null && picked != pregnancyStartDate) {
      setState(() => pregnancyStartDate = picked);
    }
  }

  void _confirmSubmit() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Submission"),
            content: const Text("Are you sure you want to submit the form?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  formSubmit();
                },
                child: const Text("Submit"),
              ),
            ],
          ),
    );
  }

  Future<void> formSubmit() async {
    if (!_formKey.currentState!.validate() || pregnancyStartDate == null) {
      _showSnackBar("Please fill all required fields!");
      return;
    }

    final weight = double.tryParse(weightController.text.trim());
    final height = double.tryParse(heightController.text.trim());
    if (weight == null || height == null) {
      _showSnackBar("Please enter valid numbers for weight and height!");
      return;
    }

    final pregnancyDuration = calculatePregnancyDuration(pregnancyStartDate!);
    final formData = {
      "user_id": widget.user_id,
      "email": widget.email,
      "full_name": nameController.text.trim(),
      "gender": selectedGender,
      "age": selectedAge,
      "weight": weight,
      "weight_unit": selectedWeightUnit,
      "height": height,
      "height_unit": selectedHeightUnit,
      "blood_pressure": bloodPressureController.text.trim(),
      "health_conditions": selectedHealthConditions,
      "health_info":
          healthInfoController.text.trim().isEmpty
              ? null
              : healthInfoController.text.trim(),
      "pregnancy_start_date": DateFormat(
        'yyyy-MM-dd',
      ).format(pregnancyStartDate!),
      "pregnancy_weeks": pregnancyDuration["weeks"],
      "pregnancy_days": pregnancyDuration["days"],
    };

    try {
      await Supabase.instance.client
          .from('mothers')
          .insert(formData)
          .select()
          .single(); // Use .single() for one row
      _showSnackBar("Form submitted successfully!", isSuccess: true);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (context) => BottomPageNavigation(
                email: widget.email,
                user_id: widget.user_id!,
              ),
        ),
      );
    } catch (error) {
      _showSnackBar("Error submitting form: ${error.toString()}");
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color:
                  isSuccess
                      ? Colors.white
                      : Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor:
              isSuccess
                  ? Colors.green.shade400
                  : Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Welcome, Please Fill Below Form!",
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.2),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(screenHeight * 0.02),
          child: Card(
            elevation: theme.cardTheme.elevation,
            shape: theme.cardTheme.shape,
            color: theme.cardTheme.color,
            child: Padding(
              padding: EdgeInsets.all(screenHeight * 0.02),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNameField(theme),
                      SizedBox(height: screenHeight * 0.02),
                      _buildGenderSection(theme),
                      SizedBox(height: screenHeight * 0.02),
                      _buildAgeSection(theme, screenHeight),
                      SizedBox(height: screenHeight * 0.02),
                      _buildHeightSection(theme),
                      SizedBox(height: screenHeight * 0.02),
                      _buildBloodPressureField(theme),
                      SizedBox(height: screenHeight * 0.02),
                      _buildWeightSection(theme),
                      SizedBox(height: screenHeight * 0.02),
                      _buildPregnancyStartDateSection(theme, screenHeight),
                      SizedBox(height: screenHeight * 0.02),
                      _buildHealthConditionsSection(theme, screenHeight),
                      SizedBox(height: screenHeight * 0.02),
                      _buildSubmitButton(theme),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField(ThemeData theme) {
    return Semantics(
      label: "Full Name Input",
      child: TextFormField(
        controller: nameController,
        focusNode: _nameFocus,
        decoration: InputDecoration(
          labelText: "Full Name",
          prefixIcon: Icon(Icons.person, color: theme.colorScheme.primary),
          border:
              theme.inputDecorationTheme.border ?? const OutlineInputBorder(),
          enabledBorder: theme.inputDecorationTheme.enabledBorder,
          focusedBorder: theme.inputDecorationTheme.focusedBorder,
          filled: theme.inputDecorationTheme.filled,
          fillColor:
              theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface,
        ),
        style: theme.textTheme.bodyMedium,
        textInputAction: TextInputAction.next,
        validator:
            (value) => value!.trim().isEmpty ? "Full Name is required" : null,
        onFieldSubmitted:
            (_) => FocusScope.of(context).requestFocus(_heightFocus),
      ),
    );
  }

  Widget _buildGenderSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select Gender",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: "Male Gender Option",
                child: RadioListTile<String>(
                  title: Text("Male", style: theme.textTheme.bodyMedium),
                  value: "Male",
                  groupValue: selectedGender,
                  onChanged: (value) => setState(() => selectedGender = value!),
                  activeColor: theme.colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                label: "Female Gender Option",
                child: RadioListTile<String>(
                  title: Text("Female", style: theme.textTheme.bodyMedium),
                  value: "Female",
                  groupValue: selectedGender,
                  onChanged: (value) => setState(() => selectedGender = value!),
                  activeColor: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAgeSection(ThemeData theme, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select Your Age",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: "Age Slider, Selected Age: $selectedAge",
          child: Slider(
            value: selectedAge.toDouble(),
            min: 18,
            max: 100,
            divisions: 82,
            label: selectedAge.round().toString(),
            onChanged: (value) => setState(() => selectedAge = value.toInt()),
            activeColor: theme.colorScheme.primary,
            inactiveColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        Text(
          "Selected Age: $selectedAge",
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildHeightSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enter Your Height",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: "Height Input",
                child: TextFormField(
                  controller: heightController,
                  focusNode: _heightFocus,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Height",
                    prefixIcon: Icon(
                      Icons.height,
                      color: theme.colorScheme.primary,
                    ),
                    border:
                        theme.inputDecorationTheme.border ??
                        const OutlineInputBorder(),
                    enabledBorder: theme.inputDecorationTheme.enabledBorder,
                    focusedBorder: theme.inputDecorationTheme.focusedBorder,
                    filled: theme.inputDecorationTheme.filled,
                    fillColor:
                        theme.inputDecorationTheme.fillColor ??
                        theme.colorScheme.surface,
                  ),
                  style: theme.textTheme.bodyMedium,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value!.trim().isEmpty) return "Height is required";
                    if (double.tryParse(value.trim()) == null) {
                      return "Enter a valid number";
                    }
                    return null;
                  },
                  onFieldSubmitted:
                      (_) => FocusScope.of(context).requestFocus(_weightFocus),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Semantics(
              label: "Height Unit Selector",
              child: DropdownButton<String>(
                value: selectedHeightUnit,
                items:
                    ["cm", "ft"].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: theme.textTheme.bodyMedium),
                      );
                    }).toList(),
                onChanged:
                    (newValue) =>
                        setState(() => selectedHeightUnit = newValue!),
                style: theme.textTheme.bodyMedium,
                dropdownColor: theme.colorScheme.surface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBloodPressureField(ThemeData theme) {
    return Semantics(
      label: "Blood Pressure Input",
      child: TextFormField(
        controller: bloodPressureController,
        focusNode: _bloodPressureFocus,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          labelText: "Blood Pressure (e.g., 120/80)",
          prefixIcon: Icon(
            Icons.monitor_heart,
            color: theme.colorScheme.primary,
          ),
          border:
              theme.inputDecorationTheme.border ?? const OutlineInputBorder(),
          enabledBorder: theme.inputDecorationTheme.enabledBorder,
          focusedBorder: theme.inputDecorationTheme.focusedBorder,
          filled: theme.inputDecorationTheme.filled,
          fillColor:
              theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface,
        ),
        style: theme.textTheme.bodyMedium,
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (value!.trim().isEmpty) return "Blood Pressure is required";
          if (!RegExp(r'^\d{2,3}/\d{2,3}$').hasMatch(value.trim())) {
            return "Enter valid blood pressure (e.g., 120/80)";
          }
          return null;
        },
        onFieldSubmitted:
            (_) => FocusScope.of(context).requestFocus(_healthInfoFocus),
      ),
    );
  }

  Widget _buildWeightSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enter Your Weight",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: "Weight Input",
                child: TextFormField(
                  controller: weightController,
                  focusNode: _weightFocus,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Weight",
                    prefixIcon: Icon(
                      Icons.scale,
                      color: theme.colorScheme.primary,
                    ),
                    border:
                        theme.inputDecorationTheme.border ??
                        const OutlineInputBorder(),
                    enabledBorder: theme.inputDecorationTheme.enabledBorder,
                    focusedBorder: theme.inputDecorationTheme.focusedBorder,
                    filled: theme.inputDecorationTheme.filled,
                    fillColor:
                        theme.inputDecorationTheme.fillColor ??
                        theme.colorScheme.surface,
                  ),
                  style: theme.textTheme.bodyMedium,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value!.trim().isEmpty) return "Weight is required";
                    if (double.tryParse(value.trim()) == null) {
                      return "Enter a valid number";
                    }
                    return null;
                  },
                  onFieldSubmitted:
                      (_) => FocusScope.of(
                        context,
                      ).requestFocus(_bloodPressureFocus),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Semantics(
              label: "Weight Unit Selector",
              child: DropdownButton<String>(
                value: selectedWeightUnit,
                items:
                    ["kg", "lbs"].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: theme.textTheme.bodyMedium),
                      );
                    }).toList(),
                onChanged:
                    (newValue) =>
                        setState(() => selectedWeightUnit = newValue!),
                style: theme.textTheme.bodyMedium,
                dropdownColor: theme.colorScheme.surface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPregnancyStartDateSection(ThemeData theme, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "When Did You Become Pregnant?",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: "Pregnancy Start Date Selector",
          child: GestureDetector(
            onTap: () => _selectPregnancyStartDate(context),
            child: AbsorbPointer(
              child: TextFormField(
                controller: TextEditingController(
                  text:
                      pregnancyStartDate != null
                          ? DateFormat('yyyy-MM-dd').format(pregnancyStartDate!)
                          : "Not set",
                ),
                decoration: InputDecoration(
                  labelText: "Pregnancy Start Date",
                  suffixIcon: Icon(
                    Icons.calendar_today,
                    color: theme.colorScheme.primary,
                  ),
                  border:
                      theme.inputDecorationTheme.border ??
                      const OutlineInputBorder(),
                  enabledBorder: theme.inputDecorationTheme.enabledBorder,
                  focusedBorder: theme.inputDecorationTheme.focusedBorder,
                  filled: theme.inputDecorationTheme.filled,
                  fillColor:
                      theme.inputDecorationTheme.fillColor ??
                      theme.colorScheme.surface,
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ),
        if (pregnancyStartDate != null) ...[
          const SizedBox(height: 8),
          Text(
            "Pregnancy Duration: ${calculatePregnancyDuration(pregnancyStartDate!)['weeks']} weeks and ${calculatePregnancyDuration(pregnancyStartDate!)['days']} days",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHealthConditionsSection(ThemeData theme, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select Any Applicable Health Conditions",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              healthConditions.map((condition) {
                return Semantics(
                  label: "$condition Health Condition Checkbox",
                  child: FilterChip(
                    label: Text(condition, style: theme.textTheme.bodyMedium),
                    selected: selectedHealthConditions.contains(condition),
                    onSelected: (isSelected) {
                      setState(() {
                        if (isSelected) {
                          selectedHealthConditions.add(condition);
                        } else {
                          selectedHealthConditions.remove(condition);
                        }
                      });
                    },
                    selectedColor: theme.colorScheme.primary.withOpacity(0.3),
                    backgroundColor: theme.colorScheme.surfaceContainer,
                    checkmarkColor: theme.colorScheme.primary,
                  ),
                );
              }).toList(),
        ),
        if (selectedHealthConditions.contains("Other")) ...[
          SizedBox(height: screenHeight * 0.02),
          Text(
            "Describe Your Health Issue",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: "Health Issue Description Input",
            child: TextFormField(
              controller: healthInfoController,
              focusNode: _healthInfoFocus,
              maxLines: null,
              decoration: InputDecoration(
                hintText: "Describe your health background or issues here...",
                prefixIcon: Icon(
                  Icons.health_and_safety,
                  color: theme.colorScheme.primary,
                ),
                border:
                    theme.inputDecorationTheme.border ??
                    const OutlineInputBorder(),
                enabledBorder: theme.inputDecorationTheme.enabledBorder,
                focusedBorder: theme.inputDecorationTheme.focusedBorder,
                filled: theme.inputDecorationTheme.filled,
                fillColor:
                    theme.inputDecorationTheme.fillColor ??
                    theme.colorScheme.surface,
              ),
              style: theme.textTheme.bodyMedium,
              textInputAction: TextInputAction.done,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return Semantics(
      label: "Submit Form Button",
      child: ElevatedButton(
        onPressed: _confirmSubmit,
        style: theme.elevatedButtonTheme.style?.copyWith(
          minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 50)),
        ),
        child: Text(
          "Submit",
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
