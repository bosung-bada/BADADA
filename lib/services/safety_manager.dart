import 'package:latlong2/latlong.dart';

import 'idle_detector_service.dart';

class SafetyManager {
  final IdleDetectorService idleDetector;

  SafetyManager({
    required this.idleDetector,
  });

  void start({
    required LatLng position,
  }) {
    idleDetector.start(startPosition: position);
  }

  void updatePosition({
    required LatLng position,
  }) {
    idleDetector.updatePosition(currentPosition: position);
  }

  void reset({
    required LatLng position,
  }) {
    idleDetector.start(startPosition: position);
  }

  void stop() {
    idleDetector.stop();
  }

  bool get isUserIdle => idleDetector.isIdleTooLong;

  Duration get idleDuration => idleDetector.idleDuration;
}