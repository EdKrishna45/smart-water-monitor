import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/water_provider.dart';
import 'screens/auth/landing_screen.dart';
import 'screens/dashboard/home_screen.dart';
import 'screens/dashboard/history_screen.dart';
import 'screens/dashboard/settings_screen.dart';
import 'screens/dashboard/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WaterProvider()),
      ],
      child: const SmartWaterApp(),
    ),
  );
}

class SmartWaterApp extends StatelessWidget {
  const SmartWaterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = authProvider.isDarkMode;

    // Premium harmonious color palettes
    const primaryColor = Color(0xFF0284C7); // Beautiful Water Sky Blue
    const darkBackground = Color(0xFF0F172A); // Slate 900
    const darkSurface = Color(0xFF1E293B); // Slate 800

    return MaterialApp(
      title: 'AquaSense AI',
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      
      // LIGHT THEME CONFIG
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
          primary: primaryColor,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          titleTextStyle: GoogleFonts.outfit(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          labelStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
          prefixIconColor: Colors.grey[500],
          suffixIconColor: Colors.grey[500],
        ),
      ),

      // DARK THEME CONFIG
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
          primary: primaryColor,
          surface: darkSurface,
        ),
        scaffoldBackgroundColor: darkBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: darkBackground,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          labelStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
          prefixIconColor: Colors.grey[400],
          suffixIconColor: Colors.grey[400],
        ),
      ),
      
      home: authProvider.isLoading
          ? const AppSplashScreen()
          : authProvider.isAuthenticated
              ? const MainNavigation()
              : const LandingScreen(),
    );
  }
}

class AppSplashScreen extends StatelessWidget {
  const AppSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0284C7);
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 80,
              color: primaryColor,
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 8,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined, color: isDark ? Colors.grey[450] : Colors.grey[650]),
            selectedIcon: Icon(Icons.grid_view, color: primaryColor),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined, color: isDark ? Colors.grey[450] : Colors.grey[650]),
            selectedIcon: Icon(Icons.history, color: primaryColor),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: isDark ? Colors.grey[450] : Colors.grey[650]),
            selectedIcon: Icon(Icons.settings, color: primaryColor),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: isDark ? Colors.grey[450] : Colors.grey[650]),
            selectedIcon: Icon(Icons.person, color: primaryColor),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}