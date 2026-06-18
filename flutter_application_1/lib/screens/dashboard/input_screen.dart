import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/water_provider.dart';
import '../widgets/app_header.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  String _waterCategory = 'Normal Water'; // Default
  double _ph = 7.0;
  double _temperature = 25.0;
  double _turbidity = 0.0;
  String _waterLevel = 'Medium'; // Low, Medium, Full, Overflow

  bool _isSaving = false;

  final List<String> _categories = ['Mineral Water', 'Normal Water', 'Pond Water', 'Dirty Water'];
  final List<Map<String, dynamic>> _waterLevels = [
    {'label': 'Low', 'color': Colors.orange},
    {'label': 'Medium', 'color': Colors.blue},
    {'label': 'Full', 'color': Colors.green},
    {'label': 'Overflow', 'color': Colors.redAccent},
  ];

  void _submit() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final water = Provider.of<WaterProvider>(context, listen: false);

    if (!auth.isAuthenticated) return;

    setState(() => _isSaving = true);
    
    // Simulate ambient light logic if needed, or default to Normal
    String lightCondition = 'Normal';

    final success = await water.addReading(
      uid: auth.currentUser!.uid,
      rawTurbidity: _turbidity,
      ph: _ph,
      temperature: _temperature,
      lightCondition: lightCondition,
      waterCategory: _waterCategory,
      waterLevel: _waterLevel,
    );
    
    setState(() => _isSaving = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reading saved successfully!'), backgroundColor: Colors.green),
      );
      
      bool isPhSafe = _ph >= 6.5 && _ph <= 8.5;
      bool isTurbiditySafe = _turbidity <= 50;
      
      if (!isPhSafe || !isTurbiditySafe) {
        _showReadingGuidanceDialog(isPhSafe, isTurbiditySafe);
      } else {
        Navigator.pop(context); // Go back to dashboard
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(water.errorMessage ?? 'Failed to save reading.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showReadingGuidanceDialog(bool isPhSafe, bool isTurbiditySafe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String reason = '';
    if (!isPhSafe && !isTurbiditySafe) {
      reason = 'pH (${_ph.toStringAsFixed(1)}) and Turbidity (${_turbidity.toStringAsFixed(0)} NTU) are out of range.';
    } else if (!isPhSafe) {
      reason = 'pH (${_ph.toStringAsFixed(1)}) is out of range; it should be between 6.5 and 8.5.';
    } else {
      reason = 'Turbidity (${_turbidity.toStringAsFixed(0)} NTU) is high; for this type, it should be below 50 NTU.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline, color: Colors.deepOrange, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Reading Guidance',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Attention: Some values for $_waterCategory are outside the optimal range. $reason',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.blueGrey[200] : Colors.blueGrey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A374A) : Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: isDark ? null : Border.all(color: Colors.blue.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECORDED DATA',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.blueGrey[400] : Colors.blueGrey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildGuidanceRow('Water Type:', _waterCategory),
                  const SizedBox(height: 8),
                  _buildGuidanceRow('pH Level:', _ph.toStringAsFixed(1)),
                  const SizedBox(height: 8),
                  _buildGuidanceRow('Turbidity:', '${_turbidity.toStringAsFixed(0)} NTU'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2865FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Go back to dashboard
                },
                child: Text(
                  'Done',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidanceRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.blueGrey[400] : Colors.blueGrey[600]),
        ),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF2885E5);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final formattedDate = DateFormat('E, MMM d, hh:mm a').format(now);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const AppHeader(),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sub-header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                          ),
                          child: const Icon(Icons.chevron_left, color: Color(0xFF2885E5)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Manual Reading',
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                          Text(
                            formattedDate,
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.blueGrey[400]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 1. Water Category Card
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          icon: Icons.water_drop_outlined,
                          iconColor: Colors.blue,
                          title: 'Water Category',
                          subtitle: 'Select the source type for custom thresholds',
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          childAspectRatio: 3.0,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          physics: const NeverScrollableScrollPhysics(),
                          children: _categories.map((category) {
                            final isSelected = _waterCategory == category;
                            return GestureDetector(
                              onTap: () => setState(() => _waterCategory = category),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? (isDark ? const Color(0xFF2885E5).withValues(alpha: 0.2) : Colors.white) 
                                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? primaryColor : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    category,
                                    style: GoogleFonts.inter(
                                      color: isSelected ? primaryColor : (isDark ? Colors.blueGrey[300] : Colors.blueGrey[600]),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  // 2. pH Level Card
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          icon: Icons.science_outlined,
                          iconColor: Colors.purple,
                          title: 'pH Level',
                          subtitle: 'Range 0-14 | Ideal for Normal: 6.5-8.5',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _ph.toStringAsFixed(1),
                                  style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green[700]),
                                ),
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text('pH', style: GoogleFonts.inter(fontSize: 16, color: Colors.blueGrey[400], fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _ph >= 6.5 && _ph <= 8.5 ? 'Neutral' : (_ph < 6.5 ? 'Acidic' : 'Alkaline'),
                                style: GoogleFonts.inter(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 12,
                            activeTrackColor: primaryColor,
                            inactiveTrackColor: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                            thumbColor: Colors.white,
                            overlayColor: primaryColor.withValues(alpha: 0.2),
                            trackShape: const RoundedRectSliderTrackShape(),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 4),
                          ),
                          child: Slider(
                            value: _ph,
                            min: 0.0,
                            max: 14.0,
                            onChanged: (val) => setState(() => _ph = val),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Temperature Card
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          icon: Icons.thermostat_outlined,
                          iconColor: Colors.redAccent,
                          title: 'Temperature',
                          subtitle: 'Celsius | Manual Entry',
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_temperature > 0) setState(() => _temperature--);
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                                ),
                                child: const Icon(Icons.remove, color: Colors.blue, size: 28),
                              ),
                            ),
                            const SizedBox(width: 32),
                            Column(
                              children: [
                                Text(
                                  _temperature.toInt().toString(),
                                  style: GoogleFonts.outfit(fontSize: 56, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFFE54A3B)),
                                ),
                                Text('°C', style: GoogleFonts.inter(fontSize: 18, color: Colors.blueGrey[400], fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(width: 32),
                            GestureDetector(
                              onTap: () {
                                if (_temperature < 100) setState(() => _temperature++);
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                                ),
                                child: const Icon(Icons.add, color: Colors.redAccent, size: 28),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 4. Turbidity Card
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          icon: Icons.visibility_outlined,
                          iconColor: Colors.teal,
                          title: 'Turbidity',
                          subtitle: 'Range 0-1000 NTU | Warning: >50 NTU',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _turbidity.toInt().toString(),
                                  style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green[700]),
                                ),
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text('NTU', style: GoogleFonts.inter(fontSize: 16, color: Colors.blueGrey[400], fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _turbidity <= 50 ? 'Acceptable' : 'Warning',
                                style: GoogleFonts.inter(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 12,
                            activeTrackColor: primaryColor,
                            inactiveTrackColor: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                            thumbColor: Colors.white,
                            overlayColor: primaryColor.withValues(alpha: 0.2),
                            trackShape: const RoundedRectSliderTrackShape(),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 4),
                          ),
                          child: Slider(
                            value: _turbidity,
                            min: 0.0,
                            max: 1000.0,
                            onChanged: (val) => setState(() => _turbidity = val),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 5. Water Level Card
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          icon: Icons.water_outlined,
                          iconColor: Colors.blue,
                          title: 'Water Level',
                          subtitle: 'Current container capacity',
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _waterLevels.map((level) {
                            final String label = level['label'];
                            final Color color = level['color'];
                            final bool isSelected = _waterLevel == label;

                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _waterLevel = label),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? color : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? color : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                                    ),
                                    boxShadow: isSelected ? [
                                      BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                                    ] : [],
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.waves, color: isSelected ? Colors.white : color, size: 24),
                                      const SizedBox(height: 8),
                                      Text(
                                        label,
                                        style: GoogleFonts.inter(
                                          color: isSelected ? Colors.white : color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Save Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Save Reading',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
          ),
          child: child,
        );
      }
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.blueGrey[400]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


