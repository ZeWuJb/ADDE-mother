import 'package:adde/auth/register_page.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:flutter/material.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  // Define image paths as a constant list since they don't need localization
  static const List<String> _imagePaths = [
    "assets/woman.png",
    "assets/woman-1.png",
    "assets/notebook.png",
    "assets/community.png",
    "assets/chatbot-1.png",
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToRegister() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
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
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.2),
                    theme.colorScheme.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
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
                    TextButton(
                      onPressed: _navigateToRegister,
                      style: theme.textButtonTheme.style?.copyWith(
                        foregroundColor: WidgetStatePropertyAll(
                          theme.colorScheme.primary,
                        ),
                      ),
                      child: Text(
                        l10n.skipButton,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        semanticsLabel: l10n.skipSemantics,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        _imagePaths.length,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
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
                            ),
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (_currentPage < _imagePaths.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _navigateToRegister();
                        }
                      },
                      style: theme.textButtonTheme.style?.copyWith(
                        foregroundColor: WidgetStatePropertyAll(
                          theme.colorScheme.primary,
                        ),
                      ),
                      child: Text(
                        _currentPage == _imagePaths.length - 1
                            ? l10n.getStartedButton
                            : l10n.nextButton,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        semanticsLabel:
                            _currentPage == _imagePaths.length - 1
                                ? l10n.getStartedSemantics
                                : l10n.nextSemantics,
                      ),
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

  Widget _buildPageContent(
    ThemeData theme,
    AppLocalizations l10n,
    int index,
    double screenHeight,
  ) {
    // Map index to localized content
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
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
            ],
            Container(
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
                    color: theme.colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              content,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
