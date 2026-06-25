import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medcam_app/models/medicine.dart';
import 'package:medcam_app/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultSheet extends StatelessWidget {
  final SearchResult result;

  const ResultSheet({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.bgBase,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Container(
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.borderAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.amberGlow, width: 1),
                            color: AppColors.bgRaised,
                          ),
                          child: result.imageUrl != null && result.imageUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: Image.network(
                                    result.imageUrl!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.medication, color: AppColors.inkFaint),
                                  ),
                                )
                              : const Icon(Icons.medication, color: AppColors.inkFaint),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.medicine,
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 22,
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (result.genericName != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.amberFaint,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      result.genericName!,
                                      style: GoogleFonts.ibmPlexMono(
                                        fontSize: 11,
                                        color: AppColors.amberGlow,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _matchBadge(result.matchType),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(result.score * 100).toStringAsFixed(0)}%',
                                    style: GoogleFonts.ibmPlexMono(
                                      fontSize: 10,
                                      color: AppColors.inkFaint,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(),

                    // Uses
                    _dataSection('USES', result.uses),

                    const SizedBox(height: 16),
                    const Divider(),

                    // Side Effects
                    _dataSection('SIDE EFFECTS', result.sideEffects),

                    const SizedBox(height: 24),

                    // Footer buttons
                    if (result.imageUrl != null && result.imageUrl!.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _launchUrl(result.imageUrl!),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('VIEW ON 1MG'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dataSection(String label, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 10,
            color: AppColors.inkFaint,
            letterSpacing: 0.15,
          ),
        ),
        const SizedBox(height: 6),
        if (value != null && value.isNotEmpty)
          Text(
            value,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 13,
              color: AppColors.inkMuted,
              height: 1.5,
            ),
          )
        else
          Text(
            '—',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 13,
              color: AppColors.inkFaint,
            ),
          ),
      ],
    );
  }

  Widget _matchBadge(String matchType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.amberGlow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        matchType.toUpperCase(),
        style: GoogleFonts.ibmPlexMono(
          fontSize: 9,
          color: AppColors.amberGlow,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
