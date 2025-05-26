import 'dart:convert';

import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/community/chat_provider.dart';
import 'package:adde/pages/community/post_provider.dart';
import 'package:adde/pages/name_suggestion/name_provider.dart';
import 'package:adde/pages/note/note_provider.dart';
import 'package:adde/pages/notification/NotificationSettingsProvider.dart';
import 'package:adde/pages/notification/notification_service.dart';
import 'package:adde/pages/profile/locale_provider.dart';
import 'package:adde/auth/authentication_gate.dart';
import 'package:adde/pages/bottom_page_navigation.dart';
import 'package:adde/theme/theme_data.dart';
import 'package:adde/theme/theme_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  String? userId;
  String? email;
  final sessionString = await getSavedSession();
  if (sessionString != null) {
    try {
      // Validate session string
      final sessionJson = jsonDecode(sessionString);
      if (sessionJson is Map<String, dynamic>) {
        final response = await Supabase.instance.client.auth.recoverSession(
          sessionString,
        );
        userId = response.user?.id;
        email = response.user?.email;
        print('Session restored: userId=$userId, email=$email');
      } else {
        print('Invalid session format: $sessionString');
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('supabase_session'); // Clear invalid session
      }
    } catch (e) {
      print('Failed to restore session: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('supabase_session'); // Clear invalid session
    }
  }

  final localeProvider = LocaleProvider();
  await localeProvider.loadLocale();
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();
  final notificationSettingsProvider = NotificationSettingsProvider();
  await notificationSettingsProvider.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => NameProvider()),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: notificationSettingsProvider),
        Provider(create: (context) => NotificationService()),
      ],
      child: MyApp(userId: userId, email: email),
    ),
  );
}

Future<String?> getSavedSession() async {
  final prefs = await SharedPreferences.getInstance();
  final sessionString = prefs.getString('supabase_session');
  print('Retrieved session: $sessionString'); // Debug log
  return sessionString;
}

class SplashScreen extends StatefulWidget {
  final String? userId;
  final String? email;
  const SplashScreen({super.key, required this.userId, this.email});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkConnectivityAndProceed();
  }

  Future<bool> _hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _showNoInternetDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              l10n.noInternetTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: Text(
              l10n.noInternetMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _checkConnectivityAndProceed();
                },
                child: Text(
                  l10n.retryButton,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        Theme.of(context).brightness == Brightness.light
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _checkConnectivityAndProceed() async {
    bool hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      _showNoInternetDialog();
    } else {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      widget.userId != null
                          ? BottomPageNavigation(
                            user_id: widget.userId!,
                            email: widget.email,
                          )
                          : const AuthenticationGate(),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assistant,
              size: 100,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.appName,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final String? userId;
  final String? email;
  const MyApp({super.key, required this.userId, this.email});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Adde Assistance App',
          theme: ThemeModes.lightMode,
          darkTheme: ThemeModes.darkMode,
          themeMode: themeProvider.themeMode,
          locale: localeProvider.locale,
          supportedLocales: const [Locale('en'), Locale('am')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            return localeProvider.locale;
          },
          home: SplashScreen(userId: userId, email: email),
        );
      },
    );
  }
}
