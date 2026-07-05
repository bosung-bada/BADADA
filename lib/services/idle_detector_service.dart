import 'package:latlong2/latlong.dart';

class IdleDetectorService {
  final Duration idleLimit;
  final double movementThresholdMeters;

  LatLng? _lastMovementPosition;
  DateTime? _lastMovementAt;

  IdleDetectorService({
    this.idleLimit = const Duration(minutes: 10),
    this.movementThresholdMeters = 10,
  });

  void start({
    required LatLng startPosition,
  }) {
    _lastMovementPosition = startPosition;
    _lastMovementAt = DateTime.now();
  }

  void stop() {
    _lastMovementPosition = null;
    _lastMovementAt = null;
  }

  void updatePosition({
    required LatLng currentPosition,
  }) {
    if (_lastMovementPosition == null || _lastMovementAt == null) {
      start(startPosition: currentPosition);
      return;
    }

    final movedDistance = const Distance().as(
      LengthUnit.Meter,
      _lastMovementPosition!,
      currentPosition,
    );

    if (movedDistance >= movementThresholdMeters) {
      _lastMovementPosition = currentPosition;
      _lastMovementAt = DateTime.now();
    }
  }

  bool get isIdleTooLong {
    if (_lastMovementAt == null) return false;

    final idleDuration = DateTime.now().difference(_lastMovementAt!);
    return idleDuration >= idleLimit;
  }

  Duration get idleDuration {
    if (_lastMovementAt == null) return Duration.zero;

    return DateTime.now().difference(_lastMovementAt!);
  }
}