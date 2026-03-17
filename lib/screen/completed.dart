import 'package:flutter/material.dart';

class CompletedTasksList extends StatelessWidget {
  final List<Map<String, dynamic>> completedTasks;
  final String userRole;

  const CompletedTasksList({
    super.key,
    required this.completedTasks,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    if (completedTasks.isEmpty) {
      return const Center(child: Text('No completed tasks'));
    }
    return ListView.builder(
      itemCount: completedTasks.length,
      itemBuilder: (context, index) {
        final task = completedTasks[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(
              task['title'] ?? task['task_description'] ?? 'Completed Task',
              style: const TextStyle(
                decoration: TextDecoration.lineThrough,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task['description'] != null)
                  Text(task['description']),
                if (task['completed_at'] != null)
                  Text('Completed at: ${task['completed_at']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            trailing: userRole == 'admin'
                ? Text('User: ${task['user_id'] ?? ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey))
                : null,
          ),
        );
      },
    );
  }
}
