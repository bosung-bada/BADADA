import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';

import 'selected_team_service.dart';
import 'user_profile_service.dart';

class SosService {
  static final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: FirebaseAuth.instance.app,
    databaseURL: 'https://badada-efbb5-default-rtdb.firebaseio.com/',
  );

  static final DatabaseReference _db = _database.ref();

  static Future<void> sendSos({
    required LatLng position,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final teamId = await SelectedTeamService.getSelectedTeamId();
    if (teamId == null) {
      throw Exception('선택된 팀이 없습니다.');
    }

    final nickname = await UserProfileService.getNickname();

    await _db.child('teams/$teamId/sos/${user.uid}').set({
      'uid': user.uid,
      'name': nickname,
      'lat': position.latitude,
      'lng': position.longitude,
      'status': 'active',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}