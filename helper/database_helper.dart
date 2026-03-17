import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // Register user via hosting API
  Future<bool> registerUser(String fullName, String username, String password,
      {String? email, String? phone, String? profilePicture}) async {
    try {
      final response = await http.post(
        Uri.parse('https://segreduino.com/segreduino/dashboard/register_api.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'full_name': fullName,
          'username': username,
          'email': email ?? '',
          'phone': phone ?? '',
          'password': password,
        }),
      );

      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data != null && data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  // Login user via hosting API
  static Future<Map<String, dynamic>> loginUser(String username, String password) async {
    final url = Uri.parse('https://segreduino.com/segreduino/dashboard/login_api.php');

    print('Sending login request to $url');
    print('Payload: ${jsonEncode({'username': username, 'password': password})}');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    print('Status: ${response.statusCode}');
    print('Response body: ${response.body}');

    final data = jsonDecode(response.body);

    if (data['success'] == true) {
      // Optionally save session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('logged_in_user', username);
      return data['user'] ?? {};
    } else {
      throw Exception(data['message']);
    }
  }

  // Save session using shared_preferences
  Future<void> saveUserSession(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('logged_in_user', username);
  }

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  // Logout and clear session
  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}