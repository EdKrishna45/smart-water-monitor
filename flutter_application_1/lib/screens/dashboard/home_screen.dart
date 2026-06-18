import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/water_provider.dart';
import '../widgets/app_header.dart';
import 'input_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final waterProvider = Provider.of<WaterProvider>(context);
    final latest = waterProvider.latestLog;
    final primaryColor = const Color(0xFF2885E5);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const AppHeader(),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Empty State Banner if no readings
                  if (latest == null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Text(
                          'No readings yet. Log your first entry!',
                          style: GoogleFonts.inter(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Latest Readings',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Column of list cards
                  Column(
                    children: [
                      _buildListCard(
                        title: 'pH Level',
                        value: latest != null ? latest.ph.toStringAsFixed(1) : '--',
                        unit: 'pH',
                        icon: Icons.science_outlined,
                        iconColor: Colors.redAccent,
                        iconBgColor: isDark ? Colors.redAccent.withValues(alpha: 0.1) : Colors.red.shade50,
                        status: latest != null && (latest.ph >= 6.5 && latest.ph <= 8.5) ? 'OPTIMAL' : (latest == null ? '--' : 'REVIEW'),
                        statusColor: const Color(0xFF0F9D58),
                        statusBgColor: isDark ? const Color(0xFF0F9D58).withValues(alpha: 0.1) : const Color(0xFFE8F5E9),
                        isDark: isDark,
                      ),
                      _buildListCard(
                        title: 'Temperature',
                        value: latest != null ? latest.temperature.toStringAsFixed(1) : '--',
                        unit: '°C',
                        icon: Icons.thermostat_outlined,
                        iconColor: const Color(0xFF155DB0),
                        iconBgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F5FF),
                        status: latest != null && (latest.temperature >= 20 && latest.temperature <= 30) ? 'STABLE' : (latest == null ? '--' : 'REVIEW'),
                        statusColor: const Color(0xFF78909C),
                        statusBgColor: isDark ? const Color(0xFF78909C).withValues(alpha: 0.1) : const Color(0xFFECEFF1),
                        isDark: isDark,
                      ),
                      _buildListCard(
                        title: 'Turbidity',
                        value: latest != null ? latest.trueTurbidity.toStringAsFixed(0) : '--',
                        unit: 'NTU',
                        icon: Icons.water_drop_outlined,
                        iconColor: Colors.amber.shade700,
                        iconBgColor: isDark ? Colors.amber.withValues(alpha: 0.1) : Colors.amber.shade50,
                        status: latest != null && latest.trueTurbidity < 5 ? 'CLEAR' : (latest == null ? '--' : 'REVIEW'),
                        statusColor: const Color(0xFFF57F17),
                        statusBgColor: isDark ? const Color(0xFFF57F17).withValues(alpha: 0.1) : const Color(0xFFFFFDE7),
                        isDark: isDark,
                      ),
                      _buildListCard(
                        title: 'Water Level',
                        value: latest != null ? latest.waterLevel : '--',
                        unit: '',
                        icon: Icons.local_drink_outlined,
                        iconColor: const Color(0xFF155DB0),
                        iconBgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F5FF),
                        status: latest != null && latest.waterLevel == 'Full' ? 'HEALTHY' : (latest == null ? '--' : 'REVIEW'),
                        statusColor: const Color(0xFF155DB0),
                        statusBgColor: isDark ? const Color(0xFF155DB0).withValues(alpha: 0.1) : const Color(0xFFE3F2FD),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Log New Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      // Navigate to Input Screen modally
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InputScreen()),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Log New Manual Reading',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    'Recent Logs',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildRecentLogs(waterProvider.logs, isDark),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String status,
    required Color statusColor,
    required Color statusBgColor,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          // Title and Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.grey[400] : Colors.blueGrey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.grey[500] : Colors.blueGrey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
          // Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: GoogleFonts.inter(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLogs(List logs, bool isDark) {
    if (logs.isEmpty) {
      return Center(child: Text('No recent logs.', style: GoogleFonts.inter(color: Colors.grey)));
    }
    
    // Take only the last 3 logs for the home screen
    final recentLogs = logs.length > 3 ? logs.sublist(logs.length - 3) : logs;
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentLogs.length,
      itemBuilder: (context, index) {
        final log = recentLogs[recentLogs.length - 1 - index]; // Reverse chronological
        final isDanger = log.status != 'Safe';
        final formattedDate = DateFormat('MMM d, hh:mm a').format(log.timestamp);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDanger 
                ? (isDark ? const Color(0xFF3D1C1C) : const Color(0xFFFFF7F7))
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDanger ? Colors.redAccent.withValues(alpha: 0.3) : (isDark ? const Color(0xFF334155) : Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              if (isDanger) ...[
                const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 24),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$formattedDate · ',
                          style: GoogleFonts.inter(color: Colors.blueGrey[600], fontSize: 13),
                        ),
                        Text(
                          log.waterCategory,
                          style: GoogleFonts.inter(color: const Color(0xFF2885E5), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'pH ${log.ph.toStringAsFixed(1)} · ${log.trueTurbidity.toStringAsFixed(0)} NTU · ${log.temperature.toStringAsFixed(0)}°C',
                      style: GoogleFonts.inter(color: isDark ? Colors.grey[400] : Colors.blueGrey[800], fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (isDanger)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'DANGER',
                    style: GoogleFonts.inter(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
