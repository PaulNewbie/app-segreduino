import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UnrecognizedWastePage extends StatefulWidget {
  const UnrecognizedWastePage({super.key});

  @override
  State<UnrecognizedWastePage> createState() => _UnrecognizedWastePageState();
}

class _UnrecognizedWastePageState extends State<UnrecognizedWastePage> {
  List<UnrecognizedWaste> _wasteItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUnrecognizedWaste();
  }

  Future<void> _fetchUnrecognizedWaste() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.100.145/flutter_api/get_unrecognized_waste.php'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _wasteItems = data
              .map((item) => UnrecognizedWaste.fromJson(item))
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load unrecognized waste');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error loading data: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unrecognized Waste'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchUnrecognizedWaste();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wasteItems.isEmpty
              ? _buildEmptyState()
              : _buildWasteList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.recycling, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No unrecognized waste found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All items have been properly categorized',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWasteList() {
    return RefreshIndicator(
      onRefresh: _fetchUnrecognizedWaste,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _wasteItems.length,
        itemBuilder: (context, index) {
          final waste = _wasteItems[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: waste.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        waste.imageUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[200],
                              child: Icon(Icons.broken_image,
                                  color: Colors.grey[400]),
                            ),
                      ),
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.image_not_supported,
                          color: Colors.grey[400]),
                    ),
              title: Text(
                'Unknown Item #${waste.id}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Detected on: ${waste.detectedDate}'),
                  Text('Bin: ${waste.binLocation}'),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showOptionsDialog(waste),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showOptionsDialog(UnrecognizedWaste waste) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Item Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Categorize'),
                onTap: () {
                  Navigator.pop(context);
                  _showCategorizeDialog(waste);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteWasteItem(waste.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCategorizeDialog(UnrecognizedWaste waste) async {
    final categories = ['Biodegradable', 'Non-biodegradable', 'Recyclable'];
    String? selectedCategory;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Categorize Waste'),
          content: DropdownButton<String>(
            value: selectedCategory,
            hint: const Text('Select category'),
            isExpanded: true,
            items: categories
                .map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => selectedCategory = value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedCategory != null) {
                  _categorizeWaste(waste.id, selectedCategory!);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteWasteItem(int id) async {
    // Implement delete functionality
  }

  Future<void> _categorizeWaste(int id, String category) async {
    // Implement categorize functionality
  }
}

class UnrecognizedWaste {
  final int id;
  final String? imageUrl;
  final String detectedDate;
  final String binLocation;

  UnrecognizedWaste({
    required this.id,
    this.imageUrl,
    required this.detectedDate,
    required this.binLocation,
  });

  factory UnrecognizedWaste.fromJson(Map<String, dynamic> json) {
    return UnrecognizedWaste(
      id: json['id'],
      imageUrl: json['image_url'],
      detectedDate: json['detected_date'],
      binLocation: json['bin_location'],
    );
  }
}