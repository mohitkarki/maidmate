import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// SignupPage handles:
/// - New user registration
/// - Username uniqueness check
/// - Email verification
/// - Google sign-up
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Controllers for reading user input
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Controls loading indicator
  bool isLoading = false;

  // Controls password visibility
  bool _obscurePassword = true;

  /// Sends password reset email using Firebase
  /// Works only if email field is filled
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

  /// Creates a new user account
  /// Steps:
  /// 1. Validate inputs
  /// 2. Check username uniqueness
  /// 3. Create Firebase user
  /// 4. Save user in Firestore
  /// 5. Send email verification
  Future<void> signup() async {
    final username = usernameController.text.trim().toLowerCase();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      final usernameRef =
      FirebaseFirestore.instance.collection('usernames').doc(username);

      final usernameDoc = await usernameRef.get();

      if (usernameDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Username already taken")),
        );
        return;
      }

      final userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await usernameRef.set({'uid': uid});

      await userCredential.user!.sendEmailVerification();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Account created. Please verify your email before login."),
        ),
      );

      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// Google sign-up flow
  /// Creates user and stores data in Firestore
  Future<void> signUpWithGoogle() async {
    try {
      setState(() => isLoading = true);

      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'email': user.email,
        'username': user.displayName ?? '',
        'provider': 'google',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// Builds the Signup UI
  /// Layout is IDENTICAL to LoginPage
  /// Only content and actions differ
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // TITLE — ALWAYS ONE LINE ON ALL DEVICES
                          FittedBox(
                            fit: BoxFit.scaleDown, // shrinks ONLY if needed
                            child: Text(
                              "Welcome to MaidMate",
                              textAlign: TextAlign.center,
                              maxLines: 1,          // FORCE single line
                              softWrap: false,      // DISABLE wrapping
                              style: TextStyle(
                                fontSize: screenWidth * 0.1, // SAME as login page
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const Text(
                            "Kaam jo aapke liye bana ho",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),

                          const SizedBox(height: 30),

                          _buildInputField(
                            controller: usernameController,
                            label: "Username",
                          ),

                          const SizedBox(height: 12),

                          _buildInputField(
                            controller: emailController,
                            label: "Email",
                          ),

                          const SizedBox(height: 12),

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

                          SizedBox(
                            width: screenWidth * 0.3,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade900,
                                padding:
                                const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          /// 🔴 OR DIVIDER — RESTORED
                          Row(
                            children: const [
                              Expanded(child: Divider()),
                              Padding(
                                padding:
                                EdgeInsets.symmetric(horizontal: 10),
                                child: Text("OR"),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed:
                              isLoading ? null : signUpWithGoogle,
                              icon: Image.asset(
                                'assets/google.png',
                                height: 20,
                              ),
                              label: const Text(
                                "Sign up with Google",
                                style:
                                TextStyle(color: Colors.black),
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

  /// Reusable input field (same as LoginPage)
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
