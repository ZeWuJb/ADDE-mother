import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AppointmentPaymentPage extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final Map<String, dynamic> doctorData;
  final Map<String, dynamic> motherData;

  const AppointmentPaymentPage({
    super.key,
    required this.appointment,
    required this.doctorData,
    required this.motherData,
  });

  @override
  State<AppointmentPaymentPage> createState() => _AppointmentPaymentPageState();
}

class _AppointmentPaymentPageState extends State<AppointmentPaymentPage> {
  final supabase = Supabase.instance.client;
  late WebViewController _webViewController;

  bool isLoading = false;
  bool isPaymentComplete = false;
  String? errorMessage;
  String? checkoutUrl;
  String? txRef;
  Timer? _statusTimer;

  // Payment API base URL - update this to match your payment server
  static const String PAYMENT_API_BASE_URL = 'http://192.168.82.180:3000';

  @override
  void initState() {
    super.initState();
    debugPrint('=== PAYMENT PAGE INITIALIZATION ===');
    debugPrint('Appointment: ${widget.appointment}');
    debugPrint('Doctor: ${widget.doctorData}');
    debugPrint('Mother: ${widget.motherData}');
    debugPrint('API Base URL: $PAYMENT_API_BASE_URL');
    _testServerConnection();
  }

  Future<void> _testServerConnection() async {
    debugPrint('=== TESTING SERVER CONNECTION ===');
    try {
      final response = await http
          .get(
            Uri.parse('$PAYMENT_API_BASE_URL/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('Health check status: ${response.statusCode}');
      debugPrint('Health check response: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ Server is reachable');
        _initializePayment();
      } else {
        setState(() {
          errorMessage = 'Server returned status ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Server connection failed: $e');
      setState(() {
        errorMessage = 'Cannot connect to payment server: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _initializePayment() async {
    debugPrint('=== INITIALIZING PAYMENT ===');
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Get payment amount from doctor data
      final paymentAmount =
          widget.doctorData['payment_required_amount']?.toString() ?? '100.00';

      // Prepare payment data - use doctor's phone number
      final paymentData = {
        'appointment_id': widget.appointment['id'],
        'amount': paymentAmount,
        'currency': 'ETB',
        'email': widget.motherData['email'] ?? 'patient@example.com',
        'first_name':
            widget.motherData['full_name']?.split(' ').first ?? 'Patient',
        'last_name':
            widget.motherData['full_name']?.split(' ').skip(1).join(' ') ?? '',
        'phone_number':
            widget.doctorData['phone_number'] ??
            '0900000000', // Use doctor's phone
      };

      debugPrint('=== PAYMENT DATA ===');
      debugPrint('Sending payment data: ${jsonEncode(paymentData)}');

      // Validate the API URL before making the request
      final apiUrl = '$PAYMENT_API_BASE_URL/initialize-appointment-payment';
      Uri? parsedUri;
      try {
        parsedUri = Uri.parse(apiUrl);
        if (!parsedUri.hasScheme || !parsedUri.hasAuthority) {
          throw FormatException('Invalid API URL format');
        }
      } catch (e) {
        debugPrint('❌ Invalid API URL: $apiUrl');
        setState(() {
          errorMessage = 'Invalid payment server URL configuration';
          isLoading = false;
        });
        return;
      }

      debugPrint('Using payment API URL: $apiUrl');

      final response = await http
          .post(
            parsedUri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(paymentData),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('=== PAYMENT RESPONSE ===');
      debugPrint('Payment response status: ${response.statusCode}');
      debugPrint('Payment response headers: ${response.headers}');
      debugPrint('Payment response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          debugPrint('Parsed response data: $data');

          if (data['checkout_url'] != null) {
            setState(() {
              checkoutUrl = data['checkout_url'];
              txRef = data['tx_ref'];
              isLoading = false;
            });

            debugPrint('✅ Payment initialized successfully');
            debugPrint('Checkout URL: $checkoutUrl');
            debugPrint('Transaction Ref: $txRef');

            _initializeWebView();
            _startPaymentStatusPolling();
          } else {
            setState(() {
              errorMessage = 'Invalid response: missing checkout_url';
              isLoading = false;
            });
          }
        } catch (e) {
          debugPrint('❌ Failed to parse response JSON: $e');
          setState(() {
            errorMessage = 'Invalid response format from server';
            isLoading = false;
          });
        }
      } else {
        debugPrint(
          '❌ Payment initialization failed with status: ${response.statusCode}',
        );
        try {
          final errorData = jsonDecode(response.body);
          setState(() {
            errorMessage =
                errorData['error'] ??
                'Failed to initialize payment (${response.statusCode})';
            isLoading = false;
          });
        } catch (e) {
          setState(() {
            errorMessage =
                'Server error: ${response.statusCode} - ${response.body}';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Payment initialization error: $e');
      setState(() {
        errorMessage = 'Network error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _initializeWebView() {
    if (checkoutUrl == null) return;

    debugPrint('=== INITIALIZING WEBVIEW ===');
    debugPrint('Loading checkout URL: $checkoutUrl');

    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                debugPrint('Payment page started loading: $url');
              },
              onPageFinished: (String url) {
                debugPrint('Payment page finished loading: $url');
                _autoFillPaymentForm();
                _checkUrlForCompletion(url);
              },
              onNavigationRequest: (NavigationRequest request) {
                debugPrint('Navigation request: ${request.url}');
                _checkUrlForCompletion(request.url);
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(checkoutUrl!));
  }

  void _autoFillPaymentForm() {
    final phoneNumber =
        widget.doctorData['phone_number'] ?? ''; // Use doctor's phone
    final email = widget.motherData['email'] ?? '';
    final amount =
        widget.doctorData['payment_required_amount']?.toString() ?? '';

    debugPrint('=== AUTO-FILLING FORM ===');
    debugPrint('Phone: $phoneNumber');
    debugPrint('Email: $email');
    debugPrint('Amount: $amount');

    if (phoneNumber.isNotEmpty || email.isNotEmpty) {
      String jsCode = '''
        function fillPaymentForm() {
          console.log("Auto-filling payment form...");
          
          // Phone number selectors
          var phoneSelectors = [
            'input[type="tel"]',
            'input[name*="phone"]',
            'input[name*="mobile"]',
            'input[placeholder*="phone"]',
            'input[placeholder*="mobile"]'
          ];
          
          // Email selectors
          var emailSelectors = [
            'input[type="email"]',
            'input[name*="email"]',
            'input[placeholder*="email"]'
          ];
          
          // Amount selectors
          var amountSelectors = [
            'input[name*="amount"]',
            'input[placeholder*="amount"]',
            'input[type="number"]'
          ];
          
          function fillField(selectors, value, fieldType) {
            if (!value) return false;
            
            for (let selector of selectors) {
              let fields = document.querySelectorAll(selector);
              for (let field of fields) {
                if (field && !field.value) {
                  console.log("Filling " + fieldType + " field");
                  field.value = value;
                  field.focus();
                  
                  ['input', 'change', 'blur'].forEach(eventType => {
                    field.dispatchEvent(new Event(eventType, { bubbles: true }));
                  });
                  
                  return true;
                }
              }
            }
            return false;
          }
          
          if ("$phoneNumber") {
            fillField(phoneSelectors, "$phoneNumber", "phone");
          }
          
          if ("$email") {
            fillField(emailSelectors, "$email", "email");
          }
          
          if ("$amount") {
            fillField(amountSelectors, "$amount", "amount");
          }
        }
        
        fillPaymentForm();
        setTimeout(fillPaymentForm, 1000);
        setTimeout(fillPaymentForm, 3000);
      ''';

      _webViewController.runJavaScript(jsCode);
    }
  }

  void _checkUrlForCompletion(String url) {
    if (isPaymentComplete) return;

    if (url.contains('payment-complete') ||
        url.contains('success') ||
        url.contains('callback')) {
      _handlePaymentCompletion();
    }
  }

  void _startPaymentStatusPolling() {
    debugPrint('=== STARTING PAYMENT STATUS POLLING ===');
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (isPaymentComplete || txRef == null) {
        timer.cancel();
        return;
      }

      try {
        final response = await http.get(
          Uri.parse(
            '$PAYMENT_API_BASE_URL/appointment-payment-status/${widget.appointment['id']}',
          ),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final paymentStatus = data['payment_status'];
          debugPrint('Payment status check: $paymentStatus');

          if (paymentStatus == 'paid') {
            timer.cancel();
            _handlePaymentCompletion(success: true);
          }
        }
      } catch (e) {
        debugPrint('Error checking payment status: $e');
      }
    });
  }

  void _handlePaymentCompletion({bool success = false}) {
    if (isPaymentComplete) return;

    debugPrint('=== PAYMENT COMPLETION ===');
    debugPrint('Success: $success');

    setState(() => isPaymentComplete = true);
    _statusTimer?.cancel();

    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              success ? l10n.paymentSuccessful : l10n.paymentCompleted,
            ),
            content: Text(
              success
                  ? l10n.paymentSuccessMessage
                  : l10n.paymentProcessingMessage,
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Return to appointments page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: success ? Colors.green : Colors.blue,
                ),
                child: Text(l10n.okLabel),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final paymentAmount =
        widget.doctorData['payment_required_amount']?.toString() ?? '100.00';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appointmentPayment),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          // Payment info header
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.paymentRequired,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.doctorName(widget.doctorData['full_name'] ?? 'Doctor'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.consultationFee(paymentAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.green.shade700, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          l10n.paymentAutoFillMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Error message
          if (errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.errorContainer,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error Details:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'API URL: $PAYMENT_API_BASE_URL',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),

          // Loading indicator
          if (isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      l10n.initializingPayment,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connecting to: $PAYMENT_API_BASE_URL',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          // WebView for payment
          else if (checkoutUrl != null)
            Expanded(child: WebViewWidget(controller: _webViewController))
          // Error state
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage ?? l10n.paymentInitializationFailed,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _testServerConnection,
                      child: Text(l10n.retryLabel),
                    ),
                  ],
                ),
              ),
            ),

          // Action buttons
          if (!isLoading && checkoutUrl != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Check payment status manually
                        try {
                          final response = await http.get(
                            Uri.parse(
                              '$PAYMENT_API_BASE_URL/appointment-payment-status/${widget.appointment['id']}',
                            ),
                          );

                          if (response.statusCode == 200) {
                            final data = jsonDecode(response.body);
                            if (data['payment_status'] == 'paid') {
                              _handlePaymentCompletion(success: true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.paymentStillPending),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.errorCheckingPayment)),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.checkPaymentStatus),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: Text(l10n.cancelLabel),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
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
