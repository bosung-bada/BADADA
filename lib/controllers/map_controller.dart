import 'dart:async';

import '../models/sos_event.dart';
import '../services/sos_listener_service.dart' as sos_listener;

class BadadaMapController {
  StreamSubscription<List<SosEvent>>? _sosSubscription;
  final Set<String> _shownSosIds = {};

  void startSosListener({
    required void Function(SosEvent sos) onSosReceived,
  }) {
    _sosSubscription?.cancel();

    _sosSubscription =
        sos_listener.SosListenerService.watchTeamSosEvents().listen((events) {
      for (final sos in events) {
        if (_shownSosIds.contains(sos.uid)) continue;

        _shownSosIds.add(sos.uid);
        onSosReceived(sos);
      }
    });
  }

  void dispose() {
    _sosSubscription?.cancel();
  }
}