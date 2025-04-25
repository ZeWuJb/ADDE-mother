import 'dart:convert';
import 'package:adde/pages/profile/profile_edit_page.dart';
import 'package:adde/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  String? profileImageBase64;
  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No user logged in')));
        return;
      }

      final response =
          await supabase
              .from('mothers')
              .select()
              .eq('user_id', user.id)
              .single();

      setState(() {
        nameController.text = response['full_name'] ?? '';
        ageController.text = response['age']?.toString() ?? '';
        profileImageBase64 = response['profile_url'];
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final email = supabase.auth.currentUser?.email ?? 'No email';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor:
            Theme.of(
              context,
            ).appBarTheme.backgroundColor, // #ff8fab (light), black (dark)
        foregroundColor:
            Theme.of(
              context,
            ).appBarTheme.foregroundColor, // black87 (light), white (dark)
        elevation: Theme.of(context).appBarTheme.elevation,
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color:
                      Theme.of(
                        context,
                      ).colorScheme.primary, // #fb6f92 (light), white (dark)
                ),
              )
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 70,
                              backgroundImage:
                                  profileImageBase64 != null
                                      ? MemoryImage(
                                        base64Decode(profileImageBase64!),
                                      )
                                      : const AssetImage('assets/user.png')
                                          as ImageProvider,
                              backgroundColor:
                                  Theme.of(context)
                                      .colorScheme
                                      .surface, // #ffe5ec (light), black87 (dark)
                            ),
                            const SizedBox(height: 8),
                            Text(
                              email,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context)
                                        .colorScheme
                                        .onSurface, // #fb6f92 (light), white (dark)
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: Theme.of(context).cardTheme.elevation,
                        shape: Theme.of(context).cardTheme.shape,
                        color:
                            Theme.of(context)
                                .cardTheme
                                .color, // #FDE2E4 (light), black54 (dark)
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const ProfileEditPage(),
                                  ),
                                )
                                .then((_) => _loadProfileData());
                          },
                          borderRadius:
                              (Theme.of(context).cardTheme.shape
                                          as RoundedRectangleBorder)
                                      .borderRadius
                                  as BorderRadius, // Cast to BorderRadius
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  color:
                                      Theme.of(context)
                                          .colorScheme
                                          .primary, // #fb6f92 (light), white (dark)
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Edit Profile',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context)
                                            .colorScheme
                                            .onSurface, // #fb6f92 (light), white (dark)
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        height: 2,
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context)
                                  .colorScheme
                                  .outline, // grey[400] (light), grey[700] (dark)
                        ),
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: Icon(
                          themeProvider.themeMode == ThemeMode.light
                              ? Icons.light_mode
                              : Icons.dark_mode,
                          color:
                              Theme.of(context)
                                  .colorScheme
                                  .onSurface, // #fb6f92 (light), white (dark)
                        ),
                        title: Text(
                          'Theme Mode',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context)
                                    .colorScheme
                                    .onSurface, // #fb6f92 (light), white (dark)
                          ),
                        ),
                        trailing: Switch(
                          value: themeProvider.themeMode == ThemeMode.dark,
                          onChanged:
                              (value) => themeProvider.toggleTheme(value),
                          activeColor:
                              Theme.of(context)
                                  .colorScheme
                                  .primary, // #fb6f92 (light), white (dark)
                          inactiveTrackColor:
                              Theme.of(context)
                                  .colorScheme
                                  .outline, // grey[400] (light), grey[700] (dark)
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
