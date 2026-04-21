import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/api_service.dart';

// --- DATA MODEL ---
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
  final String? completedAt; // Added to catch the new timestamp!

  Task({
    required this.id, required this.userId, required this.binId, required this.machineId,
    required this.machineName, required this.binType, required this.description, 
    required this.status, required this.createdAt, this.completedAt,
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
      completedAt: json['completed_at']?.toString(), // Catch the newly added DB column
    );
  }
}

class CompletedTasksPage extends StatefulWidget {
  final String userRole;
  const CompletedTasksPage({Key? key, required this.userRole}) : super(key: key);

  @override
  _CompletedTasksPageState createState() => _CompletedTasksPageState();
}

class _CompletedTasksPageState extends State<CompletedTasksPage> {
  List<Task> _completedTasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCompletedTasks();
  }

  Future<void> _fetchCompletedTasks() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('user_id') ?? '';
      
      final List<dynamic> taskData = await ApiService.fetchTasks(userId: userId);
      
      if (mounted) {
        setState(() {
          _completedTasks = taskData.map((json) => Task.fromJson(json))
              .where((t) => t.status.toLowerCase() == 'completed' || t.status.toLowerCase() == 'done')
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Log', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade600,
      ),
      backgroundColor: Colors.grey[50], 
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  color: Colors.green,
                  onRefresh: _fetchCompletedTasks,
                  child: _completedTasks.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Icon(Icons.assignment_turned_in, size: 80, color: Colors.black12),
                            SizedBox(height: 16),
                            Center(child: Text("No completed tasks yet.", style: TextStyle(color: Colors.grey, fontSize: 16))),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _completedTasks.length,
                          itemBuilder: (context, index) {
                            return _buildCompletedCard(_completedTasks[index]);
                          },
                        ),
                ),
    );
  }

  Widget _buildCompletedCard(Task task) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade200, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16, 
                      color: Colors.black54, 
                      decoration: TextDecoration.lineThrough, 
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'DONE',
                    style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.place, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${task.machineName} • ${task.binType}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 8),
            
            // --- TIME INFORMATION ---
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Task Date: ${task.createdAt}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
            
            // If the completedAt timestamp exists, show it prominently!
            if (task.completedAt != null && task.completedAt!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.done_all, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text('Finished: ${task.completedAt}', 
                    style: TextStyle(
                      fontSize: 12, 
                      color: Colors.green[700], 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}