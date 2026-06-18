import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../widgets/app_header.dart';
import 'input_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
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
                  Text(
                    'Settings',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Appearance
                  _buildSectionTitle('APPEARANCE'),
                  _buildCard(
                    children: [
                      _buildSettingTile(
                        icon: Icons.light_mode_outlined,
                        iconColor: Colors.blue,
                        title: 'Dark Mode',
                        subtitle: 'Reduce glare and save battery',
                        trailing: Switch(
                          value: authProvider.isDarkMode,
                          onChanged: (val) => authProvider.toggleTheme(val),
                          activeThumbColor: primaryColor,
                        ),
                        isLast: true,
                        isDark: isDark,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Preferences
                  _buildSectionTitle('PREFERENCES'),
                  _buildCard(
                    children: [
                      _buildSettingTile(
                        icon: Icons.notifications_outlined,
                        iconColor: Colors.deepOrange,
                        title: 'Notifications',
                        subtitle: 'Manage alerts and sounds',
                        isLast: false,
                        isDark: isDark,
                        onTap: () => _showNotificationsDialog(context, isDark),
                      ),
                      _buildSettingTile(
                        icon: Icons.language_outlined,
                        iconColor: Colors.green,
                        title: 'Language',
                        subtitle: 'English (US)',
                        isLast: true,
                        isDark: isDark,
                        onTap: () => _showLanguageDialog(context, isDark),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Support
                  _buildSectionTitle('SUPPORT'),
                  _buildCard(
                    children: [
                      _buildSettingTile(
                        icon: Icons.help_outline_rounded,
                        iconColor: Colors.indigo,
                        title: 'Help Center',
                        isLast: false,
                        isDark: isDark,
                        onTap: () => _showHelpCenter(context, isDark),
                      ),
                      _buildSettingTile(
                        icon: Icons.security_outlined,
                        iconColor: Colors.teal,
                        title: 'Privacy Policy',
                        isLast: true,
                        isDark: isDark,
                        onTap: () => _showPrivacyPolicy(context, isDark),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  Center(
                    child: Text(
                      'AQUASENSE V2.1.0',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[300],
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InputScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[400],
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155)
                  : Colors.blueGrey.withValues(alpha: 0.1),
            ),
          ),
          child: Column(children: children),
        );
      },
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    required bool isLast,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.blueGrey[400],
                  ),
                )
              : null,
          trailing:
              trailing ??
              Icon(
                Icons.chevron_right,
                color: isDark ? const Color(0xFF334155) : Colors.grey[300],
              ),
          onTap: onTap ?? (trailing == null ? () {} : null),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF334155) : Colors.grey[100],
            indent: 64,
            endIndent: 16,
          ),
      ],
    );
  }

  void _showPrivacyPolicy(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            "Welcome to AquaSense.\n\n"
            "Data Collection:\n"
            "We collect water quality readings (pH, Temperature, Turbidity) from your IoT sensors to provide real-time analytics. "
            "We also store your basic profile information.\n\n"
            "Data Usage:\n"
            "Your data is used exclusively to evaluate water purity and generate AI-driven expert suggestions. "
            "We do not sell your personal data to third parties.\n\n"
            "Security:\n"
            "We use industry-standard encryption to protect your data during transmission and storage. "
            "You can request deletion of your data at any time via the profile settings.\n\n"
            "By using AquaSense, you agree to these terms.",
            style: GoogleFonts.inter(
              color: isDark ? Colors.grey[300] : Colors.blueGrey[700],
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.inter(
                color: const Color(0xFF2885E5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpCenter(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: Colors.indigo),
            const SizedBox(width: 8),
            Text(
              'Help Center',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "How AquaSense Helps You:",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                Icons.sensors,
                "IoT Integration",
                "Automatically syncs with your smart water sensors to pull real-time data.",
                isDark,
              ),
              _buildHelpItem(
                Icons.analytics,
                "Instant Analytics",
                "Analyzes your pH, Temperature, and Turbidity levels to determine safety.",
                isDark,
              ),
              _buildHelpItem(
                Icons.auto_awesome,
                "AI Suggestions",
                "Provides actionable advice on how to treat or manage your water quality.",
                isDark,
              ),
              _buildHelpItem(
                Icons.history,
                "History Tracking",
                "Maintains a full log of your water samples for long-term monitoring.",
                isDark,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.inter(
                color: const Color(0xFF2885E5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String desc, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2885E5), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[200] : Colors.blueGrey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.blueGrey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Select Language',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'English (US)',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text(
                'Spanish',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.grey[400] : Colors.blueGrey[400],
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text(
                'French',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.grey[400] : Colors.blueGrey[400],
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context, bool isDark) {
    bool pushEnabled = true;
    bool emailEnabled = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Notification Alerts',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text(
                    'Push Notifications',
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Get alerts for critical water levels',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                  ),
                  value: pushEnabled,
                  activeThumbColor: const Color(0xFF2885E5),
                  onChanged: (val) {
                    setState(() => pushEnabled = val);
                  },
                ),
                SwitchListTile(
                  title: Text(
                    'Email Summaries',
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Weekly reports of your logs',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                  ),
                  value: emailEnabled,
                  activeThumbColor: const Color(0xFF2885E5),
                  onChanged: (val) {
                    setState(() => emailEnabled = val);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                color: const Color(0xFF2885E5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
