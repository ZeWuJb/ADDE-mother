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
        Provider(
          create: (context) => NotificationService(),
        ), // Initialized here
      ],
      child: MyApp(session: session),
    ),
  );
}

Future<String?> getSavedSession() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('supabase_session');
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
      home:
          session != null
              ? HomePage(
                user_id: Supabase.instance.client.auth.currentUser!.id,
                email: Supabase.instance.client.auth.currentUser?.email,
              )
              : const AuthenticationGate(),
    );
  }
}
