import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../data/models/place_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/services/haptic_service.dart';

class TastePassportCard extends StatelessWidget {
  final ProfileModel profile;
  final List<PlaceModel> topPlaces;
  final int totalDrops;
  final int totalSaved;
  final VoidCallback? onShare;

  const TastePassportCard({
    super.key,
    required this.profile,
    required this.topPlaces,
    required this.totalDrops,
    required this.totalSaved,
    this.onShare,
  });

  String get passportUrl => 'https://around.tashkent.app/passport/${profile.username}';

  void _copyPassportLink(BuildContext context) {
    HapticService.selection();
    Clipboard.setData(ClipboardData(text: passportUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Tashkent Taste Passport link copied: $passportUrl'),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 3),
      ),
    );
    if (onShare != null) onShare!();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [AppColors.shadowCard],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: AppColors.ink,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'TASHKENT TASTE PASSPORT',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceMono(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.paper,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.butter,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.ink, width: 1),
                  ),
                  child: Text(
                    profile.neighborhood.toUpperCase(),
                    style: GoogleFonts.spaceMono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Identity row with stamp
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.orange,
                      child: Text(
                        profile.initials,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName,
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            '@${profile.username} · Local Curator',
                            style: GoogleFonts.instrumentSans(
                              fontSize: 12,
                              color: AppColors.ink2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Visual Seal
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.orange, width: 1.5),
                      ),
                      child: const Icon(Icons.verified, size: 20, color: AppColors.orange),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Stats strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.paper2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _PassportStat(label: 'Curated Drops', value: '$totalDrops'),
                      Container(width: 1, height: 20, color: AppColors.borderHairline),
                      _PassportStat(label: 'Saved Gems', value: '$totalSaved'),
                      Container(width: 1, height: 20, color: AppColors.borderHairline),
                      _PassportStat(label: 'City Reach', value: profile.neighborhood),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Top Recommended Venues
                Text(
                  'TOP CURATED RECOMMENDATIONS',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink3,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                if (topPlaces.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.paper2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Save or drop recommendations to populate your top venues.',
                      style: TextStyle(fontSize: 11, color: AppColors.ink2),
                    ),
                  )
                else
                  ...topPlaces.take(3).map((place) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: AppColors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star, size: 11, color: AppColors.ink),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                place.name,
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              place.district,
                              style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.ink3),
                            ),
                          ],
                        ),
                      )),
                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: BouncingWidget(
                        onTap: () => _copyPassportLink(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.ink, width: 1.5),
                            boxShadow: const [AppColors.shadowTactile],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.share, size: 14, color: AppColors.ink),
                              const SizedBox(width: 6),
                              Text(
                                'Share Taste Passport',
                                style: GoogleFonts.instrumentSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PassportStat extends StatelessWidget {
  final String label;
  final String value;

  const _PassportStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(
              fontSize: 8.5,
              color: AppColors.ink3,
            ),
          ),
        ],
      ),
    );
  }
}
