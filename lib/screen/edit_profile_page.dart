import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../service/api_service.dart';

class EditProfilePage extends StatefulWidget {
  final String fullName;
  final String email;

  const EditProfilePage({
    super.key,
    this.fullName = '',
    this.email = '',
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;

  bool _isLoading = false; // 🔹 loading state

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.fullName);
    _emailController = TextEditingController(text: widget.email);
    _loadPhoneNumber();
  }

  Future<void> _loadPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('phone') ?? '';
    _phoneController.text = savedPhone;
  }

  Future<bool> _saveProfile() async {
    final url = Uri.parse(
        '${ApiConfig.baseUrl}/controllers/Actions/update_profile.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'full_name': _fullNameController.text.trim(),
          'phone': _phoneController.text.trim(),
        }),
      );

  final data = jsonDecode(response.body);
    if (data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fullName', _fullNameController.text.trim());
      await prefs.setString('email', _emailController.text.trim());
      await prefs.setString('phone', _phoneController.text.trim());

      // --- ADD LOG HERE ---
      final userIdRaw = prefs.get('user_id');
      if (userIdRaw != null && userIdRaw.toString().isNotEmpty) {
        await ApiService.logActivity(int.parse(userIdRaw.toString()), "Updated mobile profile information");
      }

      return true;
      } else {
        throw Exception(data['message'] ?? 'Update failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
      return false;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
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
                        'Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade900,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 🔹 FULL NAME FIELD (Stricter validation)
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person),
                          filled: true,
                          fillColor: Colors.green.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter your full name';
                            } else if (value.trim().length < 3) {
                              return 'Name must be at least 3 characters';
                            } else if (!RegExp(r'^[A-Za-zÀ-ÖØ-öø-ÿ\s]+$').hasMatch(value.trim())) {
                              return 'Name can only contain letters and spaces';
                            }
                            return null;
                          }
                      ),

                      const SizedBox(height: 12),

                      // 🔹 EMAIL FIELD
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          filled: true,
                          fillColor: Colors.green.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your email';
                          } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // 🔹 PHONE FIELD
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: const Icon(Icons.phone),
                          filled: true,
                          fillColor: Colors.green.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(11),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your phone number';
                          } else if (!RegExp(r'^(09|\+639)\d{9}$')
                              .hasMatch(value.trim())) {
                            return 'Enter a valid PH number (e.g. 09123456789)';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // 🔹 SAVE BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _isLoading = true);
                              final success = await _saveProfile();
                              setState(() => _isLoading = false);

                              if (success) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Profile updated successfully!'),
                                  ),
                                );
                                Navigator.pop(context, {
                                  'fullName': _fullNameController.text,
                                  'email': _emailController.text,
                                });
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Failed to update profile'),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 18,
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
