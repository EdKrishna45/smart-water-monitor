import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io' as io;
import '../../providers/water_provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/app_header.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedTab = 0; // 0 for Trends, 1 for Records
  int _selectedFilter = 0; // 0: All, 1: Warnings, 2: Critical

  @override
  Widget build(BuildContext context) {
    final waterProvider = Provider.of<WaterProvider>(context);
    final logs = waterProvider.logs;
    final primaryColor = const Color(0xFF2885E5);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int totalLogs = logs.length;
    int alerts = logs.where((l) => l.status != 'Safe').length;
    
    double avgPh = 0;
    double avgTemp = 0;
    if (totalLogs > 0) {
      avgPh = logs.map((l) => l.ph).reduce((a, b) => a + b) / totalLogs;
      avgTemp = logs.map((l) => l.temperature).reduce((a, b) => a + b) / totalLogs;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const AppHeader(),
          
          // Sub-header title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.timeline_outlined, color: primaryColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'History & Analytics',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$totalLogs total recorded logs',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.blueGrey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _downloadReport,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download_rounded, color: primaryColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Export',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stats Bar (Blue banner)
          Container(
            color: const Color(0xFF2061EC),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('TOTAL LOGS', totalLogs.toString()),
                _buildStatItem('ALERTS', alerts.toString()),
                _buildStatItem('AVG PH', totalLogs > 0 ? avgPh.toStringAsFixed(1) : '--'),
                _buildStatItem('AVG °C', totalLogs > 0 ? avgTemp.toStringAsFixed(1) : '--'),
              ],
            ),
          ),

          // Tabs
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    title: 'Trends',
                    icon: Icons.show_chart,
                    isSelected: _selectedTab == 0,
                    isDark: isDark,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTabButton(
                    title: 'Records',
                    icon: Icons.list_alt,
                    isSelected: _selectedTab == 1,
                    isDark: isDark,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _selectedTab == 0 
                  ? _buildTrendsTab(logs, isDark)
                  : _buildRecordsTab(logs, isDark),
            ),
          ),
        ],
      ),
    );
  }

  void _downloadReport() async {
    final waterProvider = Provider.of<WaterProvider>(context, listen: false);
    final logs = waterProvider.logs;

    if (logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No records to download.', style: GoogleFonts.inter())),
      );
      return;
    }

    // Prepare CSV data
    List<List<dynamic>> csvData = [
      ['Date', 'Time', 'pH Level', 'Turbidity (NTU)', 'Status', 'Water Category'],
      ...logs.map((log) => [
            DateFormat('yyyy-MM-dd').format(log.timestamp),
            DateFormat('HH:mm:ss').format(log.timestamp),
            log.ph.toStringAsFixed(2),
            log.trueTurbidity.toStringAsFixed(2),
            log.status,
            log.waterCategory,
          ]),
    ];

    String csvString = Csv().encode(csvData);
    final fileName = 'AquaSense_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

    if (kIsWeb) {
      final bytes = utf8.encode(csvString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Report downloaded as CSV.', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      try {
        String path;
        if (io.Platform.isAndroid) {
          path = '/storage/emulated/0/Download/$fileName';
        } else {
          final directory = await getApplicationDocumentsDirectory();
          path = '${directory.path}/$fileName';
        }
        
        final file = io.File(path);
        await file.writeAsString(csvString);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Downloaded directly to Downloads folder!', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold))),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download file: $e', style: GoogleFonts.inter(color: Colors.white))),
        );
      }
    }
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2865FF) : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? null : Border.all(color: isDark ? const Color(0xFF334155) : Colors.blue.withValues(alpha: 0.1)),
          boxShadow: isSelected ? [
            BoxShadow(color: const Color(0xFF2865FF).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
          ] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF2885E5), size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : const Color(0xFF2885E5)),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsTab(List logs, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPhChartCard(logs, isDark),
        const SizedBox(height: 16),
        _buildTurbidityChartCard(logs, isDark),
        const SizedBox(height: 32),
      ],
    );
  }

  Color _getPhColor(double ph) {
    if (ph >= 6.5 && ph <= 8.5) return Colors.green;
    if ((ph >= 5.5 && ph < 6.5) || (ph > 8.5 && ph <= 9.5)) return Colors.orange;
    return Colors.redAccent;
  }

  Color _getTurbidityColor(double turbidity) {
    if (turbidity <= 50.0) return Colors.green; // Acceptable
    if (turbidity <= 150.0) return Colors.orange; // Warning
    return Colors.redAccent; // Danger
  }

  Widget _buildPhChartCard(List logs, bool isDark) {
    if (logs.isEmpty) {
      return _buildEmptyChartCard('pH Levels', 'Last entries', isDark);
    }
    
    // Take up to 7 last entries
    final recentLogs = logs.length > 7 ? logs.sublist(logs.length - 7) : logs;
    
    // Fix Y-axis padding
    double minVal = recentLogs.map((e) => e.ph).reduce((a, b) => a < b ? a : b);
    double maxVal = recentLogs.map((e) => e.ph).reduce((a, b) => a > b ? a : b);
    if (minVal == maxVal) {
      minVal -= 1;
      maxVal += 1;
    }

    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.blueGrey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('pH Levels', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
          Text('Last ${recentLogs.length} entries', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal > 14 ? 14 : maxVal + 1,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: isDark ? const Color(0xFF334155) : Colors.white,
                    tooltipBorder: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade300),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        rod.toY.toStringAsFixed(1),
                        GoogleFonts.inter(
                          color: rod.color,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value % 2 != 0 && value != 0) return const Text('');
                        return Text(value.toStringAsFixed(0), style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < recentLogs.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(DateFormat('MMM d').format(recentLogs[index].timestamp), style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(recentLogs.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: recentLogs[i].ph,
                        color: _getPhColor(recentLogs[i].ph),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxVal > 14 ? 14 : maxVal + 1,
                          color: isDark ? const Color(0xFF2A374A) : Colors.grey.shade100,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurbidityChartCard(List logs, bool isDark) {
    if (logs.isEmpty) {
      return _buildEmptyChartCard('Turbidity (NTU)', 'Purity index over time', isDark);
    }
    
    // Take up to 7 last entries
    final recentLogs = logs.length > 7 ? logs.sublist(logs.length - 7) : logs;
    
    // Fix Y-axis padding
    double maxVal = recentLogs.map((e) => e.trueTurbidity).reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 1;

    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.blueGrey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Turbidity (NTU)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
          Text('Purity index over time', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal + (maxVal * 0.2), // Add 20% headroom
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: isDark ? const Color(0xFF334155) : Colors.white,
                    tooltipBorder: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade300),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        rod.toY.toStringAsFixed(0),
                        GoogleFonts.inter(
                          color: rod.color,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value % 2 != 0 && value != 0) return const Text('');
                        return Text(value.toStringAsFixed(0), style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < recentLogs.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(DateFormat('MMM d').format(recentLogs[index].timestamp), style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(recentLogs.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: recentLogs[i].trueTurbidity,
                        color: _getTurbidityColor(recentLogs[i].trueTurbidity),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxVal + (maxVal * 0.2),
                          color: isDark ? const Color(0xFF2A374A) : Colors.grey.shade100,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChartCard(String title, String subtitle, bool isDark) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.blueGrey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
          Text(subtitle, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
          Expanded(
            child: Center(
              child: Text('No data available', style: GoogleFonts.inter(color: Colors.blueGrey[300], fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsTab(List logs, bool isDark) {
    List filteredLogs = logs;
    if (_selectedFilter == 1) {
      filteredLogs = logs.where((l) => l.status == 'Warning').toList();
    } else if (_selectedFilter == 2) {
      filteredLogs = logs.where((l) => l.status == 'Danger').toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Chips Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Icon(Icons.filter_alt_outlined, color: Colors.blueGrey[400], size: 20),
              const SizedBox(width: 12),
              _buildFilterChip('All Logs', 0, isDark),
              const SizedBox(width: 8),
              _buildFilterChip('Warnings', 1, isDark),
              const SizedBox(width: 8),
              _buildFilterChip('Critical', 2, isDark),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (filteredLogs.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text('No records available.', style: GoogleFonts.inter(color: Colors.blueGrey[400])),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredLogs.length,
            itemBuilder: (context, index) {
              final log = filteredLogs[filteredLogs.length - 1 - index]; // Reverse chronological
              final isDanger = log.status != 'Safe';
              final formattedDate = DateFormat('MMM d, hh:mm a').format(log.timestamp).toUpperCase();
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2332) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF2A2D3E) : Colors.blueGrey.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [                    // Top Row
                    Row(
                      children: [
                        Icon(isDanger ? Icons.cancel_outlined : Icons.check_circle_outline, 
                             color: isDanger ? Colors.redAccent : Colors.green, size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            formattedDate,
                            style: GoogleFonts.inter(color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[600], fontSize: 11, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2885E5).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            log.waterCategory,
                            style: GoogleFonts.inter(color: const Color(0xFF4A9BFF), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showReportDetailsDialog(context, log, isDark),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.remove_red_eye_outlined, color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[600], size: 14),
                                const SizedBox(width: 4),
                                Text('View', style: GoogleFonts.inter(color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[600], fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final uid = authProvider.currentUser?.uid ?? '';
                            if (uid.isNotEmpty) {
                              final waterProvider = Provider.of<WaterProvider>(context, listen: false);
                              await waterProvider.deleteLog(uid, log.id);
                            }
                          },
                          child: Icon(Icons.delete_outline, color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[600], size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Bottom Row (Stats)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatColumn('PH', log.ph.toStringAsFixed(1), isDanger ? Colors.redAccent : Colors.green, isDark),
                        _buildDivider(isDark),
                        _buildStatColumn('TEMP', '${log.temperature.toStringAsFixed(0)}°', isDanger ? Colors.redAccent : Colors.green, isDark),
                        _buildDivider(isDark),
                        _buildStatColumn('TURB', log.trueTurbidity.toStringAsFixed(0), isDanger ? Colors.redAccent : Colors.green, isDark),
                        _buildDivider(isDark),
                        _buildStatColumn('LEVEL', log.waterLevel, const Color(0xFF4A9BFF), isDark),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int index, bool isDark) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF2865FF) 
              : (isDark ? const Color(0xFF1E293B) : Colors.transparent),
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: isDark ? const Color(0xFF334155) : Colors.blueGrey.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Colors.blueGrey[400],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor, bool isDark) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[500], fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 30,
      width: 1,
      color: isDark ? Colors.blueGrey.withValues(alpha: 0.2) : Colors.grey[200],
    );
  }

  void _showReportDetailsDialog(BuildContext context, dynamic log, bool isDark) {
    final isDanger = log.status != 'Safe';
    final statusColor = isDanger ? Colors.redAccent : Colors.greenAccent;
    final statusText = log.status.toUpperCase();
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B29) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isDark ? null : Border.all(color: Colors.blueGrey.withValues(alpha: 0.1)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                      border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey[200]!)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CHEMICAL REPORT DETAILS', style: GoogleFonts.inter(color: isDark ? Colors.blueGrey[400] : Colors.blueGrey[600], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text('ID: ${log.id}', style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(Icons.close, color: Colors.blueGrey[400]),
                        )
                      ],
                    ),
                  ),
                  // Body
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Purity Status Assessment', style: GoogleFonts.inter(color: isDark ? Colors.blueGrey[200] : Colors.blueGrey[700], fontSize: 14, fontWeight: FontWeight.bold)),
                            Text(statusText, style: GoogleFonts.inter(color: statusColor, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Grid layout (Voltage removed)
                        Row(
                          children: [
                            Expanded(child: _buildDetailCard('PH LEVEL', log.ph.toStringAsFixed(1), isDark)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildDetailCard('TEMPERATURE', '${log.temperature.toStringAsFixed(1)} °C', isDark)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildDetailCard('NTU SCORE', '${log.trueTurbidity.toStringAsFixed(2)} NTU', isDark)),
                            const SizedBox(width: 12),
                            Expanded(child: const SizedBox()), // Empty spacer to keep grid alignment
                          ],
                        ),
                        const SizedBox(height: 20),
                        // AI Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(16),
                            border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.water_drop_outlined, color: Color(0xFF3B82F6), size: 18),
                                  const SizedBox(width: 8),
                                  Text('AI PURITY CLASSIFICATION:', style: GoogleFonts.inter(color: const Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(log.waterCategory, style: GoogleFonts.inter(color: isDark ? Colors.grey[300] : Colors.blueGrey[800], fontSize: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Expert Suggestion
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.green.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.green.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.shield_outlined, color: isDark ? Colors.greenAccent : Colors.green[600], size: 18),
                                  const SizedBox(width: 8),
                                  Text('EXPERT SUGGESTIONS:', style: GoogleFonts.inter(color: isDark ? Colors.greenAccent : Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(log.advice, style: GoogleFonts.inter(color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[800], fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                      border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey[200]!)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              final uid = authProvider.currentUser?.uid ?? '';
                              if (uid.isNotEmpty) {
                                final waterProvider = Provider.of<WaterProvider>(context, listen: false);
                                await waterProvider.deleteLog(uid, log.id);
                              }
                            },
                            child: Text('Delete Sample', style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2865FF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text('Dismiss Report', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailCard(String title, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: isDark ? null : Border.all(color: Colors.blueGrey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(color: isDark ? Colors.blueGrey[400] : Colors.blueGrey[500], fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
