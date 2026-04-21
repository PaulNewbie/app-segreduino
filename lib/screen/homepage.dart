import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Segreduino/screen/bin_level_page.dart';
import 'package:Segreduino/screen/system.dart';
import 'package:Segreduino/screen/tasks.dart';
import 'package:Segreduino/screen/unrecognized_waste_page.dart';
import 'package:Segreduino/screen/edit_profile_page.dart';
import 'package:Segreduino/screen/dashboard.dart';
import '../service/api_service.dart';
import 'app_theme.dart';

// ── Menu item descriptor ──────────────────────────────────────
class _MenuItem {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color accentBg;
  final Widget page;

  const _MenuItem({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.accentBg,
    required this.page,
  });
}

const List<_MenuItem> _menuItems = [
  _MenuItem(
    label:    'Machine\nDashboard',
    subtitle: 'Live kiosk status',
    icon:     Icons.precision_manufacturing_rounded,
    accent:   AppColors.primary,
    accentBg: AppColors.primarySurface,
    page:     MachineDashboardPage(),
  ),
  _MenuItem(
    label:    'Bin\nLevels',
    subtitle: 'Check fill levels',
    icon:     Icons.bar_chart_rounded,
    accent:   AppColors.recyclable,
    accentBg: AppColors.recyclableBg,
    page:     BinLevelPage(),
  ),
  _MenuItem(
    label:    'Tasks &\nSchedule',
    subtitle: 'Manage routines',
    icon:     Icons.task_alt_rounded,
    accent:   Color(0xFF6A1B9A),
    accentBg: Color(0xFFEDE7F6),
    page:     TasksPage(),
  ),
  _MenuItem(
    label:    'Unrecognized\nWaste',
    subtitle: 'Review flagged items',
    icon:     Icons.help_outline_rounded,
    accent:   AppColors.warning,
    accentBg: AppColors.warningBg,
    page:     UnrecognizedWastePage(),
  ),
  _MenuItem(
    label:    'Settings',
    subtitle: 'Account & system',
    icon:     Icons.settings_rounded,
    accent:   AppColors.locked,
    accentBg: AppColors.lockedBg,
    page:     SystemPage(),
  ),
];

// ─────────────────────────────────────────────────────────────
class DashboardPage extends StatefulWidget {
  final String? fullName;
  final String? email;

  const DashboardPage({
    super.key,
    this.fullName,
    this.email,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late String fullName;
  late String email;
  String? userId;
  
  // 📸 Variable to hold the loaded image URL
  String _avatarUrl = '';

  // ── Live stats ────────────────────────────────────────────────
  int  _activeTasks    = 0;
  int  _alertCount     = 0;
  bool _statsLoading   = true;

  @override
  void initState() {
    super.initState();
    fullName = widget.fullName ?? '';
    email    = widget.email    ?? '';
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('user_id');

      // 📸 Load Avatar URL and construct full link
      String savedAvatar = prefs.getString('avatar_url') ?? '';
      if (savedAvatar.isNotEmpty && !savedAvatar.startsWith('http')) {
         String domain = ApiConfig.baseUrl.replaceAll(RegExp(r'/src/?$'), '');
         _avatarUrl = domain + savedAvatar;
      } else {
         _avatarUrl = savedAvatar;
      }

      // Fetch tasks + notifications in parallel
      final results = await Future.wait([
        ApiService.fetchTasks(userId: userId ?? ''),
        ApiService.fetchUnreadCount(),
      ]);

      final tasks      = results[0] as List<dynamic>;
      final alertCount = results[1] as int;

      // Count only non-completed tasks
      final active = tasks.where((t) {
        final status = (t['task_status'] ?? '').toString().toLowerCase();
        return status != 'completed' && status != 'done';
      }).length;

      if (mounted) {
        setState(() {
          _activeTasks  = active;
          _alertCount   = alertCount;
          _statsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(fullName: fullName, email: email),
      ),
    );
    
    // 🔄 Always reload stats when returning from profile page 
    // so if they changed their picture, it updates immediately!
    _loadStats(); 

    if (result != null) {
      setState(() {
        fullName = result['fullName'] ?? fullName;
        email    = result['email']    ?? email;
      });
    }
  }

  // ── Greeting based on hour ────────────────────────────────────
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ── Avatar initials — up to 2 words (First + Last initial) ───
  String get _initials {
    if (fullName.isEmpty) return 'U';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadStats,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildStatsStrip()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'QUICK ACCESS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _MenuCard(item: _menuItems[i]),
                    childCount: _menuItems.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:   2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing:  12,
                    childAspectRatio: 1.05,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar — tappable, shows picture OR initials
          GestureDetector(
            onTap: _navigateToEditProfile,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.18),
                  backgroundImage: _avatarUrl.isNotEmpty 
                      ? NetworkImage(_avatarUrl) 
                      : null,
                  // Only show the text initials if there is NO avatar URL
                  child: _avatarUrl.isEmpty
                      ? Text(
                          _initials,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded,
                        size: 9, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Greeting + full name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting,',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  // Show full name; fall back gracefully if empty
                  fullName.isNotEmpty ? fullName : 'User',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Notification bell with live badge
          GestureDetector(
            onTap: () => _loadStats(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_none_rounded,
                      color: Colors.white, size: 22),
                ),
                if (_alertCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: AppColors.danger, shape: BoxShape.circle),
                      child: Text(
                        _alertCount > 99 ? '99+' : '$_alertCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats strip — real data ───────────────────────────────────
  Widget _buildStatsStrip() {
    final taskValue  = _statsLoading ? '…' : '$_activeTasks';
    final alertValue = _statsLoading ? '…' : '$_alertCount';
    final alertColor = _alertCount > 0 ? AppColors.danger  : AppColors.success;
    final alertBg    = _alertCount > 0 ? AppColors.dangerBg : AppColors.successBg;
    final alertIcon  = _alertCount > 0
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline_rounded;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Row(
        children: [
          // Bins OK — static (no bin-level API on homepage yet)
          _StatPill(
            icon:    Icons.delete_sweep_rounded,
            label:   'Bins Status',
            value:   'OK',
            color:   AppColors.success,
            bg:      AppColors.successBg,
            loading: false,
          ),
          const SizedBox(width: 10),
          // Active tasks — live
          _StatPill(
            icon:    Icons.task_rounded,
            label:   'Active Tasks',
            value:   taskValue,
            color:   AppColors.recyclable,
            bg:      AppColors.recyclableBg,
            loading: _statsLoading,
          ),
          const SizedBox(width: 10),
          // Alerts — live, color shifts red if > 0
          _StatPill(
            icon:    alertIcon,
            label:   'Alerts',
            value:   alertValue,
            color:   alertColor,
            bg:      alertBg,
            loading: _statsLoading,
          ),
        ],
      ),
    );
  }
}

// ── Stat pill ─────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  final Color    bg;
  final bool     loading;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(height: 8),
            loading
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: color),
                  )
                : Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Menu card ─────────────────────────────────────────────────
class _MenuCard extends StatefulWidget {
  final _MenuItem item;
  const _MenuCard({super.key, required this.item});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0,
      upperBound: 0.04,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => item.page));
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: item.accent.withOpacity(0.18),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: item.accent.withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.accentBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, size: 24, color: item.accent),
              ),
              const Spacer(),
              Text(
                item.label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              // Accent underline
              Container(
                height: 3,
                width: 28,
                decoration: BoxDecoration(
                  color: item.accent.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}