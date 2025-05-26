import 'package:adde/auth/authentication_service.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/health_form_page.dart';
import 'package:flutter/material.dart';
import 'package:adde/component/input_fild.dart';
import 'package:adde/auth/login_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    // Background gradient animation
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
    _gradientColorAnimation = ColorTween(
      begin: Colors.blue.withOpacity(0.2),
      end: Colors.purple.withOpacity(0.2),
    ).animate(
      CurvedAnimation(
        parent: _backgroundAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Fade animation for loading overlay
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
  void didUpdateWidget(RegisterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isLoading) {
      _fadeController.forward();
    } else {
      _fadeController.reverse();
    }
  }

  Future<void> _nativeGoogleSignIn() async {
    setState(() => _isLoading = true);
    var webClientId = dotenv.env['WEB_CLIENT_ID']!;
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

      if (response.session != null && mounted) {
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
      if (response.user != null && mounted) {
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
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    MotherFormPage(email: email, user_id: response.user!.id),
            settings: const RouteSettings(name: '/mother_form'),
          ),
        );
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
          duration: const Duration(seconds: 3),
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
    _backgroundAnimationController.dispose();
    _fadeController.dispose();
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
          // Animated background gradient
          AnimatedBuilder(
            animation: _backgroundAnimationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _gradientColorAnimation.value ??
                          theme.colorScheme.primary.withOpacity(0.2),
                      theme.colorScheme.secondary.withOpacity(0.2),
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
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      _buildProfileImage(theme),
                      SizedBox(height: screenHeight * 0.03),
                      _buildWelcomeText(theme, l10n),
                      SizedBox(height: screenHeight * 0.03),
                      _buildInputField(
                        emailController,
                        l10n.emailLabel,
                        true,
                        0,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      _buildInputField(
                        passwordController,
                        l10n.passwordLabel,
                        true,
                        1,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      _buildInputField(
                        confirmPasswordController,
                        l10n.confirmPasswordLabel,
                        true,
                        2,
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
    );
  }

  Widget _buildProfileImage(ThemeData theme) {
    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 600),
        child: Container(
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
        ),
      ),
    );
  }

  Widget _buildWelcomeText(ThemeData theme, AppLocalizations l10n) {
    return Column(
      children: [
        AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 500),
          child: AnimatedSlide(
            offset: const Offset(0, 0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            child: Text(
              l10n.welcomeRegister,
              style: theme.textTheme.displayMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 500),
          child: AnimatedSlide(
            offset: const Offset(0, 0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            child: Text(
              l10n.assistMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
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
    return AnimatedOpacity(
      opacity: 1.0,
      duration: Duration(milliseconds: 500 + index * 100),
      child: AnimatedSlide(
        offset: const Offset(0, 0),
        duration: Duration(milliseconds: 500 + index * 100),
        curve: Curves.easeOut,
        child: InputFiled(
          controller: controller,
          hintText: hintText,
          obscure: obscure,
          email: hintText == AppLocalizations.of(context)!.emailLabel,
        ),
      ),
    );
  }

  Widget _buildSignUpButton(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedScale(
        scale: _isLoading ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: ElevatedButton(
          onPressed:
              _isLoading
                  ? null
                  : () =>
                      _signUp(emailController.text, passwordController.text),
          style: theme.elevatedButtonTheme.style?.copyWith(
            minimumSize: const WidgetStatePropertyAll(
              Size(double.infinity, 50),
            ),
            elevation: WidgetStateProperty.resolveWith<double>(
              (states) => states.contains(WidgetState.pressed) ? 2 : 8,
            ),
            shadowColor: WidgetStatePropertyAll(
              theme.colorScheme.shadow.withOpacity(0.3),
            ),
          ),
          child: Text(
            l10n.signUpButton,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimary,
            ),
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
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                  settings: const RouteSettings(name: '/login'),
                ),
              ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style:
                theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ) ??
                const TextStyle(),
            child: Text(l10n.loginLink),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton(ThemeData theme, AppLocalizations l10n) {
    return GestureDetector(
      onTap: _isLoading ? null : _nativeGoogleSignIn,
      child: AnimatedScale(
        scale: _isLoading ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Container(
          width: 225,
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(10),
            color: theme.colorScheme.surfaceContainerHighest,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: Image.asset("assets/google.png", width: 24),
                ),
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
      ),
    );
  }
}
