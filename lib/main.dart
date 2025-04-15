import 'package:adde/pages/community/chat_provider.dart';
import 'package:adde/pages/community/post_provider.dart';
import 'package:adde/pages/notification/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adde/auth/authentication_gate.dart';
import 'package:adde/pages/bottom_page_navigation.dart';
import 'package:adde/theme/theme_data.dart';
import 'package:adde/theme/theme_provider.dart';

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
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  widget.session != null
                      ? HomePage(
                        user_id: Supabase.instance.client.auth.currentUser!.id,
                        email: Supabase.instance.client.auth.currentUser?.email,
                      )
                      : const AuthenticationGate(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade300,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assistant, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'Adde Assistance',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
