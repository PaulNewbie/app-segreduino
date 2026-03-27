import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Set your local IP and port for testing
  // static const String baseUrl = 'https://segreduino.com/segreduino/dashboard';
  // When deploying to production later, just change this single line to "https://segreduino.com"
  // static const String baseUrl = 'http://192.168.100.209:8000'; // Home Wifi ip add 
  static const String baseUrl = 'https://floralwhite-mule-302326.hostingersite.com';// Hostinger live server
  // static const String baseUrl = 'http://192.168.0.114:8000'; // Dea wifi
  
  // API timeout duration
  static const Duration timeoutDuration = Duration(seconds: 20);
}

class ApiService {
  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // 🔹 Facebook Login
  static Future<Map<String, dynamic>> loginWithFacebook(
      String facebookId, String fullName, String email) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/controllers/Api/facebook_login_api.php');

    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'facebook_id': facebookId,
        'full_name': fullName,
        'email': email,
      }),
    ).timeout(ApiConfig.timeoutDuration);

    print('FB raw response: ${response.body}');
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_id', data['user']['user_id'].toString());
      await prefs.setString('full_name', data['user']['full_name'] ?? '');
      await prefs.setString('email', data['user']['email'] ?? '');
      await prefs.setString('role', 'staff'); // force staff role
      return Map<String, dynamic>.from(data['user']); // cast
    } else {
      throw Exception(data['message'] ?? 'Facebook login failed');
    }
  }

  // 🔹 LOGIN
  static Future<Map<String, dynamic>> loginUser(String username, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/controllers/Api/login_api.php'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    ).timeout(ApiConfig.timeoutDuration);

    final data = jsonDecode(response.body);

    if (data['success'] == true) {
      return data['user'];
    } else {
      throw Exception(data['message']);
    }
  }

  // 🔹 Check Username
  static Future<bool> checkUsernameExists(String username, {int retryCount = 3}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/controllers/Api/check_username.php'),
          headers: _headers,
          body: jsonEncode({"username": username}),
        ).timeout(ApiConfig.timeoutDuration);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map && data.containsKey('exists')) {
            return data['exists'] == true;
          }
        }
      } catch (e) {
        if (i == retryCount - 1) {
          throw Exception('Failed to check username: ${e.toString()}');
        }
        await Future.delayed(Duration(seconds: i + 1));
      }
    }
    return false;
  }

  // 🔹 RESET PASSWORD
  static Future<bool> resetPassword(String username, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/controllers/reset_password.php'),
        headers: _headers,
        body: jsonEncode({
          "username": username,
          "new_password": newPassword,
        }),
      ).timeout(ApiConfig.timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return true;
        }
        throw Exception(data['message'] ?? 'Password reset failed');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  // 🔹 FORGOT PASSWORD FLOW
  static Future<bool> forgotPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/controllers/Actions/verify_code_and_reset.php'),
        headers: _headers,
        body: jsonEncode({
          "email": email,
          "code": code,
          "new_password": newPassword,
        }),
      ).timeout(ApiConfig.timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return true;
        }
        throw Exception(data['message'] ?? 'Password reset failed');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  // 🔹 REGISTER USER
  static Future<bool> registerUser(
    String fullName,
    String username,
    String password, {
    String email = '',
    String phone = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/controllers/Api/register_api.php'),
        headers: _headers,
        body: jsonEncode({
          "full_name": fullName,
          "username": username,
          "email": email,
          "phone": phone,
          "password": password,
        }),
      ).timeout(ApiConfig.timeoutDuration);

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        return true;
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      throw Exception("Registration failed: ${e.toString()}");
    }
  }

  // 🔹 UPDATE PROFILE
  static Future<bool> updateProfile({
    required String email,
    required String fullName,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/controllers/Actions/update_profile.php'),
        headers: _headers,
        body: jsonEncode({
          "email": email,
          "full_name": fullName,
          "phone": phone,
        }),
      ).timeout(ApiConfig.timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return true;
        }
        throw Exception(data['message'] ?? 'Profile update failed');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Profile update failed: ${e.toString()}');
    }
  }

  // 🔹 FETCH TASKS
  static Future<List<dynamic>> fetchTasks({String? userId, int retryCount = 3}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        final uri = userId != null && userId.isNotEmpty
            ? Uri.parse('${ApiConfig.baseUrl}/controllers/Api/tasks_api.php?user_id=$userId')
            : Uri.parse('${ApiConfig.baseUrl}/controllers/Api/tasks_api.php');

        final response = await http
            .get(uri, headers: _headers)
            .timeout(ApiConfig.timeoutDuration);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            return data['tasks'];
          }
          throw Exception(data['message'] ?? 'Failed to load tasks');
        }
        throw Exception('Server error: ${response.statusCode}');
      } catch (e) {
        if (i == retryCount - 1) {
          throw Exception('Failed to load tasks: ${e.toString()}');
        }
        await Future.delayed(Duration(seconds: i + 1));
      }
    }
    throw Exception('Failed to load tasks after $retryCount attempts');
  }

  // 🔹 FETCH SCHEDULES
  static Future<List<dynamic>> fetchSchedules(String userId, {int retryCount = 3}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/controllers/Api/schedules_api.php?user_id=$userId'),
          headers: _headers,
        ).timeout(ApiConfig.timeoutDuration);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            return data['tasks'];
          }
          throw Exception(data['message'] ?? 'Failed to load schedules');
        }
        throw Exception('Server error: ${response.statusCode}');
      } catch (e) {
        if (i == retryCount - 1) throw Exception('Failed to load schedules: $e');
        await Future.delayed(Duration(seconds: i + 1));
      }
    }
    throw Exception('Failed to load schedules after $retryCount attempts');
  }

  // 🔹 FETCH UNREAD NOTIFICATIONS COUNT
  static Future<int> fetchUnreadCount({int retryCount = 3}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/controllers/Api/get_alert_count.php'),
          headers: _headers,
        ).timeout(ApiConfig.timeoutDuration);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['unread_count'] ?? 0;
        }
      } catch (e) {
        if (i == retryCount - 1) return 0;
        await Future.delayed(Duration(seconds: i + 1));
      }
    }
    return 0;
  }

  // 🔹 CHANGE PASSWORD
  static Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');

    if (email == null) throw Exception("Email not found in session.");

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/controllers/Actions/change_password.php'),
      headers: _headers,
      body: jsonEncode({
        "email": email,
        "old_password": oldPassword,
        "new_password": newPassword,
      }),
    ).timeout(ApiConfig.timeoutDuration);

    final data = jsonDecode(response.body);
    if (data['success']) return true;

    throw Exception(data['message']);
  }

  // 🔹 MARK TASK AS DONE
  static Future<bool> markTaskAsDone(String taskId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/controllers/Actions/mark_task_done.php'),
        headers: _headers,
        body: jsonEncode({
          'task_id': taskId,
        }),
      ).timeout(ApiConfig.timeoutDuration);

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        return true;
      } else {
        throw Exception(data['message'] ?? 'Failed to mark task as done');
      }
    } catch (e) {
      throw Exception('Mark task as done failed: ${e.toString()}');
    }
  }

  // 🔹 FETCH NOTIFICATIONS
  static Future<List<dynamic>> fetchNotifications({int retryCount = 3}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/controllers/Api/get_notifications.php'),
          headers: _headers,
        ).timeout(ApiConfig.timeoutDuration);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            return data['data']; // 'data' contains the array of notifications
          }
          throw Exception(data['message'] ?? 'Failed to load notifications');
        }
        throw Exception('Server error: ${response.statusCode}');
      } catch (e) {
        if (i == retryCount - 1) throw Exception('Failed to load notifications: $e');
        await Future.delayed(Duration(seconds: i + 1));
      }
    }
    throw Exception('Failed to load notifications after $retryCount attempts');
  }

}