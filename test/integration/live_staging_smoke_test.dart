// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Two-User Live Staging Smoke Test (Step C)', () async {
    // 1. Parse .env
    final envFile = File('.env');
    expect(envFile.existsSync(), isTrue, reason: '.env file must exist');
    final lines = envFile.readAsLinesSync();
    final env = <String, String>{};
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final eqIdx = trimmed.indexOf('=');
      if (eqIdx > 0) {
        env[trimmed.substring(0, eqIdx).trim()] = trimmed.substring(eqIdx + 1).trim();
      }
    }

    final supabaseUrl = env['SUPABASE_URL'];
    final supabaseAnonKey = env['SUPABASE_ANON_KEY'];

    expect(supabaseUrl, isNotNull);
    expect(supabaseAnonKey, isNotNull);
    expect(supabaseUrl!.startsWith('https://'), isTrue);
    expect(supabaseAnonKey!.startsWith('eyJ'), isTrue);

    print('Connecting to live Supabase staging: $supabaseUrl');

    // Initialize two distinct Supabase clients for Alice and Bob
    final clientA = SupabaseClient(
      supabaseUrl,
      supabaseAnonKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    final clientB = SupabaseClient(
      supabaseUrl,
      supabaseAnonKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final aliceEmail = 'alice_$timestamp@test.uz';
    final bobEmail = 'bob_$timestamp@test.uz';
    const testPassword = 'Password123!Safe';

    print('--- FLOW 1: Sign Up & Profile Creation ---');
    // Sign up Alice
    final resA = await clientA.auth.signUp(
      email: aliceEmail,
      password: testPassword,
      data: {'username': 'alice_$timestamp', 'full_name': 'Alice Wonder'},
    );
    expect(resA.user, isNotNull);
    final aliceId = resA.user!.id;
    print('User A registered: id=$aliceId, email=$aliceEmail');

    // Sign up Bob
    final resB = await clientB.auth.signUp(
      email: bobEmail,
      password: testPassword,
      data: {'username': 'bob_$timestamp', 'full_name': 'Bob Builder'},
    );
    expect(resB.user, isNotNull);
    final bobId = resB.user!.id;
    print('User B registered: id=$bobId, email=$bobEmail');

    // Sign in to establish active authenticated sessions for clientA and clientB
    final loginA = await clientA.auth.signInWithPassword(email: aliceEmail, password: testPassword);
    expect(loginA.session, isNotNull);
    print('User A signed in with session token: auth.uid=${clientA.auth.currentUser!.id}');

    final loginB = await clientB.auth.signInWithPassword(email: bobEmail, password: testPassword);
    expect(loginB.session, isNotNull);
    print('User B signed in with session token: auth.uid=${clientB.auth.currentUser!.id}');

    // Verify profiles exist in public.profiles
    final profileA = await clientA.from('profiles').select().eq('id', aliceId).maybeSingle();
    expect(profileA, isNotNull, reason: 'Profile A must be created by trigger');
    print('Profile A verified: username=${profileA!['username']}, neighborhood=${profileA['neighborhood']}');

    final profileB = await clientB.from('profiles').select().eq('id', bobId).maybeSingle();
    expect(profileB, isNotNull, reason: 'Profile B must be created by trigger');
    print('Profile B verified: username=${profileB!['username']}, neighborhood=${profileB['neighborhood']}');

    print('--- FLOW 2: Mutual Friendship Handshake ---');
    // Alice sends friend request to Bob
    await clientA.from('friendships').insert({
      'user_id': aliceId,
      'friend_id': bobId,
      'status': 'pending',
    });
    print('Alice sent friendship request to Bob (pending)');

    // Verify Bob sees pending incoming request
    final incomingRequests = await clientB.from('friendships').select().eq('friend_id', bobId);
    expect(incomingRequests.any((r) => r['user_id'] == aliceId && r['status'] == 'pending'), isTrue);

    // Bob accepts the friendship request
    await clientB.from('friendships').update({'status': 'accepted'}).eq('user_id', aliceId).eq('friend_id', bobId);
    print('Bob accepted Alice friendship request (status=accepted)');

    // Verify are_friends RPC helper via query
    final checkFriends = await clientA.from('friendships').select().eq('user_id', aliceId).eq('friend_id', bobId).single();
    expect(checkFriends['status'], equals('accepted'));

    print('--- FLOW 3: Places Discovery & Friends-Only Drops ---');
    // Fetch canonical Breadly venue
    final breadly = await clientA.from('places').select().eq('slug', 'breadly-bakery-cafe').single();
    final breadlyId = breadly['id'] as String;
    print('Discovered venue: ${breadly['name']} (id=$breadlyId)');

    // Alice creates a private "friends" drop at Breadly
    final dropNote = 'Best artisan sourdough in Tashkent! Test $timestamp';
    final dropA = await clientA.from('posts').insert({
      'author_id': aliceId,
      'place_id': breadlyId,
      'note': dropNote,
      'audience': 'friends',
      'rating': 5,
      'tags': ['sourdough', 'coffee'],
    }).select().single();
    final postId = dropA['id'] as String;
    print('Alice published friends-only drop at Breadly: id=$postId');

    // Bob calls get_friends_feed RPC
    final bobFeed = await clientB.rpc('get_friends_feed', params: {'page_limit': 10, 'page_offset': 0}) as List;
    final foundAliceDrop = bobFeed.any((item) => item['post_id'] == postId);
    expect(foundAliceDrop, isTrue, reason: 'Bob must receive Alice friends-only drop because they are mutual friends');
    print('Bob successfully received Alice drop in live friends feed!');

    print('--- FLOW 4: Saved Places Shortlists ---');
    // Bob saves Breadly as 'want_to_go'
    await clientB.from('saved_places').insert({
      'user_id': bobId,
      'place_id': breadlyId,
      'status': 'want_to_go',
    });
    final bobSaves = await clientB.from('saved_places').select().eq('user_id', bobId);
    expect(bobSaves.length, equals(1));
    expect(bobSaves.first['status'], equals('want_to_go'));
    print('Bob saved Breadly to shortlist with status: want_to_go');

    // Bob updates status to 'been'
    await clientB.from('saved_places').update({'status': 'been'}).eq('user_id', bobId).eq('place_id', breadlyId);
    final updatedSave = await clientB.from('saved_places').select().eq('user_id', bobId).eq('place_id', breadlyId).single();
    expect(updatedSave['status'], equals('been'));
    print('Bob updated Breadly shortlist status to: been');

    print('--- FLOW 5: Safety, Blocking & Content Isolation ---');
    // Bob blocks Alice
    await clientB.from('blocks').insert({
      'blocker_id': bobId,
      'blocked_id': aliceId,
    });
    print('Bob blocked Alice');

    // Bob calls get_friends_feed RPC again -> Alice drop MUST NOT appear
    final bobFeedAfterBlock = await clientB.rpc('get_friends_feed', params: {'page_limit': 10, 'page_offset': 0}) as List;
    final aliceDropAfterBlock = bobFeedAfterBlock.any((item) => item['post_id'] == postId);
    expect(aliceDropAfterBlock, isFalse, reason: 'Blocked user drops MUST NOT appear in friends feed');
    print('Verified: Alice drop was excluded from Bob feed after blocking');

    // Unblock Alice
    await clientB.from('blocks').delete().eq('blocker_id', bobId).eq('blocked_id', aliceId);
    print('Bob unblocked Alice');

    print('=== ALL 5 TWO-USER SMOKE TEST FLOWS COMPLETED SUCCESSFULLY ON STAGING ===');
  }, timeout: const Timeout(Duration(seconds: 45)));
}
