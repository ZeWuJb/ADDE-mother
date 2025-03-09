import 'package:adde/auth/authentication_service.dart';
import 'package:adde/pages/health_form_page.dart';

import 'package:flutter/material.dart';

import 'package:adde/component/input_fild.dart';
import 'package:adde/pages/login_page.dart';
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
  final _auth_service = AuthenticationService();
  final supabase = SupabaseClient(
    'https://kbqbwdmwzbkbpmayitib.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImticWJ3ZG13emJrYnBtYXlpdGliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk5NTA0MDQsImV4cCI6MjA1NTUyNjQwNH0.8b0DnlgE5UOlSa4OtMonctmFmDyLAr3zbj6ROrLRj0A',
  );

  Future<void> _nativeGoogleSignIn() async {
    /// TODO: update the Web client ID with your own.
    const webClientId =
        '455569810410-jjrlbek9hmpi5i9ia9c40ijusmnbrhhj.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: webClientId);
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      print("Google Sign-Up was canceled by the user.");
      return;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final String? accessToken = googleAuth.accessToken;
    final String? idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      print("Google Sign-Up Error: Missing tokens.");
      return;
    }

    try {
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      if (supabase.auth.currentSession != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MotherFormPage(email: googleUser.email),
          ),
        );
      }

      print("Google Sign-Up successful!");
      print("Supabase Session: ${response.session}");
    } catch (e) {
      print("Google Sign-Up Error: $e");
    }
  }

  signUp(String email, String password) async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: password not mached!!",
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
        ),
      );
      return;
    }
    try {
      final response = await _auth_service.signUpWithEmail(email, password);
      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            content: Text(
              "Signup successful!",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
        // Navigate to home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MotherFormPage(email: email)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            content: Text(
              "Signup failed. Please try again.",
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
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 70),
            child: Column(
              children: [
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/user.png"),
                    ),
                  ),
                ),
                SizedBox(height: 25),
                Text(
                  "WELCOME",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  "We Are Here, To Assist You!!!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                ),
                SizedBox(height: 25),
                InputFiled(
                  controller: emailController,
                  hintText: "Email Address",
                  email: true,
                ),
                InputFiled(
                  controller: passwordController,
                  hintText: "Password",
                  obscure: true,
                ),
                InputFiled(
                  controller: confirmPasswordController,
                  hintText: "Confirm passwor",
                  obscure: true,
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap:
                        () => signUp(
                          emailController.text,
                          passwordController.text,
                        ),

                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Text(
                            "SignUp",
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
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginPage(),
                            ),
                          );
                        },
                        child: Text(
                          "Login",
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
                          Text("Sign Up with Google"),
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
