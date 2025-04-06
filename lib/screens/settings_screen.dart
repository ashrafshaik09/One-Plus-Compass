import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:compass_2/providers/theme_provider.dart';
import 'package:compass_2/utils/app_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  
  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }
  
  Future<void> _loadAppVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      _appVersion = '1.0.0';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: const Text('Dark Mode'),
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (_) => themeProvider.toggleTheme(),
                      activeColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About'),
                    subtitle: Text('Version $_appVersion'),
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.privacy_tip_outlined),
                    title: Text('Privacy Policy'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Center(
              child: Text(
                'Complus © ${DateTime.now().year}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        );
      },
    );
  }
}
