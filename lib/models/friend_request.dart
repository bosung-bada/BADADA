class FriendRequest {
  final String uid;
  final String nickname;
  final String status;

  const FriendRequest({
    required this.uid,
    required this.nickname,
    required this.status,
  });

  factory FriendRequest.fromMap(
    String uid,
    Map<dynamic, dynamic> map,
  ) {
    return FriendRequest(
      uid: uid,
      nickname: map['nickname'] ?? '',
      status: map['status'] ?? '',
    );
  }
}