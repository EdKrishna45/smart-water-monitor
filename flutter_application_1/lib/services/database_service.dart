import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/water_log.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class DatabaseService {
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.121.42.201:8000'; 
    }
    return 'http://127.0.0.1:8000';
  }

  Future<void> saveWaterLog(String uid, WaterLog log) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/logs/$uid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'rawTurbidity': log.rawTurbidity,
        'trueTurbidity': log.trueTurbidity,
        'ph': log.ph,
        'temperature': log.temperature,
        'lightCondition': log.lightCondition,
        'wqi': log.wqi,
        'status': log.status,
        'advice': log.advice,
        'waterCategory': log.waterCategory,
        'waterLevel': log.waterLevel,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Failed to save log');
    }
  }

  Future<List<WaterLog>> fetchWaterLogs(String uid) async {
    final response = await http.get(Uri.parse('$_baseUrl/logs/$uid')).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) {
        return WaterLog(
          id: json['id'],
          rawTurbidity: json['rawTurbidity'].toDouble(),
          trueTurbidity: json['trueTurbidity'].toDouble(),
          ph: json['ph'].toDouble(),
          temperature: json['temperature'].toDouble(),
          lightCondition: json['lightCondition'],
          wqi: json['wqi'].toDouble(),
          status: json['status'],
          advice: json['advice'],
          waterCategory: json['waterCategory'],
          waterLevel: json['waterLevel'],
          timestamp: DateTime.parse(json['timestamp']),
        );
      }).toList();
    } else {
      throw Exception('Failed to fetch logs');
    }
  }

  Future<void> deleteWaterLog(String uid, String logId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/logs/$uid/$logId')).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete log');
    }
  }

  Future<void> syncLocalLogsToCloud(String uid) async {
    // No-op for custom backend as we removed local queue
  }
}
