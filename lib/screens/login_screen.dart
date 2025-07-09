import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test1/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isDarkMode;
  final MaterialColor themeColor;
  final void Function(bool) toggleDarkMode;
  final void Function(MaterialColor) changeThemeColor;

  const LoginScreen({
    super.key,
    required this.isDarkMode,
    required this.toggleDarkMode,
    required this.themeColor,
    required this.changeThemeColor,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool showPassword = false;

  static const int maxAttempts = 5;
  static const Duration cooldownDuration = Duration(hours: 2);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final attemptsRef = FirebaseFirestore.instance.collection('login_attempts').doc(email);

    try {
      final snapshot = await attemptsRef.get();
      final data = snapshot.data();
      final now = DateTime.now();

      if (data != null && data['lockedUntil'] != null) {
        final lockedUntil = (data['lockedUntil'] as Timestamp).toDate();
        if (lockedUntil.isAfter(now)) {
          final remaining = lockedUntil.difference(now);
          _showErrorDialog("Too many failed attempts. Try again in ${remaining.inMinutes} minutes.");
          return;
        }
      }

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;

      await attemptsRef.delete(); // clear attempts on success

      if (user != null && !user.emailVerified) {
        await FirebaseAuth.instance.signOut();
        _showVerifyDialog(user);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              user: user,
              isDarkMode: widget.isDarkMode,
              toggleDarkMode: widget.toggleDarkMode,
              themeColor: widget.themeColor,
              changeThemeColor: widget.changeThemeColor,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      final doc = await attemptsRef.get();
      final currentAttempts = (doc.data()?['attempts'] ?? 0) + 1;
      final lockedUntil = currentAttempts >= maxAttempts
          ? DateTime.now().add(cooldownDuration)
          : null;

      await attemptsRef.set({
        'attempts': currentAttempts,
        'lastAttempt': FieldValue.serverTimestamp(),
        if (lockedUntil != null) 'lockedUntil': Timestamp.fromDate(lockedUntil),
      });

      _showErrorDialog(currentAttempts >= maxAttempts
          ? "Too many failed attempts. Account locked for 2 hours."
          : "Login failed. Attempt $currentAttempts of $maxAttempts.");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showVerifyDialog(User user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Email Not Verified"),
        content: const Text("Please verify your email to continue."),
        actions: [
          TextButton(
            onPressed: () async {
              await user.sendEmailVerification();
              Navigator.pop(context);
              _showErrorDialog("Verification email sent.");
            },
            child: const Text("Resend Email"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final TextEditingController emailResetController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reset Password"),
        content: TextField(
          controller: emailResetController,
          decoration: const InputDecoration(
            labelText: "Enter your email",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final email = emailResetController.text.trim();
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                _showErrorDialog("Password reset email sent. Check your inbox.");
              } on FirebaseAuthException catch (e) {
                _showErrorDialog(e.message ?? "Failed to send reset email.");
              }
            },
            child: const Text("Send"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: const Color.fromARGB(255, 89, 230, 255),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Gmail',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: !showPassword,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => showPassword = !showPassword),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: const Text("Forgot Password?"),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color.fromARGB(255, 89, 230, 255),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Login', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
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
