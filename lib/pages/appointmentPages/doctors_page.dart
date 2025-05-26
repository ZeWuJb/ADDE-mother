import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'doctors_card.dart';
import 'appointments_page.dart'; // Assuming SocketTestPage is from this import

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({super.key});

  @override
  State<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> doctors = [];
  List<dynamic> nurses = [];
  bool isLoading = false;
  bool hasError = false;
  bool showProfessionals =
      true; // Default to true to show professionals on load
  String selectedType = 'doctor'; // Default to doctors

  @override
  void initState() {
    super.initState();
    // Fetch will be triggered in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch professionals on page load or on error
    if (doctors.isEmpty && nurses.isEmpty || hasError) {
      fetchProfessionals();
    }
  }

  Future<void> fetchProfessionals() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      hasError = false;
    });

    final l10n = AppLocalizations.of(context)!;

    try {
      final supabase = Supabase.instance.client;

      // Check authentication status
      if (supabase.auth.currentUser == null) {
        throw Exception('User is not authenticated');
      }

      print('Fetching professionals from doctors table');
      final response = await supabase
          .from('doctors')
          .select('*')
          .order('full_name', ascending: true)
          .timeout(const Duration(seconds: 10));

      print('Supabase response: $response');

      if (!mounted) return;

      setState(() {
        // Split professionals by type
        doctors = response.where((item) => item['type'] == 'doctor').toList();
        nurses = response.where((item) => item['type'] == 'nurse').toList();
      });
    } catch (error) {
      print('Error fetching professionals: $error');
      if (!mounted) return;

      setState(() {
        hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorLoadingEntries(error.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: l10n.retryButton,
            onPressed: fetchProfessionals,
            textColor: Theme.of(context).colorScheme.onError,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine which professionals to display
    final professionals = selectedType == 'doctor' ? doctors : nurses;
    final professionalLabel =
        selectedType == 'doctor' ? l10n.doctorsLabel : l10n.nursesLabel;
    final noProfessionalsMessage =
        selectedType == 'doctor'
            ? l10n.noDoctorsAvailable
            : l10n.noNursesAvailable;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.availableHealthProfessionals,
            style: theme.appBarTheme.titleTextStyle?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color:
                  theme.brightness == Brightness.light
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
            ),
          ),
          backgroundColor:
              theme.brightness == Brightness.light
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onPrimary,
          elevation: theme.appBarTheme.elevation,
          actions: [
            IconButton(
              icon: Icon(
                Icons.refresh,
                color:
                    theme.brightness == Brightness.light
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
              ),
              onPressed: fetchProfessionals,
              tooltip: l10n.retryButton,
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
                      theme.colorScheme.primary.withOpacity(0.2),
                      theme.colorScheme.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Main Content
            Column(
              children: [
                // Navigation and Type Selection
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Health Professionals Button
                      Semantics(
                        label: l10n.navigateToHealthProfessionals,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              showProfessionals = !showProfessionals;
                              if (showProfessionals) {
                                selectedType = 'doctor'; // Default to doctors
                                fetchProfessionals();
                              }
                            });
                          },
                          style: theme.elevatedButtonTheme.style?.copyWith(
                            backgroundColor: WidgetStatePropertyAll(
                              showProfessionals
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.primary.withOpacity(0.5),
                            ),
                            foregroundColor: WidgetStatePropertyAll(
                              theme.colorScheme.onPrimary,
                            ),
                            minimumSize: WidgetStatePropertyAll(
                              Size(screenWidth * 0.35, 48),
                            ),
                          ),
                          child: Text(
                            l10n.healthProfessionalsLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                      // Appointments Button
                      Semantics(
                        label: l10n.navigateToAppointments,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const SocketTestPage(doctorId: ''),
                              ),
                            );
                          },
                          style: theme.elevatedButtonTheme.style?.copyWith(
                            backgroundColor: WidgetStatePropertyAll(
                              theme.colorScheme.primary,
                            ),
                            foregroundColor: WidgetStatePropertyAll(
                              theme.colorScheme.onPrimary,
                            ),
                            minimumSize: WidgetStatePropertyAll(
                              Size(screenWidth * 0.25, 48),
                            ),
                          ),
                          child: Text(
                            l10n.appointmentsLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Doctors and Nurses Buttons (shown when Health Professionals is active)
                if (showProfessionals)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Semantics(
                          label: l10n.navigateToDoctors,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedType = 'doctor';
                              });
                            },
                            style: theme.elevatedButtonTheme.style?.copyWith(
                              backgroundColor: WidgetStatePropertyAll(
                                selectedType == 'doctor'
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary.withOpacity(
                                      0.5,
                                    ),
                              ),
                              foregroundColor: WidgetStatePropertyAll(
                                theme.colorScheme.onPrimary,
                              ),
                              minimumSize: WidgetStatePropertyAll(
                                Size(screenWidth * 0.25, 48),
                              ),
                            ),
                            child: Text(
                              l10n.doctorsLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                        Semantics(
                          label: l10n.navigateToNurses,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedType = 'nurse';
                              });
                            },
                            style: theme.elevatedButtonTheme.style?.copyWith(
                              backgroundColor: WidgetStatePropertyAll(
                                selectedType == 'nurse'
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary.withOpacity(
                                      0.5,
                                    ),
                              ),
                              foregroundColor: WidgetStatePropertyAll(
                                theme.colorScheme.onPrimary,
                              ),
                              minimumSize: WidgetStatePropertyAll(
                                Size(screenWidth * 0.25, 48),
                              ),
                            ),
                            child: Text(
                              l10n.nursesLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Professionals List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: fetchProfessionals,
                    color: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surface,
                    child:
                        !showProfessionals
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.medical_services_outlined,
                                    size: 64,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.selectHealthProfessionals,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : isLoading
                            ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            )
                            : hasError
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 60,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    l10n.errorLoadingEntries(
                                      'Failed to load $professionalLabel',
                                    ),
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: fetchProfessionals,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor:
                                          theme.colorScheme.onPrimary,
                                    ),
                                    child: Text(l10n.retryButton),
                                  ),
                                ],
                              ),
                            )
                            : professionals.isEmpty
                            ? Center(
                              child: Semantics(
                                label: noProfessionalsMessage,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_off,
                                      size: 64,
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      noProfessionalsMessage,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color:
                                                theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            : ListView.builder(
                              itemCount: professionals.length,
                              padding: EdgeInsets.all(screenHeight * 0.02),
                              itemBuilder: (context, index) {
                                final professional = professionals[index];
                                return DoctorCard(doctor: professional);
                              },
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
