import 'package:flutter/material.dart';
import '../models/water_log.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';

class WaterProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<WaterLog> _logs = [];
  bool _isLoading = false;
  String? _errorMessage;
  final List<String> _activeAlerts = [];

  List<WaterLog> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<String> get activeAlerts => _activeAlerts;

  WaterLog? get latestLog => _logs.isNotEmpty ? _logs.first : null;

  /// Fetches historical logs from DB (Local or Firestore)
  Future<void> fetchLogs(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _logs = await _databaseService.fetchWaterLogs(uid);
      _evaluateActiveAlerts();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Evaluates safety alerts based on the most recent log parameters
  void _evaluateActiveAlerts() {
    _activeAlerts.clear();
    final latest = latestLog;
    if (latest == null) return;

    // pH alert: WHO standards define normal safe pH as 6.5 to 8.5
    if (latest.ph < 6.5 || latest.ph > 8.5) {
      _activeAlerts.add(
        '⚠️ Abnormal pH detected (${latest.ph})! Normal drinking water pH should be between 6.5 and 8.5.'
      );
    }

    // Turbidity alert: safe standard is < 5 NTU
    if (latest.trueTurbidity > 5.0) {
      _activeAlerts.add(
        '⚠️ High Turbidity detected (${latest.trueTurbidity} NTU)! Level exceeds the safe standard of 5.0 NTU.'
      );
    }

    // Temperature alert: high temp promotes bacterial replication
    if (latest.temperature >= 35.0) {
      _activeAlerts.add(
        '⚠️ High Water Temperature (${latest.temperature}°C)! High temperatures encourage organic decay and pathogenetic growth.'
      );
    }
  }

  /// Adds a new manual reading, processes it through AI service, and saves it
  Future<bool> addReading({
    required String uid,
    required double rawTurbidity,
    required double ph,
    required double temperature,
    required String lightCondition,
    required String waterCategory,
    required String waterLevel,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Run AI/ML corrections
      final trueTurbidity = AIService.calculateTrueTurbidity(rawTurbidity, lightCondition, temperature);
      final wqi = AIService.calculateWQI(ph, trueTurbidity, temperature);
      final status = AIService.determineSafetyStatus(ph, trueTurbidity, wqi);
      final advice = AIService.generateAdvisoryAdvice(ph, trueTurbidity, temperature, status);

      // 2. Build model
      final newLog = WaterLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        rawTurbidity: rawTurbidity,
        trueTurbidity: trueTurbidity,
        ph: ph,
        temperature: temperature,
        lightCondition: lightCondition,
        wqi: wqi,
        status: status,
        advice: advice,
        waterCategory: waterCategory,
        waterLevel: waterLevel,
        timestamp: DateTime.now(),
      );

      // 3. Save to database (Local or Cloud Firestore)
      await _databaseService.saveWaterLog(uid, newLog);

      // 4. Update memory list (put new reading first)
      _logs.insert(0, newLog);
      _evaluateActiveAlerts();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes a water log entry
  Future<bool> deleteLog(String uid, String logId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _databaseService.deleteWaterLog(uid, logId);
      _logs.removeWhere((log) => log.id == logId);
      _evaluateActiveAlerts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Triggers local cache uploads to Firestore and refreshes logs list
  Future<void> syncOfflineLogs(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _databaseService.syncLocalLogsToCloud(uid);
      await fetchLogs(uid);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear logs from provider memory
  void clearLogs() {
    _logs.clear();
    _activeAlerts.clear();
    notifyListeners();
  }
}
