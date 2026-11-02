import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import 'bouncing_widget.dart';

/// Highly tactile, brand-aligned empty and resilience state widget for Around.
/// Provides prominent iconography, explanatory copy, and primary/secondary action CTAs.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? primaryActionText;
  final VoidCallback? onPrimaryActionTap;
  final IconData? primaryActionIcon;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryActionTap;
  final IconData? secondaryActionIcon;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final bool isCompact;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.primaryActionText,
    this.onPrimaryActionTap,
    this.primaryActionIcon,
    this.secondaryActionText,
    this.onSecondaryActionTap,
    this.secondaryActionIcon,
    this.iconBackgroundColor,
    this.iconColor,
    this.isCompact = false,
  });

  /// Factory preset for when a user's friend feed has no drops yet.
  factory EmptyStateWidget.feedEmpty({
    required VoidCallback onInviteFriends,
    required VoidCallback onDiscoverVenues,
  }) {
    return EmptyStateWidget(
      icon: Icons.people_outline_rounded,
      title: 'Your circle is quiet today',
      subtitle: 'Around is built around places friends actually go. Invite your Tashkent circle to see their honest recommendations, or discover local favorites on the map.',
      primaryActionText: 'Invite Friends via Telegram',
      primaryActionIcon: Icons.send_rounded,
      onPrimaryActionTap: onInviteFriends,
      secondaryActionText: 'Explore Tashkent Venues',
      secondaryActionIcon: Icons.explore_rounded,
      onSecondaryActionTap: onDiscoverVenues,
    );
  }

  /// Factory preset for when a user has no saved places or a collection is empty.
  factory EmptyStateWidget.savedEmpty({
    required String filterName,
    required VoidCallback onDiscoverVenues,
  }) {
    final isAll = filterName.toLowerCase() == 'all';
    return EmptyStateWidget(
      icon: Icons.bookmark_outline_rounded,
      title: isAll ? 'No saved gems yet' : 'No places in "$filterName"',
      subtitle: isAll
          ? 'Save your favorite coffee bars, bakeries, and evening spots across Tashkent to build your personal city guide.'
          : 'Save places to "$filterName" to easily find and plan visits with friends.',
      primaryActionText: 'Discover Venues',
      primaryActionIcon: Icons.explore_rounded,
      onPrimaryActionTap: onDiscoverVenues,
    );
  }

  /// Factory preset for network errors or offline resilience.
  factory EmptyStateWidget.error({
    required String message,
    required VoidCallback onRetry,
  }) {
    return EmptyStateWidget(
      icon: Icons.wifi_off_rounded,
      title: 'Connection interrupted',
      subtitle: message.isNotEmpty
          ? message
          : 'Unable to reach the server. Your offline outbox is safe and will sync once connected.',
      primaryActionText: 'Retry Connection',
      primaryActionIcon: Icons.refresh_rounded,
      onPrimaryActionTap: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = isCompact
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 20)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 32);

    final iconSize = isCompact ? 24.0 : 32.0;
    final circleSize = isCompact ? 48.0 : 64.0;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSubtle, width: 1.0),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon badge
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: iconBackgroundColor ?? AppColors.butterSubtle,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: iconSize,
              color: iconColor ?? AppColors.ink,
            ),
          ),
          SizedBox(height: isCompact ? 12 : 16),

          // Title
          Text(
            title,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: isCompact ? 16 : 19,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            subtitle,
            style: GoogleFonts.instrumentSans(
              fontSize: isCompact ? 12 : 13.5,
              color: AppColors.ink2,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isCompact ? 16 : 22),

          // Action Buttons
          if (primaryActionText != null) ...[
            BouncingWidget(
              onTap: onPrimaryActionTap,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 46),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: const [AppColors.shadowTactile],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (primaryActionIcon != null) ...[
                      Icon(primaryActionIcon, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        primaryActionText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.instrumentSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (secondaryActionText != null) ...[
            const SizedBox(height: 10),
            BouncingWidget(
              onTap: onSecondaryActionTap,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (secondaryActionIcon != null) ...[
                      Icon(secondaryActionIcon, size: 15, color: AppColors.ink),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        secondaryActionText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.instrumentSans(
                          color: AppColors.ink,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
