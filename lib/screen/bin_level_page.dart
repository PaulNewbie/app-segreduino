import 'package:flutter/material.dart';

class AnimatedBinCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String percent;
  final Color color;

  const AnimatedBinCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(imagePath, height: 100, width: 100), // Icon size increased
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  percent,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class BinLevelPage extends StatelessWidget {
  const BinLevelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 28),
                onPressed: () {
                  Navigator.pop(context); // Goes back to Homepage
                },
              ),
              const SizedBox(height: 12),

              // Title
              const Center(
                child: Text(
                  'FLOOR WASTE BIN LEVEL',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Bin Cards in vertical list
              Expanded(
                child: ListView(
                  children: const [
                    AnimatedBinCard(
                      imagePath: 'assets/biode.png',
                      title: 'Biodegradable',
                      percent: '52%',
                      color: Colors.green,
                    ),
                    AnimatedBinCard(
                      imagePath: 'assets/NONBIO.png',
                      title: 'Non-Biodegradable',
                      percent: '30%',
                      color: Colors.orange,
                    ),
                    AnimatedBinCard(
                      imagePath: 'assets/RECYCLE.png',
                      title: 'Recyclable',
                      percent: '74%',
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
