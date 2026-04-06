import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Segreduino/screen/bin_level_page.dart';
import 'package:Segreduino/screen/system.dart';
import 'package:Segreduino/screen/tasks.dart';
import 'package:Segreduino/screen/unrecognized_waste_page.dart';
import 'package:Segreduino/screen/edit_profile_page.dart';
import 'package:Segreduino/screen/dashboard.dart';




class DashboardPage extends StatefulWidget {
  final String? fullName;
  final String? email;

  const DashboardPage({
    super.key,
    required this.fullName,
    required this.email,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late String fullName;
  late String email;
  bool showWelcome = true;

  static const List<List<Color>> cardGradients = [
    [Color(0xFF66BB6A), Color(0xFFA5D6A7)], // 🟢 Machine Dashboard
    [Color(0xFF81D4FA), Color(0xFFB3E5FC)],
    [Color(0xFFBA68C8), Color(0xFFD1C4E9)],
    [Color(0xFFE57373), Color(0xFFFFCDD2)],
    [Color(0xFFFFEB3B), Color(0xFFFFF59D)],
  ];

  static const List<Color> iconColors = [
    Colors.white,
    Colors.white,
    Colors.white,
    Colors.white,
    Colors.white,
  ];

  static const List<String> labels = [
    'Machine Dashboard', // 🆕 new tile
    'Bin Level',
    'Tasks & Schedule',
    'Unrecognized Waste',
    'Settings',
  ];

  static const List<IconData> icons = [
    Icons.precision_manufacturing_rounded,
    Icons.bar_chart,
    Icons.task,
    Icons.help_outline,
    Icons.settings,
  ];

  static const List<Widget> pages = [
    MachineDashboardPage(),
    BinLevelPage(),
    TasksPage(),
    UnrecognizedWastePage(),
    SystemPage(),
  ];

  @override
  void initState() {
    super.initState();
    fullName = widget.fullName ?? '';
    email = widget.email ?? '';

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          showWelcome = false;
        });
      }
    });
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          fullName: fullName,
          email: email,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        fullName = result['fullName'] ?? fullName;
        email = result['email'] ?? email;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFAF3E0), Color(0xFFFFF8E1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              GestureDetector(
                onTap: _navigateToEditProfile,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.shade100.withOpacity(0.7),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      )
                    ],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showWelcome)
                        Text(
                          'Welcome, $fullName!',
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      if (showWelcome) const SizedBox(height: 10),
                      Text(
                        'Menu',
                        style: GoogleFonts.fredoka(
                          fontSize: 32,
                          color: Colors.white,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.green.shade200,
                              offset: const Offset(0, 0),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    itemCount: labels.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      return NeumorphicCard(
                        icon: icons[index],
                        label: labels[index],
                        gradientColors: cardGradients[index],
                        iconColor: iconColors[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => pages[index]),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NeumorphicCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final Color iconColor;
  final VoidCallback? onTap;

  const NeumorphicCard({
    super.key,
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.iconColor,
    this.onTap,
  });

  @override
  State<NeumorphicCard> createState() => _NeumorphicCardState();
}

class _NeumorphicCardState extends State<NeumorphicCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors.last.withOpacity(0.6),
                offset: const Offset(8, 8),
                blurRadius: 20,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                offset: const Offset(-8, -8),
                blurRadius: 20,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 60, color: widget.iconColor),
                const SizedBox(height: 16),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.iconColor.withOpacity(0.9),
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(1, 1),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
