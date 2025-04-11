import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adde/component/input_fild.dart'; // Assuming this is your custom input widget

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool isLoading = false;
  bool isEmailSent = false;

  Future<void> sendPasswordResetEmail() async {
    setState(() => isLoading = true);
    try {
      final email = emailController.text.trim();

      if (email.isEmpty) {
        throw 'Please enter your email address';
      }

      // Send password reset email
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo:
            'io.supabase.adde://reset-password/', // Optional: Deep link to handle reset
      );

      setState(() {
        isEmailSent = true;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password reset email sent to $email"),
          backgroundColor: Colors.green.shade300,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red.shade300,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password"), elevation: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                "Reset Your Password",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isEmailSent
                    ? "Check your email for the reset link"
                    : "Enter your email to receive a reset link",
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 30),
              InputFiled(
                controller: emailController,
                hintText: "Email Address",
                email: true,
                enabled: !isEmailSent, // Disable input after email is sent
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    isLoading || isEmailSent ? null : sendPasswordResetEmail,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                    isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                          isEmailSent ? "Email Sent" : "Send Reset Link",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
