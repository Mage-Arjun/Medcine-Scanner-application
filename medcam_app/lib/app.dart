import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medcam_app/screens/dashboard/dashboard_screen.dart';
import 'package:medcam_app/screens/history/history_screen.dart';
import 'package:medcam_app/screens/scanner/scanner_screen.dart';
import 'package:medcam_app/screens/settings/settings_screen.dart';
import 'package:medcam_app/providers/tab_provider.dart';
import 'package:medcam_app/providers/theme_provider.dart';
import 'package:medcam_app/theme/app_theme.dart';
import 'package:medcam_app/widgets/glass_card.dart';

class MedCamApp extends ConsumerStatefulWidget {
  const MedCamApp({super.key});

  @override
  ConsumerState<MedCamApp> createState() => _MedCamAppState();
}

class _MedCamAppState extends ConsumerState<MedCamApp>
    with SingleTickerProviderStateMixin {
  final _screens = const [
    ScannerScreen(),
    DashboardScreen(),
    HistoryScreen(),
  ];

  late AnimationController _navAnimController;
  late Animation<double> _navSlideAnimation;

  @override
  void initState() {
    super.initState();
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _navSlideAnimation = CurvedAnimation(
      parent: _navAnimController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _navAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = ref.watch(themeProvider);
    final currentIndex = ref.watch(tabProvider);

    return MaterialApp(
      title: 'MediCam',
      theme: isDark ? AppTheme.dark : AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (navContext) => Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary(brightness),
                        AppColors.primaryDim(brightness),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'MediCam',
                  style: Theme.of(navContext).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            actions: [
              // Theme toggle
              Container(
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Theme.of(navContext).colorScheme.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: AppColors.borderColor(Theme.of(navContext).brightness),
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: 18,
                  ),
                  color: AppColors.primary(brightness),
                  onPressed: () => ref.read(themeProvider.notifier).toggle(),
                ),
              ),
              // Settings
              Container(
                margin: const EdgeInsets.only(right: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Theme.of(navContext).colorScheme.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: AppColors.borderColor(Theme.of(navContext).brightness),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings_rounded, size: 18),
                  color: AppColors.inkMuted,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(navContext).push(
                      PageRouteBuilder(
                        pageBuilder: (_, _, _) => const SettingsScreen(),
                        transitionsBuilder: (_, animation, _, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: _screens[currentIndex],
          ),
          // ── Floating Capsule Nav Bar ────────────────────────────────────
          bottomNavigationBar: _buildFloatingNav(currentIndex),
        ),
      ),
    );
  }

  Widget _buildFloatingNav(int currentIndex) {
    final brightness = Theme.of(context).brightness;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_navSlideAnimation),
      child: Container(
        padding: EdgeInsets.only(
          left: AppSpacing.xxl,
          right: AppSpacing.xxl,
          top: AppSpacing.sm,
          bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
        ),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          blur: 24,
          borderRadius: AppRadius.pill,
          color: AppColors.glass(brightness),
          borderColor: AppColors.glassBorderColor(brightness),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary(brightness).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                icon: Icons.document_scanner_outlined,
                activeIcon: Icons.document_scanner,
                label: 'Scan',
                index: 0,
                currentIndex: currentIndex,
              ),
              _navItem(
                icon: Icons.search_rounded,
                activeIcon: Icons.search_rounded,
                label: 'Search',
                index: 1,
                currentIndex: currentIndex,
              ),
              _navItem(
                icon: Icons.history_rounded,
                activeIcon: Icons.history_rounded,
                label: 'History',
                index: 2,
                currentIndex: currentIndex,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required int currentIndex,
  }) {
    final brightness = Theme.of(context).brightness;
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(tabProvider.notifier).goTo(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg + 4,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary(brightness).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: isActive ? AppColors.primary(brightness) : AppColors.inkFaint,
            ),
            if (isActive) ...[
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primary(brightness),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
