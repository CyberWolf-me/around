import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {'who': 'Noor Haddad', 'init': 'NH', 'txt': 'dropped Kettle & Loaf', 'when': '2h ago', 'placeId': 'kettle'},
      {'who': 'Teo Vasquez', 'init': 'TV', 'txt': 'saved your drop at The Fern Room', 'when': '5h ago', 'placeId': 'fern'},
      {'who': 'Mina Osei', 'init': 'MO', 'txt': 'started following you', 'when': '7h ago', 'placeId': null},
      {'who': 'Ari Lindqvist', 'init': 'AL', 'txt': 'added Castellan to your Friday plan', 'when': '1d ago', 'placeId': 'castellan'},
    ];

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0x2015130F)),
        itemBuilder: (context, i) {
          final n = notifications[i];
          final placeId = n['placeId'];

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
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
            onTap: placeId != null
                ? () {
                    HapticService.light();
                    context.push('/places/$placeId');
                  }
                : null,
          );
        },
      ),
    );
  }
}
