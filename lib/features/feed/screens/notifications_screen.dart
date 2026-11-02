import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../data/repositories/notifications_repository.dart';
import '../../../data/services/haptic_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = notifications.where((n) => n.unread).length;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Activity',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: BouncingWidget(
                onTap: () {
                  HapticService.selection();
                  ref.read(notificationsProvider.notifier).markAllRead();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.orangeSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Mark all read ($unreadCount)',
                    style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold, fontSize: 11.5),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: AppColors.paper2,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none, size: 28, color: AppColors.ink3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No new activity',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'When friends drop places or invite you to plans in Tashkent, notifications will appear here.',
                      style: GoogleFonts.instrumentSans(fontSize: 12.5, color: AppColors.ink2, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = notifications[i];
                final placeId = n.placeId;
                final isUnread = n.unread;

                return BouncingWidget(
                  onTap: () {
                    HapticService.light();
                    if (isUnread) {
                      ref.read(notificationsProvider.notifier).markAsRead(n.id);
                    }
                    if (placeId != null && placeId.isNotEmpty) {
                      context.push('/places/$placeId');
                    } else if (n.actorId.isNotEmpty) {
                      context.push('/users/${n.actorId}');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUnread ? AppColors.butterSubtle : AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isUnread ? AppColors.butter : AppColors.borderHairline,
                        width: 1,
                      ),
                      boxShadow: const [AppColors.shadowSubtle],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isUnread ? AppColors.orange : AppColors.butter,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            n.actorInitials,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isUnread ? Colors.white : AppColors.ink,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.instrumentSans(fontSize: 13, color: AppColors.ink),
                                  children: [
                                    TextSpan(text: '${n.actorName} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: n.message, style: const TextStyle(color: AppColors.ink2)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.timeAgo,
                                style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.ink3),
                              ),
                            ],
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4, left: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 16, color: AppColors.ink3),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
