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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  Future<void> fetchDoctors() async {
    try {
      final response = await supabase.from('doctors').select('*');
      setState(() {
        doctors = response;
        isLoading = false;
      });
    } catch (error) {
      print('Error fetching doctors: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.availableDoctors,
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
      ),
      body: Column(
        children: [
          // Navigation Buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Doctors Button (Inactive on DoctorsPage)
                Semantics(
                  label: l10n.navigateToDoctors,
                  child: ElevatedButton(
                    onPressed: null, // Disabled since we're on DoctorsPage
                    style: theme.elevatedButtonTheme.style?.copyWith(
                      backgroundColor: WidgetStatePropertyAll(
                        theme.colorScheme.primary.withOpacity(
                          0.5,
                        ), // Dimmed to indicate inactive
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
                // Booking Button
                // Appointments Button (Navigates to SocketTestPage)
                Semantics(
                  label: l10n.navigateToAppointments,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const SocketTestPage(doctorId: ''),
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
          // Existing Doctors List
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    )
                    : doctors.isEmpty
                    ? Center(
                      child: Semantics(
                        label: l10n.noDoctorsAvailable,
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
                              l10n.noDoctorsAvailable,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    : ListView.builder(
                      itemCount: doctors.length,
                      padding: EdgeInsets.all(screenHeight * 0.02),
                      itemBuilder: (context, index) {
                        final doctor = doctors[index];
                        return DoctorCard(doctor: doctor);
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
