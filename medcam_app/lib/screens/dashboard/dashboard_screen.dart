import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medcam_app/core/constants.dart';
import 'package:medcam_app/models/medicine.dart';
import 'package:medcam_app/providers/search_provider.dart';
import 'package:medcam_app/screens/result/result_sheet.dart';
import 'package:medcam_app/theme/app_theme.dart';
import 'package:medcam_app/widgets/drug_card.dart';
import 'package:medcam_app/widgets/loading_skeleton.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ResultSheet(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);

    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'search drugs or composition...',
              prefixIcon: const Icon(Icons.search, color: AppColors.inkFaint, size: 20),
              suffixIcon: state.query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: AppColors.inkFaint, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchProvider.notifier).clear();
                      },
                    )
                  : null,
            ),
          ),
        ),

        // Results area
        Expanded(
          child: _buildContent(state),
        ),
      ],
    );
  }

  Widget _buildContent(SearchState state) {
    if (state.isLoading) {
      return const LoadingSkeleton();
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
              const SizedBox(height: 12),
              Text(
                'search failed',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state.error!,
                style: GoogleFonts.ibmPlexMono(fontSize: 10, color: AppColors.inkFaint),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.read(searchProvider.notifier).search(state.query),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.query.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication_outlined, color: AppColors.amberDim, size: 48),
            const SizedBox(height: 12),
            Text(
              'search medicines',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'type a drug name, composition, or condition',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11,
                color: AppColors.inkFaint,
              ),
            ),
          ],
        ),
      );
    }

    if (state.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, color: AppColors.inkFaint, size: 48),
              const SizedBox(height: 12),
              Text(
                'no results',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  color: AppColors.inkFaint,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'try a different search term',
                style: GoogleFonts.ibmPlexMono(fontSize: 10, color: AppColors.inkFaint),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
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
}
