import '../services/selected_team_service.dart';
import '../services/selected_team_service.dart';
import 'package:flutter/material.dart';

import '../models/friend_user.dart';
import '../models/team_model.dart';
import '../services/friend_service.dart';
import '../services/team_service.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final TextEditingController teamNameController = TextEditingController();
  final Set<String> selectedFriendUids = {};

Future<void> createTeam() async {
  final teamName = teamNameController.text.trim();

  if (teamName.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('팀 이름을 입력해주세요.')),
    );
    return;
  }

  if (selectedFriendUids.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('팀에 추가할 친구를 선택해주세요.')),
    );
    return;
  }

  try {
    await TeamService.createTeam(
      teamName: teamName,
      memberUids: selectedFriendUids.toList(),
    );

    setState(() {
      teamNameController.clear();
      selectedFriendUids.clear();
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('팀이 생성되었습니다.')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('팀 생성 실패: $e')),
    );
  }
}

  Widget buildFriendCheckbox(FriendUser friend) {
    final isSelected = selectedFriendUids.contains(friend.uid);

    return CheckboxListTile(
      value: isSelected,
      title: Text(friend.nickname),
      subtitle: const Text('BADADA 친구'),
      onChanged: (value) {
        setState(() {
          if (value == true) {
            selectedFriendUids.add(friend.uid);
          } else {
            selectedFriendUids.remove(friend.uid);
          }
        });
      },
    );
  }

Widget buildTeamCard(TeamModel team) {
  return Card(
    child: ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.groups),
      ),
      title: Text(team.name),
      subtitle: Text('멤버 ${team.memberUids.length}명'),
      trailing: const Icon(Icons.check_circle_outline),
      onTap: () async {
        await SelectedTeamService.saveSelectedTeam(
          teamId: team.id,
          teamName: team.name,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${team.name} 팀이 선택되었습니다.'),
          ),
        );
      },
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('팀'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: teamNameController,
              decoration: InputDecoration(
                hintText: '팀 이름 입력',
                prefixIcon: const Icon(Icons.edit),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '친구 선택',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 8),

            StreamBuilder<List<FriendUser>>(
              stream: FriendService.watchMyFriends(),
              builder: (context, snapshot) {
                final friends = snapshot.data ?? [];

                if (friends.isEmpty) {
                  return const Card(
                    child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('친구가 없습니다.'),
                      subtitle: Text('먼저 친구를 추가해주세요.'),
                    ),
                  );
                }

                return Card(
                  child: Column(
                    children: friends.map(buildFriendCheckbox).toList(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: createTeam,
                icon: const Icon(Icons.group_add),
                label: const Text('팀 만들기'),
              ),
            ),

            const SizedBox(height: 24),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '내 팀',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: StreamBuilder<List<TeamModel>>(
                stream: TeamService.watchMyTeams(),
                builder: (context, snapshot) {
                  final teams = snapshot.data ?? [];

                  if (teams.isEmpty) {
                    return const Card(
                      child: ListTile(
                        leading: Icon(Icons.groups),
                        title: Text('아직 팀이 없습니다.'),
                        subtitle: Text('친구를 선택해서 팀을 만들어보세요.'),
                      ),
                    );
                  }

                  return ListView(
                    children: teams.map(buildTeamCard).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}