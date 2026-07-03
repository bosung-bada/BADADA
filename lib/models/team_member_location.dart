class TeamMemberLocation {
  final String uid;
  final String name;
  final double lat;
  final double lng;
  final bool isTracking;
  final String updatedAt;

  const TeamMemberLocation({
    required this.uid,
    required this.name,
    required this.lat,
    required this.lng,
    required this.isTracking,
    required this.updatedAt,
  });

  factory TeamMemberLocation.fromMap(
    String uid,
    Map<dynamic, dynamic> map,
  ) {
    return TeamMemberLocation(
      uid: uid,
      name: map['name'] ?? '',
      lat: (map['lat'] ?? 0).toDouble(),
      lng: (map['lng'] ?? 0).toDouble(),
      isTracking: map['isTracking'] ?? false,
      updatedAt: map['updatedAt'] ?? '',
    );
  }
}