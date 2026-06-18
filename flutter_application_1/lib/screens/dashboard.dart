import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/log_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logProvider = Provider.of<LogProvider>(context);
    final latest = logProvider.latestLog;

    return Scaffold(
      appBar: AppBar(title: const Text('Real-Time Status')),
      body: Center(
        child: latest == null
            ? const Text('No data yet. Go to Simulate Data.')
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('AI Corrected Turbidity', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text(
                    '${latest.trueTurbidity.toStringAsFixed(2)} NTU',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: latest.status == 'Safe'
                          ? Colors.green
                          : (latest.status == 'Warning' ? Colors.orange : Colors.red),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Status: ${latest.status}',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}