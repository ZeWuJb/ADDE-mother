import 'package:adde/pages/community/chat_provider.dart';
import 'package:adde/pages/community/post_provider.dart';
import 'package:adde/pages/name_suggestion/name_provider.dart';
import 'package:adde/pages/note/note_provider.dart';
import 'package:adde/pages/notification/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adde/auth/authentication_gate.dart';
import 'package:adde/pages/bottom_page_navigation.dart';
import 'package:adde/theme/theme_data.dart';
import 'package:adde/theme/theme_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kbqbwdmwzbkbpmayitib.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImticWJ3ZG13emJrYnBtYXlpdGliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk5NTA0MDQsImV4cCI6MjA1NTUyNjQwNH0.8b0DnlgE5UOlSa4OtMonctmFmDyLAr3zbj6ROrLRj0A',
  );

  final session = await getSavedSession();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => NameProvider()),
        Provider(create: (context) => NotificationService()),
      ],
      child: MyApp(session: session),
    ),
  );
}

Future<String?> getSavedSession() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('supabase_session');
}

class SplashScreen extends StatefulWidget {
  final String? session;
  const SplashScreen({super.key, required this.session});

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              'No Internet Connection',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color:
                    Theme.of(
                      context,
                    ).colorScheme.onSurface, // #fb6f92 (light), white (dark)
              ),
            ),
            content: Text(
              'Please check your internet connection and try again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant, // black54 (light), white70 (dark)
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _checkConnectivityAndProceed();
                },
                child: Text(
                  'Retry',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        Theme.of(context).brightness == Brightness.light
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onPrimary, // #fb6f92 (light), white (dark)
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
                      widget.session != null
                          ? HomePage(
                            user_id:
                                Supabase.instance.client.auth.currentUser!.id,
                            email:
                                Supabase
                                    .instance
                                    .client
                                    .auth
                                    .currentUser
                                    ?.email,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          Theme.of(context).brightness == Brightness.light
              ? Theme.of(context).colorScheme.primary
              : Theme.of(
                context,
              ).colorScheme.onPrimary, // #fb6f92 (light), white (dark)
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assistant,
              size: 100,
              color:
                  Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(
                        context,
                      ).colorScheme.primary, // white (light), black (dark)
            ),
            const SizedBox(height: 20),
            Text(
              'Adde Assistance',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color:
                    Theme.of(context).brightness == Brightness.light
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(
                          context,
                        ).colorScheme.primary, // white (light), black (dark)
              ),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).brightness == Brightness.light
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(
                      context,
                    ).colorScheme.primary, // white (light), black (dark)
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final String? session;
  const MyApp({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Adde Assistance App',
      theme: ThemeModes.lightMode,
      darkTheme: ThemeModes.darkMode,
      themeMode: themeProvider.themeMode,
      home: SplashScreen(session: session),
    );
  }
}
