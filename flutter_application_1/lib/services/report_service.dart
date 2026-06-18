import '../models/water_log.dart';

class ReportService {
  /// Generates a cleanly formatted CSV string from a list of water logs.
  static String generateCSV(List<WaterLog> logs) {
    StringBuffer buffer = StringBuffer();
    
    // Header
    buffer.writeln(
      'Log ID,Timestamp,pH Level,Temperature (C),Raw Turbidity (NTU),AI Corrected NTU,WQI Score,Safety Status,AI Advisory Advice'
    );

    // Rows
    for (var log in logs) {
      final sanitizedAdvice = log.advice.replaceAll('\n', ' ').replaceAll(',', ';');
      buffer.writeln(
        '"${log.id}",'
        '"${log.timestamp.toIso8601String()}",'
        '${log.ph},'
        '${log.temperature},'
        '${log.rawTurbidity},'
        '${log.trueTurbidity},'
        '${log.wqi},'
        '"${log.status}",'
        '"$sanitizedAdvice"'
      );
    }

    return buffer.toString();
  }

  /// Generates a beautiful official text-based report summary designed to be shareable
  static String generatePrintableTextReport(List<WaterLog> logs, String username) {
    if (logs.isEmpty) return 'No data available to generate report.';

    double avgPh = logs.map((l) => l.ph).reduce((a, b) => a + b) / logs.length;
    double avgTemp = logs.map((l) => l.temperature).reduce((a, b) => a + b) / logs.length;
    double avgNtu = logs.map((l) => l.trueTurbidity).reduce((a, b) => a + b) / logs.length;
    double avgWqi = logs.map((l) => l.wqi).reduce((a, b) => a + b) / logs.length;

    int safeCount = logs.where((l) => l.status == 'Safe').length;
    int warningCount = logs.where((l) => l.status == 'Warning').length;
    int dangerCount = logs.where((l) => l.status == 'Danger').length;

    StringBuffer buffer = StringBuffer();
    buffer.writeln('================================================================');
    buffer.writeln('          WATER QUALITY ANALYSIS CERTIFICATE & REPORT           ');
    buffer.writeln('================================================================');
    buffer.writeln('Generator Profile : $username');
    buffer.writeln('Report Date       : ${DateTime.now().toLocal()}');
    buffer.writeln('Total Log Records : ${logs.length} entries');
    buffer.writeln('================================================================\n');

    buffer.writeln('1. EXECUTIVE SUMMARY (HISTORICAL METRICS)');
    buffer.writeln('----------------------------------------------------------------');
    buffer.writeln('• Average Water Quality Index (WQI) : ${avgWqi.toStringAsFixed(1)} / 100');
    buffer.writeln('• Average pH Value                  : ${avgPh.toStringAsFixed(2)}');
    buffer.writeln('• Average Temperature               : ${avgTemp.toStringAsFixed(1)} °C');
    buffer.writeln('• Average Turbidity (NTU)           : ${avgNtu.toStringAsFixed(2)} NTU');
    buffer.writeln('• Health Classification Distribution:');
    buffer.writeln('    - SAFE (No risk)       : $safeCount logs (${(safeCount/logs.length*100).toStringAsFixed(0)}%)');
    buffer.writeln('    - WARNING (Boil/Filter): $warningCount logs (${(warningCount/logs.length*100).toStringAsFixed(0)}%)');
    buffer.writeln('    - DANGER (Toxic/murky) : $dangerCount logs (${(dangerCount/logs.length*100).toStringAsFixed(0)}%)');
    buffer.writeln('================================================================\n');

    buffer.writeln('2. FULL RECORDS AUDIT LOG');
    buffer.writeln('----------------------------------------------------------------');
    for (int i = 0; i < logs.length; i++) {
      final log = logs[i];
      buffer.writeln(
        '[Entry #${i + 1}] | Time: ${log.timestamp.toLocal().toString().substring(0, 19)}\n'
        '  - Metrics  : pH: ${log.ph} | Temp: ${log.temperature}°C | Raw: ${log.rawTurbidity} NTU | Corrected: ${log.trueTurbidity} NTU\n'
        '  - Score    : WQI: ${log.wqi} | Status: [${log.status.toUpperCase()}]\n'
        '  - AI Advice: ${log.advice}\n'
        '----------------------------------------------------------------'
      );
    }
    buffer.writeln('\n================================================================');
    buffer.writeln('           END OF REPORT - SMART TURBIDITY AI SENSOR            ');
    buffer.writeln('================================================================');

    return buffer.toString();
  }
}
