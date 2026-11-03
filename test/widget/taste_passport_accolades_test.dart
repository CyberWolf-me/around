import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/models/profile_model.dart';
import 'package:around_app/data/repositories/profiles_repository.dart';
import 'package:around_app/features/profile/screens/taste_passport_screen.dart';
import 'package:around_app/features/profile/widgets/curator_trophy_cabinet.dart';

class _MockProfileNotifier extends ProfileNotifier {
  final ProfileModel _initial;
  _MockProfileNotifier(this._initial);

  @override
  ProfileModel build() => _initial;
}

void main() {
  group('P32-01: TastePassportScreen Trophy Cabinet Integration Tests', () {
    testWidgets('renders CuratorTrophyCabinet with mastery title and crown pill on personal passport', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const testProfile = ProfileModel(
        id: 'curator-me',
        username: 'kamila_c',
        fullName: 'Kamila Karimova',
        bio: 'Tashkent specialty coffee explorer.',
        neighborhood: 'Mirabad',
        dropsCount: 12,
        friendsCount: 5,
        savedCount: 8,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWith(() => _MockProfileNotifier(testProfile)),
          ],
          child: const MaterialApp(
            home: TastePassportScreen(username: 'you'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify CuratorTrophyCabinet is present
      expect(find.byType(CuratorTrophyCabinet), findsOneWidget);

      // Verify crown counter and mastery title widgets inside cabinet
      expect(find.byKey(const Key('crown_count_text')), findsOneWidget);
      expect(find.byKey(const Key('mastery_title_text')), findsOneWidget);

      // Verify share accolades button exists
      expect(find.byKey(const Key('share_accolades_button')), findsOneWidget);
    });
  });
}
