import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'homepage.dart'; // Ensure this file exists
import 'package:Segreduino/service/api_service.dart';

class Task {
  final String id;
  final String userId;
  final String binId;
  final String machineId;
  final String description;
  final String status;
  final String createdAt;


  Task({
    required this.id,
    required this.userId,
    required this.binId,
    required this.machineId,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['task_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      binId: json['bin_id']?.toString() ?? '',
      machineId: json['machine_id']?.toString() ?? '',
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
  final String description;
  final String scheduledDate;
  final String createdAt;
  final int movedToTasks;

  ScheduledTask({
    required this.scheduleId,
    required this.userId,
    required this.floorLevel,
    required this.description,
    required this.scheduledDate,
    required this.createdAt,
    required this.movedToTasks,
  });

  factory ScheduledTask.fromJson(Map<String, dynamic> json) {
    return ScheduledTask(
      scheduleId: json['schedule_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      floorLevel: json['floor_level']?.toString() ?? '',
      description: json['task_description']?.toString() ?? '',
      scheduledDate: json['schedule_date']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      movedToTasks: int.tryParse(json['moved_to_tasks'].toString()) ?? 0,
    );
  }
}

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

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
    setState(() {
      _userId = prefs.getString('user_id') ?? '';
    });
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role') ?? 'staff';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()), // show while loading
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Task Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
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

class _TasksList extends StatefulWidget {
  final String userId;
  final String userRole;
  final VoidCallback? onTaskCompleted;
  const _TasksList({required this.userId, required this.userRole, this.onTaskCompleted});
  @override
  _TasksListState createState() => _TasksListState();
}

class _TasksListState extends State<_TasksList> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      setState(() => _isLoading = true);

      // Staff (may userId) → tasks niya lang
      // Admin (walang userId) → lahat ng tasks
      final List<dynamic> taskData = await ApiService.fetchTasks(userId: widget.userId);

      final List<Task> allTasks = taskData.map((json) => Task.fromJson(json)).toList();

      if (mounted) {
        setState(() {
          _tasks = allTasks
              .where((task) => task.status.toLowerCase() == 'pending' || task.status.toLowerCase() == 'in_progress')
              .toList();
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      print('Fetch error: $e');
      if (mounted) {
        setState(() {
          _error = 'Connection error. Please check your server and try again.';
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _markTaskAsDone(String taskId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/controllers/Actions/mark_task_done.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'task_id': taskId}),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Marked as completed')),
          );
        }

        await _fetchTasks();

        final parentState = context.findAncestorStateOfType<_TasksPageState>();
        parentState?._tabController.animateTo(1);
        parentState?._completedTabKey.currentState?._fetchCompletedTasks();

      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Update failed')),
          );
        }
      }
    } catch (e) {
      print('Mark done error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildTaskCard({required Task task}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: task.status == 'Completed' ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.userRole == 'admin'
                        ? 'Task ID: ${task.id} | User ID: ${task.userId}'
                        : 'Task: ${task.description}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Icon(
                  task.status == 'Completed' ? Icons.check_circle : Icons.pending_actions,
                  color: task.status == 'Completed' ? Colors.green : Colors.orange,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Bin ID: ${task.binId}'),
            Text('Machine ID: ${task.machineId}'),
            Text('Status: ${task.status == 'in_progress' ? 'In Progress' : task.status}'),
            Text('Created at: ${task.createdAt}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            if (task.status != 'Completed')
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _markTaskAsDone(task.id);
                  },
                  icon: const Icon(Icons.done),
                  label: const Text('Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_tasks.isEmpty) return const Center(child: Text('No tasks available'));

    return RefreshIndicator(
      onRefresh: _fetchTasks,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: _tasks.length,
        itemBuilder: (context, index) => _buildTaskCard(task: _tasks[index]),
      ),
    );
  }
}

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
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchScheduledTasks();
  }

  Future<void> _fetchScheduledTasks() async {
    try {
      setState(() => _isLoading = true);

      final schedules = await ApiService.fetchSchedules(widget.userId);

      setState(() {
        _scheduledTasks = schedules
            .map((json) => ScheduledTask.fromJson(json))
            .where((task) => task.movedToTasks == 0) // ✅ show only active schedules
            .toList();

        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      print('Scheduled fetch error: $e');
      setState(() {
        _error = 'Failed to load scheduled tasks. Please check your connection.';
        _isLoading = false;
      });
    }
  }



  Widget _buildScheduledTaskCard(ScheduledTask task) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.userRole == 'admin'
                        ? 'Schedule ID: ${task.scheduleId}'
                        : 'Scheduled Task',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const Icon(Icons.schedule, color: Colors.blue, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text('Floor Level: ${task.floorLevel}'),
            Text('Description: ${task.description}'),
            Text('Schedule for: ${task.scheduledDate}'),
            const SizedBox(height: 8),
            Text('Created at: ${task.createdAt}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_scheduledTasks.isEmpty) return const Center(child: Text('No scheduled tasks available'));

    return RefreshIndicator(
      onRefresh: _fetchScheduledTasks,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: _scheduledTasks.length,
        itemBuilder: (context, index) => _buildScheduledTaskCard(_scheduledTasks[index]),
      ),
    );
  }
}

class CompletedTasksList extends StatefulWidget {
  final String userId;
  final String userRole;
  const CompletedTasksList({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<CompletedTasksList> createState() => _CompletedTasksListState();
}

class _CompletedTasksListState extends State<CompletedTasksList> {
  List<Task> _completedTasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCompletedTasks();
  }

  Future<void> _fetchCompletedTasks() async {
    try {
      setState(() => _isLoading = true);

      // ✅ Pass userId to fetch tasks specific to this user
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/controllers/Api/tasks_api.php?user_id=${widget.userId}',
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final allTasks = (data['tasks'] as List)
              .map((json) => Task.fromJson(json))
              .toList();

          if (mounted) {
            setState(() {
              _completedTasks = allTasks
                  .where((task) => task.status.toLowerCase() == 'completed')
                  .toList();
              _error = null;
              _isLoading = false;
            });
          }
        } else {
          throw Exception(data['message'] ?? 'Unknown error occurred');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Completed fetch error: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load completed tasks: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_completedTasks.isEmpty) return const Center(child: Text('No completed tasks'));

    return RefreshIndicator(
      onRefresh: _fetchCompletedTasks,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: _completedTasks.length,
        itemBuilder: (context, index) {
          final task = _completedTasks[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.green.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.description,
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    task.createdAt,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}