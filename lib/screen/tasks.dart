import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/api_service.dart';
import 'app_theme.dart'; // ← adjust path if needed

// ==========================================
// 1. DATA MODELS  (fields unchanged — API contract preserved)
// ==========================================

class Task {
  final String id;
  final String userId;
  final String binId;
  final String machineId;
  final String machineName;
  final String binType;
  final String description;
  final String status;
  final String createdAt;

  Task({
    required this.id,
    required this.userId,
    required this.binId,
    required this.machineId,
    required this.machineName,
    required this.binType,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id:          json['task_id']?.toString()          ?? '',
      userId:      json['user_id']?.toString()          ?? '',
      binId:       json['bin_id']?.toString()           ?? '',
      machineId:   json['machine_id']?.toString()       ?? '',
      machineName: json['machine_name']?.toString()     ?? 'Kiosk/Machine',
      binType:     json['bin_type']?.toString()         ?? 'Trash Bin',
      description: json['task_description']?.toString() ?? '',
      status:      json['task_status']?.toString()      ?? 'Pending',
      createdAt:   json['created_at']?.toString()       ?? '',
    );
  }
}

class ScheduledTask {
  final String scheduleId;
  final String userId;
  final String floorLevel;
  final String machineName;
  final String binType;
  final String description;
  final String recurrencePattern;
  final String dayOfWeek;
  final String scheduleTime;
  final String createdAt;

  ScheduledTask({
    required this.scheduleId,
    required this.userId,
    required this.floorLevel,
    required this.machineName,
    required this.binType,
    required this.description,
    required this.recurrencePattern,
    required this.dayOfWeek,
    required this.scheduleTime,
    required this.createdAt,
  });

  factory ScheduledTask.fromJson(Map<String, dynamic> json) {
    return ScheduledTask(
      scheduleId:        json['schedule_id']?.toString()       ?? '',
      userId:            json['user_id']?.toString()           ?? '',
      floorLevel:        json['floor_level']?.toString()       ?? '',
      machineName:       json['machine_name']?.toString()      ?? 'Kiosk/Machine',
      binType:           json['bin_type']?.toString()          ?? 'Trash Bin',
      description:       json['task_description']?.toString()  ?? '',
      recurrencePattern: json['recurrence_pattern']?.toString() ?? 'weekly',
      dayOfWeek:         json['day_of_week']?.toString()       ?? '',
      scheduleTime:      json['schedule_time']?.toString()     ?? '08:00:00',
      createdAt:         json['created_at']?.toString()        ?? '',
    );
  }
}

// ==========================================
// 2. FILTER / SORT STATE
// ==========================================

enum SortOrder { newest, oldest }

const List<String> kBinFilters = [
  'All',
  'Biodegradable',
  'Recyclable',
  'Non-Biodegradable',
];

// ==========================================
// 3. MAIN PAGE
// ==========================================

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage>
    with SingleTickerProviderStateMixin {
  String? _userId;
  String _userRole = 'staff';
  late TabController _tabController;
  final GlobalKey<_CompletedTasksListState> _completedTabKey =
      GlobalKey<_CompletedTasksListState>();

  // ── shared filter state (lifted; passed down to tabs) ──────
  SortOrder _sortOrder   = SortOrder.newest;
  String    _binFilter   = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserRole();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userId = prefs.getString('user_id') ?? '');
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userRole = prefs.getString('role') ?? 'staff');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Filter / sort bar ──────────────────────────────────────
  // Short display labels for bin filter chips
  static const Map<String, String> _binFilterLabels = {
    'All':               'All',
    'Biodegradable':     'Bio',
    'Recyclable':        'Recyc',
    'Non-Biodegradable': 'Non-Bio',
  };

  Widget _buildFilterBar() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        return Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // ── Sort chips ──────────────────────────────────
                _SortChip(
                  label: '↑ New',
                  selected: _sortOrder == SortOrder.newest,
                  onTap: () => setState(() => _sortOrder = SortOrder.newest),
                ),
                const SizedBox(width: 5),
                _SortChip(
                  label: '↓ Old',
                  selected: _sortOrder == SortOrder.oldest,
                  onTap: () => setState(() => _sortOrder = SortOrder.oldest),
                ),
                // ── Thin vertical divider ───────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 1,
                  height: 22,
                  color: AppColors.outline,
                ),
                // ── Bin-type filter chips ───────────────────────
                ...kBinFilters.map((f) {
                  final selected = _binFilter == f;
                  final color = f == 'All'
                      ? AppColors.primary
                      : BinColors.foreground(f);
                  final label = _binFilterLabels[f] ?? f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => setState(() => _binFilter = f),
                      selectedColor: color,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.onSurface,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                      backgroundColor: AppColors.surfaceVariant,
                      side: BorderSide(
                        color: selected ? color : AppColors.outline,
                        width: selected ? 1.5 : 1,
                      ),
                      showCheckmark: false,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Tasks'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}), // rebuild to toggle filter bar
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500, fontSize: 13),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Tasks'),
            Tab(text: 'Completed'),
            Tab(text: 'Scheduled'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Thin divider between AppBar and filter bar
          const Divider(height: 1, thickness: 1, color: AppColors.outline),
          _buildFilterBar(),
          const Divider(height: 1, thickness: 1, color: AppColors.outline),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TasksList(
                  userId:    _userId!,
                  userRole:  _userRole,
                  sortOrder: _sortOrder,
                  binFilter: _binFilter,
                  onTaskCompleted: () {
                    _tabController.animateTo(1);
                    _completedTabKey.currentState?._fetchCompletedTasks();
                  },
                ),
                CompletedTasksList(
                  key:       _completedTabKey,
                  userId:    _userId!,
                  userRole:  _userRole,
                  sortOrder: _sortOrder,
                  binFilter: _binFilter,
                ),
                _ScheduledTasksList(
                  userId:    _userId!,
                  userRole:  _userRole,
                  sortOrder: _sortOrder,
                  binFilter: _binFilter,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sort chip helper ──────────────────────────────────────────
class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  selected ? AppColors.primary : AppColors.outline),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// TAB 1: ACTIVE TASKS & LOCKED ROUTINES
// ==========================================

class _TasksList extends StatefulWidget {
  final String userId;
  final String userRole;
  final SortOrder sortOrder;
  final String binFilter;
  final VoidCallback? onTaskCompleted;

  const _TasksList({
    required this.userId,
    required this.userRole,
    required this.sortOrder,
    required this.binFilter,
    this.onTaskCompleted,
  });

  @override
  _TasksListState createState() => _TasksListState();
}

class _TasksListState extends State<_TasksList> {
  List<Task> _activeTasks         = [];
  List<ScheduledTask> _upcomingRoutines = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  // Re-fetch when filter/sort changes from parent
  @override
  void didUpdateWidget(_TasksList old) {
    super.didUpdateWidget(old);
    // No re-fetch needed — data is already in memory, filtering is local
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
      _error     = null;
    });
    try {
      final taskData     = await ApiService.fetchTasks(userId: widget.userId);
      final scheduleData = await ApiService.fetchSchedules(widget.userId);

      final allTasks     = taskData.map((j) => Task.fromJson(j)).toList();
      final allSchedules =
          scheduleData.map((j) => ScheduledTask.fromJson(j)).toList();

      if (mounted) {
        setState(() {
          _activeTasks = allTasks
              .where((t) =>
                  t.status.toLowerCase() != 'completed' &&
                  t.status.toLowerCase() != 'done')
              .toList();
          _upcomingRoutines = allSchedules;
          _isLoading        = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error     = 'Connection error. Please check your server.';
          _isLoading = false;
        });
      }
    }
  }

  List<Task> get _filteredSortedTasks {
    var list = _activeTasks.where((t) {
      if (widget.binFilter == 'All') return true;
      return t.binType.toLowerCase().contains(
          widget.binFilter.split('-').first.toLowerCase());
    }).toList();

    list.sort((a, b) => widget.sortOrder == SortOrder.newest
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<void> _markTaskAsDone(Task task) async {
    try {
      final success = await ApiService.markTaskAsDone(task.id);
      if (success) {
        await ApiService.logActivity(
          int.parse(widget.userId),
          'Completed task: ${task.description}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('Task marked as done!'),
            ]),
            backgroundColor: AppColors.success,
          ));
        }
        await _fetchAllData();
        widget.onTaskCompleted?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  String _getNextOccurrenceDate(
      String pattern, String targetDayOfWeek) {
    DateTime now = DateTime.now();
    if (pattern.toLowerCase() == 'daily') return 'Tomorrow';
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    int target = days.indexOf(targetDayOfWeek) + 1;
    if (target == 0) return targetDayOfWeek;
    int diff = target - now.weekday;
    if (diff <= 0) diff += 7;
    DateTime next = now.add(Duration(days: diff));
    return '$targetDayOfWeek (${next.month}/${next.day})';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _fetchAllData);
    }

    final tasks = _filteredSortedTasks;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchAllData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // ── Section header ─────────────────────────────────
          _SectionHeader(
            label: "Today's Tasks",
            count: tasks.length,
          ),
          const SizedBox(height: 10),

          if (tasks.isEmpty)
            _EmptyState(
              icon: Icons.task_alt_rounded,
              message: widget.binFilter == 'All'
                  ? 'No active tasks. You\'re all caught up!'
                  : 'No tasks for "${widget.binFilter}".',
            )
          else
            ...tasks.map(_buildActiveCard),

          const SizedBox(height: 8),
          const Divider(color: AppColors.outline),
          const SizedBox(height: 8),

          _SectionHeader(
            label: 'Upcoming Routine Schedules',
            count: _upcomingRoutines.length,
          ),
          const SizedBox(height: 10),

          if (_upcomingRoutines.isEmpty)
            const _EmptyState(
              icon: Icons.schedule_rounded,
              message: 'No upcoming scheduled routines.',
            )
          else
            ..._upcomingRoutines.map(_buildLockedCard),
        ],
      ),
    );
  }

  Widget _buildActiveCard(Task task) {
    final binColor = BinColors.foreground(task.binType);
    final binBg    = BinColors.background(task.binType);
    final binIcon  = BinColors.icon(task.binType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: binColor.withOpacity(0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bin-type badge ────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: binBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(binIcon, size: 13, color: binColor),
                      const SizedBox(width: 5),
                      Text(
                        task.binType,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: binColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ── Description ───────────────────────────────────
            Text(
              task.description,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            // ── Location row — OVERFLOW FIXED ─────────────────
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(    // ← Fixes the RenderFlex overflow
                  child: Text(
                    '${task.machineName} · ${task.binType}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.createdAt,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _markTaskAsDone(task),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Mark as Done'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedCard(ScheduledTask routine) {
    final unlockDate = _getNextOccurrenceDate(
        routine.recurrencePattern, routine.dayOfWeek);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.lockedBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outline, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_clock_rounded,
                    color: AppColors.locked, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    routine.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.locked,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place_outlined,
                    size: 14, color: AppColors.locked),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${routine.floorLevel} · ${routine.machineName}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.locked),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.lock_rounded, size: 14),
              label: Text('Locked until $unlockDate'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.locked,
                disabledForegroundColor: AppColors.locked,
                side: const BorderSide(color: AppColors.disabled),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 2: COMPLETED TASKS
// ==========================================

class CompletedTasksList extends StatefulWidget {
  final String userId;
  final String userRole;
  final SortOrder sortOrder;
  final String binFilter;

  const CompletedTasksList({
    super.key,
    required this.userId,
    required this.userRole,
    required this.sortOrder,
    required this.binFilter,
  });

  @override
  State<CompletedTasksList> createState() => _CompletedTasksListState();
}

class _CompletedTasksListState extends State<CompletedTasksList> {
  List<Task> _completedTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompletedTasks();
  }

  Future<void> _fetchCompletedTasks() async {
    setState(() => _isLoading = true);
    try {
      final taskData = await ApiService.fetchTasks(userId: widget.userId);
      final all = taskData.map((j) => Task.fromJson(j)).toList();
      if (mounted) {
        setState(() {
          _completedTasks = all
              .where((t) =>
                  t.status.toLowerCase() == 'completed' ||
                  t.status.toLowerCase() == 'done')
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Task> get _filteredSorted {
    var list = _completedTasks.where((t) {
      if (widget.binFilter == 'All') return true;
      return t.binType.toLowerCase().contains(
          widget.binFilter.split('-').first.toLowerCase());
    }).toList();

    list.sort((a, b) => widget.sortOrder == SortOrder.newest
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final tasks = _filteredSorted;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchCompletedTasks,
      child: tasks.isEmpty
          ? ListView(children: const [
              SizedBox(height: 60),
              _EmptyState(
                icon: Icons.assignment_turned_in_outlined,
                message: 'No completed tasks yet.',
              ),
            ])
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: tasks.length,
              itemBuilder: (_, i) => _buildCompletedCard(tasks[i]),
            ),
    );
  }

  Widget _buildCompletedCard(Task task) {
    final binColor = BinColors.foreground(task.binType);
    final binBg    = BinColors.background(task.binType);
    final binIcon  = BinColors.icon(task.binType);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side:
            BorderSide(color: AppColors.success.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Done icon circle
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.success, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.onSurfaceVariant,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // ── Bin badge + location — OVERFLOW FIXED ────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: binBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(binIcon, size: 11, color: binColor),
                            const SizedBox(width: 4),
                            Text(
                              task.binType,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: binColor,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.machineName,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (task.createdAt.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.createdAt,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.disabled),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 3: SCHEDULED (revamped with real data)
// ==========================================

class _ScheduledTasksList extends StatefulWidget {
  final String userId;
  final String userRole;
  final SortOrder sortOrder;
  final String binFilter;

  const _ScheduledTasksList({
    required this.userId,
    required this.userRole,
    required this.sortOrder,
    required this.binFilter,
  });

  @override
  _ScheduledTasksListState createState() => _ScheduledTasksListState();
}

class _ScheduledTasksListState extends State<_ScheduledTasksList> {
  List<ScheduledTask> _scheduledTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchScheduledTasks();
  }

  Future<void> _fetchScheduledTasks() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.fetchSchedules(widget.userId);
      if (mounted) {
        setState(() {
          _scheduledTasks =
              data.map((j) => ScheduledTask.fromJson(j)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _recurrenceLabel(ScheduledTask r) {
    final pattern = r.recurrencePattern.toLowerCase();
    if (pattern == 'daily') return 'Every day';
    if (r.dayOfWeek.isNotEmpty) return 'Every ${r.dayOfWeek}';
    return r.recurrencePattern;
  }

  String _formatTime(String raw) {
    // Convert "08:00:00" → "08:00 AM"
    try {
      final parts = raw.split(':');
      int h = int.parse(parts[0]);
      final m = parts[1];
      final suffix = h >= 12 ? 'PM' : 'AM';
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      return '$h:$m $suffix';
    } catch (_) {
      return raw;
    }
  }

  List<ScheduledTask> get _filteredSorted {
    var list = _scheduledTasks.where((r) {
      if (widget.binFilter == 'All') return true;
      return r.binType.toLowerCase().contains(
          widget.binFilter.split('-').first.toLowerCase());
    }).toList();

    list.sort((a, b) => widget.sortOrder == SortOrder.newest
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final tasks = _filteredSorted;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchScheduledTasks,
      child: tasks.isEmpty
          ? ListView(children: const [
              SizedBox(height: 60),
              _EmptyState(
                icon: Icons.calendar_month_outlined,
                message: 'No scheduled routines found.',
              ),
            ])
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: tasks.length,
              itemBuilder: (_, i) =>
                  _buildScheduleCard(tasks[i]),
            ),
    );
  }

  Widget _buildScheduleCard(ScheduledTask r) {
    final binColor = BinColors.foreground(r.binType);
    final binBg    = BinColors.background(r.binType);
    final binIcon  = BinColors.icon(r.binType);
    final isDaily  = r.recurrencePattern.toLowerCase() == 'daily';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: binColor.withOpacity(0.25), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: recurrence badge + time ──────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recurrence badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    // Neutral indigo — no overlap with any bin-type color
                    color: isDaily
                        ? const Color(0xFFEDE7F6) // light violet
                        : const Color(0xFFE8EAF6), // light indigo
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDaily
                            ? Icons.repeat_rounded
                            : Icons.calendar_today_rounded,
                        size: 12,
                        color: isDaily
                            ? const Color(0xFF6A1B9A) // deep violet
                            : const Color(0xFF283593), // deep indigo
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _recurrenceLabel(r),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDaily
                              ? const Color(0xFF6A1B9A)
                              : const Color(0xFF283593),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Time chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 12, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(r.scheduleTime),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Description ───────────────────────────────────
            Text(
              r.description,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.outline, height: 1),
            const SizedBox(height: 10),

            // ── Machine + Bin details — OVERFLOW FIXED ─────────
            Row(
              children: [
                // Machine info
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.precision_manufacturing_rounded,
                          size: 14, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Kiosk',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.disabled,
                                    fontWeight: FontWeight.w600)),
                            Text(
                              r.machineName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Floor
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.layers_rounded,
                          size: 14, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Floor',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.disabled,
                                    fontWeight: FontWeight.w600)),
                            Text(
                              r.floorLevel.isNotEmpty
                                  ? r.floorLevel
                                  : '—',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Bin-type pill ─────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: binBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(binIcon, size: 13, color: binColor),
                  const SizedBox(width: 5),
                  Text(
                    r.binType,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: binColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SHARED HELPER WIDGETS
// ==========================================

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        if (count > 0)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 56, color: AppColors.outline),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

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
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(
                    color: AppColors.onSurface, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}