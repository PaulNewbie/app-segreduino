import 'package:flutter/material.dart';
import '../service/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (_formKey.currentState!.validate()) {
       final success = await ApiService.registerUser(
        _fullNameController.text.trim(),
        _usernameController.text.trim(),
        _passwordController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username/email already exists or registration failed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon,
      {bool isPassword = false, VoidCallback? toggleVisibility, bool isVisible = false}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black),
      prefixIcon: Icon(icon, color: Colors.green),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.amber),
              onPressed: toggleVisibility,
            )
          : null,
      filled: true,
      fillColor: Colors.amber[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 48,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fill in the form below to sign up',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 32),

                // Registration Form
                Form(
                  key: _formKey,
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: 300,
                        child: TextFormField(
                          controller: _fullNameController,
                          style: const TextStyle(color: Colors.black),
                          decoration: _buildInputDecoration('Full Name', Icons.person_outline),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter full name';
                            }
                            // Only letters and spaces, at least 2 words, each starting uppercase
                            if (!RegExp(r'^[A-Z][a-z]+(\s[A-Z][a-z]+)+$').hasMatch(value)) {
                              return 'Enter full name (e.g. Juan Dela Cruz, no numbers/symbols)';
                            }
                            return null;
                          },
                        ),
                      ),

                          SizedBox(
                        width: 300,
                        child: TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.black),
                          decoration: _buildInputDecoration('Username', Icons.alternate_email),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter username'
                              : null,
                        ),
                      ),
                      SizedBox(
                        width: 300,
                        child: TextFormField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.black),
                          decoration: _buildInputDecoration('Email', Icons.email_outlined),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter email';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return 'Enter valid email';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(
                        width: 300,
                        child: TextFormField(
                          controller: _phoneController,
                          style: const TextStyle(color: Colors.black),
                          decoration: _buildInputDecoration('Phone', Icons.phone),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter phone'
                              : null,
                        ),
                      ),
                      SizedBox(
                        width: 300,
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          style: const TextStyle(color: Colors.black),
                          decoration: _buildInputDecoration(
                            'Password',
                            Icons.lock_outline,
                            isPassword: true,
                            toggleVisibility: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                            isVisible: _showPassword,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter password';
                            }
                            // Minimum 8 chars, at least 1 uppercase, 1 lowercase, 1 number, 1 special char
                            if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$').hasMatch(value)) {
                              return 'Password must be at least 8 characters,\ninclude upper & lower case, number, and special character';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(
                        width: 300,
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_showConfirmPassword,
                          style: const TextStyle(color: Colors.black),
                          decoration: _buildInputDecoration(
                            'Confirm Password',
                            Icons.lock_outline,
                            isPassword: true,
                            toggleVisibility: () {
                              setState(() {
                                _showConfirmPassword = !_showConfirmPassword;
                              });
                            },
                            isVisible: _showConfirmPassword,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirm password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            // Optional: repeat password strength check for confirm password
                            if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$').hasMatch(value)) {
                              return 'Password must be at least 8 characters,\ninclude upper & lower case, number, and special character';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                 const SizedBox(height: 32),
                SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
    onPressed: () async {
      try {
        bool success = await ApiService.registerUser(
          _fullNameController.text.trim(),
          _usernameController.text.trim(),
          _passwordController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
        );

        if (!context.mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Registration successful")),
          );
          Navigator.pop(context); // back to login
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: const Text(
  'Register',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),
),
),

// 👇 Add this Row below the Register button
SizedBox(height: 16), // spacing
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text("Already have an account?"),
    TextButton(
      onPressed: () {
        // TODO: Navigate to the login screen
        Navigator.pushNamed(context, '/auth/login'); // Replace with your login route
      },
      child: Text(
        'Log in',
        style: TextStyle(fontWeight: FontWeight.bold),
       ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
    );
  }
}