import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _codeVerified = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _errorMessage;

  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return "Please enter a password.";
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$').hasMatch(value)) {
      return "Password must be at least 8 characters,\ninclude upper & lower case, number, and special character (!@#\$&*~)";
    }
    return null;
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    print('SEND CODE PRESSED: $email');
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = "Please enter a valid email address.");
      return;
    }
    setState(() => _errorMessage = null);

    final response = await http.post(
      Uri.parse('https://segreduino.com/segreduino/dashboard/verification_email.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    print('API response (send code): ${response.body}');

    // Fix: Handle empty or invalid JSON
    if (response.body.isEmpty) {
      setState(() => _errorMessage = "No response from server.");
      return;
    }
    try {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() => _codeSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent to your email!')),
        );
      } else {
        setState(() => _errorMessage = data['message'] ?? 'Failed to send code.');
      }
    } catch (e) {
      setState(() => _errorMessage = "Invalid response from server.");
    }
  }

  Future<void> _verifyCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    print('VERIFY CODE PRESSED: email=$email, code=$code');

    if (code.isEmpty) {
      setState(() => _errorMessage = "Please enter the verification code.");
      return;
    }

    final response = await http.post(
      Uri.parse('https://segreduino.com/segreduino/dashboard/verify_code.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    print('API response (verify code): ${response.body}');

    if (response.body.isEmpty) {
      setState(() => _errorMessage = "No response from server.");
      return;
    }
    try {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          _codeVerified = true;
          _errorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code verified! You can now set a new password.')),
        );
      } else {
        setState(() => _errorMessage = data['message'] ?? 'Invalid code.');
      }
    } catch (e) {
      setState(() => _errorMessage = "Invalid response from server.");
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    print('RESET PASSWORD PRESSED');
    print('DEBUG email: $email');
    print('DEBUG code: $code');
    print('DEBUG newPassword: $newPassword');
    print('DEBUG confirmPassword: $confirmPassword');

    // Password validation
    final passwordError = _validatePassword(newPassword);
    if (code.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorMessage = "Please fill in all fields.");
      return;
    }
    if (passwordError != null) {
      setState(() => _errorMessage = passwordError);
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = "Passwords do not match.");
      return;
    }

    final response = await http.post(
      Uri.parse('https://segreduino.com/segreduino/dashboard/verify_code_and_reset.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code, 'new_password': newPassword}),
    );
    print('API response (reset password): ${response.body}');
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successful!')),
      );
      Navigator.pop(context);
    } else {
      setState(() => _errorMessage = data['message'] ?? 'Failed to reset password.');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('FORGOT PASSWORD BUILD CALLED');
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text("Reset Password", style: TextStyle(color: Colors.green)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.green),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Enter your email',
                labelStyle: const TextStyle(color: Colors.green),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green.shade700, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
              enabled: !_codeSent,
              style: const TextStyle(color: Colors.black),
            ),
            if (!_codeSent) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _sendCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text("Send Verification Code"),
              ),
            ],
            if (_codeSent) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Enter verification code',
                  labelStyle: const TextStyle(color: Colors.green),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green.shade700, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                ),
                enabled: !_codeVerified,
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 16),
              if (!_codeVerified)
                ElevatedButton(
                  onPressed: _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 77, 139, 19),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text("Verify Code"),
                ),
              if (_codeVerified) ...[
                TextField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Enter new password',
                    labelStyle: const TextStyle(color: Colors.green),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green.shade700, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showNewPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _showNewPassword = !_showNewPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: !_showNewPassword,
                  style: const TextStyle(color: Colors.black),
                  onChanged: (value) {
                    setState(() {
                      _errorMessage = _validatePassword(value);
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm new password',
                    labelStyle: const TextStyle(color: Colors.green),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green.shade700, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _showConfirmPassword = !_showConfirmPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: !_showConfirmPassword,
                  style: const TextStyle(color: Colors.black),
                  onChanged: (value) {
                    setState(() {
                      if (value != _newPasswordController.text) {
                        _errorMessage = "Passwords do not match.";
                      } else {
                        _errorMessage = _validatePassword(value);
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text("Reset Password"),
                ),
              ],
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ]
          ],
        ),
      ),
    );
  }
}