import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'who': 'Kamila Rahimova',
      'init': 'KR',
      'txt': 'dropped Breadly Bakery & Café in Mirabad',
      'when': '2h ago',
      'placeId': 'breadly',
      'unread': true,
    },
    {
      'who': 'Bekzod Alimov',
      'init': 'BA',
      'txt': 'saved your drop at B&B Coffee House',
      'when': '4h ago',
      'placeId': 'bnb',
      'unread': true,
    },
    {
      'who': 'Aziza Tursunova',
      'init': 'AT',
      'txt': 'started following you',
      'when': '6h ago',
      'placeId': null,
      'unread': true,
    },
    {
      'who': 'Rustam Mirzaev',
      'init': 'RM',
      'txt': 'added Steam Bar & Lounge to your Friday plan',
      'when': '1d ago',
      'placeId': 'steam',
      'unread': false,
    },
    {
      'who': 'Diyor Usmanov',
      'init': 'DU',
      'txt': 'dropped Tim’s Coffee & Roastery',
      'when': '1d ago',
      'placeId': 'tims',
      'unread': false,
    },
  ];

  void _markAllRead() {
    HapticService.selection();
    setState(() {
      for (final n in _notifications) {
        n['unread'] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['unread'] == true).length;

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
                onPressed: _markAllRead,
                child: Text(
                  'Mark all read ($unreadCount)',
                  style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0x2015130F)),
        itemBuilder: (context, i) {
          final n = _notifications[i];
          final placeId = n['placeId'] as String?;
          final isUnread = n['unread'] == true;

          return Container(
            decoration: BoxDecoration(
              color: isUnread ? AppColors.butter.withValues(alpha: 0.28) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: AppColors.butter,
                child: Text(
                  n['init'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink, fontSize: 11),
                ),
              ),
              title: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
                  children: [
                    TextSpan(text: '${n['who']} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: n['txt'] as String, style: const TextStyle(color: AppColors.ink2)),
                  ],
                ),
              ),
              subtitle: Text(n['when'] as String, style: Theme.of(context).textTheme.labelSmall),
              trailing: placeId != null
                  ? const Icon(Icons.chevron_right, size: 18, color: AppColors.ink3)
                  : null,
              onTap: () {
                HapticService.light();
                setState(() => n['unread'] = false);
                if (placeId != null) {
                  context.push('/places/$placeId');
                }
              },
            ),
          );
        },
      ),
    );
  }
}
