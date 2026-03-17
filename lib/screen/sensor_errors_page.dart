import 'package:flutter/material.dart';

class SensorErrorsPage extends StatelessWidget {
  const SensorErrorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> errors = [
      {
        'sensor': 'Sensor A',
        'type': 'Biodegradable',
        'error': 'not responding',
        'date': 'June 5, 9:12 AM',

      },
      {
        'sensor': 'Sensor B',
        'type': 'Recyclable',
        'error': 'disconnected',
        'date': 'June 4, 2:03 PM',
        
      },
      {
        'sensor': 'Sensor C',
        'type': 'Non-Biodegradable',
        'error': 'voltage error',
        'date': 'June 3, 7:45 AM',
      
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Errors'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Implement refresh functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing sensor status...')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red.shade50,
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Text(
                  '${errors.length} Active Errors',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: errors.length,
              itemBuilder: (context, index) {
                final error = errors[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: InkWell(
                    onTap: () => _showErrorDetails(context, error),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                error['sensor'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '(${error['type']})',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${error['error']}',
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                error['date'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Implement resolve functionality
                                },
                                child: const Text('Resolve'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

 

 

  void _showErrorDetails(BuildContext context, Map<String, dynamic> error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(error['sensor']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Type', error['type']),
            _buildDetailRow('Error', error['error']),
            _buildDetailRow('Date', error['date']),
            const SizedBox(height: 16),
            const Text(
              'Recommended Action:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check the sensor connections and power supply. If the error persists, contact technical support.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement resolve functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Mark as Resolved'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}