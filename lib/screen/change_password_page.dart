import 'package:flutter/material.dart';
import 'package:Seregduino/service/api_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _changePassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        bool success = await ApiService.changePassword(
          oldPassword: _oldPasswordController.text,
          newPassword: _newPasswordController.text,
        );

        if (!mounted) return;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password changed successfully'),
              backgroundColor: Colors.green,
            ),
          );

          _oldPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          Navigator.pop(context);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: ' ', // Reserve space to keep height consistent
      prefixIcon: Icon(icon, color: Colors.green),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off : Icons.visibility,
          color: Colors.green,
        ),
        onPressed: toggle,
      ),
      filled: true,
      fillColor: Colors.green.shade50,
      errorStyle: const TextStyle(fontSize: 12, height: 0.8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 10,
              shadowColor: Colors.green.shade200,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Update Your Password',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade900,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // OLD PASSWORD
                      TextFormField(
                        controller: _oldPasswordController,
                        obscureText: _obscureOld,
                        decoration: _fieldDecoration(
                          label: 'Old Password',
                          icon: Icons.lock,
                          obscure: _obscureOld,
                          toggle: () => setState(() => _obscureOld = !_obscureOld),
                        ),
                        validator: (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter your old password'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // NEW PASSWORD
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNew,
                        decoration: _fieldDecoration(
                          label: 'New Password',
                          icon: Icons.lock_outline,
                          obscure: _obscureNew,
                          toggle: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          } else if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          } else if (value == _oldPasswordController.text) {
                            return 'New password must be different from old password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // CONFIRM PASSWORD
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: _fieldDecoration(
                          label: 'Confirm Password',
                          icon: Icons.lock_outline,
                          obscure: _obscureConfirm,
                          toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        validator: (value) {
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // SAVE BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Save Password',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
