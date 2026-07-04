import 'package:flutter/material.dart';

import '../models/friend_request.dart';
import '../services/friend_service.dart';
import '../services/user_profile_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController searchController = TextEditingController();

  bool isSearching = false;
  bool isSendingRequest = false;

  String? searchedNickname;
  String? searchedUid;
  String? message;

  Future<void> searchFriend() async {
    final nickname = searchController.text.trim();

    if (nickname.isEmpty) {
      setState(() {
        message = '닉네임을 입력해주세요.';
        searchedNickname = null;
        searchedUid = null;
      });
      return;
    }

    setState(() {
      isSearching = true;
      message = null;
      searchedNickname = null;
      searchedUid = null;
    });

    final uid = await UserProfileService.findUidByNickname(nickname);

    setState(() {
      isSearching = false;

      if (uid == null) {
        message = '해당 닉네임의 사용자를 찾을 수 없습니다.';
      } else {
        searchedNickname = nickname;
        searchedUid = uid;
      }
    });
  }

  Future<void> sendRequest() async {
    if (searchedUid == null || searchedNickname == null) return;

    setState(() {
      isSendingRequest = true;
    });

    try {
      final myNickname = await UserProfileService.getNickname();

      await FriendService.sendFriendRequest(
        targetUid: searchedUid!,
        myNickname: myNickname,
      );

      setState(() {
        message = '🌊 $searchedNickname님에게 해루질 친구 요청을 보냈습니다.';
      });
    } catch (e) {
      setState(() {
        message = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        isSendingRequest = false;
      });
    }
  }

  Widget buildRequestCard(FriendRequest request) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.waves),
        ),
        title: Text(request.nickname),
        subtitle: const Text('해루질 친구 요청을 보냈습니다.'),
        trailing: Wrap(
          spacing: 8,
          children: [
            ElevatedButton(
              onPressed: () {},
              child: const Text('수락'),
            ),
            OutlinedButton(
              onPressed: () {},
              child: const Text('거절'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('친구'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: '닉네임 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isSearching ? null : searchFriend,
                icon: const Icon(Icons.person_search),
                label: Text(isSearching ? '검색 중...' : '친구 검색'),
              ),
            ),

            const SizedBox(height: 16),

            if (message != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(message!),
                ),
              ),

            if (searchedUid != null)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(searchedNickname ?? '사용자'),
                  subtitle: Text('UID: $searchedUid'),
                  trailing: ElevatedButton(
                    onPressed: isSendingRequest ? null : sendRequest,
                    child: Text(isSendingRequest ? '전송 중' : '추가'),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '📨 받은 친구 요청',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),

            const SizedBox(height: 8),

            StreamBuilder<List<FriendRequest>>(
              stream: FriendService.watchReceivedRequests(),
              builder: (context, snapshot) {
                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return const Card(
                    child: ListTile(
                      leading: Icon(Icons.inbox),
                      title: Text('받은 친구 요청이 없습니다.'),
                    ),
                  );
                }

                return Column(
                  children: requests.map(buildRequestCard).toList(),
                );
              },
            ),

            const SizedBox(height: 16),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '👥 내 친구',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Expanded(
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text('친구가 없습니다.'),
                  subtitle: Text('친구 요청을 수락하면 여기에 표시됩니다.'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}