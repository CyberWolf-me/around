import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/curator_notification_service.dart';
import 'package:around_app/data/repositories/notifications_repository.dart';
import 'package:around_app/data/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late NotificationsNotifier notifier;
  late CuratorNotificationService service;
  late int initialCount;

  setUp(() async {
    await StorageService.init();
    await StorageService.clearAll();
    container = ProviderContainer();
    notifier = container.read(notificationsProvider.notifier);
    service = CuratorNotificationService(notificationsNotifier: notifier);
    initialCount = notifier.state.length;
  });

  tearDown(() async {
    container.dispose();
    await StorageService.clearAll();
  });

  group('P21-04: CuratorNotificationService Unit Tests', () {
    test('streak milestone unlocks notification on 2-week threshold', () async {
      final dispatched = await service.checkAndNotifyStreakMilestone(
        userId: 'curator_alice',
        streakWeeks: 2,
        lang: 'en',
      );

      expect(dispatched, isTrue);
      expect(notifier.state.length, equals(initialCount + 1));
      final notif = notifier.state.first;
      expect(notif.recipientId, equals('curator_alice'));
      expect(notif.kind, equals('trophy'));
      expect(notif.message, contains('2-week Tashkent explorer streak'));
      expect(notif.unread, isTrue);
    });

    test('streak milestone dedupes repeated evaluations for the same milestone', () async {
      final first = await service.checkAndNotifyStreakMilestone(
        userId: 'curator_bob',
        streakWeeks: 4,
        lang: 'en',
      );
      expect(first, isTrue);
      expect(notifier.state.length, equals(initialCount + 1));

      // Re-evaluating the same 4-week milestone must be ignored
      final second = await service.checkAndNotifyStreakMilestone(
        userId: 'curator_bob',
        streakWeeks: 4,
        lang: 'en',
      );
      expect(second, isFalse);
      expect(notifier.state.length, equals(initialCount + 1));
    });

    test('streak milestone ignores streaks under threshold (< 2)', () async {
      final dispatched = await service.checkAndNotifyStreakMilestone(
        userId: 'curator_newbie',
        streakWeeks: 1,
      );
      expect(dispatched, isFalse);
      expect(notifier.state.length, equals(initialCount));
    });

    test('streak milestone localizes correctly for Uzbek and Russian', () async {
      final uzDispatched = await service.checkAndNotifyStreakMilestone(
        userId: 'curator_uz',
        streakWeeks: 8,
        lang: 'uz',
      );
      expect(uzDispatched, isTrue);
      expect(notifier.state.first.message, contains('8 haftalik kashfiyot seriyasini'));

      final ruDispatched = await service.checkAndNotifyStreakMilestone(
        userId: 'curator_ru',
        streakWeeks: 12,
        lang: 'ru',
      );
      expect(ruDispatched, isTrue);
      expect(notifier.state.first.message, contains('12-недельной серии открытий'));
    });

    test('district crown delivers notification with localized copy and dedupes', () async {
      final dispatched = await service.checkAndNotifyDistrictCrown(
        userId: 'curator_crown',
        districtName: 'Yakkasaray',
        lang: 'ru',
      );

      expect(dispatched, isTrue);
      expect(notifier.state.length, equals(initialCount + 1));
      expect(notifier.state.first.message, contains('Корона района! Вы стали главным куратором района Yakkasaray'));

      // Deduplication check
      final second = await service.checkAndNotifyDistrictCrown(
        userId: 'curator_crown',
        districtName: 'Yakkasaray',
        lang: 'ru',
      );
      expect(second, isFalse);
      expect(notifier.state.length, equals(initialCount + 1));
    });

    test('district crown supports Uzbek localization', () async {
      final dispatched = await service.checkAndNotifyDistrictCrown(
        userId: 'curator_crown_uz',
        districtName: 'Chilanzar',
        lang: 'uz',
      );

      expect(dispatched, isTrue);
      expect(notifier.state.first.message, contains('Shahar Choʻqqisi! Siz Chilanzar tumanining yetakchi kuratoriga aylandingiz!'));
    });

    test('trophy unlocked dispatches notification and dedupes', () async {
      final dispatched = await service.checkAndNotifyTrophyUnlocked(
        userId: 'curator_trophy',
        trophyId: 'espresso_master',
        trophyTitle: 'Espresso Master',
        lang: 'en',
      );

      expect(dispatched, isTrue);
      expect(notifier.state.length, equals(initialCount + 1));
      expect(notifier.state.first.message, contains('New Achievement Unlocked: "Espresso Master"'));

      // Deduplication check
      final second = await service.checkAndNotifyTrophyUnlocked(
        userId: 'curator_trophy',
        trophyId: 'espresso_master',
        trophyTitle: 'Espresso Master',
        lang: 'en',
      );
      expect(second, isFalse);
      expect(notifier.state.length, equals(initialCount + 1));
    });
  });
}
