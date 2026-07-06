import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/map_controller.dart';
import '../models/sos_event.dart';
import '../models/team_member_location.dart';
import '../services/location_share_service.dart';
import '../services/idle_detector_service.dart';
import '../services/safety_manager.dart';
import '../services/sos_service.dart';
import '../services/team_location_service.dart';
import '../widgets/sos_popup.dart';
import '../widgets/safety_check_dialog.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? currentPosition;
  final List<LatLng> trackPoints = [];
  List<TeamMemberLocation> teamMembers = [];

  StreamSubscription<Position>? positionStream;
  StreamSubscription<List<TeamMemberLocation>>? teamSubscription;
  Timer? trackingTimer;
  final BadadaMapController badadaController = BadadaMapController();
  final MapController mapController = MapController();
  SosEvent? activeSos;
  final SafetyManager safetyManager = SafetyManager(
    idleDetector: IdleDetectorService(
      // TODO(BADADA): 베타/출시 전 Duration(minutes: 10)으로 복구.
      idleLimit: const Duration(seconds: 30),
    ),
  );
  bool hasShownIdleWarning = false;
  bool isSafetyDialogOpen = false;

  bool isTracking = false;
  DateTime? startedAt;
  Duration trackingDuration = Duration.zero;
  double totalDistance = 0;

  @override
  void initState() {
    super.initState();
    loadCurrentLocation();

    teamSubscription = TeamLocationService.watchSelectedTeamLocations().listen(
      (members) {
        setState(() {
          teamMembers = members;
        });
      },
    );

    badadaController.startSosListener(
      onSosReceived: handleSosReceived,
    );
  }

  @override
  void dispose() {
    positionStream?.cancel();
    teamSubscription?.cancel();
    trackingTimer?.cancel();
    badadaController.dispose();
    super.dispose();
  }

  Future<bool> checkLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> loadCurrentLocation() async {
    final allowed = await checkLocationPermission();
    if (!allowed) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    if (!mounted) return;

    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> startTracking() async {
    final allowed = await checkLocationPermission();
    if (!allowed) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    final firstPoint = LatLng(position.latitude, position.longitude);

    setState(() {
      isTracking = true;
      startedAt = DateTime.now();
      trackingDuration = Duration.zero;
      totalDistance = 0;
      currentPosition = firstPoint;
      trackPoints
        ..clear()
        ..add(firstPoint);
    });

    await LocationShareService.updateMyLocation(
      position: firstPoint,
      isTracking: true,
    );

    safetyManager.start(
      position: firstPoint,
    );
    hasShownIdleWarning = false;
    isSafetyDialogOpen = false;

    trackingTimer?.cancel();
    trackingTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (startedAt == null || !mounted) return;

      setState(() {
        trackingDuration = DateTime.now().difference(startedAt!);
      });

      if (currentPosition != null) {
        await handleIdleDetected(currentPosition!);
      }
    });

    positionStream?.cancel();
    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
      ),
    ).listen((position) async {
      final point = LatLng(position.latitude, position.longitude);

      safetyManager.updatePosition(
        position: point,
      );

      await handleIdleDetected(point);

      setState(() {
        if (trackPoints.isNotEmpty) {
          totalDistance += const Distance().as(
            LengthUnit.Meter,
            trackPoints.last,
            point,
          );
        }

        currentPosition = point;
        trackPoints.add(point);
      });

      await LocationShareService.updateMyLocation(
        position: point,
        isTracking: true,
      );
    });
  }

  Future<void> stopTracking() async {
    await positionStream?.cancel();
    positionStream = null;
    trackingTimer?.cancel();
    trackingTimer = null;
    safetyManager.stop();
    hasShownIdleWarning = false;
    isSafetyDialogOpen = false;

    if (currentPosition != null) {
      await LocationShareService.updateMyLocation(
        position: currentPosition!,
        isTracking: false,
      );
    }

    final prefs = await SharedPreferences.getInstance();

    final trackJson = trackPoints
        .map((p) => {
              'lat': p.latitude,
              'lng': p.longitude,
            })
        .toList();

    final record = {
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': DateTime.now().toIso8601String(),
      'durationSeconds': trackingDuration.inSeconds,
      'distanceMeters': totalDistance,
      'pointCount': trackPoints.length,
      'track': trackJson,
    };

    final records = prefs.getStringList('harvesting_records') ?? [];
    records.add(jsonEncode(record));

    await prefs.setStringList('harvesting_records', records);

    if (!mounted) return;

    setState(() {
      isTracking = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '저장 완료: ${(totalDistance / 1000).toStringAsFixed(2)}km / 위치 ${trackPoints.length}개',
        ),
      ),
    );
  }

  Future<void> handleIdleDetected(LatLng point) async {
    if (!isTracking) return;
    if (!safetyManager.isUserIdle) return;
    if (hasShownIdleWarning || isSafetyDialogOpen) return;

    hasShownIdleWarning = true;
    isSafetyDialogOpen = true;

    debugPrint('🚨 IDLE DETECTED');

    if (!mounted) return;

    final isSafe = await showSafetyCheckDialog(
      context: context,
      countdownSeconds: 30,
    );

    isSafetyDialogOpen = false;

    if (!mounted) return;

    if (isSafe) {
      safetyManager.reset(position: point);
      hasShownIdleWarning = false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 안전 확인 완료. 무이동 감지를 다시 시작합니다.'),
        ),
      );

      return;
    }

    debugPrint('🚨 AUTO SOS TRIGGER (TEST MODE)');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text('🚨 AUTO SOS TEST MODE - 실제 전송은 비활성화되어 있습니다.'),
      ),
    );
    hasShownIdleWarning = false;
  }

  Future<void> showSosCountdown() async {
    if (currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 위치를 확인할 수 없습니다.')),
      );
      return;
    }

    int count = 3;
    Timer? countdownTimer;
    bool sent = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            countdownTimer ??= Timer.periodic(
              const Duration(seconds: 1),
              (timer) async {
                if (!Navigator.of(dialogContext).canPop()) {
                  timer.cancel();
                  return;
                }

                if (count > 1) {
                  setDialogState(() {
                    count--;
                  });
                  return;
                }

                timer.cancel();
                sent = true;
                Navigator.of(dialogContext).pop();
              },
            );

            return AlertDialog(
              title: const Text('🚨 SOS 전송'),
              content: Text('$count초 후 SOS가 전송됩니다.'),
              actions: [
                TextButton(
                  onPressed: () {
                    countdownTimer?.cancel();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('취소'),
                ),
              ],
            );
          },
        );
      },
    );

    countdownTimer?.cancel();

    if (!sent) return;
    if (currentPosition == null) return;

    try {
      await SosService.sendSos(
        position: currentPosition!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚨 SOS가 팀에 전송되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SOS 전송 실패: $e')),
      );
    }
  }

  Future<void> handleSosReceived(SosEvent sos) async {
    if (!mounted) return;

    await showSosPopup(
      context: context,
      sos: sos,
      onMoveToMap: () {
        final sosPoint = LatLng(sos.lat, sos.lng);

        setState(() {
          activeSos = sos;
        });

        mapController.move(sosPoint, 17);
      },
    );
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  List<Marker> buildMarkers() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final markers = <Marker>[];

    for (final member in teamMembers) {
      if (member.uid == currentUid) continue;

      markers.add(
        Marker(
          point: LatLng(
            member.lat,
            member.lng,
          ),
          width: 120,
          height: 80,
          child: Column(
            children: [
              const Icon(
                Icons.person_pin_circle,
                size: 46,
                color: Colors.blue,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: Colors.white,
                child: Text(
                  member.name.isEmpty ? '팀원' : member.name,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (currentPosition != null) {
      markers.add(
        Marker(
          point: currentPosition!,
          width: 70,
          height: 70,
          child: const Icon(
            Icons.my_location,
            size: 48,
            color: Colors.green,
          ),
        ),
      );
    }

    if (activeSos != null) {
      markers.add(
        Marker(
          point: LatLng(activeSos!.lat, activeSos!.lng),
          width: 130,
          height: 90,
          child: Column(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 54,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: Colors.white,
                child: Text(
                  '🚨 ${activeSos!.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final center = currentPosition ?? LatLng(36.8151, 127.1139);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.badada.app',
              ),
              if (trackPoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: trackPoints,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              MarkerLayer(markers: buildMarkers()),
            ],
          ),
          if (isTracking)
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🟢 해루질 중',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('⏱ 시간: ${formatDuration(trackingDuration)}'),
                      Text(
                        '🚶 이동거리: ${(totalDistance / 1000).toStringAsFixed(2)} km',
                      ),
                      Text('📍 기록 좌표: ${trackPoints.length}개'),
                      Text('👥 팀원: ${teamMembers.length}명'),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: showSosCountdown,
                    child: const Text(
                      '🚨 SOS',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isTracking ? stopTracking : startTracking,
                    child: Text(
                      isTracking ? '🛑 해루질 종료' : '🟢 해루질 시작',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
