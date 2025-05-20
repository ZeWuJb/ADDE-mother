import 'package:adde/auth/change_password_page.dart';
import 'package:adde/auth/register_page.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:adde/pages/bottom_page_navigation.dart';
import 'package:adde/auth/authentication_service.dart';
import 'package:adde/component/input_fild.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthenticationService authenticationService = AuthenticationService();
  final supabase = Supabase.instance.client;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0); // Ensure top is visible on load
      }
    });
  }

  Future<void> _saveSession(String session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('supabase_session', session);
  }

  Future<void> _nativeGoogleSignIn() async {
    setState(() => _isLoading = true);
    const webClientId =
        '455569810410-jjrlbek9hmpi5i9ia9c40ijusmnbrhhj.apps.googleusercontent.com';
    final l10n = AppLocalizations.of(context)!;

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw l10n.googleSignInCancelledError;

      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw l10n.googleAuthFailedError;
      }

      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );

      if (response.session != null) {
        await _saveSession(response.session!.accessToken);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => BottomPageNavigation(
                    user_id: response.user!.id,
                    email: response.user?.email,
                  ),
            ),
          );
        }
      } else {
        _showSnackBar(l10n.googleSignInFailedError);
      }
    } catch (e) {
      _showSnackBar(
        e.toString().contains('cancelled')
            ? l10n.googleSignInCancelledError
            : l10n.errorLabel(e.toString()),
      ); // Improved error handling
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    final email = userNameController.text.trim();
    final password = passwordController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar(l10n.emptyFieldsError);
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackBar(l10n.invalidEmailError);
      return;
    }
    if (password.length < 6) {
      _showSnackBar(l10n.invalidPasswordError);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await authenticationService.signInWithEmailAndPassword(
        email,
        password,
      );
      if (response.session != null) {
        await _saveSession(response.session!.accessToken);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => BottomPageNavigation(
                    email: email,
                    user_id: supabase.auth.currentUser!.id,
                  ),
            ),
          );
        }
      } else {
        _showSnackBar(l10n.loginFailedError);
      }
    } catch (e) {
      _showSnackBar(l10n.errorLabel(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  void dispose() {
    userNameController.dispose();
    passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.2),
                    theme.colorScheme.secondary.withOpacity(0.2),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            controller: _scrollController,
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.08, bottom: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      _buildProfileImage(theme),
                      SizedBox(height: screenHeight * 0.03),
                      _buildWelcomeText(theme, l10n),
                      SizedBox(height: screenHeight * 0.03),
                      InputFiled(
                        controller: userNameController,
                        hintText: l10n.emailLabel,
                        email: true,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      InputFiled(
                        controller: passwordController,
                        hintText: l10n.passwordLabel,
                        obscure: true,
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      _buildForgetPasswordLink(theme, l10n),
                      SizedBox(height: screenHeight * 0.015),
                      _buildLoginButton(theme, l10n),
                      SizedBox(height: screenHeight * 0.02),
                      _buildRegisterLink(theme, l10n),
                      SizedBox(height: screenHeight * 0.06),
                      _buildGoogleSignInButton(theme, l10n),
                      SizedBox(height: screenHeight * 0.08),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: theme.colorScheme.shadow.withOpacity(0.3),
                child: Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(ThemeData theme) {
    return Container(
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage("assets/profile.png"),
          fit: BoxFit.cover,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeText(ThemeData theme, AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.welcomeBack,
          style: theme.textTheme.displayMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.appName,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildForgetPasswordLink(ThemeData theme, AppLocalizations l10n) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordPage(),
                ),
              ),
          child: Text(
            l10n.forgetPassword,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: theme.elevatedButtonTheme.style?.copyWith(
          minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 50)),
        ),
        child: Text(
          l10n.logIn,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink(ThemeData theme, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.noAccount,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WelcomePage()),
              ),
          child: Text(
            l10n.register,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton(ThemeData theme, AppLocalizations l10n) {
    return GestureDetector(
      onTap: _isLoading ? null : _nativeGoogleSignIn,
      child: Container(
        width: 225,
        decoration: BoxDecoration(
          border: Border.all(width: 1, color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(10),
          color: theme.colorScheme.surfaceContainerHighest,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/google.png", width: 24),
              const SizedBox(width: 10),
              Text(
                l10n.signInWithGoogle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
