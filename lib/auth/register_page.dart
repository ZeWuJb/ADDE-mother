import 'package:adde/auth/authentication_service.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/health_form_page.dart';
import 'package:flutter/material.dart';
import 'package:adde/component/input_fild.dart';
import 'package:adde/auth/login_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final AuthenticationService _authService = AuthenticationService();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
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
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _showSnackBar(l10n.googleSignUpCancelledError);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw l10n.googleSignUpTokenError;
      }

      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.session != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => MotherFormPage(
                    email: googleUser.email,
                    user_id: response.user!.id,
                  ),
            ),
          );
        }
      } else {
        _showSnackBar(l10n.googleSignUpFailedError);
      }
    } catch (e) {
      _showSnackBar(l10n.signUpError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp(String email, String password) async {
    final l10n = AppLocalizations.of(context)!;
    if (password != confirmPasswordController.text) {
      _showSnackBar(l10n.passwordsDoNotMatchError);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _authService.signUpWithEmail(email, password);
      if (response.user != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.signUpSuccess,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.green.shade400,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      MotherFormPage(email: email, user_id: response.user!.id),
            ),
          );
        }
      } else {
        _showSnackBar(l10n.signUpFailedError);
      }
    } catch (e) {
      _showSnackBar(l10n.signUpError(e.toString()));
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
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
                padding: EdgeInsets.only(top: screenHeight * 0.06, bottom: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      _buildProfileImage(theme),
                      SizedBox(height: screenHeight * 0.03),
                      _buildWelcomeText(theme, l10n),
                      SizedBox(height: screenHeight * 0.03),
                      InputFiled(
                        controller: emailController,
                        hintText: l10n.emailLabel,
                        email: true,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      InputFiled(
                        controller: passwordController,
                        hintText: l10n.passwordLabel,
                        obscure: true,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      InputFiled(
                        controller: confirmPasswordController,
                        hintText: l10n.confirmPasswordLabel,
                        obscure: true,
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      _buildSignUpButton(theme, l10n),
                      SizedBox(height: screenHeight * 0.02),
                      _buildLoginLink(theme, l10n),
                      SizedBox(height: screenHeight * 0.06),
                      _buildGoogleSignInButton(theme, l10n),
                      SizedBox(height: screenHeight * 0.04),
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
          image: AssetImage("assets/user.png"),
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
          l10n.welcomeRegister,
          style: theme.textTheme.displayMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.assistMessage,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed:
            _isLoading
                ? null
                : () => _signUp(emailController.text, passwordController.text),
        style: theme.elevatedButtonTheme.style?.copyWith(
          minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 50)),
        ),
        child: Text(
          l10n.signUpButton,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink(ThemeData theme, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.alreadyHaveAccount,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              ),
          child: Text(
            l10n.loginLink,
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
                l10n.signUpWithGoogle,
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
