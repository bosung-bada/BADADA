import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/sos_event.dart';
import 'selected_team_service.dart';

class SosListenerService {
  static final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: FirebaseAuth.instance.app,
    databaseURL: 'https://badada-efbb5-default-rtdb.firebaseio.com/',
  );

  static final DatabaseReference _db = _database.ref();

  static Stream<List<SosEvent>> watchTeamSosEvents() async* {
    final teamId = await SelectedTeamService.getSelectedTeamId();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (teamId == null || currentUid == null) {
      yield <SosEvent>[];
      return;
    }

    yield* _db.child('teams/$teamId/sos').onValue.map((event) {
      final data = event.snapshot.value;

      if (data == null) {
        return <SosEvent>[];
      }

      final map = data as Map<dynamic, dynamic>;

      return map.entries
          .map((entry) {
            return SosEvent.fromMap(
              entry.key.toString(),
              entry.value as Map<dynamic, dynamic>,
            );
          })
          .where((sos) => sos.uid != currentUid)
          .where((sos) => sos.status == 'active')
          .toList();
    });
  }
}