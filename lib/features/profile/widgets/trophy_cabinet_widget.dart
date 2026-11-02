import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';

enum TrophyCategory { all, crowns, streaks, quests }

class TrophyItem {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String icon;
  final TrophyCategory category;
  final bool isUnlocked;
  final double progress; // 0.0 to 1.0
  final String progressLabel;
  final String? unlockedDate;
  final String tier;

  const TrophyItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.category,
    required this.isUnlocked,
    required this.progress,
    required this.progressLabel,
    this.unlockedDate,
    required this.tier,
  });
}

class TrophyCabinetWidget extends StatefulWidget {
  final List<TrophyItem> trophies;
  final String curatorName;

  const TrophyCabinetWidget({
    super.key,
    required this.trophies,
    this.curatorName = 'Curator',
  });

  static List<TrophyItem> createDefaultTrophies({
    required Set<String> visitedPlaceIds,
    required int streakWeeks,
    required List<String> userDropDistricts,
    Set<String>? heldDistrictCrowns,
  }) {
    final crowns = heldDistrictCrowns ?? <String>{};

    final mirabadDrops = userDropDistricts.where((d) => d.toLowerCase().contains('mirabad')).length;
    final mirabadUnlocked = crowns.contains('Mirabad') || mirabadDrops >= 3;
    final centralDrops = userDropDistricts.where((d) => d.toLowerCase().contains('central')).length;
    final centralUnlocked = crowns.contains('Central Tashkent') || centralDrops >= 3;
    final yakkasarayDrops = userDropDistricts.where((d) => d.toLowerCase().contains('yakkasaray')).length;
    final yakkasarayUnlocked = crowns.contains('Yakkasaray') || yakkasarayDrops >= 3;
    final oldCityDrops = userDropDistricts
        .where((d) => d.toLowerCase().contains('shaykhontohur') || d.toLowerCase().contains('chorsu'))
        .length;
    final oldCityUnlocked = crowns.contains('Shaykhontohur') || oldCityDrops >= 3;

    final s2Unlocked = streakWeeks >= 2;
    final s4Unlocked = streakWeeks >= 4;
    final s8Unlocked = streakWeeks >= 8;
    final s12Unlocked = streakWeeks >= 12;

    final coffeeVisited =
        {'breadly', 'tims', 'pie-republic', 'coffee-milk', 'blend-coffee'}.intersection(visitedPlaceIds).length;
    final plovVisited = {'chorsu', 'besh-qozon-plov', 'chorsu-bazaar-domes'}.intersection(visitedPlaceIds).length;
    final nightVisited = {'steam', 'sette', 'hotel-uzbekistan-bar', 'city-21-hilton'}.intersection(visitedPlaceIds).length;
    final parkVisited = {'centralpark', 'bobur-park', 'ecopark-tashkent', 'botanical-garden'}.intersection(visitedPlaceIds).length;

    return [
      TrophyItem(
        id: 'crown_mirabad',
        title: 'Mirabad Legend',
        subtitle: 'District Crown',
        description: 'Earned by becoming the leading curator in Mirabad with verified venue drops.',
        icon: '👑',
        category: TrophyCategory.crowns,
        isUnlocked: mirabadUnlocked,
        progress: (mirabadDrops / 3).clamp(0.0, 1.0),
        progressLabel: mirabadUnlocked ? 'Local Legend' : '$mirabadDrops/3 drops',
        tier: 'Crown',
      ),
      TrophyItem(
        id: 'crown_central',
        title: 'Central Maestro',
        subtitle: 'District Crown',
        description: 'Commanding curator presence across Central Tashkent avenues and plazas.',
        icon: '👑',
        category: TrophyCategory.crowns,
        isUnlocked: centralUnlocked,
        progress: (centralDrops / 3).clamp(0.0, 1.0),
        progressLabel: centralUnlocked ? 'Local Legend' : '$centralDrops/3 drops',
        tier: 'Crown',
      ),
      TrophyItem(
        id: 'crown_yakkasaray',
        title: 'Yakkasaray Icon',
        subtitle: 'District Crown',
        description: 'Celebrated tastemaker across Yakkasaray cozy alleys and craft spots.',
        icon: '👑',
        category: TrophyCategory.crowns,
        isUnlocked: yakkasarayUnlocked,
        progress: (yakkasarayDrops / 3).clamp(0.0, 1.0),
        progressLabel: yakkasarayUnlocked ? 'Local Legend' : '$yakkasarayDrops/3 drops',
        tier: 'Crown',
      ),
      TrophyItem(
        id: 'crown_old_city',
        title: 'Old City Regent',
        subtitle: 'District Crown',
        description: 'Master explorer of Shaykhontohur and historic Chorsu heritage havens.',
        icon: '👑',
        category: TrophyCategory.crowns,
        isUnlocked: oldCityUnlocked,
        progress: (oldCityDrops / 3).clamp(0.0, 1.0),
        progressLabel: oldCityUnlocked ? 'Local Legend' : '$oldCityDrops/3 drops',
        tier: 'Crown',
      ),
      TrophyItem(
        id: 'streak_2wk',
        title: '2-Week Spark',
        subtitle: 'Discovery Streak',
        description: 'Maintained continuous weekly venue discovery drops for 2 consecutive weeks.',
        icon: '🔥',
        category: TrophyCategory.streaks,
        isUnlocked: s2Unlocked,
        progress: (streakWeeks / 2).clamp(0.0, 1.0),
        progressLabel: s2Unlocked ? 'Secured' : '$streakWeeks/2 wks',
        tier: 'Bronze',
      ),
      TrophyItem(
        id: 'streak_4wk',
        title: '4-Week Flame',
        subtitle: 'Discovery Streak',
        description: 'Consistent month-long exploration with weekly drops across Tashkent.',
        icon: '🔥',
        category: TrophyCategory.streaks,
        isUnlocked: s4Unlocked,
        progress: (streakWeeks / 4).clamp(0.0, 1.0),
        progressLabel: s4Unlocked ? 'Secured' : '$streakWeeks/4 wks',
        tier: 'Silver',
      ),
      TrophyItem(
        id: 'streak_8wk',
        title: '8-Week Blaze',
        subtitle: 'Discovery Streak',
        description: 'Two months of unwavering venue curation across the capital.',
        icon: '⚡',
        category: TrophyCategory.streaks,
        isUnlocked: s8Unlocked,
        progress: (streakWeeks / 8).clamp(0.0, 1.0),
        progressLabel: s8Unlocked ? 'Secured' : '$streakWeeks/8 wks',
        tier: 'Gold',
      ),
      TrophyItem(
        id: 'streak_12wk',
        title: '12-Week Legend',
        subtitle: 'Discovery Streak',
        description: 'Three months of continuous discovery. A true city explorer legend.',
        icon: '💎',
        category: TrophyCategory.streaks,
        isUnlocked: s12Unlocked,
        progress: (streakWeeks / 12).clamp(0.0, 1.0),
        progressLabel: s12Unlocked ? 'Secured' : '$streakWeeks/12 wks',
        tier: 'Diamond',
      ),
      TrophyItem(
        id: 'quest_coffee',
        title: 'Mirabad Roastmaster',
        subtitle: 'Specialty Coffee Quest',
        description: 'Visited 3+ artisan roasteries along Shevchenko Street.',
        icon: '☕',
        category: TrophyCategory.quests,
        isUnlocked: coffeeVisited >= 3,
        progress: (coffeeVisited / 3).clamp(0.0, 1.0),
        progressLabel: coffeeVisited >= 3 ? 'Master' : '$coffeeVisited/3 spots',
        tier: 'Medal',
      ),
      TrophyItem(
        id: 'quest_plov',
        title: 'Master Oshpaz',
        subtitle: 'Old City Plov Quest',
        description: 'Tasted legendary wedding plov from massive bronze kazans.',
        icon: '🥘',
        category: TrophyCategory.quests,
        isUnlocked: plovVisited >= 2,
        progress: (plovVisited / 2).clamp(0.0, 1.0),
        progressLabel: plovVisited >= 2 ? 'Master' : '$plovVisited/2 spots',
        tier: 'Medal',
      ),
      TrophyItem(
        id: 'quest_nocturne',
        title: 'Tashkent Nocturne',
        subtitle: 'Vinyl & Sunset Quest',
        description: 'Experienced evening vinyl sets and craft cocktails.',
        icon: '🍸',
        category: TrophyCategory.quests,
        isUnlocked: nightVisited >= 2,
        progress: (nightVisited / 2).clamp(0.0, 1.0),
        progressLabel: nightVisited >= 2 ? 'Master' : '$nightVisited/2 spots',
        tier: 'Medal',
      ),
      TrophyItem(
        id: 'quest_green',
        title: 'Green City Walker',
        subtitle: 'Emerald Promenade Quest',
        description: 'Strolled shaded sycamore and lake gardens across Tashkent.',
        icon: '🌿',
        category: TrophyCategory.quests,
        isUnlocked: parkVisited >= 2,
        progress: (parkVisited / 2).clamp(0.0, 1.0),
        progressLabel: parkVisited >= 2 ? 'Master' : '$parkVisited/2 spots',
        tier: 'Medal',
      ),
    ];
  }

  @override
  State<TrophyCabinetWidget> createState() => _TrophyCabinetWidgetState();
}

class _TrophyCabinetWidgetState extends State<TrophyCabinetWidget> {
  TrophyCategory _selectedCategory = TrophyCategory.all;

  List<TrophyItem> get _filteredTrophies {
    if (_selectedCategory == TrophyCategory.all) {
      return widget.trophies;
    }
    return widget.trophies.where((t) => t.category == _selectedCategory).toList();
  }

  int get _unlockedCount => widget.trophies.where((t) => t.isUnlocked).length;

  void _showTrophyDetails(BuildContext context, TrophyItem trophy) {
    HapticService.selection();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.inkLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: trophy.isUnlocked ? AppColors.orangeSubtle : AppColors.paper2,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: trophy.isUnlocked ? AppColors.orange : AppColors.borderSubtle,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    trophy.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  trophy.title,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  trophy.subtitle.toUpperCase(),
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: trophy.isUnlocked ? AppColors.orange : AppColors.ink3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  trophy.description,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 14,
                    color: AppColors.ink2,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: trophy.isUnlocked ? AppColors.mintSubtle : AppColors.paper2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: trophy.isUnlocked ? AppColors.mint.withValues(alpha: 0.3) : AppColors.borderSubtle,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trophy.isUnlocked ? Icons.verified : Icons.lock_outline,
                        size: 16,
                        color: trophy.isUnlocked ? AppColors.mint : AppColors.ink3,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        trophy.isUnlocked
                            ? (trophy.unlockedDate != null
                                ? 'Unlocked: ${trophy.unlockedDate}'
                                : 'Unlocked — Achievement Completed')
                            : 'Progress: ${trophy.progressLabel}',
                        style: GoogleFonts.spaceMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: trophy.isUnlocked ? AppColors.mint : AppColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(modalContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.paper,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTrophies;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TROPHY CABINET',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.orange,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orangeSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_unlockedCount / ${widget.trophies.length} Earned',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Achievements & Accolades',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', TrophyCategory.all),
                const SizedBox(width: 8),
                _buildFilterChip('Crowns', TrophyCategory.crowns),
                const SizedBox(width: 8),
                _buildFilterChip('Streaks', TrophyCategory.streaks),
                const SizedBox(width: 8),
                _buildFilterChip('Quests', TrophyCategory.quests),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No trophies in this category yet',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 13,
                    color: AppColors.ink3,
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                final trophy = filtered[index];
                return _buildTrophyCard(context, trophy);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TrophyCategory category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        setState(() {
          _selectedCategory = category;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : AppColors.paper2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.ink : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.paper : AppColors.ink2,
          ),
        ),
      ),
    );
  }

  Widget _buildTrophyCard(BuildContext context, TrophyItem trophy) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showTrophyDetails(context, trophy),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: trophy.isUnlocked ? AppColors.paper : AppColors.paper.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: trophy.isUnlocked
                  ? AppColors.orange.withValues(alpha: 0.3)
                  : AppColors.borderHairline,
              width: trophy.isUnlocked ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: trophy.isUnlocked ? AppColors.orangeSubtle : AppColors.paper2,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      trophy.icon,
                      style: TextStyle(
                        fontSize: 18,
                        color: trophy.isUnlocked ? null : AppColors.ink3,
                      ),
                    ),
                  ),
                  if (trophy.isUnlocked)
                    const Icon(Icons.check_circle, size: 16, color: AppColors.orange)
                  else
                    const Icon(Icons.lock_outline, size: 14, color: AppColors.inkLight),
                ],
              ),
              const SizedBox(height: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trophy.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: trophy.isUnlocked ? AppColors.ink : AppColors.ink3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (trophy.isUnlocked)
                    Text(
                      trophy.tier.toUpperCase(),
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange,
                        letterSpacing: 0.5,
                      ),
                    )
                  else ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: trophy.progress,
                        minHeight: 3,
                        backgroundColor: AppColors.borderSubtle,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ink3),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trophy.progressLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceMono(
                        fontSize: 8,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
