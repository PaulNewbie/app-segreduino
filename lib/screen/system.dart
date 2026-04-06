import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Segreduino/screen/change_password_page.dart';
import 'package:Segreduino/screen/edit_profile_page.dart';
import 'package:Segreduino/screen/login.dart';
import 'package:Segreduino/screen/sensor_status_page.dart';

class SystemPage extends StatefulWidget {
  const SystemPage({super.key});

  @override
  State<SystemPage> createState() => _SystemPageState();
}

class _SystemPageState extends State<SystemPage> {
  bool _notificationsEnabled = true;
  final bool _darkModeEnabled = false;
  bool _sensorsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 10,
                    shadowColor: Colors.green.shade200,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('User Account', style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            ListTile(
                              leading: const Icon(Icons.person),
                              title: const Text('Profile'),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const EditProfilePage(
                                      fullName: '',
                                      email: '',
                                    ),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.lock),
                              title: const Text('Change Password'),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (
                                      _) => const ChangePasswordPage()),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.logout),
                              title: const Text('Log Out'),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () async {
                                final shouldLogout = await showDialog<bool>(
                                  context: context,
                                  builder: (context) =>
                                      AlertDialog(
                                        title: const Text('Confirm Logout'),
                                        content: const Text(
                                            'Are you sure you want to log out?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(
                                                    false),
                                            child: const Text('No'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                            ),
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('Yes'),
                                          ),
                                        ],
                                      ),
                                );
                                if (shouldLogout == true) {
                                  final prefs = await SharedPreferences
                                      .getInstance();
                                  await prefs.clear();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (_) =>
                                        LoginPage()),
                                        (route) => false,
                                  );
                                }
                              },
                            ),
                            const Divider(thickness: 1.2),
                            const SizedBox(height: 10),

                            // 🌿 About Section
                            ListTile(
                              leading: const Icon(Icons.info_outline, color: Colors.green),
                              title: const Text('About'),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // App Logo at the Top
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.asset(
                                            'assets/sereg.png', // 🔹 Replace with your app logo path
                                            height: 80,
                                            width: 80,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Segreduino',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Automated Waste Segregation Kiosk\nwith Bin Level Monitoring System',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const Divider(height: 24, thickness: 1.2),
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Developed by:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            '• Amatorio, Maureen C.\n'
                                                '• Barasan, Sierabel\n'
                                                '• Bantugan, Dea Armie B.\n'
                                                '• Dionisio, Honey Shayne',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          '© 2025 Pambayang Dalubhasaan ng Marilao(PDM)\nCapstone Project',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        child: const Text(
                                          'Close',
                                          style: TextStyle(color: Colors.green),
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                      ),
                    ),
                ),
            ),
        ),
    );
  }
}

/* const SizedBox(height: 20),
                  const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SwitchListTile(
                    title: const Text('Enable Alerts'),
                    value: _notificationsEnabled,
                    onChanged: (val) {
                      setState(() => _notificationsEnabled = val);
                    },
                  ),

    /*const SizedBox(height: 20),
                  const Text('Sensors', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SwitchListTile(
                    title: const Text('System'),
                    subtitle: const Text('Turn all sensors on/off'),
                    value: _sensorsEnabled,
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.green,
                    onChanged: (val) => _showSensorConfirmation(val),
                  ),
                   // === SENSOR SECTION COMMENTED OUT ===

                  ListTile(
                    leading: const Icon(Icons.sensors),
                    title: const Text('Sensor & Relay Status'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SensorStatusPage()),
                        );
                    },
                  ),
                  */
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  }
 */

/*Future<void> _showSensorConfirmation(bool value) async {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(value ? 'Activate Sensors' : 'Deactivate Sensors'),
        content: Text(value
            ? 'Are you sure you want to activate all sensors?'
            : 'Are you sure you want to deactivate all sensors? This will stop all monitoring.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () {
              setState(() => _sensorsEnabled = value);
              Navigator.of(context).pop();
              _showSensorStatusMessage(value);
            },
            child: Text(value ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );
  }

  void _showSensorStatusMessage(bool isEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEnabled ? 'All sensors activated' : 'All sensors deactivated',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
}

 */
