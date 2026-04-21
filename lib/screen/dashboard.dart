import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../service/api_service.dart';
import 'package:Segreduino/screen/overflow_notifications_page.dart';
import 'app_theme.dart';

class MachineDashboardPage extends StatefulWidget {
  const MachineDashboardPage({super.key});

  @override
  State<MachineDashboardPage> createState() => _MachineDashboardPageState();
}

class _MachineDashboardPageState extends State<MachineDashboardPage> {
  List<Map<String, dynamic>> machines = [];
  bool isLoading = true;
  String? errorMsg;

  // ── Bin type definitions ──────────────────────────────────────
  static const List<_BinDef> bins = [
    _BinDef('Bio',     AppColors.biodegradable, AppColors.biodegradableBg, Icons.eco_rounded),
    _BinDef('Non-Bio', AppColors.nonBio,        AppColors.nonBioBg,        Icons.delete_outline_rounded),
    _BinDef('Recyc',   AppColors.recyclable,    AppColors.recyclableBg,    Icons.recycling_rounded),
  ];

  @override
  void initState() {
    super.initState();
    fetchMachines();
  }

  Future<void> fetchMachines() async {
    setState(() { isLoading = true; errorMsg = null; });
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/controllers/Actions/add_kiosk.php'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['success'] == true && data['data'] != null) {
          machines = (data['data'] as List)
              .map<Map<String, dynamic>>((e) => e is Map
                  ? Map<String, dynamic>.from(e)
                  : {'machine_name': e.toString(), 'location': ''})
              .toList();
        } else {
          machines = [];
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
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Machine Dashboard',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 22),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OverflowNotificationsPage()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Builder(builder: (context) {
        if (isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (errorMsg != null && machines.isEmpty) {
          return _ErrorState(message: errorMsg!, onRetry: fetchMachines);
        }
        if (machines.isEmpty) {
          return const _EmptyState();
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: fetchMachines,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _SummaryStrip(machineCount: machines.length),
              const SizedBox(height: 20),
              ...machines.asMap().entries.map(
                (e) => _MachineCard(machine: e.value, index: e.key),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Bin definition ────────────────────────────────────────────
class _BinDef {
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;
  const _BinDef(this.label, this.color, this.bg, this.icon);
}

// ── Summary strip ─────────────────────────────────────────────
class _SummaryStrip extends StatelessWidget {
  final int machineCount;
  const _SummaryStrip({required this.machineCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryPill(
          icon:  Icons.precision_manufacturing_rounded,
          label: 'Kiosks Online',
          value: '$machineCount',
          color: AppColors.primary,
          bg:    AppColors.primarySurface,
        ),
        const SizedBox(width: 10),
        _SummaryPill(
          icon:  Icons.sensors_rounded,
          label: 'Sensors Active',
          value: '${machineCount * 3}',
          color: AppColors.recyclable,
          bg:    AppColors.recyclableBg,
        ),
        const SizedBox(width: 10),
        _SummaryPill(
          icon:  Icons.warning_amber_rounded,
          label: 'Alerts',
          value: '0',
          color: AppColors.warning,
          bg:    AppColors.warningBg,
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;
  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
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
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 13, color: color),
            ),
            const SizedBox(height: 7),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 9.5, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── Machine card ──────────────────────────────────────────────
class _MachineCard extends StatelessWidget {
  final Map<String, dynamic> machine;
  final int index;

  const _MachineCard({required this.machine, required this.index});

  // Simulated bin levels — replace with real API values when available
  List<int> get _levels => [
        (30 + index * 7) % 101,
        (55 + index * 5) % 101,
        (20 + index * 12) % 101,
      ];

  @override
  Widget build(BuildContext context) {
    final name     = (machine['machine_name'] ?? '').toString();
    final location = (machine['location']     ?? '').toString();
    final levels   = _levels;
    final bins     = _MachineDashboardPageState.bins;

    final maxLevel    = levels.reduce((a, b) => a > b ? a : b);
    final statusColor = maxLevel >= 90
        ? AppColors.danger
        : maxLevel >= 70
            ? AppColors.warning
            : AppColors.success;
    final statusLabel = maxLevel >= 90
        ? 'Critical'
        : maxLevel >= 70
            ? 'High'
            : 'Normal';
    final statusBg = maxLevel >= 90
        ? AppColors.dangerBg
        : maxLevel >= 70
            ? AppColors.warningBg
            : AppColors.successBg;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.precision_manufacturing_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Unnamed Kiosk' : name,
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 12, color: AppColors.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                location,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(statusLabel,
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bin level circles ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: List.generate(3, (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                  child: _BinLevelTile(def: bins[i], level: levels[i]),
                ),
              )),
            ),
          ),

          // ── Footer ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 12, color: AppColors.disabled),
                const SizedBox(width: 4),
                Text('Last synced just now',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.disabled)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // TODO: navigate to machine detail
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  child: const Row(
                    children: [
                      Text('Details'),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_forward_ios_rounded, size: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bin level tile — circular design ─────────────────────────
class _BinLevelTile extends StatelessWidget {
  final _BinDef def;
  final int level;

  const _BinLevelTile({required this.def, required this.level});

  Color get _activeColor {
    if (level >= 90) return AppColors.danger;
    if (level >= 70) return AppColors.warning;
    return def.color;
  }

  @override
  Widget build(BuildContext context) {
    final pct    = (level / 100).clamp(0.0, 1.0);
    final active = _activeColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: def.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: def.color.withOpacity(0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular progress with percentage inside
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value:           pct,
                  strokeWidth:     6.5,
                  backgroundColor: def.color.withOpacity(0.12),
                  valueColor:      AlwaysStoppedAnimation<Color>(active),
                  strokeCap:       StrokeCap.round,
                ),
              ),
              Text(
                '$level%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: active,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          // Icon + label below the circle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(def.icon, size: 11, color: def.color),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  def.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: def.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
                color: AppColors.primarySurface, shape: BoxShape.circle),
            child: const Icon(Icons.precision_manufacturing_rounded,
                size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text('No kiosks found',
              style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface)),
          const SizedBox(height: 6),
          Text('Add a kiosk to start monitoring.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 52, color: AppColors.danger),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface)),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}