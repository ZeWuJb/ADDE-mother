import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'tele-conseltation_page.dart';

class SocketTestPage extends StatefulWidget {
  final String? doctorId;
  const SocketTestPage({super.key, this.doctorId});

  @override
  State<SocketTestPage> createState() => _SocketTestPageState();
}

class _SocketTestPageState extends State<SocketTestPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> pendingAppointments = [];
  List<Map<String, dynamic>> acceptedAppointments = [];
  List<Map<String, dynamic>> rejectedAppointments = [];

  String connectionStatus = 'Connected';
  String errorMessage = '';
  bool isLoading = true;
  bool isReconnecting = false;

  RealtimeChannel? tempAppointmentsChannel;
  RealtimeChannel? appointmentsChannel;
  late TabController _tabController;
  final Set<String> _processedAppointments = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    Future.microtask(() {
      _setupRealtimeSubscriptions();
      _loadAppointments();

      Timer.periodic(const Duration(seconds: 30), (timer) {
        if (mounted) {
          _fetchAppointmentsFromDatabase();
        }
      });
    });
  }

  void _setupRealtimeSubscriptions() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        errorMessage = AppLocalizations.of(context)!.pleaseLogIn;
        connectionStatus = 'Authentication Error';
      });
      return;
    }

    tempAppointmentsChannel =
        supabase
            .channel('temp-appointments-mother-$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.delete,
              schema: 'public',
              table: 'temporary_appointments',
              callback: (payload) {
                if (mounted) {
                  _fetchAppointmentsFromDatabase();
                }
              },
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'temporary_appointments',
              callback: (payload) {
                if (mounted) {
                  _fetchAppointmentsFromDatabase();
                }
              },
            )
            .subscribe();

    appointmentsChannel =
        supabase
            .channel('appointments-mother-$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'appointments',
              callback: (payload) {
                if (mounted) {
                  _fetchAppointmentsFromDatabase();
                  if (payload.newRecord['status'] == 'accepted') {
                    _showStatusDialog(
                      AppLocalizations.of(context)!.appointmentAccepted,
                      AppLocalizations.of(context)!.videoConsultationMessage,
                      theme: Theme.of(context),
                    );
                  }
                }
              },
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'appointments',
              callback: (payload) {
                if (mounted) {
                  _fetchAppointmentsFromDatabase();
                }
              },
            )
            .subscribe();
  }

  Future<void> _loadAppointments() async {
    setState(() => isLoading = true);
    try {
      await _fetchAppointmentsFromDatabase();
    } catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = AppLocalizations.of(
            context,
          )!.errorLabel(error.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _fetchAppointmentsFromDatabase() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final tempResponse = await supabase
          .from('temporary_appointments')
          .select('''
            id, doctor_id, requested_time, created_at,
            doctors:doctor_id (id, full_name, speciality, profile_url)
          ''')
          .eq('mother_id', userId)
          .order('created_at', ascending: false);

      final appResponse = await supabase
          .from('appointments')
          .select('''
            id, requested_time, status, payment_status, video_conference_link,
            created_at, updated_at,
            doctors:doctor_id (id, full_name, speciality, profile_url)
          ''')
          .eq('mother_id', userId)
          .order('requested_time', ascending: true);

      List<Map<String, dynamic>> pending =
          tempResponse
              .map(
                (appointment) => {
                  ...Map<String, dynamic>.from(appointment),
                  'status': 'pending',
                  'appointmentId': appointment['id'],
                },
              )
              .toList();

      List<Map<String, dynamic>> accepted = [];
      List<Map<String, dynamic>> declined = [];

      for (var appointment in appResponse) {
        final appointmentMap = Map<String, dynamic>.from(appointment);
        String status = appointmentMap['status'] ?? 'pending';

        if (status == 'accepted') {
          accepted.add(appointmentMap);
          if (appointmentMap['video_conference_link']?.toString().isNotEmpty ==
                  true &&
              !_processedAppointments.contains(appointmentMap['id'])) {
            _processedAppointments.add(appointmentMap['id']);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigateToVideoCall(appointmentMap);
            });
          }
        } else if (status == 'declined' || status == 'cancelled') {
          declined.add(appointmentMap);
        }
      }

      if (mounted) {
        setState(() {
          pendingAppointments = pending;
          acceptedAppointments = accepted;
          rejectedAppointments = declined;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = AppLocalizations.of(
            context,
          )!.errorLabel(error.toString());
        });
      }
    }
  }

  void _navigateToVideoCall(Map<String, dynamic> appointment) {
    final doctorName = appointment['doctors']?['full_name'] ?? 'Doctor';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TeleConseltationPage(
              appointment: appointment,
              doctorName: doctorName,
            ),
      ),
    );
  }

  void _showStatusDialog(
    String title,
    String message, {
    required ThemeData theme,
  }) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            content: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: theme.textButtonTheme.style?.copyWith(
                  foregroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.primary,
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.okLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) {
      return AppLocalizations.of(context)!.notSpecified;
    }
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('MMM d, yyyy - h:mm a').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  Widget _buildAppointmentCard(
    Map<String, dynamic> appointment,
    ThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final status = appointment['status'] ?? 'unknown';
    final Color statusColor =
        status == 'pending'
            ? Colors.amber
            : status == 'accepted'
            ? Colors.green
            : Colors.red;
    final hasVideoLink =
        appointment['video_conference_link']?.toString().isNotEmpty == true;

    return Semantics(
      label: l10n.doctorRating(
        appointment['doctors']?['full_name'] ?? 'Unknown Doctor',
        appointment['doctors']?['speciality'] ?? '',
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        elevation: theme.cardTheme.elevation,
        shape: theme.cardTheme.shape,
        color: theme.cardTheme.color,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      appointment['doctor_name'] ??
                          (appointment['doctors']?['full_name'] ??
                              'Unknown Doctor'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateTime(appointment['requested_time']),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (status == 'accepted') ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed:
                      hasVideoLink
                          ? () => _navigateToVideoCall(appointment)
                          : null,
                  icon: const Icon(Icons.video_call),
                  label: Text(l10n.joinVideoCall),
                  style: theme.elevatedButtonTheme.style?.copyWith(
                    backgroundColor: WidgetStatePropertyAll(
                      hasVideoLink
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                    foregroundColor: WidgetStatePropertyAll(
                      hasVideoLink
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    tempAppointmentsChannel?.unsubscribe();
    appointmentsChannel?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.pageTitleAppointments,
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: theme.textTheme.bodyMedium,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          tabs: [
            Tab(
              icon: Icon(
                Icons.hourglass_empty,
                color: theme.colorScheme.primary,
              ),
              text: l10n.tabPending(pendingAppointments.length),
            ),
            Tab(
              icon: Icon(Icons.check_circle, color: theme.colorScheme.primary),
              text: l10n.tabAccepted(acceptedAppointments.length),
            ),
            Tab(
              icon: Icon(Icons.cancel, color: theme.colorScheme.primary),
              text: l10n.tabRejected(rejectedAppointments.length),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
            onPressed: _loadAppointments,
            tooltip: l10n.refreshAppointmentsTooltip,
          ),
        ],
      ),
      body: Column(
        children: [
          if (connectionStatus != 'Connected')
            Container(
              padding: const EdgeInsets.all(8),
              color: theme.colorScheme.error.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.wifi_off,
                    color: theme.colorScheme.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.statusPrefix(connectionStatus),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isReconnecting)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() => isReconnecting = true);
                      _fetchAppointmentsFromDatabase();
                      setState(() {
                        isReconnecting = false;
                        connectionStatus = 'Connected';
                      });
                    },
                    style: theme.textButtonTheme.style?.copyWith(
                      foregroundColor: WidgetStatePropertyAll(
                        theme.colorScheme.error,
                      ),
                    ),
                    child: Text(
                      l10n.retryLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: theme.colorScheme.error.withOpacity(0.1),
              width: double.infinity,
              child: Text(
                errorMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    )
                    : TabBarView(
                      controller: _tabController,
                      children: [
                        pendingAppointments.isEmpty
                            ? _buildEmptyState(
                              l10n.noPendingAppointments,
                              Icons.hourglass_empty,
                              theme,
                            )
                            : ListView.builder(
                              itemCount: pendingAppointments.length,
                              padding: EdgeInsets.all(screenHeight * 0.01),
                              itemBuilder:
                                  (context, index) => _buildAppointmentCard(
                                    pendingAppointments[index],
                                    theme,
                                  ),
                            ),
                        acceptedAppointments.isEmpty
                            ? _buildEmptyState(
                              l10n.noAcceptedAppointments,
                              Icons.check_circle,
                              theme,
                            )
                            : ListView.builder(
                              itemCount: acceptedAppointments.length,
                              padding: EdgeInsets.all(screenHeight * 0.01),
                              itemBuilder:
                                  (context, index) => _buildAppointmentCard(
                                    acceptedAppointments[index],
                                    theme,
                                  ),
                            ),
                        rejectedAppointments.isEmpty
                            ? _buildEmptyState(
                              l10n.noRejectedAppointments,
                              Icons.cancel,
                              theme,
                            )
                            : ListView.builder(
                              itemCount: rejectedAppointments.length,
                              padding: EdgeInsets.all(screenHeight * 0.01),
                              itemBuilder:
                                  (context, index) => _buildAppointmentCard(
                                    rejectedAppointments[index],
                                    theme,
                                  ),
                            ),
                      ],
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        tooltip: l10n.bookNewAppointmentTooltip,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
