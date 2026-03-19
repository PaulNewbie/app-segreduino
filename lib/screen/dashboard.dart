import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../service/api_service.dart';

class MachineDashboardPage extends StatefulWidget {
  const MachineDashboardPage({super.key});

  @override
  State<MachineDashboardPage> createState() => _MachineDashboardPageState();
}

class _MachineDashboardPageState extends State<MachineDashboardPage> {
  List<Map<String, dynamic>> machines = [];
  bool isLoading = true;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    fetchMachines();
  }

  Future<void> fetchMachines() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/controllers/Actions/add_kiosk.php')
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['success'] == true && data['data'] != null) {
          final rawList = data['data'] as List;
          // ensure each entry is a Map<String, dynamic>
          machines = rawList.map<Map<String, dynamic>>((e) {
            if (e is Map) {
              return Map<String, dynamic>.from(e);
            } else {
              return {'machine_name': e.toString(), 'location': ''};
            }
          }).toList();
        } else {
          machines = [];
          // optional: capture message if present
          if (data is Map && data['message'] != null) {
            errorMsg = data['message'].toString();
          }
        }
      } else {
        errorMsg = 'Server returned ${response.statusCode}';
      }
    } catch (e) {
      errorMsg = 'Error fetching machines: $e';
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green,
        title: Text(
          'Machine Dashboard',
          style: GoogleFonts.fredoka(
            color: Colors.white,
            fontSize: 24,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: Builder(builder: (context) {
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (errorMsg != null && machines.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                errorMsg!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          );
        }

        if (machines.isEmpty) {
          return const Center(child: Text("No kiosks found."));
        }

        return RefreshIndicator(
          onRefresh: fetchMachines,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView.builder(
              itemCount: machines.length,
              itemBuilder: (context, index) {
                final machine = machines[index];
                return _buildMachineCard(machine, index);
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMachineCard(Map<String, dynamic> machine, int index) {
    // Colors / icons
    final List<List<Color>> gradients = [
      [const Color(0xFF26C6DA), const Color(0xFF80DEEA)],
      [const Color(0xFF66BB6A), const Color(0xFFA5D6A7)],
      [const Color(0xFFFFCA28), const Color(0xFFFFE082)],
    ];
    final gradient = gradients[index % gradients.length];
    final iconList = [Icons.factory, Icons.recycling, Icons.delete_outline];
    final icon = iconList[index % iconList.length];

    // Safe string extraction
    final machineName = (machine['machine_name'] ?? '').toString();
    final location = (machine['location'] ?? '').toString();

    // Simulated bin levels (you can replace this if API supplies actual levels)
    final Map<String, int> binLevels = {
      'Bio': (30 + (index * 7)) % 101, // sample values 30,37,44...
      'Non-Bio': (55 + (index * 5)) % 101,
      'Recyclable': (20 + (index * 12)) % 101,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withOpacity(0.5),
            offset: const Offset(4, 6),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 40, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    machineName.isEmpty ? 'Unnamed Kiosk' : machineName,
                    style: GoogleFonts.fredoka(
                      fontSize: 20,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: binLevels.entries.map<Widget>((entry) {
                final type = entry.key;
                final level = entry.value.clamp(0, 100);
                Color indicatorColor;
                if (level >= 90) {
                  indicatorColor = Colors.redAccent;
                } else if (level >= 70) {
                  indicatorColor = Colors.orangeAccent;
                } else {
                  indicatorColor = Colors.greenAccent;
                }
                return Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 70,
                          width: 70,
                          child: CircularProgressIndicator(
                            value: level / 100,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            color: indicatorColor,
                            strokeWidth: 7,
                          ),
                        ),
                        Text(
                          '$level%',
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      type,
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              location,
              style: GoogleFonts.fredoka(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: navigate to details or bins under this machine
                },
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('View Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
