import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
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
        title: const Text('Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: () {
                  HapticService.selection();
                  ref.read(notificationsProvider.notifier).markAllRead();
                },
                child: Text(
                  'Mark all read ($unreadCount)',
                  style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold, fontSize: 12),
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
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.paper2,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none, size: 28, color: AppColors.ink3),
                    ),
                    const SizedBox(height: 14),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0x2015130F)),
              itemBuilder: (context, i) {
                final n = notifications[i];
                final placeId = n.placeId;
                final isUnread = n.unread;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: isUnread ? AppColors.butter.withValues(alpha: 0.28) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isUnread ? AppColors.orange : AppColors.butter,
                        border: Border.all(color: AppColors.ink, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        n.actorInitials,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isUnread ? Colors.white : AppColors.ink,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
                        children: [
                          TextSpan(text: '${n.actorName} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: n.message, style: const TextStyle(color: AppColors.ink2)),
                        ],
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(n.timeAgo, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (placeId != null || n.actorId.isNotEmpty)
                          const Icon(Icons.chevron_right, size: 18, color: AppColors.ink3),
                      ],
                    ),
                    onTap: () {
                      HapticService.light();
                      ref.read(notificationsProvider.notifier).markAsRead(n.id);
                      if (placeId != null && placeId.isNotEmpty) {
                        context.push('/places/$placeId');
                      } else if (n.actorId.isNotEmpty && n.actorId != 'you') {
                        context.push('/users/${n.actorId}');
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
