import 'dart:convert';
import 'package:adde/auth/authentication_service.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/health_form_page.dart';
import 'package:flutter/material.dart';
import 'package:adde/component/input_fild.dart';
import 'package:adde/auth/login_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final AuthenticationService _authService = AuthenticationService();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _backgroundAnimationController;
  late Animation<Color?> _gradientColorAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  String? _lastLocale;

  @override
  void initState() {
    super.initState();
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;

    if (_lastLocale != currentLocale) {
      _lastLocale = currentLocale;
      setState(() {});
    }

    if (!_backgroundAnimationController.isAnimating) {
      _gradientColorAnimation = ColorTween(
        begin: theme.colorScheme.primary.withOpacity(0.2),
        end: theme.colorScheme.secondary.withOpacity(0.2),
      ).animate(
        CurvedAnimation(
          parent: _backgroundAnimationController,
          curve: Curves.easeInOut,
        ),
      );
      _backgroundAnimationController.repeat(reverse: true);
    }

    if (_isLoading) {
      _fadeController.forward();
    } else {
      _fadeController.reverse();
    }
  }

  Future<void> _saveSession(Session session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = session.toJson();
      final sessionString = jsonEncode(sessionJson);
      await prefs.setString('supabase_session', sessionString);
      print('Session saved successfully');
    } catch (e) {
      print('Error saving session: $e');
      if (mounted) {
        _showSnackBar(AppLocalizations.of(context)!.signUpError(e.toString()));
      }
    }
  }

  Future<void> _nativeGoogleSignIn() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;
    final webClientId = dotenv.env['WEB_CLIENT_ID'];

    if (webClientId == null || webClientId.isEmpty) {
      _showSnackBar(l10n.googleSignUpConfigError);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw l10n.googleSignUpCancelledError;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw l10n.googleSignUpTokenError;
      }

      final response = await Supabase.instance.client.auth
          .signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          )
          .timeout(const Duration(seconds: 10));

      if (response.session != null && mounted) {
        await _saveSession(response.session!);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => MotherFormPage(
                  email: googleUser.email,
                  user_id: response.user!.id,
                ),
            settings: const RouteSettings(name: '/mother_form'),
          ),
        );
      } else {
        throw l10n.googleSignUpFailedError;
      }
    } catch (e) {
      print('Google Sign-Up error: $e');
      if (mounted) {
        _showSnackBar(
          e.toString().contains('cancelled')
              ? l10n.googleSignUpCancelledError
              : l10n.signUpError(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUp(String email, String password) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    if (email.isEmpty ||
        password.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _showSnackBar(l10n.emptyFieldsError);
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackBar(l10n.invalidEmailError);
      return;
    }
    if (password.length < 6) {
      _showSnackBar(l10n.passwordTooShortError);
      return;
    }
    if (password != confirmPasswordController.text) {
      _showSnackBar(l10n.passwordsDoNotMatchError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService
          .signUpWithEmail(email, password)
          .timeout(const Duration(seconds: 10));

      if (response.session != null && response.user != null && mounted) {
        await _saveSession(response.session!);
        _showSnackBar(l10n.signUpSuccess, isSuccess: true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      MotherFormPage(email: email, user_id: response.user!.id),
              settings: const RouteSettings(name: '/mother_form'),
            ),
          );
        }
      } else {
        throw l10n.signUpFailedError;
      }
    } catch (e) {
      print('Sign-Up error: $e');
      if (mounted) {
        _showSnackBar(l10n.signUpError(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color:
                isSuccess
                    ? Colors.white
                    : Theme.of(context).colorScheme.onError,
          ),
        ),
        backgroundColor:
            isSuccess
                ? Colors.green.shade400
                : Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.retryButton,
          onPressed: () {
            if (message.contains('Google')) {
              _nativeGoogleSignIn();
            } else {
              _signUp(emailController.text, passwordController.text);
            }
          },
          textColor:
              isSuccess ? Colors.white : Theme.of(context).colorScheme.onError,
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _scrollController.dispose();
    _backgroundAnimationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedBuilder(
              animation: _backgroundAnimationController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _gradientColorAnimation.value ??
                            theme.colorScheme.primary.withOpacity(0.2),
                        theme.colorScheme.surface,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                );
              },
            ),
            SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: screenHeight * 0.06,
                    bottom: screenHeight * 0.04,
                    left: 16,
                    right: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      children: [
                        _buildProfileImage(theme).animate().scale(
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        _buildWelcomeText(
                          theme,
                          l10n,
                        ).animate().fadeIn(duration: 500.ms),
                        SizedBox(height: screenHeight * 0.03),
                        _buildInputField(
                          emailController,
                          l10n.emailLabel,
                          false,
                          0,
                        ).animate().slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 500.ms,
                          delay: 100.ms,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        _buildInputField(
                          passwordController,
                          l10n.passwordLabel,
                          true,
                          1,
                        ).animate().slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 500.ms,
                          delay: 200.ms,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        _buildInputField(
                          confirmPasswordController,
                          l10n.confirmPasswordLabel,
                          true,
                          2,
                        ).animate().slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 500.ms,
                          delay: 300.ms,
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        _buildSignUpButton(
                          theme,
                          l10n,
                        ).animate().scale(duration: 500.ms, delay: 400.ms),
                        SizedBox(height: screenHeight * 0.02),
                        _buildLoginLink().animate().fadeIn(
                          duration: 500.ms,
                          delay: 500.ms,
                        ),
                        SizedBox(height: screenHeight * 0.06),
                        _buildGoogleSignInButton().animate().scale(
                          duration: 500.ms,
                          delay: 600.ms,
                        ),
                        SizedBox(height: screenHeight * 0.04),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  color: theme.colorScheme.shadow.withOpacity(0.3),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                      strokeWidth: 5,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
            color: theme.colorScheme.shadow.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.assistMessage,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hintText,
    bool obscure,
    int index,
  ) {
    return InputFiled(
      controller: controller,
      hintText: hintText,
      obscure: obscure,
      email: hintText == AppLocalizations.of(context)!.emailLabel,
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
          elevation: WidgetStateProperty.resolveWith<double>(
            (states) => states.contains(WidgetState.pressed) ? 2 : 8,
          ),
          shadowColor: WidgetStatePropertyAll(
            theme.colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child:
            _isLoading
                ? CircularProgressIndicator(
                  color: theme.colorScheme.onPrimary,
                  strokeWidth: 2,
                )
                : Text(
                  l10n.signUpButton,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
      ),
    );
  }

  Widget _buildLoginLink() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
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
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                  settings: const RouteSettings(name: '/login'),
                ),
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

  Widget _buildGoogleSignInButton() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: _isLoading ? null : _nativeGoogleSignIn,
      child: Container(
        width: 225,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.secondaryContainer,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/google.png", height: 24),
              const SizedBox(width: 8),
              Text(
                l10n.signUpWithGoogle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
