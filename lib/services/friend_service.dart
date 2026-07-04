import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/friend_request.dart';

class FriendService {
  static final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: FirebaseAuth.instance.app,
    databaseURL: 'https://badada-efbb5-default-rtdb.firebaseio.com/',
  );

  static final DatabaseReference _db = _database.ref();

  static Future<void> sendFriendRequest({
    required String targetUid,
    required String myNickname,
  }) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    if (targetUid == me.uid) {
      throw Exception('본인에게는 친구 요청을 보낼 수 없습니다.');
    }

    await _db.child('friend_requests/$targetUid/${me.uid}').set({
      'nickname': myNickname,
      'status': 'pending',
      'requestedAt': DateTime.now().toIso8601String(),
    });
  }

  static Stream<List<FriendRequest>> watchReceivedRequests() {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return Stream.value([]);

    return _db.child('friend_requests/${me.uid}').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <FriendRequest>[];

      final map = data as Map<dynamic, dynamic>;

      return map.entries.map((entry) {
        return FriendRequest.fromMap(
          entry.key.toString(),
          entry.value as Map<dynamic, dynamic>,
        );
      }).toList();
    });
  }

  static Future<void> acceptFriendRequest({
    required String requesterUid,
  }) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    await _db.child('friends/${me.uid}/$requesterUid').set(true);
    await _db.child('friends/$requesterUid/${me.uid}').set(true);
    await _db.child('friend_requests/${me.uid}/$requesterUid').remove();
  }

  static Future<void> rejectFriendRequest({
    required String requesterUid,
  }) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    await _db.child('friend_requests/${me.uid}/$requesterUid').remove();
  }
}