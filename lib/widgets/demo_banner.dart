import 'package:flutter/material.dart';

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key, required this.isDemo});

  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    if (!isDemo) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('Demo customer bypass active: lock restrictions are disabled for testing.'),
    );
  }
}
