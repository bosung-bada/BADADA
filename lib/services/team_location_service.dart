import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/team_member_location.dart';
import 'selected_team_service.dart';

class TeamLocationService {
  static final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: FirebaseAuth.instance.app,
    databaseURL: 'https://badada-efbb5-default-rtdb.firebaseio.com/',
  );

  static final DatabaseReference _db = _database.ref();

  static Stream<List<TeamMemberLocation>> watchSelectedTeamLocations() async* {
    final teamId = await SelectedTeamService.getSelectedTeamId();

    if (teamId == null) {
      yield <TeamMemberLocation>[];
      return;
    }

    yield* _db.child('teams/$teamId/locations').onValue.map((event) {
      final data = event.snapshot.value;

      if (data == null) {
        return <TeamMemberLocation>[];
      }

      final map = data as Map<dynamic, dynamic>;

      return map.entries.map((entry) {
        return TeamMemberLocation.fromMap(
          entry.key.toString(),
          entry.value as Map<dynamic, dynamic>,
        );
      }).toList();
    });
  }
}
