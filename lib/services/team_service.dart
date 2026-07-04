import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/team_model.dart';

class TeamService {
  static final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: FirebaseAuth.instance.app,
    databaseURL: 'https://badada-efbb5-default-rtdb.firebaseio.com/',
  );

  static final DatabaseReference _db = _database.ref();

  static Future<void> createTeam({
    required String teamName,
    required List<String> memberUids,
  }) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    final teamRef = _db.child('teams').push();
    final teamId = teamRef.key!;

    final allMembers = {me.uid, ...memberUids};

    await teamRef.set({
      'id': teamId,
      'name': teamName,
      'ownerUid': me.uid,
      'createdAt': DateTime.now().toIso8601String(),
      'members': {
        for (final uid in allMembers) uid: true,
      },
    });

    for (final uid in allMembers) {
      await _db.child('user_teams/$uid/$teamId').set(true);
    }
  }

  static Stream<List<TeamModel>> watchMyTeams() {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return Stream.value([]);

    return _db.child('user_teams/${me.uid}').onValue.asyncMap((event) async {
      final data = event.snapshot.value;
      if (data == null) return <TeamModel>[];

      final map = data as Map<dynamic, dynamic>;
      final teams = <TeamModel>[];

      for (final entry in map.entries) {
        final teamId = entry.key.toString();
        final teamSnapshot = await _db.child('teams/$teamId').get();

        if (teamSnapshot.value != null) {
          teams.add(
            TeamModel.fromMap(
              teamId,
              teamSnapshot.value as Map<dynamic, dynamic>,
            ),
          );
        }
      }

      return teams;
    });
  }
}