import 'dart:convert';
import 'dart:io'; // Needed for File
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart'; // Needed for picking images
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

  bool _isLoading = false; // loading state for form
  
  // --- Profile Picture Variables ---
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPic = false;
  String _userId = "";
  String _currentAvatarUrl = ""; 

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.fullName);
    _emailController = TextEditingController(text: widget.email);
    _loadUserData();
  }

  // 🔹 Load phone, user ID, and existing avatar
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _phoneController.text = prefs.getString('phone') ?? '';
      _userId = prefs.getString('user_id') ?? '';
      
      String savedAvatar = prefs.getString('avatar_url') ?? ''; 
      
      // Dynamically grab your domain/IP from your ApiConfig!
      if (savedAvatar.isNotEmpty && !savedAvatar.startsWith('http')) {
         
         String domain = ApiConfig.baseUrl;
         // Remove "/src" from the end if it exists, because the assets folder is in the root!
         domain = domain.replaceAll(RegExp(r'/src/?$'), '');
         _currentAvatarUrl = domain + savedAvatar;
         
      } else {
         _currentAvatarUrl = savedAvatar;
      }
    });
  }

  // 📸 Function to open the gallery
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Compress slightly for faster uploads
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _uploadAvatar(); // Automatically upload once selected
    }
  }

  // 🚀 Function to send the image to the server
  Future<void> _uploadAvatar() async {
    if (_imageFile == null || _userId.isEmpty) return;

    setState(() { _isUploadingPic = true; });

    try {
      var response = await ApiService.uploadAvatar(_userId, _imageFile!);
      if (response['success'] == true) {
        
        // Optionally save the new avatar URL locally if your API returns it
        if (response['avatar_url'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('avatar_url', response['avatar_url']);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Upload failed'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isUploadingPic = false; });
      }
    }
  }

  Future<bool> _saveProfile() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/controllers/Actions/update_profile.php');
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
                      const SizedBox(height: 20),

                      // 🔹 PROFILE PICTURE WIDGET
                      GestureDetector(
                        onTap: _isUploadingPic ? null : _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.green.shade100,
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!) as ImageProvider
                                  : (_currentAvatarUrl.isNotEmpty
                                      ? NetworkImage(_currentAvatarUrl)
                                      : null),
                              child: _imageFile == null && _currentAvatarUrl.isEmpty
                                  ? Icon(Icons.person, size: 50, color: Colors.green.shade700)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                padding: const EdgeInsets.all(6),
                                child: _isUploadingPic
                                    ? const SizedBox(
                                        width: 16, 
                                        height: 16, 
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                      )
                                    : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Tap to change photo", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      
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
                                if(mounted){
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text('Profile updated successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.pop(context, {
                                    'fullName': _fullNameController.text,
                                    'email': _emailController.text,
                                  });
                                }
                              } else {
                                if(mounted){
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to update profile'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
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