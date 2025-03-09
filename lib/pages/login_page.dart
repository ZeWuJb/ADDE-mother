import 'package:adde/auth/authentication_service.dart';
import 'package:adde/pages/home_page.dart';
import 'package:adde/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:adde/component/input_fild.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late String email;
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthenticationService authenticatioService = AuthenticationService();
  final supabase = SupabaseClient(
    'https://kbqbwdmwzbkbpmayitib.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImticWJ3ZG13emJrYnBtYXlpdGliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk5NTA0MDQsImV4cCI6MjA1NTUyNjQwNH0.8b0DnlgE5UOlSa4OtMonctmFmDyLAr3zbj6ROrLRj0A',
  );

  Future<void> _nativeGoogleSignIn() async {
    const webClientId =
        '455569810410-jjrlbek9hmpi5i9ia9c40ijusmnbrhhj.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: webClientId);
    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser!.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;
    try {
      if (accessToken == null) {
        throw 'No Access Token found.';
      }
      if (idToken == null) {
        throw 'No ID Token found.';
      }

      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      if (supabase.auth.currentSession != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(email: response.user?.email),
          ),
        );
      }

      print("Google Sign-In successful!");
      print("Supabase Session: ${response.session}");
    } catch (e) {
      print("Google Sign-In Error: $e");
    }
  }

  // Function to fetch pregnancy data from the 'mothers' table
  // Function to fetch pregnancy data from the 'mothers' table
  Future<void> _fetchPregnancyData(String email) async {
    try {
      final response = await Supabase.instance.client
          .from('mothers')
          .select('email') // Select only relevant columns
          .eq('email', email) // Filter by email
          .limit(1); // Limit to one result

      if (response.isNotEmpty) {
        setState(() {
          this.email = response[0]['email'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load pregnancy data.")),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("An error occurred: $error")));
    }
  }

  void login() async {
    final email = userNameController.text.trim();
    final password = passwordController.text.trim();

    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter both email and password."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final response = await authenticatioService.signInWithEmailAndPassword(
        email,
        password,
      );

      if (response.session != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Login successful!",
              style: TextStyle(color: Colors.green),
            ),
          ),
        );

        // Fetch pregnancy data after successful login
        await _fetchPregnancyData(email);

        // Navigate to HomePage with the email
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(email: email)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Login failed. Please try again.",
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          content: Text(
            "Error: $e",
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    userNameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/profile.png"),
                      fit: BoxFit.cover,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(height: 25),

                // Welcome Back Text
                Text(
                  "WELCOME BACK",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 10),
                Text(
                  "Adde Assistance App!!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                ),
                SizedBox(height: 25),

                // Input Fields
                InputFiled(
                  controller: userNameController,
                  hintText: "Email Address",
                  email: true,
                ),
                InputFiled(
                  controller: passwordController,
                  hintText: "Password",
                  obscure: true,
                ),

                // Forget Password
                Padding(
                  padding: const EdgeInsets.only(left: 220, top: 10),
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Forget Password feature coming soon!"),
                        ),
                      );
                    },
                    child: Text(
                      "Forget password",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),

                // LogIn Button
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: login,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Text(
                            "LogIn",
                            style: TextStyle(
                              fontSize: 22,
                              color: Theme.of(context).colorScheme.onSecondary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Register Link
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WelcomePage(),
                            ),
                          );
                        },
                        child: Text(
                          "Register",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 50),
                GestureDetector(
                  onTap: _nativeGoogleSignIn,
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Image.asset("assets/google.png", width: 30),
                          SizedBox(width: 10),
                          Text("SignIn with Google"),
                        ],
                      ),
                    ),
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
