import 'package:flutter/material.dart';
import 'package:medcam_app/models/medicine.dart';
import 'package:medcam_app/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class DrugCard extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;

  const DrugCard({super.key, required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: result.imageUrl != null && result.imageUrl!.isNotEmpty
                    ? Image.network(
                        result.imageUrl!,
                        height: 80,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        color: const Color(0x55FFFFFF),
                        colorBlendMode: BlendMode.srcATop,
                        errorBuilder: (_, __, ___) => _placeholderImage(),
                      )
                    : _placeholderImage(),
              ),
              const SizedBox(height: 8),
              Text(
                result.medicine,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 14,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (result.genericName != null && result.genericName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    result.genericName!,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      color: AppColors.inkMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (result.uses != null && result.uses!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    result.uses!,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      color: AppColors.inkFaint,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgRaised,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.medication, color: AppColors.inkFaint, size: 32),
    );
  }
}
