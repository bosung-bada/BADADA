import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/team_member_location.dart';

class MapMarkers {
  static List<Marker> build({
    required List<TeamMemberLocation> teamMembers,
    required LatLng? currentPosition,
  }) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final markers = <Marker>[];

    for (final member in teamMembers) {
      if (member.uid == currentUid) continue;

      markers.add(
        Marker(
          point: LatLng(member.lat, member.lng),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          point: currentPosition,
          width: 70,
          height: 70,
          child: const Icon(
            Icons.my_location,
            color: Colors.green,
            size: 48,
          ),
        ),
      );
    }

    return markers;
  }
}