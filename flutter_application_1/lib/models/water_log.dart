import 'dart:convert';

class WaterLog {
  final String id;
  final double rawTurbidity;
  final double trueTurbidity;
  final double ph;
  final double temperature;
  final String lightCondition;
  final double wqi;
  final String status; // 'Safe', 'Warning', 'Danger'
  final String advice;
  final String waterCategory; // 'Mineral Water', 'Normal Water', 'Pond Water', 'Dirty Water'
  final String waterLevel; // 'Low', 'Medium', 'Full', 'Overflow'
  final DateTime timestamp;

  WaterLog({
    required this.id,
    required this.rawTurbidity,
    required this.trueTurbidity,
    required this.ph,
    required this.temperature,
    required this.lightCondition,
    required this.wqi,
    required this.status,
    required this.advice,
    required this.waterCategory,
    required this.waterLevel,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rawTurbidity': rawTurbidity,
      'trueTurbidity': trueTurbidity,
      'ph': ph,
      'temperature': temperature,
      'lightCondition': lightCondition,
      'wqi': wqi,
      'status': status,
      'advice': advice,
      'waterCategory': waterCategory,
      'waterLevel': waterLevel,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WaterLog.fromMap(Map<String, dynamic> map) {
    return WaterLog(
      id: map['id'] ?? '',
      rawTurbidity: (map['rawTurbidity'] as num).toDouble(),
      trueTurbidity: (map['trueTurbidity'] as num).toDouble(),
      ph: (map['ph'] as num).toDouble(),
      temperature: (map['temperature'] as num).toDouble(),
      lightCondition: map['lightCondition'] ?? 'Normal',
      wqi: (map['wqi'] as num).toDouble(),
      status: map['status'] ?? 'Safe',
      advice: map['advice'] ?? '',
      waterCategory: map['waterCategory'] ?? 'Normal Water',
      waterLevel: map['waterLevel'] ?? 'Medium',
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  String toJson() => json.encode(toMap());

  factory WaterLog.fromJson(String source) => WaterLog.fromMap(json.decode(source));
}