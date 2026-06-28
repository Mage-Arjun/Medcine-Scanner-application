import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medcam_app/core/constants.dart';
import 'package:medcam_app/models/medicine.dart';
import 'package:medcam_app/models/history_entry.dart';
import 'package:medcam_app/providers/history_provider.dart';
import 'package:medcam_app/providers/search_provider.dart';
import 'package:medcam_app/providers/tab_provider.dart';
import 'package:medcam_app/screens/result/result_sheet.dart';
import 'package:medcam_app/theme/app_theme.dart';
import 'package:medcam_app/widgets/drug_card.dart';
import 'package:medcam_app/widgets/loading_skeleton.dart';
import 'package:medcam_app/widgets/aurora_background.dart';
import 'package:medcam_app/widgets/glass_card.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: AppLimits.searchDebounceMs),
      () => ref.read(searchProvider.notifier).search(value),
    );
  }

  void _showResult(SearchResult result) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ResultSheet(result: result),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _dateString() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final history = ref.watch(historyProvider);
    final isSearching = state.query.isNotEmpty;

    return AuroraBackground(
      child: Column(
        children: [
          if (!isSearching) _buildHeader(),
          if (!isSearching) _buildQuickScanCard(),
          _buildSearchBar(state),
          Expanded(
            child: isSearching
                ? _buildSearchResults(state)
                : _buildDashboardContent(history),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _dateString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted(brightness),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickScanCard() {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        blur: 16,
        borderRadius: AppRadius.xl,
                    color: AppColors.primary(brightness).withValues(alpha: 0.15),
        borderColor: AppColors.primary(brightness).withValues(alpha: 0.2),
        onTap: () {
          HapticFeedback.mediumImpact();
          ref.read(tabProvider.notifier).goTo(AppTabs.scanner);
        },
        boxShadow: [
          BoxShadow(
            color: AppColors.primary(brightness).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan Medicine',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text(brightness),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Point your camera at any medicine',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted(brightness),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary(brightness).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                color: AppColors.primary(brightness),
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(SearchState state) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm,
      ),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        blur: 12,
        borderRadius: AppRadius.md,
        color: AppColors.glass(brightness),
        borderColor: _isSearchFocused
            ? AppColors.primary(brightness).withValues(alpha: 0.5)
            : AppColors.glassBorderColor(brightness),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: _onSearchChanged,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.text(brightness),
          ),
          decoration: InputDecoration(
            hintText: 'search drugs or composition...',
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.primary(brightness),
              size: 20,
            ),
            suffixIcon: state.query.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                    ),
                    color: AppColors.textFaint(brightness),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchProvider.notifier).clear();
                      _searchFocusNode.unfocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            filled: true,
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(List<HistoryEntry> history) {
    final brightness = Theme.of(context).brightness;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (history.isNotEmpty) ...[
            _buildSectionHeader('Recent Scans', Icons.history_rounded),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: history.length.clamp(0, 8),
                itemBuilder: (context, index) {
                  final entry = history[index];
                  return _recentMedicineCard(entry, brightness);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],

          _buildSectionHeader('Quick Actions', Icons.bolt_rounded),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.camera_alt_rounded,
                    label: 'Scan',
                    color: AppColors.primary(brightness),
                    onTap: () {
                      ref.read(tabProvider.notifier).goTo(AppTabs.scanner);
                    },
                    brightness: brightness,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.search_rounded,
                    label: 'Search',
                    color: AppColors.secondary(brightness),
                    onTap: () {
                      _searchFocusNode.requestFocus();
                    },
                    brightness: brightness,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.history_rounded,
                    label: 'History',
                    color: AppColors.safeGreen,
                    onTap: () {
                      ref.read(tabProvider.notifier).goTo(AppTabs.history);
                    },
                    brightness: brightness,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary(brightness)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }

  Widget _recentMedicineCard(HistoryEntry entry, Brightness brightness) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        final result = SearchResult(
          medicine: entry.medicine,
          genericName: entry.genericName,
          score: 1.0,
          matchType: 'history',
          imageUrl: entry.imageUrl,
        );
        _showResult(result);
      },
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        margin: const EdgeInsets.only(right: AppSpacing.md),
        blur: 12,
        borderRadius: AppRadius.xl,
        color: AppColors.glass(brightness),
        borderColor: AppColors.glassBorderColor(brightness),
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: AppColors.primaryFaint(brightness),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: entry.imageUrl != null && entry.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Image.network(
                          entry.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.medication_rounded,
                            color: AppColors.primary(brightness),
                            size: 20,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.medication_rounded,
                        color: AppColors.primary(brightness),
                        size: 20,
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                entry.medicine,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text(brightness),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                entry.source.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: AppColors.textFaint(brightness),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required Brightness brightness,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        blur: 12,
        borderRadius: AppRadius.xl,
        color: AppColors.glass(brightness),
        borderColor: AppColors.glassBorderColor(brightness),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted(brightness),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(SearchState state) {
    final brightness = Theme.of(context).brightness;
    if (state.isLoading) {
      return const LoadingSkeleton();
    }

    if (state.error != null) {
      return _buildErrorState(state, brightness);
    }

    if (state.results.isEmpty) {
      return _buildEmptyResults(brightness);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.72,
      ),
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        final result = state.results[index];
        return DrugCard(
          result: result,
          onTap: () => _showResult(result),
        );
      },
    );
  }

  Widget _buildErrorState(SearchState state, Brightness brightness) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Search Failed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted(brightness),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            OutlinedButton(
              onPressed: () =>
                  ref.read(searchProvider.notifier).search(state.query),
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyResults(Brightness brightness) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.raised(brightness),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                color: AppColors.textFaint(brightness),
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No Results Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try a different search term',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted(brightness),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
