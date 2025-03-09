import 'package:flutter/material.dart';
import 'package:adde/pages/register_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int current_page = 0;

  final image_content = [
    {
      "title": "Adey Pregnancy And Child Care App",
      "image": "assets/woman.png",
      "content":
          "Welcome to Adey, your  trusted partner for a safe and health pregnaancy and child care journy",
    },
    {
      "image": "assets/woman-1.png",
      "content":
          "The app will provide tracking tools to help users monitor their pregnancy and postpartum progress, including weight tracking, contraction timing, and breastfeeding tracker.",
    },
    {
      "image": "assets/notebook.png",
      "content":
          "The app will provide educational resources to help users learn about maternal health, including articles, videos, and podcasts.",
    },
    {
      "image": "assets/notebook.png",
      "content":
          "The app will provide a community support feature to help users connect with other users, share experiences, and receive support.",
    },
    {
      "image": "assets/chatbot-1.png",
      "content":
          "The app will provide a chatbot feature to assist users with pregnancy and child care-related queries, offering instant responses, guidance, and support based on user concerns and frequently asked questions",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                SizedBox(height: 100),
                Text(
                  image_content[current_page]["title"] != null
                      ? image_content[current_page]["title"]!
                      : "",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
                ),
                Container(
                  height: 250,
                  width: 300,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(image_content[current_page]["image"]!),
                    ),
                  ),
                ),
                Text(
                  image_content[current_page]["content"]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterPage()),
                    );
                  },
                  child: Text(
                    "Skip",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      ".",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight:
                            current_page == 0
                                ? FontWeight.w700
                                : FontWeight.w300,
                        color:
                            current_page == 0
                                ? Theme.of(context).colorScheme.onSecondary
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      ".",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight:
                            current_page == 1
                                ? FontWeight.w700
                                : FontWeight.w300,
                        color:
                            current_page == 1
                                ? Theme.of(context).colorScheme.onSecondary
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      ".",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight:
                            current_page == 2
                                ? FontWeight.w700
                                : FontWeight.w300,
                        color:
                            current_page == 2
                                ? Theme.of(context).colorScheme.onSecondary
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      ".",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight:
                            current_page == 3
                                ? FontWeight.w700
                                : FontWeight.w300,
                        color:
                            current_page == 3
                                ? Theme.of(context).colorScheme.onSecondary
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      ".",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight:
                            current_page == 4
                                ? FontWeight.w700
                                : FontWeight.w300,
                        color:
                            current_page == 4
                                ? Theme.of(context).colorScheme.onSecondary
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      ".",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight:
                            current_page == 5
                                ? FontWeight.w700
                                : FontWeight.w300,
                        color:
                            current_page == 5
                                ? Theme.of(context).colorScheme.onSecondary
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (current_page < image_content.length - 1) {
                        current_page++;
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterPage(),
                          ),
                        );
                      }
                    });
                  },
                  child: Text(
                    "Next",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
