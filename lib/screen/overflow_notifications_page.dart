import 'package:flutter/material.dart';

class OverflowNotificationsPage extends StatelessWidget {
  const OverflowNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> overflows = [
      {
        'bin': 'Biodegradable',
        'status': 'Bin is full',
        'time': 'June 5, 10:30 AM',
        'urgency': 'high'
      },
      {
        'bin': 'Recyclable',
        'status': 'Almost overflowing',
        'time': 'June 4, 4:00 PM',
        'urgency': 'medium'
      },
      {
        'bin': 'Non-Biodegradable',
        'status': 'Overflow detected',
        'time': 'June 3, 9:10 AM',
        'urgency': 'high'
      },
    ];

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
        child: overflows.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: overflows.length,
                itemBuilder: (context, index) {
                  final overflow = overflows[index];
                  return _buildNotificationCard(overflow, context);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/check_circle.png',
            width: 120, // mas malaki na
            height: 120,
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

  Widget _buildNotificationCard(Map<String, String> overflow, BuildContext context) {
    Color urgencyColor = _getUrgencyColor(overflow['urgency']!);
    String binImage = _getBinImage(overflow['bin']!);

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
                      width: 64, // mas malaki na
                      height: 64,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overflow['bin']!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          overflow['status']!,
                          style: TextStyle(
                            color: urgencyColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildUrgencyIndicator(overflow['urgency']!),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    overflow['time']!,
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

  // Return the asset path for each bin type
  String _getBinImage(String binType) {
    switch (binType) {
      case 'Biodegradable':
        return 'assets/biodegradable_bin.png';
      case 'Recyclable':
        return 'assets/recyclable_bin.png';
      case 'Non-Biodegradable':
        return 'assets/non_biodegradable_bin.png';
      default:
        return 'assets/bin.png';
    }
  }
}