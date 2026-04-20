import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'homepage.dart'; 
import '../service/api_service.dart';
// Note: Ensure your ApiConfig import is here if you use ApiConfig.baseUrl!

// ==========================================
// 1. DATA MODELS
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
    required this.id, required this.userId, required this.binId, required this.machineId,
    required this.machineName, required this.binType, required this.description,
    required this.status, required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['task_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      binId: json['bin_id']?.toString() ?? '',
      machineId: json['machine_id']?.toString() ?? '',
      machineName: json['machine_name']?.toString() ?? 'Kiosk/Machine',
      binType: json['bin_type']?.toString() ?? 'Trash Bin',
      description: json['task_description']?.toString() ?? '',
      status: json['task_status']?.toString() ?? 'Pending',
      createdAt: json['created_at']?.toString() ?? '',
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
    required this.scheduleId, required this.userId, required this.floorLevel,
    required this.machineName, required this.binType, required this.description,
    required this.recurrencePattern, required this.dayOfWeek,
    required this.scheduleTime, required this.createdAt,
  });

  factory ScheduledTask.fromJson(Map<String, dynamic> json) {
    return ScheduledTask(
      scheduleId: json['schedule_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      floorLevel: json['floor_level']?.toString() ?? '',
      machineName: json['machine_name']?.toString() ?? 'Kiosk/Machine',
      binType: json['bin_type']?.toString() ?? 'Trash Bin',
      description: json['task_description']?.toString() ?? '',
      recurrencePattern: json['recurrence_pattern']?.toString() ?? 'weekly',
      dayOfWeek: json['day_of_week']?.toString() ?? '',
      scheduleTime: json['schedule_time']?.toString() ?? '08:00:00',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

// ==========================================
// 2. MAIN PAGE (Restored Constructor!)
// ==========================================

class TasksPage extends StatefulWidget {
  const TasksPage({super.key}); // Restored: No longer requires userRole!

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> with SingleTickerProviderStateMixin {
  String? _userId;
  String _userRole = 'staff';
  late TabController _tabController;
  final GlobalKey<_CompletedTasksListState> _completedTabKey = GlobalKey<_CompletedTasksListState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserRole();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _userId = prefs.getString('user_id') ?? ''; });
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _userRole = prefs.getString('role') ?? 'staff'; });
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue, // Changed to match your new premium UI
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Tasks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: 'Tasks'),
                Tab(text: 'Completed'),
                Tab(text: 'Scheduled'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TasksList(
                    userId: _userId!,
                    userRole: _userRole,
                    onTaskCompleted: () {
                      _tabController.animateTo(1);
                      _completedTabKey.currentState?._fetchCompletedTasks();
                    },
                  ),
                  CompletedTasksList(key: _completedTabKey, userId: _userId!, userRole: _userRole),
                  _ScheduledTasksList(userId: _userId!, userRole: _userRole),
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
// TAB 1: ACTIVE TASKS & LOCKED ROUTINES
// ==========================================

class _TasksList extends StatefulWidget {
  final String userId;
  final String userRole;
  final VoidCallback? onTaskCompleted;
  const _TasksList({required this.userId, required this.userRole, this.onTaskCompleted});
  @override
  _TasksListState createState() => _TasksListState();
}

class _TasksListState extends State<_TasksList> {
  List<Task> _activeTasks = [];
  List<ScheduledTask> _upcomingRoutines = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // 1. Fetch Tasks
      final List<dynamic> taskData = await ApiService.fetchTasks(userId: widget.userId);
      final List<Task> allTasks = taskData.map((json) => Task.fromJson(json)).toList();
      
      // 2. Fetch Schedules (for the locked section)
      final List<dynamic> scheduleData = await ApiService.fetchSchedules(widget.userId);
      final List<ScheduledTask> allSchedules = scheduleData.map((json) => ScheduledTask.fromJson(json)).toList();

      if (mounted) {
        setState(() {
          _activeTasks = allTasks.where((t) => t.status.toLowerCase() != 'completed' && t.status.toLowerCase() != 'done').toList();
          _upcomingRoutines = allSchedules;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Connection error. Check your server.'; _isLoading = false; });
    }
  }

  // We now pass the whole Task object instead of just the ID
  Future<void> _markTaskAsDone(Task task) async {
    try {
      final success = await ApiService.markTaskAsDone(task.id);

      if (success) {
        // We use int.parse() because widget.userId is a String, and your API expects an int
        await ApiService.logActivity(
          int.parse(widget.userId), 
          "Completed task: ${task_id.description}" // This makes the log dynamic!
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task completed!'), backgroundColor: Colors.green)
          );
        }
        await _fetchAllData();
        widget.onTaskCompleted?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)
        );
      }
    }
  }

  String _getNextOccurrenceDate(String pattern, String targetDayOfWeek) {
    DateTime now = DateTime.now();
    if (pattern.toLowerCase() == 'daily') return "Tomorrow";
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    int target = days.indexOf(targetDayOfWeek) + 1; 
    if (target == 0) return targetDayOfWeek;
    int diff = target - now.weekday;
    if (diff <= 0) diff += 7; 
    DateTime next = now.add(Duration(days: diff));
    return "Next $targetDayOfWeek (${next.month}/${next.day})";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    return RefreshIndicator(
      onRefresh: _fetchAllData,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Today's Active Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          if (_activeTasks.isEmpty) const Text("No tasks for today. You're caught up!", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          ..._activeTasks.map((t) => _buildActiveCard(t)).toList(),
          
          const Divider(height: 40, thickness: 2),
          
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Upcoming Scheduled Routines", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          if (_upcomingRoutines.isEmpty) const Text("No upcoming routines.", style: TextStyle(color: Colors.grey)),
          ..._upcomingRoutines.map((r) => _buildLockedCard(r)).toList(),
        ],
      ),
    );
  }

  Widget _buildActiveCard(Task task) {
    return Card(
      elevation: 3, margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade200, width: 2)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.location_on, size: 16, color: Colors.grey), const SizedBox(width: 4), Text('${task.machineName} • ${task.binType}', style: const TextStyle(fontWeight: FontWeight.w600))]),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _markTaskAsDone(task),
                icon: const Icon(Icons.check_circle_outline), label: const Text('Mark as Done'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedCard(ScheduledTask routine) {
    String unlockDate = _getNextOccurrenceDate(routine.recurrencePattern, routine.dayOfWeek);
    return Card(
      elevation: 0, margin: const EdgeInsets.only(bottom: 12), color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.lock_clock, color: Colors.grey, size: 20), const SizedBox(width: 8), Text(routine.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey))]),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.place, size: 16, color: Colors.grey), const SizedBox(width: 4), Text('${routine.floorLevel} Floor • ${routine.machineName}', style: const TextStyle(color: Colors.grey))]),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(onPressed: null, icon: const Icon(Icons.lock), label: Text('Locked until $unlockDate'))),
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
  const CompletedTasksList({super.key, required this.userId, required this.userRole});
  @override
  State<CompletedTasksList> createState() => _CompletedTasksListState();
}

class _CompletedTasksListState extends State<CompletedTasksList> {
  List<Task> _completedTasks = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _fetchCompletedTasks(); }

  Future<void> _fetchCompletedTasks() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> taskData = await ApiService.fetchTasks(userId: widget.userId);
      final List<Task> allTasks = taskData.map((json) => Task.fromJson(json)).toList();
      if (mounted) {
        setState(() {
          _completedTasks = allTasks.where((t) => t.status.toLowerCase() == 'completed' || t.status.toLowerCase() == 'done').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.green));
    return RefreshIndicator(
      color: Colors.green,
      onRefresh: _fetchCompletedTasks,
      child: _completedTasks.isEmpty
          ? ListView(children: const [SizedBox(height: 100), Icon(Icons.assignment_turned_in, size: 80, color: Colors.black12), SizedBox(height: 16), Center(child: Text("No completed tasks yet.", style: TextStyle(color: Colors.grey)))])
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _completedTasks.length,
              itemBuilder: (context, index) {
                final task = _completedTasks[index];
                return Card(
                  elevation: 1, margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.green.shade200, width: 1.5)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 24), const SizedBox(width: 12),
                            Expanded(child: Text(task.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54, decoration: TextDecoration.lineThrough))),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(children: [const Icon(Icons.place, size: 16, color: Colors.grey), const SizedBox(width: 4), Text('${task.machineName} • ${task.binType}', style: const TextStyle(color: Colors.grey))]),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ==========================================
// TAB 3: SCHEDULED (MASTER DIRECTORY)
// ==========================================

class _ScheduledTasksList extends StatefulWidget {
  final String userId;
  final String userRole;
  const _ScheduledTasksList({required this.userId, required this.userRole});
  @override
  _ScheduledTasksListState createState() => _ScheduledTasksListState();
}

class _ScheduledTasksListState extends State<_ScheduledTasksList> {
  List<ScheduledTask> _scheduledTasks = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _fetchScheduledTasks(); }

  Future<void> _fetchScheduledTasks() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> schedules = await ApiService.fetchSchedules(widget.userId);
      if (mounted) {
        setState(() {
          _scheduledTasks = schedules.map((json) => ScheduledTask.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _fetchScheduledTasks,
      child: _scheduledTasks.isEmpty
        ? const Center(child: Text('No scheduled tasks available'))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _scheduledTasks.length,
            itemBuilder: (context, index) {
              final routine = _scheduledTasks[index];
              String routineText = routine.recurrencePattern.toLowerCase() == 'daily' ? 'Daily at ${routine.scheduleTime}' : 'Weekly on ${routine.dayOfWeek} at ${routine.scheduleTime}';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12), elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1.5)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [const Icon(Icons.loop, color: Colors.blue, size: 24), const SizedBox(width: 8), Expanded(child: Text(routineText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)))]),
                      const Divider(height: 24),
                      Text(routine.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Row(children: [const Icon(Icons.place, size: 16, color: Colors.grey), const SizedBox(width: 4), Text('${routine.floorLevel} Floor • ${routine.machineName}')]),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}