import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:compass_2/screens/compass_screen.dart';
import 'package:compass_2/screens/qibla_screen.dart';
import 'package:compass_2/screens/trail_screen.dart';
import 'package:compass_2/screens/elevation_screen.dart';
import 'package:compass_2/providers/theme_provider.dart';
import 'package:compass_2/utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();
  final List<String> _tabTitles = ['Compass', 'Qibla', 'Trail', 'Elevation'];
  final List<IconData> _tabIcons = [
    Icons.explore, 
    Icons.mosque, 
    Icons.route,
    Icons.terrain
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                child: Row(
                  children: [
                    Text(
                      _tabTitles[_tabController.index],
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const Spacer(),
                    // Dark mode toggle with animation
                    GestureDetector(
                      onTap: () {
                        themeProvider.toggleTheme();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDarkMode
                              ? AppTheme.darkPrimaryColor.withOpacity(0.2)
                              : AppTheme.primaryColor.withOpacity(0.1),
                        ),
                        child: Icon(
                          isDarkMode ? Icons.light_mode : Icons.dark_mode,
                          color: isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const PageScrollPhysics(), // Enable smooth scrolling
                  onPageChanged: (index) {
                    _tabController.animateTo(index);
                  },
                  children: const [
                    CompassScreen(),
                    QiblaScreen(),
                    TrailScreen(),
                    ElevationScreen(),
                  ],
                ),
              ),
              // Improved tab bar with pill-shaped indicator
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppTheme.darkCardBackground : AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(30), // More rounded for pill shape
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  // Improved indicator with gradient and more rounded corners
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      colors: isDarkMode 
                          ? [Color(0xFF9C89B8), AppTheme.darkPrimaryColor]
                          : [Color(0xFF9C89B8), AppTheme.primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: isDarkMode ? AppTheme.darkBackgroundColor : Colors.white,
                  unselectedLabelColor: isDarkMode ? AppTheme.darkTextLight : AppTheme.textLight,
                  dividerColor: Colors.transparent,
                  splashBorderRadius: BorderRadius.circular(30),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  tabs: List.generate(_tabTitles.length, (index) {
                    return Tab(
                      height: 58,
                      icon: Icon(_tabIcons[index]),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
