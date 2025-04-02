import 'package:flutter/material.dart';
import 'package:compass_2/screens/compass_screen.dart';
import 'package:compass_2/screens/qibla_screen.dart';
import 'package:compass_2/screens/trail_screen.dart';
import 'package:compass_2/screens/elevation_screen.dart';
import 'package:compass_2/utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF7F2FA)],
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
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () {
                        // TODO: Navigate to settings screen
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    CompassScreen(),
                    QiblaScreen(),
                    TrailScreen(),
                    ElevationScreen(),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(28),
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
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: AppTheme.primaryColor,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textLight,
                  dividerColor: Colors.transparent,
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
