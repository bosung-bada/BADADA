import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/team_member_location.dart';
import '../services/location_share_service.dart';
import '../services/team_location_service.dart';

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

  bool isTracking = false;
  DateTime? startedAt;
  Duration trackingDuration = Duration.zero;
  double totalDistance = 0;

  @override
  void initState() {
    super.initState();
    loadCurrentLocation();

    teamSubscription = TeamLocationService.watchSelectedTeamLocations().listen((members) {
      setState(() {
        teamMembers = members;
      });
    });
  }

  @override
  void dispose() {
    positionStream?.cancel();
    teamSubscription?.cancel();
    trackingTimer?.cancel();
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

    LocationShareService.updateMyLocation(
      position: firstPoint,
      isTracking: true,
    );

    trackingTimer?.cancel();
    trackingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (startedAt == null) return;
      setState(() {
        trackingDuration = DateTime.now().difference(startedAt!);
      });
    });

    positionStream?.cancel();
    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
      ),
    ).listen((position) {
      final point = LatLng(position.latitude, position.longitude);

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

      LocationShareService.updateMyLocation(
        position: point,
        isTracking: true,
      );
    });
  }

  Future<void> stopTracking() async {
    await positionStream?.cancel();
    trackingTimer?.cancel();

    if (currentPosition != null) {
      LocationShareService.updateMyLocation(
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

  String formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  List<Marker> buildMarkers() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final markers = <Marker>[];

    if (currentPosition != null) {
      markers.add(
        Marker(
          point: currentPosition!,
          width: 60,
          height: 60,
          child: const Icon(
            Icons.my_location,
            size: 42,
          ),
        ),
      );
    }

    for (final member in teamMembers) {
      if (member.uid == currentUid) continue;

      markers.add(
        Marker(
          point: LatLng(member.lat, member.lng),
          width: 100,
          height: 76,
          child: Column(
            children: [
              const Icon(
                Icons.person_pin_circle,
                size: 42,
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

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final center = currentPosition ?? LatLng(36.8151, 127.1139);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
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
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: isTracking ? stopTracking : startTracking,
                child: Text(
                  isTracking ? '🛑 해루질 종료' : '🟢 해루질 시작',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}