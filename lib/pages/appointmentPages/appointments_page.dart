import 'package:flutter/material.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'payment_page.dart';

class AppointmentsPage extends StatefulWidget {
  final String? doctorId;

  const AppointmentsPage({super.key, this.doctorId});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointmentsFromDatabase();
  }

  Future<void> _fetchAppointmentsFromDatabase() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Fetch from appointments table (accepted appointments only)
      final response = await Supabase.instance.client
          .from('appointments')
          .select('''
            *,
            doctors!appointments_doctor_id_fkey(
              id,
              full_name, 
              profile_url, 
              payment_required_amount,
              speciality,
              phone_number
            )
          ''')
          .eq('mother_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _appointments =
              response.isNotEmpty
                  ? List<Map<String, dynamic>>.from(response)
                  : [];
          _isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Error fetching appointments: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToVideoCall(Map<String, dynamic> appointment) async {
    final videoLink = appointment['video_conference_link'];
    if (videoLink != null && videoLink.isNotEmpty) {
      final Uri url = Uri.parse(videoLink);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.couldNotLaunchVideoCall,
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.videoLinkNotAvailable),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _navigateToPayment(Map<String, dynamic> appointment) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      // Get doctor data from the appointment (already joined)
      final doctorData = appointment['doctors'] as Map<String, dynamic>?;

      if (doctorData == null) {
        debugPrint(
          'Doctor data is null in appointment: ${appointment.toString()}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorLoadingPaymentData),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      // Get current user ID
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('User ID is null');
        return;
      }

      // Get mother data from mothers table (no phone_number field)
      final motherResponse =
          await Supabase.instance.client
              .from('mothers')
              .select('full_name, email') // Removed phone_number
              .eq('user_id', userId)
              .single();

      debugPrint('Mother data fetched: $motherResponse');
      debugPrint('Doctor data: $doctorData');
      debugPrint('Appointment data: $appointment');

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => AppointmentPaymentPage(
                  appointment: appointment,
                  doctorData: doctorData,
                  motherData: motherResponse,
                ),
          ),
        ).then((_) {
          if (mounted) {
            _fetchAppointmentsFromDatabase();
          }
        });
      }
    } catch (e) {
      debugPrint('Error in _navigateToPayment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorLoadingPaymentData}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildPaymentStatusChip(String? paymentStatus) {
    final l10n = AppLocalizations.of(context)!;

    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    switch (paymentStatus) {
      case 'paid':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        text = l10n.paid;
        icon = Icons.check_circle;
        break;
      case 'unpaid':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        text = l10n.paymentRequired;
        icon = Icons.payment;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        text = l10n.unknown;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    final l10n = AppLocalizations.of(context)!;

    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case 'accepted':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        text = l10n.accepted;
        break;
      case 'pending':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        text = l10n.pending;
        break;
      case 'declined':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        text = l10n.declined;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        text = l10n.unknown;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myAppointments),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _appointments.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noAppointmentsScheduled,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Only accepted appointments appear here',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetchAppointmentsFromDatabase,
                child: ListView.builder(
                  itemCount: _appointments.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final appointment = _appointments[index];
                    final doctor =
                        appointment['doctors'] as Map<String, dynamic>?;
                    final status = appointment['status'];
                    final paymentStatus = appointment['payment_status'];
                    final hasVideoLink =
                        appointment['video_conference_link'] != null &&
                        appointment['video_conference_link'].isNotEmpty;
                    final appointmentTime =
                        DateTime.parse(
                          appointment['requested_time'] as String,
                        ).toLocal();
                    final isUpcoming = appointmentTime.isAfter(DateTime.now());

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with date and time
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormat(
                                      'EEEE, MMMM d, y • h:mm a',
                                    ).format(appointmentTime),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Doctor information
                            if (doctor != null) ...[
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage:
                                        doctor['profile_url'] != null
                                            ? NetworkImage(
                                              doctor['profile_url'],
                                            )
                                            : null,
                                    radius: 24,
                                    child:
                                        doctor['profile_url'] == null
                                            ? Icon(
                                              Icons.person,
                                              color:
                                                  theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            )
                                            : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doctor['full_name'] ??
                                              l10n.unknownDoctor,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                        if (doctor['speciality'] != null)
                                          Text(
                                            doctor['speciality'],
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                ),
                                          ),
                                        if (doctor['payment_required_amount'] !=
                                            null)
                                          Text(
                                            '${l10n.consultationFee}: ${doctor['payment_required_amount']} ETB',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Status chips
                            Row(
                              children: [
                                _buildStatusChip(status),
                                const SizedBox(width: 8),
                                _buildPaymentStatusChip(paymentStatus),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Action buttons based on payment status
                            if (paymentStatus == 'unpaid') ...[
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      () => _navigateToPayment(appointment),
                                  icon: const Icon(Icons.payment),
                                  label: Text(l10n.payNow),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.error,
                                    foregroundColor: theme.colorScheme.onError,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.orange.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        l10n.paymentRequiredMessage,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (paymentStatus == 'paid' &&
                                hasVideoLink &&
                                isUpcoming) ...[
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      () => _navigateToVideoCall(appointment),
                                  icon: const Icon(Icons.video_call),
                                  label: Text(l10n.joinVideoCall),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor:
                                        theme.colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (paymentStatus == 'paid' &&
                                !isUpcoming) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.history,
                                      color: Colors.grey.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        l10n.appointmentCompleted,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (paymentStatus == 'paid' &&
                                !hasVideoLink) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.hourglass_empty,
                                      color: Colors.blue.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        l10n.videoLinkPending,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
