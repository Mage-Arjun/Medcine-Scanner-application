import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medcam_app/screens/dashboard/dashboard_screen.dart';
import 'package:medcam_app/screens/history/history_screen.dart';
import 'package:medcam_app/screens/scanner/scanner_screen.dart';
import 'package:medcam_app/screens/settings/settings_screen.dart';
import 'package:medcam_app/theme/app_theme.dart';

class MedCamApp extends ConsumerStatefulWidget {
  const MedCamApp({super.key});

  @override
  ConsumerState<MedCamApp> createState() => _MedCamAppState();
}

class _MedCamAppState extends ConsumerState<MedCamApp> {
  int _currentIndex = 0;

  final _screens = const [
    ScannerScreen(),
    DashboardScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedCam',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (navContext) => Scaffold(
          appBar: AppBar(
            title: const Text('medscan'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 20),
                onPressed: () {
                  Navigator.of(navContext).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner_outlined),
                activeIcon: Icon(Icons.qr_code_scanner),
                label: 'SCANNER',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'DASHBOARD',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'HISTORY',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
