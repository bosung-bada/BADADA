class TeamModel {
  final String id;
  final String name;
  final String ownerUid;
  final List<String> memberUids;
  final String createdAt;

  const TeamModel({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.memberUids,
    required this.createdAt,
  });

  factory TeamModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final membersMap = map['members'] as Map<dynamic, dynamic>? ?? {};

    return TeamModel(
      id: id,
      name: map['name'] ?? '',
      ownerUid: map['ownerUid'] ?? '',
      memberUids: membersMap.keys.map((key) => key.toString()).toList(),
      createdAt: map['createdAt'] ?? '',
    );
  }
}