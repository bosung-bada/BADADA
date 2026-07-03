import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';

class LocationShareService {
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  static Future<void> updateMyLocation({
    required LatLng position,
    required bool isTracking,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db.child('teams/test-team/members/${user.uid}').set({
      'name': '보성',
      'lat': position.latitude,
      'lng': position.longitude,
      'isTracking': isTracking,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}