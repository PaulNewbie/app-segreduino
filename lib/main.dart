import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screen/login.dart';
import 'screen/homepage.dart';
import 'screen/app_theme.dart';
import 'screen/dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('is_dark_mode') ?? false;

  runApp(MyApp(isDarkMode: isDarkMode));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  MyApp({super.key, required this.isDarkMode}) {
    themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _userId;
  String? _userRole; // Store the user role ('Admin' or 'Staff')
  bool _isLoading = true;

  // 🔥 ADDED: State variable to track dark mode
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
      _userRole = prefs.getString('role'); // Retrieve role during check
      _isLoading = false;
    });
  }

  // 🔥 ADDED: A method to allow child widgets to toggle the theme
  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Waste Management',
      
      // Use the newly defined isDarkMode variable here
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      
      // Pass the toggle function down to your Dashboard/HomePage
      home: _userId == null
          ? const LoginPage()
          : (_userRole == 'Admin'
              ? const DashboardPage() // This matches the class in homepage.dart
              : const DashboardPage()), // Use DashboardPage here too if you haven't made a separate Staff page
    );
  }
}
