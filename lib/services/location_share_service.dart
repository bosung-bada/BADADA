import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';

import 'user_profile_service.dart';

class LocationShareService {
  static final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: FirebaseAuth.instance.app,
    databaseURL: 'https://badada-efbb5-default-rtdb.firebaseio.com/',
  );

  static final DatabaseReference _db = _database.ref();

  static Future<void> updateMyLocation({
    required LatLng position,
    required bool isTracking,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nickname = await UserProfileService.getNickname();

    await _db.child('teams/test-team/members/${user.uid}').set({
      'name': nickname,
      'lat': position.latitude,
      'lng': position.longitude,
      'isTracking': isTracking,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}