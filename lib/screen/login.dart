import 'package:Segreduino/screen/forgot_password.dart';
import 'package:Segreduino/screen/register.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Segreduino/screen/homepage.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final username = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final user = await ApiService.loginUser(username, password);

      if (!mounted) return;

      // Save user info to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user['user_id']?.toString() ?? '');
      await prefs.setString('full_name', user['full_name'] ?? '');
      await prefs.setString('email', user['email'] ?? '');
      await prefs.setString('role', user['role'] ?? 'user');
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('phone', user['phone']?.toString() ?? '');
      await prefs.setString('avatar_url', user['avatar']?.toString() ?? '');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardPage(
            fullName: user['full_name'] ?? 'User',
            email: user['email'] ?? '',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        // You can now use account.email, account.displayName, etc.
        // Optionally, save the user info to your SQLite database here.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign in successful: ${account.email}')),
        );
        // Example: Save to SQLite (pseudo-code)
        // await DatabaseHelper().registerUser(
        //   account.displayName ?? '',
        //   account.email,
        //   '', // No password for Google sign-in
        //   email: account.email,
        // );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign in cancelled')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign in failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 45,
                        backgroundImage: AssetImage('assets/sereg.png'),
                        backgroundColor: Colors.transparent,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'SegreDuino',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 32),

                      TextFormField(
                        controller: _emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: const TextStyle(color: Colors.black),
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.green),
                          filled: true,
                          fillColor: Colors.amber[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                        obscureText: !_showPassword,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Colors.black),
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.green),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.amber,
                            ),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                          filled: true,
                          fillColor: Colors.amber[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),
               
                     Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    // Google Sign-In Button
    /*
    InkWell(
      onTap: _isLoading ? null : _handleGoogleSignIn,
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.grey.withOpacity(0.2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.only(right: 24), // spacing to the right
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/google_logo.png',
              height: 24,
              width: 24,
            ),
            const SizedBox(width: 10),
            const Text(
              'Google',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
    */
  ],
),

const SizedBox(height: 24),

// Sign Up Prompt
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    const Text(
      "Don't have an account?",
      style: TextStyle(color: Colors.black),
    ),
    TextButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RegisterPage()),
      ),
      child: const Text(
        'Sign Up',
        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
      ),
    ),
  ],
),

// Loading Overlay
if (_isLoading)
  Container(
    color: Colors.black26,
    child: const Center(
      child: CircularProgressIndicator(),
     ),
      ),
  ],
), // <-- End of Stack
    ),
      ),
), // <-- End of Stack

// End of build method
),
        ],
      
    ),
    );

}
}
// End of build method
