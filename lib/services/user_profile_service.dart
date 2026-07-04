import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserProfileService {
  static final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: FirebaseAuth.instance.app,
    databaseURL: 'https://badada-efbb5-default-rtdb.firebaseio.com/',
  );

  static final DatabaseReference _db = _database.ref();

  static String normalizeNickname(String nickname) {
    return nickname.trim().toLowerCase();
  }

  static Future<void> saveProfile({
    required String nickname,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final normalizedNickname = normalizeNickname(nickname);

    await _db.child('users/${user.uid}').set({
      'uid': user.uid,
      'nickname': nickname,
      'normalizedNickname': normalizedNickname,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await _db.child('nicknames/$normalizedNickname').set({
      'uid': user.uid,
      'nickname': nickname,
    });
  }

  static Future<String> getNickname() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '팀원';

    final snapshot = await _db.child('users/${user.uid}/nickname').get();

    if (snapshot.value == null) return '팀원';
    return snapshot.value.toString();
  }

  static Future<String?> findUidByNickname(String nickname) async {
    final normalizedNickname = normalizeNickname(nickname);
    final snapshot = await _db.child('nicknames/$normalizedNickname/uid').get();

    if (snapshot.value == null) return null;
    return snapshot.value.toString();
  }
}