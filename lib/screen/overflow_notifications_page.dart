import 'package:flutter/material.dart';
import '../service/api_service.dart'; // Make sure this path matches your project structure

class OverflowNotificationsPage extends StatefulWidget {
  const OverflowNotificationsPage({super.key});

  @override
  State<OverflowNotificationsPage> createState() => _OverflowNotificationsPageState();
}

class _OverflowNotificationsPageState extends State<OverflowNotificationsPage> {
  List<dynamic> notifications = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await ApiService.fetchNotifications();
      setState(() {
        // Optional: If you ONLY want 'bin_full' on this specific page
        // notifications = data.where((n) => n['type'] == 'bin_full').toList();
        notifications = data; 
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load alerts.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Overflow Alerts',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red.shade700,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade700,
              Colors.white,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification, context);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/check_circle.png',
            width: 120,
            height: 120,
            // Fallback in case image is missing:
            errorBuilder: (context, error, stackTrace) => 
                Icon(Icons.check_circle, size: 120, color: Colors.green.shade700),
          ),
          const SizedBox(height: 16),
          Text(
            'All Bins Normal',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No overflow alerts at the moment',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(dynamic notification, BuildContext context) {
    // Determine mapping based on the data sent from PHP
    String type = notification['type'] ?? 'unknown';
    String binName = notification['raw_message'] ?? 'General Bin';
    String status = notification['msg'] ?? 'Notification';
    String time = notification['time'] ?? 'Unknown time';
    
    // Assign urgency logic
    String urgency = type == 'bin_full' ? 'high' : 'medium';
    Color urgencyColor = _getUrgencyColor(urgency);
    String binImage = _getBinImage(binName);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: urgencyColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: urgencyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      binImage,
                      width: 64,
                      height: 64,
                      // Fallback icon if the asset image is missing
                      errorBuilder: (context, error, stackTrace) => 
                          Icon(Icons.delete_outline, size: 64, color: urgencyColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          binName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status,
                          style: TextStyle(
                            color: urgencyColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildUrgencyIndicator(urgency),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrgencyIndicator(String urgency) {
    Color color = _getUrgencyColor(urgency);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        urgency.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.yellow.shade700;
    }
  }

  String _getBinImage(String binType) {
    if (binType.toLowerCase().contains('non')) {
      return 'assets/non_biodegradable_bin.png';
    } else if (binType.toLowerCase().contains('bio')) {
      return 'assets/biodegradable_bin.png';
    } else if (binType.toLowerCase().contains('recycl')) {
      return 'assets/recyclable_bin.png';
    }
    return 'assets/bin.png'; // default
  }
}