import 'package:flutter/material.dart';

class SensorStatusPage extends StatefulWidget {
  const SensorStatusPage({super.key});

  @override
  State<SensorStatusPage> createState() => _SensorStatusPageState();
}

class _SensorStatusPageState extends State<SensorStatusPage> {
  // Initial relay statuses (true = ON, false = OFF)
  List<bool> relayStatus = [true, false, true, false, true];
  bool allRelaysOn = false;

  // Initial relay names
  List<String> relayNames = [
    'Switch All Relays',
    'Relay 1',
    'Relay 2',
    'Relay 3',
    'Relay 4',
    'Relay 5',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor & Relay Status'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '🔌 Relay Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            // Switch All Relays card
            Card(
              elevation: 2,
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.power_settings_new,
                  color: allRelaysOn ? Colors.green : Colors.red,
                  size: 28,
                ),
                title: Text(
                  relayNames[0],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  allRelaysOn ? 'All Relays: ON' : 'All Relays: OFF',
                  style: TextStyle(
                    color: allRelaysOn ? Colors.green : Colors.red,
                  ),
                ),
                trailing: Switch(
                  value: allRelaysOn,
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                  onChanged: (bool value) {
                    setState(() {
                      allRelaysOn = value;
                      for (int i = 0; i < relayStatus.length; i++) {
                        relayStatus[i] = value;
                      }
                    });
                    _showAllRelaysToggleMessage(value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Individual relay cards
            for (int i = 0; i < relayStatus.length; i++)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.power_settings_new,
                    color: relayStatus[i] ? Colors.green : Colors.red,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _showEditRelayNameDialog(i + 1),
                          child: Row(
                            children: [
                              Text(
                                relayNames[i + 1],
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _showDeleteRelayDialog(i),
                        tooltip: 'Delete Relay',
                      ),
                    ],
                  ),
                  subtitle: Text(
                    relayStatus[i] ? 'Status: ON' : 'Status: OFF',
                    style: TextStyle(
                      color: relayStatus[i] ? Colors.green : Colors.red,
                    ),
                  ),
                  trailing: Switch(
                    value: relayStatus[i],
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                    onChanged: (bool value) {
                      setState(() {
                        relayStatus[i] = value;
                        _updateAllRelaysStatus();
                      });
                    },
                  ),
                ),
              ),
            const Divider(height: 30, thickness: 1),
            const Text(
              '📡 Sensor Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            _sensorItem('Sensor 1', 'Working properly', Colors.green),
            _sensorItem('Sensor 2', 'No signal', Colors.orange),
            _sensorItem('Sensor 3', 'Error detected', Colors.red),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewRelay,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _sensorItem(String name, String status, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(
          Icons.sensors,
          color: color,
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 12,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _updateAllRelaysStatus() {
    bool allOn = relayStatus.every((status) => status == true);
    if (allRelaysOn != allOn) {
      setState(() {
        allRelaysOn = allOn;
      });
    }
  }

  void _showAllRelaysToggleMessage(bool isOn) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isOn ? Icons.check_circle : Icons.info,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              isOn ? 'All relays turned ON' : 'All relays turned OFF',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: isOn ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  void _showEditRelayNameDialog(int index) {
    final TextEditingController controller = TextEditingController(text: relayNames[index]);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text('Edit Relay Name'),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter new relay name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    relayNames[index] = controller.text.trim();
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('Renamed to "${controller.text.trim()}"'),
                        ],
                      ),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(8),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteRelayDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
              const SizedBox(width: 8),
              const Text('Delete Relay'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete "${relayNames[index + 1]}"?'),
              const SizedBox(height: 8),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteRelay(index);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteRelay(int index) {
    setState(() {
      relayNames.removeAt(index + 1);
      relayStatus.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Relay deleted successfully'),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(8),
      ),
    );
    _updateAllRelaysStatus();
  }

  void _addNewRelay() {
    setState(() {
      relayNames.add('Relay ${relayNames.length}');
      relayStatus.add(false);
    });
    _updateAllRelaysStatus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('New relay added successfully'),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(8),
      ),
    );
  }
}