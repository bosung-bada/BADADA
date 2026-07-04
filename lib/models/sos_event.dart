class SosEvent {
  final String uid;
  final String name;
  final double lat;
  final double lng;
  final String status;
  final String createdAt;

  const SosEvent({
    required this.uid,
    required this.name,
    required this.lat,
    required this.lng,
    required this.status,
    required this.createdAt,
  });

  factory SosEvent.fromMap(String uid, Map<dynamic, dynamic> map) {
    return SosEvent(
      uid: uid,
      name: map['name']?.toString() ?? '팀원',
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
      status: map['status']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
    );
  }
}