import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:compass_2/screens/compass_screen.dart';
import 'package:compass_2/screens/qibla_screen.dart';
import 'package:compass_2/screens/trail_screen.dart';
import 'package:compass_2/screens/celestial_screen.dart'; // Updated import
import 'package:compass_2/screens/settings_screen.dart';
import 'package:compass_2/providers/theme_provider.dart';
import 'package:compass_2/utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CompassScreen(),
    const QiblaScreen(),
    const CelestialScreen(), // Updated to use the CelestialScreen
    const TrailScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [AppTheme.darkBackgroundColor, Color(0xFF121212)]
                : [Colors.white, Color(0xFFF7F2FA)],
          ),
        ),
        child: SafeArea(
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore),
            label: 'Compass',
          ),
          NavigationDestination(
            icon: Icon(Icons.mosque),
            label: 'Qibla',
          ),
          NavigationDestination(
            icon: Icon(Icons.terrain), // Could use wb_sunny or wb_twilight as alternatives
            label: 'Celestial', // Updated label
          ),
          NavigationDestination(
            icon: Icon(Icons.route),
            label: 'Trail',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
