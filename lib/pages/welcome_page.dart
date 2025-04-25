import 'package:adde/auth/register_page.dart';
import 'package:flutter/material.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  static const List<Map<String, String>> _imageContent = [
    {
      "title": "Adey Pregnancy And Child Care App",
      "image": "assets/woman.png",
      "content":
          "Welcome to Adey, your trusted partner for a safe and healthy pregnancy and child care journey.",
    },
    {
      "image": "assets/woman-1.png",
      "content":
          "Track your pregnancy and postpartum progress with tools for weight tracking, contraction timing, and breastfeeding.",
    },
    {
      "image": "assets/notebook.png",
      "content":
          "Access educational resources on maternal health, including articles, videos, and podcasts.",
    },
    {
      "image": "assets/notebook.png",
      "content":
          "Connect with a community of users, share experiences, and receive support.",
    },
    {
      "image": "assets/chatbot-1.png",
      "content":
          "Use our chatbot for instant responses and guidance on pregnancy and child care queries.",
    },
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

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          // Gradient Background
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
          // Main Content
          Column(
            children: [
              // Carousel Section
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _imageContent.length,
                  onPageChanged:
                      (index) => setState(() => _currentPage = index),
                  itemBuilder:
                      (context, index) => _buildPageContent(
                        theme,
                        _imageContent[index],
                        screenHeight,
                      ),
                ),
              ),
              // Bottom Section: Pagination Dots and Buttons
              Padding(
                padding: EdgeInsets.all(screenHeight * 0.02),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Skip Button
                    TextButton(
                      onPressed: _navigateToRegister,
                      style: theme.textButtonTheme.style?.copyWith(
                        foregroundColor: WidgetStatePropertyAll(
                          theme.colorScheme.primary,
                        ),
                      ),
                      child: Text(
                        "Skip",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        semanticsLabel: "Skip onboarding",
                      ),
                    ),
                    // Pagination Dots
                    Row(
                      children: List.generate(
                        _imageContent.length,
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
                    // Next Button
                    TextButton(
                      onPressed: () {
                        if (_currentPage < _imageContent.length - 1) {
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
                        _currentPage == _imageContent.length - 1
                            ? "Get Started"
                            : "Next",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        semanticsLabel:
                            _currentPage == _imageContent.length - 1
                                ? "Get started"
                                : "Next page",
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
    Map<String, String> content,
    double screenHeight,
  ) {
    return Semantics(
      label: "Onboarding page ${_currentPage + 1}",
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.02),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (content["title"] != null) ...[
              Text(
                content["title"]!,
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
                  image: AssetImage(content["image"]!),
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
              content["content"]!,
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
