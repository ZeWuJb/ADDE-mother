import 'package:adde/auth/register_page.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:flutter/material.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  late AnimationController _backgroundAnimationController;
  late Animation<Color?> _gradientColorAnimation;

  // Define image paths as a constant list since they don't need localization
  static const List<String> _imagePaths = [
    "assets/woman.png",
    "assets/woman-1.png",
    "assets/notebook.png",
    "assets/community.png",
    "assets/chatbot-1.png",
  ];

  @override
  void initState() {
    super.initState();
    // Initialize background gradient animation
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
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  void _navigateToRegister() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterPage(),
        settings: const RouteSettings(name: '/register'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
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
                      theme.colorScheme.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              );
            },
          ),
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _imagePaths.length,
                  onPageChanged:
                      (index) => setState(() => _currentPage = index),
                  itemBuilder:
                      (context, index) =>
                          _buildPageContent(theme, l10n, index, screenHeight),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(screenHeight * 0.02),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAnimatedButton(
                      text: l10n.skipButton,
                      semanticsLabel: l10n.skipSemantics,
                      onPressed: _navigateToRegister,
                      theme: theme,
                    ),
                    Row(
                      children: List.generate(
                        _imagePaths.length,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color:
                                  _currentPage == index
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withOpacity(
                                        0.5,
                                      ),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow:
                                  _currentPage == index
                                      ? [
                                        BoxShadow(
                                          color: theme.colorScheme.primary
                                              .withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                      : [],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildAnimatedButton(
                      text:
                          _currentPage == _imagePaths.length - 1
                              ? l10n.getStartedButton
                              : l10n.nextButton,
                      semanticsLabel:
                          _currentPage == _imagePaths.length - 1
                              ? l10n.getStartedSemantics
                              : l10n.nextSemantics,
                      onPressed: () {
                        if (_currentPage < _imagePaths.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOutQuad,
                          );
                        } else {
                          _navigateToRegister();
                        }
                      },
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedButton({
    required String text,
    required String semanticsLabel,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(1.0),
        child: TextButton(
          onPressed: onPressed,
          style: theme.textButtonTheme.style?.copyWith(
            foregroundColor: WidgetStatePropertyAll(theme.colorScheme.primary),
            overlayColor: WidgetStatePropertyAll(
              theme.colorScheme.primary.withOpacity(0.1),
            ),
          ),
          child: Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            semanticsLabel: semanticsLabel,
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(
    ThemeData theme,
    AppLocalizations l10n,
    int index,
    double screenHeight,
  ) {
    final String title = index == 0 ? l10n.welcomePageTitle1 : '';
    final String content = switch (index) {
      0 => l10n.welcomePageContent1,
      1 => l10n.welcomePageContent2,
      2 => l10n.welcomePageContent3,
      3 => l10n.welcomePageContent4,
      4 => l10n.welcomePageContent5,
      _ => '',
    };

    return Semantics(
      label: l10n.onboardingPageSemantics(index + 1),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.02),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (title.isNotEmpty) ...[
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 500),
                child: AnimatedSlide(
                  offset: const Offset(0, 0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
            ],
            AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 600),
                child: Container(
                  height: screenHeight * 0.35,
                  width: screenHeight * 0.4,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(_imagePaths[index]),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 500),
              child: AnimatedSlide(
                offset: const Offset(0, 0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                child: Text(
                  content,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
