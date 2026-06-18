import 'package:flutter/material.dart';
import '../models/water_log.dart';

class LogProvider with ChangeNotifier {
  final List<WaterLog> _logs = [];

  List<WaterLog> get logs => _logs;

  WaterLog? get latestLog => _logs.isNotEmpty ? _logs.last : null;

  void addManualReading(double rawTurbidity, String lightCondition) {
    // 1. Mock "AI" Correction Logic: Adjusting for light interference
    double trueTurbidity = rawTurbidity;
    if (lightCondition == 'High') {
      trueTurbidity = rawTurbidity + 4.5; // Simulating a correction
    } else if (lightCondition == 'Low') {
      trueTurbidity = rawTurbidity - 2.0;
    }

    // 2. Status Logic based on True Turbidity (NTU)
    String status = 'Safe';
    if (trueTurbidity > 5 && trueTurbidity <= 15) {
      status = 'Warning';
    } else if (trueTurbidity > 15) {
      status = 'Danger';
    }

    // 3. Create and save the log
    final newLog = WaterLog(
      id: DateTime.now().toString(),
      rawTurbidity: rawTurbidity,
      trueTurbidity: trueTurbidity,
      ph: 7.0,          // Default neutral pH (not provided in legacy form)
      temperature: 25.0, // Default room temperature
      wqi: status == 'Safe' ? 85.0 : (status == 'Warning' ? 55.0 : 25.0),
      lightCondition: lightCondition,
      status: status,
      advice: status == 'Safe'
          ? 'Water quality is within acceptable limits.'
          : (status == 'Warning'
              ? 'Turbidity levels are elevated. Monitor closely.'
              : 'Turbidity levels are critically high. Do not use.'),
      waterCategory: 'Normal Water',
      waterLevel: 'Medium',
      timestamp: DateTime.now(),
    );

    _logs.add(newLog);
    notifyListeners(); // Tells the UI to update immediately
  }
}