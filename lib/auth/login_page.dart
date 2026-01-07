import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/home_page.dart';
import 'signup_page.dart';

/// LoginPage is a StatefulWidget because
/// - it manages loading state
/// - password visibility toggle
/// - Firebase async calls
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers to read text from TextFields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Controls loading spinner on Login button
  bool isLoading = false;

  // Controls password visibility (eye icon)
  bool _obscurePassword = true;

  /// initState runs ONCE when this screen loads
  /// Used here to auto-login already verified users
  @override
  void initState() {
    super.initState();
    autoLogin();
  }

  /// Automatically logs in the user if:
  /// - user is already logged in
  /// - email is verified
  /// Prevents showing login screen again
  Future<void> autoLogin() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      // Small delay for smoother navigation
      await Future.delayed(const Duration(milliseconds: 300));

      // Safety check to avoid widget crash
      if (!mounted) return;

      // Replace login page with home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  /// Handles user login with Firebase Authentication
  /// Steps:
  /// 1. Validate input
  /// 2. Login with Firebase
  /// 3. Check email verification
  /// 4. Navigate to HomePage
  Future<void> login() async {
    // Basic validation
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email and password are required")),
      );
      return;
    }

    try {
      // Show loading spinner
      setState(() => isLoading = true);

      // Firebase login
      final userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Block unverified users
      if (!userCredential.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please verify your email before logging in."),
          ),
        );
        return;
      }

      if (!mounted) return;

      // Successful login → go to home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } finally {
      // Stop loading spinner
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// Sends password reset email to user
  /// Only works if email field is not empty
  Future<void> forgotPassword() async {
    if (emailController.text.trim().isEmpty) return;

    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: emailController.text.trim(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password reset email sent")),
    );
  }

  /// Builds the UI for the Login Page
  /// Uses responsive sizing so layout works on all devices
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[300],

      /// SafeArea prevents UI from going under notch/status bar
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                // Forces content to take at least full screen height
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Center(
                    // THIS Center keeps everything vertically centered
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          /// Title
                          Text(
                            "Welcome Back",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: screenWidth * 0.1,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          /// Subtitle
                          Text(
                            "Great to have you back!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 30),

                          /// Email input field
                          _buildInputField(
                            controller: emailController,
                            label: "Email",
                          ),

                          const SizedBox(height: 12),

                          /// Password input field with visibility toggle
                          _buildInputField(
                            controller: passwordController,
                            label: "Password",
                            obscure: _obscurePassword,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey.withAlpha(200),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 8),

                          /// Forgot password button
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: forgotPassword,
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// Login button (responsive width)
                          SizedBox(
                            width: screenWidth * 0.3,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade900,
                                padding:
                                const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Text(
                                "Login",
                                style:
                                TextStyle(color: Colors.white),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          /// Navigate to Signup page
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignupPage(),
                                ),
                              );
                            },
                            child: const Text.rich(
                              TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(color: Colors.black),
                                children: [
                                  TextSpan(
                                    text: "Sign up",
                                    style: TextStyle(
                                      color: Colors.cyan,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Reusable input field widget
  /// Avoids duplicate email/password UI code
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
